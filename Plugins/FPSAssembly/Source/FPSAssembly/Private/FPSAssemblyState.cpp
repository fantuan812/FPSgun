#include "FPSAssemblyState.h"
#include "Dom/JsonObject.h"
#include "Serialization/JsonSerializer.h"
#include "Serialization/JsonWriter.h"
namespace
{
std::string Text(const FString& S) { return TCHAR_TO_UTF8(*S); }
FString Text(const std::string& S) { return UTF8_TO_TCHAR(S.c_str()); }
bool ExactText(const FString& S)
{
    FTCHARToUTF8 Encoded(*S); FUTF8ToTCHAR Decoded(Encoded.Get(), Encoded.Length());
    for (TCHAR C : S) if (C == 0) return false;
    return FString(Decoded.Length(), Decoded.Get()) == S;
}
bool ReadText(const TSharedPtr<FJsonObject>& O, const TCHAR* Key, FString& Out)
{
    return O && O->TryGetStringField(Key, Out) && Out.Len() <= 96 && ExactText(Out);
}
bool ReadInteger(const TSharedPtr<FJsonObject>& O, const TCHAR* Key, int32& Out)
{
    double Value = 0;
    if (!O || !O->TryGetNumberField(Key, Value) || !FMath::IsFinite(Value) ||
        Value < MIN_int32 || Value > MAX_int32 || Value != FMath::FloorToDouble(Value)) return false;
    Out = int32(Value); return true;
}
bool Fields(const TSharedPtr<FJsonObject>& O, std::initializer_list<const TCHAR*> Expected)
{
    if (!O || O->Values.Num() != int32(Expected.size())) return false;
    for (const auto* Key : Expected) if (!O->HasField(Key)) return false;
    return true;
}
}
bool FFPSAssemblyState::ToRules(fpsassembly::State& Out, FString& Reason) const
{
    const auto Reject = [&](const TCHAR* Why) { Reason = Why; return false; };
    if (Revision < 0 || Instances.Num() > 4096 || Links.Num() > Instances.Num()) return Reject(TEXT("State bounds"));
    fpsassembly::State Next; Next.revision = uint64(Revision);
    for (const auto& Item : Instances)
    {
        if (!ExactText(Item.Id) || !ExactText(Item.DefinitionId) || !ExactText(Item.BoundOwner)) return Reject(TEXT("Invalid text"));
        fpsassembly::Instance I;
        I.id = Text(Item.Id); I.definition_id = Text(Item.DefinitionId); I.durability = Item.Durability;
        I.quality = Item.Quality; I.bound_owner = Text(Item.BoundOwner); I.locked = Item.Locked;
        for (const auto& Pair : Item.Affixes)
        {
            if (!ExactText(Pair.Key)) return Reject(TEXT("Invalid affix text"));
            I.affixes.emplace(Text(Pair.Key), Pair.Value);
        }
        if (!Next.instances.emplace(I.id, I).second) return Reject(TEXT("Duplicate instance"));
    }
    for (const auto& Link : Links)
    {
        if (!ExactText(Link.Child) || !ExactText(Link.Parent) || !ExactText(Link.Slot)) return Reject(TEXT("Invalid link text"));
        Next.links.push_back({Text(Link.Child), Text(Link.Parent), Text(Link.Slot)});
    }
    Out = std::move(Next); Reason.Reset(); return true;
}
FFPSAssemblyState FFPSAssemblyState::FromRules(const fpsassembly::State& Source)
{
    FFPSAssemblyState Out; Out.Revision = int64(Source.revision);
    for (const auto& Pair : Source.instances)
    {
        const auto& I = Pair.second; FFPSPartInstance Item;
        Item.Id = Text(I.id); Item.DefinitionId = Text(I.definition_id); Item.Durability = I.durability;
        Item.Quality = I.quality; Item.BoundOwner = Text(I.bound_owner); Item.Locked = I.locked;
        for (const auto& A : I.affixes) Item.Affixes.Add(Text(A.first), A.second);
        Out.Instances.Add(MoveTemp(Item));
    }
    for (const auto& L : Source.links)
    {
        FFPSAssemblyLink Link; Link.Child = Text(L.child); Link.Parent = Text(L.parent); Link.Slot = Text(L.slot);
        Out.Links.Add(MoveTemp(Link));
    }
    return Out;
}
bool FPSAssemblyCodec::Encode(const FFPSAssemblyState& State, const fpsassembly::Catalog& Catalog, FString& Out, FString& Reason)
{
    fpsassembly::State Native;
    if (!State.ToRules(Native, Reason)) return false;
    if (!fpsassembly::Validate(Catalog, Native)) { Reason = TEXT("Invalid assembly state"); return false; }
    auto Root = MakeShared<FJsonObject>(); Root->SetNumberField(TEXT("schema_version"), SchemaVersion);
    // Decimal string avoids JSON double precision loss above 2^53.
    Root->SetStringField(TEXT("revision"), LexToString(State.Revision));
    TArray<TSharedPtr<FJsonValue>> Items;
    for (const auto& Pair : Native.instances)
    {
        const auto& I = Pair.second; auto O = MakeShared<FJsonObject>();
        O->SetStringField(TEXT("id"), Text(I.id)); O->SetStringField(TEXT("definition_id"), Text(I.definition_id));
        O->SetNumberField(TEXT("durability"), I.durability); O->SetNumberField(TEXT("quality"), I.quality);
        O->SetStringField(TEXT("bound_owner"), Text(I.bound_owner)); O->SetBoolField(TEXT("locked"), I.locked);
        auto Affixes = MakeShared<FJsonObject>(); for (const auto& A : I.affixes) Affixes->SetNumberField(Text(A.first), A.second);
        O->SetObjectField(TEXT("affixes"), Affixes); Items.Add(MakeShared<FJsonValueObject>(O));
    }
    Root->SetArrayField(TEXT("instances"), Items);
    std::sort(Native.links.begin(), Native.links.end(), [](const auto& A, const auto& B) { return A.child < B.child; });
    TArray<TSharedPtr<FJsonValue>> Links;
    for (const auto& L : Native.links)
    {
        auto O = MakeShared<FJsonObject>(); O->SetStringField(TEXT("child"), Text(L.child));
        O->SetStringField(TEXT("parent"), Text(L.parent)); O->SetStringField(TEXT("slot"), Text(L.slot));
        Links.Add(MakeShared<FJsonValueObject>(O));
    }
    Root->SetArrayField(TEXT("links"), Links);
    FString Candidate;
    if (!FJsonSerializer::Serialize(Root, TJsonWriterFactory<>::Create(&Candidate)) || FTCHARToUTF8(*Candidate).Length() > MaxBytes)
    { Reason = TEXT("Encoding size/failure"); return false; }
    Out = MoveTemp(Candidate); Reason.Reset(); return true;
}
bool FPSAssemblyCodec::Decode(const FString& Json, const fpsassembly::Catalog& Catalog, FFPSAssemblyState& Out, FString& Reason)
{
    const auto Reject = [&](const TCHAR* Why) { Reason = Why; return false; };
    if (Json.Len() > MaxBytes || FTCHARToUTF8(*Json).Length() > MaxBytes || !ExactText(Json)) return Reject(TEXT("Invalid payload size/text"));
    TSharedPtr<FJsonObject> Root;
    if (!FJsonSerializer::Deserialize(TJsonReaderFactory<>::Create(Json), Root) ||
        !Fields(Root, {TEXT("schema_version"), TEXT("revision"), TEXT("instances"), TEXT("links")})) return Reject(TEXT("Invalid DTO object"));
    int32 Version = 0;
    if (!ReadInteger(Root, TEXT("schema_version"), Version) || Version != SchemaVersion) return Reject(TEXT("Unsupported DTO version"));
    FString Revision;
    if (!ReadText(Root, TEXT("revision"), Revision) || Revision.IsEmpty() || Revision.Len() > 19) return Reject(TEXT("Invalid revision"));
    FFPSAssemblyState Candidate;
    for (TCHAR C : Revision)
    {
        if (C < '0' || C > '9' || Candidate.Revision > (MAX_int64 - (C - '0')) / 10) return Reject(TEXT("Revision overflow"));
        Candidate.Revision = Candidate.Revision * 10 + (C - '0');
    }
    if (LexToString(Candidate.Revision) != Revision) return Reject(TEXT("Noncanonical revision"));
    const TArray<TSharedPtr<FJsonValue>>* Items = nullptr; const TArray<TSharedPtr<FJsonValue>>* Links = nullptr;
    if (!Root->TryGetArrayField(TEXT("instances"), Items) || !Root->TryGetArrayField(TEXT("links"), Links) ||
        Items->Num() > int32(Catalog.max_instances) || Links->Num() > Items->Num()) return Reject(TEXT("Invalid array bounds"));
    for (const auto& Value : *Items)
    {
        if (!Value || Value->Type != EJson::Object) return Reject(TEXT("Invalid instance object"));
        const auto O = Value->AsObject(); FFPSPartInstance I;
        if (!Fields(O, {TEXT("id"), TEXT("definition_id"), TEXT("durability"), TEXT("quality"), TEXT("affixes"), TEXT("bound_owner"), TEXT("locked")}) ||
            !ReadText(O, TEXT("id"), I.Id) || !ReadText(O, TEXT("definition_id"), I.DefinitionId) ||
            !ReadText(O, TEXT("bound_owner"), I.BoundOwner) || !ReadInteger(O, TEXT("durability"), I.Durability) ||
            !ReadInteger(O, TEXT("quality"), I.Quality) || !O->TryGetBoolField(TEXT("locked"), I.Locked)) return Reject(TEXT("Invalid instance fields"));
        const TSharedPtr<FJsonObject>* Affixes = nullptr;
        if (!O->TryGetObjectField(TEXT("affixes"), Affixes) || !Affixes->IsValid() || (*Affixes)->Values.Num() > 16) return Reject(TEXT("Invalid affixes"));
        for (const auto& A : (*Affixes)->Values)
        {
            int32 Number = 0;
            if (!ReadInteger(*Affixes, *A.Key, Number)) return Reject(TEXT("Invalid affix number"));
            I.Affixes.Add(A.Key, Number);
        }
        Candidate.Instances.Add(MoveTemp(I));
    }
    for (const auto& Value : *Links)
    {
        if (!Value || Value->Type != EJson::Object) return Reject(TEXT("Invalid link object"));
        const auto O = Value->AsObject(); FFPSAssemblyLink L;
        if (!Fields(O, {TEXT("child"), TEXT("parent"), TEXT("slot")}) || !ReadText(O, TEXT("child"), L.Child) ||
            !ReadText(O, TEXT("parent"), L.Parent) || !ReadText(O, TEXT("slot"), L.Slot)) return Reject(TEXT("Invalid link fields"));
        Candidate.Links.Add(MoveTemp(L));
    }
    fpsassembly::State Native;
    if (!Candidate.ToRules(Native, Reason)) return false;
    if (!fpsassembly::Validate(Catalog, Native)) return Reject(TEXT("Invalid restored assembly"));
    Out = MoveTemp(Candidate); Reason.Reset(); return true;
}
