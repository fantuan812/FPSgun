#include "FPSAssemblyPresentation.h"
bool FFPSAssemblyPresentation::ToRules(const fpsassembly::Catalog& Catalog, fpsassembly::State& Out, FString& Reason) const
{
    if (Serial < 0 || SourceRevision < 0 || Parts.Num() > int32(Catalog.max_parts_per_weapon) || Links.Num() > Parts.Num())
    { Reason = TEXT("Invalid public assembly bounds"); return false; }
    fpsassembly::State Candidate; Candidate.revision = uint64(SourceRevision);
    if (Weapon.IsEmpty())
    {
        if (!Parts.IsEmpty() || !Links.IsEmpty()) { Reason = TEXT("Hidden weapon has parts"); return false; }
        Out = std::move(Candidate); Reason.Reset(); return true;
    }
    for (const auto& P : Parts)
    {
        fpsassembly::Instance I; I.id = TCHAR_TO_UTF8(*P.Id); I.definition_id = TCHAR_TO_UTF8(*P.DefinitionId);
        const auto D = Catalog.definitions.find(I.definition_id);
        if (D == Catalog.definitions.end()) { Reason = TEXT("Unknown public definition"); return false; }
        // Synthetic default used ONLY by structural validation; never returned as item condition or combat stats.
        I.durability = D->second.max_durability > 0 ? D->second.max_durability : -1;
        if (!Candidate.instances.emplace(I.id, I).second) { Reason = TEXT("Duplicate public part"); return false; }
    }
    for (const auto& L : Links) Candidate.links.push_back({TCHAR_TO_UTF8(*L.Child), TCHAR_TO_UTF8(*L.Parent), TCHAR_TO_UTF8(*L.Slot)});
    fpsassembly::Index Index; const std::string Root = TCHAR_TO_UTF8(*Weapon);
    if (!fpsassembly::BuildIndex(Catalog, Candidate, Index) || !Candidate.instances.count(Root) ||
        Index.members.size() != 1 || Index.roots.at(Root) != Root || !Catalog.definitions.at(Candidate.instances.at(Root).definition_id).weapon_root)
    { Reason = TEXT("Invalid public assembly tree"); return false; }
    Out = std::move(Candidate); Reason.Reset(); return true;
}
