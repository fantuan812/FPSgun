#include "FPSAssemblyDefinition.h"
namespace
{
std::string Text(const FString& Value) { return TCHAR_TO_UTF8(*Value); }
fpsassembly::Tags Tags(const FGameplayTagContainer& Source)
{
    fpsassembly::Tags Result;
    for (const auto& Tag : Source) Result.insert(Text(Tag.ToString()));
    return Result;
}
fpsassembly::Stats Stats(const TMap<FString, double>& Source)
{
    fpsassembly::Stats Result;
    for (const auto& Pair : Source) Result.emplace(Text(Pair.Key), Pair.Value);
    return Result;
}
}
const UFPSAssemblyDefinition* UFPSAssemblyCatalog::Find(const FString& Id) const
{
    for (const UFPSAssemblyDefinition* Definition : Definitions)
        if (Definition && Definition->Id.Equals(Id, ESearchCase::CaseSensitive)) return Definition;
    return nullptr;
}
bool UFPSAssemblyCatalog::Compile(fpsassembly::Catalog& Out, FString& Reason) const
{
    fpsassembly::Catalog Next;
    if (MaxInstances < 1 || MaxDepth < 1 || MaxPartsPerWeapon < 1) { Reason = TEXT("Invalid catalog bounds"); return false; }
    Next.max_instances = MaxInstances; Next.max_depth = MaxDepth; Next.max_parts_per_weapon = MaxPartsPerWeapon;
    for (const UFPSAssemblyDefinition* Asset : Definitions)
    {
        if (!Asset) { Reason = TEXT("Null definition"); return false; }
        fpsassembly::Definition D;
        D.id = Text(Asset->Id); D.weapon_root = Asset->WeaponRoot;
        D.tags = Tags(Asset->Tags); D.requires_all = Tags(Asset->RequiresAll); D.excludes_any = Tags(Asset->ExcludesAny);
        D.base_stats = Stats(Asset->BaseStats); D.add_stats = Stats(Asset->AddStats); D.multiply_stats = Stats(Asset->MultiplyStats);
        D.max_durability = Asset->MaxDurability;
        for (const auto& Slot : Asset->Slots)
        {
            const FVector Scale = Slot.LocalTransform.GetScale3D();
            if (Slot.Capacity < 1 || Slot.LocalTransform.ContainsNaN() || !Slot.LocalTransform.GetRotation().IsNormalized() ||
                Scale.X <= 0 || !Scale.Equals(FVector(Scale.X), 0.0001))
            { Reason = TEXT("Invalid slot transform/capacity"); return false; }
            fpsassembly::Slot S;
            S.id = Text(Slot.Id); S.accepts_any = Tags(Slot.AcceptsAny); S.required = Slot.Required; S.capacity = Slot.Capacity;
            for (const auto& Token : Slot.OccupancyTokens)
                if (!S.occupancy_tokens.insert(Text(Token)).second) { Reason = TEXT("Duplicate occupancy token"); return false; }
            D.slots.push_back(std::move(S));
        }
        if (!Next.definitions.emplace(D.id, D).second) { Reason = TEXT("Duplicate definition ID"); return false; }
    }
    const auto Result = fpsassembly::ValidateCatalog(Next);
    if (!Result) { Reason = FString::Printf(TEXT("Invalid catalog rule %d: %s"), int32(Result.code), UTF8_TO_TCHAR(Result.instance.c_str())); return false; }
    Out = std::move(Next); Reason.Reset(); return true;
}
