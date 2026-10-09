#include "FPSAssemblyAuthoring.h"
#include "FPSAssemblyDefinition.h"
#include "Engine/StaticMesh.h"
#include "Animation/AnimSequence.h"
#include "NiagaraSystem.h"
#include "FPSAssemblyJson.h"
#include "Dom/JsonObject.h"
#include "Serialization/JsonSerializer.h"
namespace
{
bool Integer(const TSharedPtr<FJsonObject>& O, const TCHAR* Key, int32& Out)
{
    double V = 0;
    if (!O->TryGetNumberField(Key, V) || !FMath::IsFinite(V) || V != FMath::FloorToDouble(V) || V < 0 || V > MAX_int32) return false;
    Out = int32(V); return true;
}
bool String(const TSharedPtr<FJsonObject>& O, const TCHAR* Key, FString& Out)
{
    return O->TryGetStringField(Key, Out) && Out.Len() <= 96;
}
bool Tags(const TSharedPtr<FJsonObject>& O, const TCHAR* Key, FGameplayTagContainer& Out)
{
    const TArray<TSharedPtr<FJsonValue>>* Values = nullptr;
    if (!O->TryGetArrayField(Key, Values) || Values->Num() > 64) return false;
    TSet<FString> Seen;
    for (const auto& V : *Values)
    {
        FString S;
        if (!V || !V->TryGetString(S) || Seen.Contains(S) || !fpsassembly::StableId(TCHAR_TO_UTF8(*S))) return false;
        const FGameplayTag Tag = FGameplayTag::RequestGameplayTag(FName(*S), false);
        if (!Tag.IsValid()) return false; // Register authored tags through the plugin tag source before parsing.
        Seen.Add(S); Out.AddTag(Tag);
    }
    return true;
}
bool Stats(const TSharedPtr<FJsonObject>& O, const TCHAR* Key, TMap<FString, double>& Out)
{
    const TSharedPtr<FJsonObject>* Values = nullptr;
    if (!O->TryGetObjectField(Key, Values) || !Values->IsValid() || (*Values)->Values.Num() > 32) return false;
    for (const auto& Pair : (*Values)->Values)
    {
        double Number;
        if (!Pair.Value || !Pair.Value->TryGetNumber(Number) || !FMath::IsFinite(Number)) return false;
        Out.Add(Pair.Key, Number);
    }
    return true;
}
bool Numbers(const TSharedPtr<FJsonObject>& O, const TCHAR* Key, int32 Count, TArray<double>& Out)
{
    const TArray<TSharedPtr<FJsonValue>>* Values = nullptr;
    if (!O->TryGetArrayField(Key, Values) || Values->Num() != Count) return false;
    for (const auto& V : *Values)
    {
        double Number;
        if (!V || !V->TryGetNumber(Number) || !FMath::IsFinite(Number)) return false;
        Out.Add(Number);
    }
    return true;
}
bool SoftPath(const TSharedPtr<FJsonValue>& Value, FSoftObjectPath& Out)
{
    if (!Value) return false;
    if (Value->Type == EJson::Null) { Out.Reset(); return true; }
    FString S;
    if (!Value->TryGetString(S) || S.Len() > 512 || (!S.StartsWith(TEXT("/Game/")) && !S.StartsWith(TEXT("/FPSAssembly/")))) return false;
    FSoftObjectPath P(S);
    if (!P.IsValid() || !P.GetSubPathString().IsEmpty()) return false;
    Out = P; return true;
}
template <class Asset>
bool References(const TSharedPtr<FJsonObject>& O, const TCHAR* Key, TMap<FString, TSoftObjectPtr<Asset>>& Out)
{
    const TSharedPtr<FJsonObject>* Values = nullptr;
    if (!O->TryGetObjectField(Key, Values) || !Values->IsValid() || (*Values)->Values.Num() > 32) return false;
    for (const auto& Pair : (*Values)->Values)
    {
        FSoftObjectPath Path;
        if (!fpsassembly::StableId(TCHAR_TO_UTF8(*Pair.Key)) || !SoftPath(Pair.Value, Path)) return false;
        Out.Add(Pair.Key, TSoftObjectPtr<Asset>(Path));
    }
    return true;
}
}
UFPSAssemblyCatalog* UFPSAssemblyAuthoring::CreateTransientCatalog(UObject* Outer, const FString& Json, FString& Reason)
{
    const auto Reject = [&](const TCHAR* Why) -> UFPSAssemblyCatalog* { Reason = Why; return nullptr; };
    if (!IsInGameThread() || !Outer || Json.Len() > 2*1024*1024 || !FPSAssemblyJson::UniqueFields(Json)) return Reject(TEXT("Invalid authoring payload"));
    TSharedPtr<FJsonObject> Root;
    if (!FJsonSerializer::Deserialize(TJsonReaderFactory<>::Create(Json), Root) || !Root) return Reject(TEXT("Invalid authoring JSON"));
    int32 Version;
    if (!Integer(Root, TEXT("schema_version"), Version) || Version != 1) return Reject(TEXT("Unsupported authoring schema"));
    auto* Catalog = NewObject<UFPSAssemblyCatalog>(Outer);
    if (!Integer(Root, TEXT("max_instances"), Catalog->MaxInstances) || !Integer(Root, TEXT("max_depth"), Catalog->MaxDepth) ||
        !Integer(Root, TEXT("max_parts_per_weapon"), Catalog->MaxPartsPerWeapon)) return Reject(TEXT("Invalid authoring bounds"));
    const TSharedPtr<FJsonObject>* Definitions = nullptr;
    if (!Root->TryGetObjectField(TEXT("definitions"), Definitions) || !Definitions->IsValid() || (*Definitions)->Values.Num() > 4096) return Reject(TEXT("Invalid definitions"));
    for (const auto& Pair : (*Definitions)->Values)
    {
        if (!Pair.Value || Pair.Value->Type != EJson::Object) return Reject(TEXT("Invalid definition object"));
        const auto D = Pair.Value->AsObject(); auto* Asset = NewObject<UFPSAssemblyDefinition>(Catalog);
        if (!String(D, TEXT("id"), Asset->Id) || !Asset->Id.Equals(Pair.Key, ESearchCase::CaseSensitive) ||
            !D->TryGetBoolField(TEXT("weapon_root"), Asset->WeaponRoot) || !Tags(D, TEXT("tags"), Asset->Tags) ||
            !Tags(D, TEXT("requires_all"), Asset->RequiresAll) || !Tags(D, TEXT("excludes_any"), Asset->ExcludesAny) ||
            !Stats(D, TEXT("base_stats"), Asset->BaseStats) || !Stats(D, TEXT("add_stats"), Asset->AddStats) ||
            !Stats(D, TEXT("multiply_stats"), Asset->MultiplyStats) || !Integer(D, TEXT("max_durability"), Asset->MaxDurability))
            return Reject(TEXT("Invalid definition fields or unregistered tags"));
        const auto* MeshValue = D->Values.Find(TEXT("mesh")); FSoftObjectPath MeshPath;
        if (!MeshValue || !SoftPath(*MeshValue, MeshPath) || !References(D, TEXT("animations"), Asset->Animations) || !References(D, TEXT("effects"), Asset->Effects))
            return Reject(TEXT("Invalid presentation references"));
        Asset->Mesh = TSoftObjectPtr<UStaticMesh>(MeshPath);
        const TArray<TSharedPtr<FJsonValue>>* Slots = nullptr;
        if (!D->TryGetArrayField(TEXT("slots"), Slots) || Slots->Num() > 32) return Reject(TEXT("Invalid slot list"));
        for (const auto& Value : *Slots)
        {
            if (!Value || Value->Type != EJson::Object) return Reject(TEXT("Invalid slot object"));
            const auto O = Value->AsObject(); FFPSAssemblySlot S;
            if (!String(O, TEXT("id"), S.Id) || !Tags(O, TEXT("accepts_any"), S.AcceptsAny) ||
                !O->TryGetBoolField(TEXT("required"), S.Required) || !Integer(O, TEXT("capacity"), S.Capacity)) return Reject(TEXT("Invalid slot rule"));
            const TArray<TSharedPtr<FJsonValue>>* Tokens = nullptr;
            if (!O->TryGetArrayField(TEXT("occupancy_tokens"), Tokens) || Tokens->Num() > 64) return Reject(TEXT("Invalid occupancy"));
            for (const auto& Token : *Tokens)
            {
                FString Id; if (!Token || !Token->TryGetString(Id)) return Reject(TEXT("Invalid occupancy token"));
                S.OccupancyTokens.Add(Id);
            }
            const TSharedPtr<FJsonObject>* Transform = nullptr;
            if (!O->TryGetObjectField(TEXT("local_transform"), Transform) || !Transform->IsValid()) return Reject(TEXT("Missing local transform"));
            TArray<double> P, Q, Scale;
            if (!Numbers(*Transform, TEXT("translation_cm"), 3, P) || !Numbers(*Transform, TEXT("rotation_xyzw"), 4, Q) ||
                !Numbers(*Transform, TEXT("scale"), 3, Scale)) return Reject(TEXT("Invalid transform values"));
            S.LocalTransform = FTransform(FQuat(Q[0], Q[1], Q[2], Q[3]), FVector(P[0], P[1], P[2]), FVector(Scale[0], Scale[1], Scale[2]));
            Asset->Slots.Add(MoveTemp(S));
        }
        Catalog->Definitions.Add(Asset);
    }
    fpsassembly::Catalog Native;
    if (!Catalog->Compile(Native, Reason)) return nullptr;
    Reason.Reset(); return Catalog;
}
