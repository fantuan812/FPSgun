#include "FPSAssemblyComponent.h"
#include "GameFramework/Actor.h"
#include "Net/UnrealNetwork.h"
namespace
{
bool ExactId(const FString& Value, bool AllowEmpty = false)
{
    if (AllowEmpty && Value.IsEmpty()) return true;
    const std::string Native = TCHAR_TO_UTF8(*Value);
    return fpsassembly::StableId(Native) && Value.Equals(UTF8_TO_TCHAR(Native.c_str()), ESearchCase::CaseSensitive);
}
FString RuleReason(const fpsassembly::Result& R)
{
    return FString::Printf(TEXT("Assembly rule %d: %s / %s"), int32(R.code), UTF8_TO_TCHAR(R.instance.c_str()), UTF8_TO_TCHAR(R.detail.c_str()));
}
}
UFPSAssemblyComponent::UFPSAssemblyComponent() { SetIsReplicatedByDefault(true); PrimaryComponentTick.bCanEverTick = false; }
void UFPSAssemblyComponent::GetLifetimeReplicatedProps(TArray<FLifetimeProperty>& Out) const
{
    Super::GetLifetimeReplicatedProps(Out); DOREPLIFETIME_CONDITION(UFPSAssemblyComponent, State, COND_OwnerOnly);
    DOREPLIFETIME(UFPSAssemblyComponent, Presentation);
}
void UFPSAssemblyComponent::OnRep_Presentation() { OnPresentationChanged.Broadcast(); }
void UFPSAssemblyComponent::OnRep_State() { Initialized = true; OnChanged.Broadcast(); }
bool UFPSAssemblyComponent::Native(fpsassembly::Catalog& Definitions, fpsassembly::State& Value, FString& Reason) const
{
    if (!Initialized || !Catalog) { Reason = TEXT("Assembly not initialized"); return false; }
    return Catalog->Compile(Definitions, Reason) && State.ToRules(Value, Reason);
}
bool UFPSAssemblyComponent::RestoreCommitted(const FFPSAssemblyState& Loaded, FString& Reason)
{
    if (!IsInGameThread() || !GetOwner() || !GetOwner()->HasAuthority() || Committing || !Catalog)
    { Reason = TEXT("Trusted server restore unavailable"); return false; }
    fpsassembly::Catalog D; fpsassembly::State S;
    if (!Catalog->Compile(D, Reason) || !Loaded.ToRules(S, Reason)) return false;
    if (const auto R = fpsassembly::Validate(D, S); !R) { Reason = RuleReason(R); return false; }
    // A runtime refresh cannot roll back an accepted version. Initial reconnect may restore any valid revision.
    if (Initialized && Loaded.Revision <= State.Revision) { Reason = TEXT("Stale restore"); return false; }
    FFPSAssemblyPresentation View;
    FString Selected = PresentedWeapon;
    if (!S.instances.count(TCHAR_TO_UTF8(*Selected))) Selected.Reset();
    if (!MakePresentation(D, S, Selected, View, Reason)) return false;
    State = Loaded; PresentedWeapon = Selected; Presentation = MoveTemp(View);
    Initialized = true; Reason.Reset(); OnChanged.Broadcast(); OnPresentationChanged.Broadcast(); return true;
}
bool UFPSAssemblyComponent::TryApply(int64 ExpectedRevision, const FString& AuthorizedOwner, const TArray<FFPSAssemblyLink>& Edits, FString& Reason)
{
    if (!IsInGameThread() || !GetOwner() || !GetOwner()->HasAuthority() || Committing || !CommitCandidate.IsBound())
    { Reason = TEXT("Server inventory commit owner unavailable"); return false; }
    if (!ExactId(AuthorizedOwner) || ExpectedRevision < 0 || State.Revision == MAX_int64 || Edits.Num() > 4096)
    { Reason = TEXT("Invalid revision/edit bounds"); return false; }
    fpsassembly::Catalog D; fpsassembly::State Before, Candidate;
    if (!Native(D, Before, Reason)) return false;
    fpsassembly::Request Request; Request.expected_revision = uint64(ExpectedRevision); Request.owner = TCHAR_TO_UTF8(*AuthorizedOwner);
    for (const auto& E : Edits)
    {
        if (!ExactId(E.Child) || !ExactId(E.Parent, true) || !ExactId(E.Slot, true)) { Reason = TEXT("Invalid edit ID"); return false; }
        Request.edits.push_back({TCHAR_TO_UTF8(*E.Child), TCHAR_TO_UTF8(*E.Parent), TCHAR_TO_UTF8(*E.Slot)});
    }
    if (const auto R = fpsassembly::Prepare(D, Before, Request, Candidate); !R) { Reason = RuleReason(R); return false; }
    const FFPSAssemblyState Proposed = FFPSAssemblyState::FromRules(Candidate);
    FFPSAssemblyPresentation View;
    if (!MakePresentation(D, Candidate, PresentedWeapon, View, Reason)) return false;
    bool Accepted = false;
    {
        TGuardValue<bool> Guard(Committing, true);
        // On rejection there is no state mutation, visual notification, stat publication or revision advance.
        Accepted = CommitCandidate.Execute(State.Revision, Proposed, Reason);
    }
    if (!Accepted) return false;
    State = Proposed; Presentation = MoveTemp(View); Reason.Reset();
    OnChanged.Broadcast(); OnPresentationChanged.Broadcast(); return true;
}
bool UFPSAssemblyComponent::IsReady(const FString& Weapon, FString& Reason) const
{
    fpsassembly::Catalog D; fpsassembly::State S;
    if (!Native(D, S, Reason)) return false;
    const auto R = fpsassembly::ValidateReady(D, S, TCHAR_TO_UTF8(*Weapon));
    if (!R) { Reason = RuleReason(R); return false; }
    Reason.Reset(); return true;
}
bool UFPSAssemblyComponent::EvaluateStats(const FString& Weapon, TMap<FString, double>& Out, FString& Reason) const
{
    fpsassembly::Catalog D; fpsassembly::State S; fpsassembly::Stats Values;
    if (!Native(D, S, Reason)) return false;
    const auto R = fpsassembly::Evaluate(D, S, TCHAR_TO_UTF8(*Weapon), Values);
    if (!R) { Reason = RuleReason(R); return false; }
    TMap<FString, double> Candidate;
    for (const auto& Pair : Values) Candidate.Add(UTF8_TO_TCHAR(Pair.first.c_str()), Pair.second);
    Out = MoveTemp(Candidate); Reason.Reset(); return true;
}

bool UFPSAssemblyComponent::MakePresentation(const fpsassembly::Catalog& D, const fpsassembly::State& S,
    const FString& Weapon, FFPSAssemblyPresentation& Out, FString& Reason) const
{
    if (!ExactId(Weapon, true) || Presentation.Serial == MAX_int64) { Reason = TEXT("Presentation serial exhausted"); return false; }
    FFPSAssemblyPresentation Next; Next.Serial = Presentation.Serial + 1; Next.SourceRevision = int64(S.revision); Next.Weapon = Weapon;
    if (!Weapon.IsEmpty())
    {
        fpsassembly::Index Index; const std::string Root = TCHAR_TO_UTF8(*Weapon);
        if (!fpsassembly::BuildIndex(D, S, Index) || !S.instances.count(Root) || Index.roots.at(Root) != Root ||
            !D.definitions.at(S.instances.at(Root).definition_id).weapon_root)
        { Reason = TEXT("Presentation root unavailable"); return false; }
        for (const auto& Id : Index.members.at(Root))
        {
            FFPSPresentedPart P; P.Id = UTF8_TO_TCHAR(Id.c_str()); P.DefinitionId = UTF8_TO_TCHAR(S.instances.at(Id).definition_id.c_str());
            Next.Parts.Add(MoveTemp(P));
        }
        for (const auto& Link : S.links) if (Index.roots.at(Link.child) == Root)
        {
            FFPSAssemblyLink L; L.Child = UTF8_TO_TCHAR(Link.child.c_str()); L.Parent = UTF8_TO_TCHAR(Link.parent.c_str()); L.Slot = UTF8_TO_TCHAR(Link.slot.c_str());
            Next.Links.Add(MoveTemp(L));
        }
    }
    Out = MoveTemp(Next); Reason.Reset(); return true;
}
bool UFPSAssemblyComponent::SelectPresentation(const FString& WeaponInstance, FString& Reason)
{
    if (!IsInGameThread() || !GetOwner() || !GetOwner()->HasAuthority() || Committing)
    { Reason = TEXT("Server equipment owner unavailable"); return false; }
    fpsassembly::Catalog D; fpsassembly::State S; FFPSAssemblyPresentation View;
    if (!Native(D, S, Reason) || !MakePresentation(D, S, WeaponInstance, View, Reason)) return false;
    PresentedWeapon = WeaponInstance; Presentation = MoveTemp(View); OnPresentationChanged.Broadcast(); return true;
}
