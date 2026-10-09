#include "FPSAssemblyVisuals.h"
#include "FPSAssemblyComponent.h"
#include "Components/StaticMeshComponent.h"
#include "Engine/AssetManager.h"
#include "Engine/StreamableManager.h"
#include "Engine/World.h"

void UFPSAssemblyVisuals::Clear()
{
    ++Generation;
    if (Loading) { Loading->CancelHandle(); Loading.Reset(); }
    for (UStaticMeshComponent* Mesh : Meshes) if (Mesh) Mesh->DestroyComponent();
    Meshes.Reset();
}
void UFPSAssemblyVisuals::Bind(UFPSAssemblyComponent* Source, const FString& WeaponInstance)
{
    if (Assembly)
    {
        Assembly->OnChanged.RemoveDynamic(this, &UFPSAssemblyVisuals::Refresh);
        Assembly->OnPresentationChanged.RemoveDynamic(this, &UFPSAssemblyVisuals::Refresh);
    }
    Clear(); Assembly = Source; Weapon = WeaponInstance; PublicView = false;
    if (Assembly) Assembly->OnChanged.AddDynamic(this, &UFPSAssemblyVisuals::Refresh);
    Refresh();
}
void UFPSAssemblyVisuals::BindPresentation(UFPSAssemblyComponent* Source)
{
    Bind(Source, FString()); PublicView = true;
    if (Assembly)
    {
        Assembly->OnChanged.RemoveDynamic(this, &UFPSAssemblyVisuals::Refresh);
        Assembly->OnPresentationChanged.AddDynamic(this, &UFPSAssemblyVisuals::Refresh);
    }
    Refresh();
}
bool UFPSAssemblyVisuals::ReadSnapshot(FFPSAssemblyState& Out, FString& Root, int64& Version) const
{
    if (!Assembly || !Assembly->Catalog) return false;
    if (!PublicView) { Out = Assembly->GetState(); Root = Weapon; Version = Out.Revision; return true; }
    fpsassembly::Catalog D; fpsassembly::State S; FString Reason;
    const auto View = Assembly->GetPresentation();
    if (!Assembly->Catalog->Compile(D, Reason) || !View.ToRules(D, S, Reason)) return false;
    Out = FFPSAssemblyState::FromRules(S); Root = View.Weapon; Version = View.Serial; return true;
}
void UFPSAssemblyVisuals::Refresh()
{
    Clear(); Status = TEXT("Unavailable");
    if (!Assembly || !Assembly->Catalog || !GetWorld() || GetWorld()->GetNetMode() == NM_DedicatedServer) return;
    FFPSAssemblyState Snapshot; FString RootId; int64 ViewVersion = 0;
    if (!ReadSnapshot(Snapshot, RootId, ViewVersion)) return;
    fpsassembly::Catalog D; fpsassembly::State S; fpsassembly::Index Index; FString Reason;
    if (!Assembly->Catalog->Compile(D, Reason) || !Snapshot.ToRules(S, Reason) || !fpsassembly::BuildIndex(D, S, Index)) return;
    const std::string Root = TCHAR_TO_UTF8(*RootId);
    if (!S.instances.count(Root) || Index.roots.at(Root) != Root || !D.definitions.at(S.instances.at(Root).definition_id).weapon_root) return;
    TArray<FSoftObjectPath> Paths;
    for (const auto& Id : Index.members.at(Root))
    {
        const auto* Definition = Assembly->Catalog->Find(UTF8_TO_TCHAR(S.instances.at(Id).definition_id.c_str()));
        if (!Definition || Definition->Mesh.IsNull()) { Status = TEXT("MissingMeshReference"); return; }
        Paths.AddUnique(Definition->Mesh.ToSoftObjectPath());
    }
    Status = TEXT("Loading");
    const uint64 Token = Generation; const int64 Revision = ViewVersion;
    Loading = UAssetManager::GetStreamableManager().RequestAsyncLoad(Paths,
        FStreamableDelegate::CreateWeakLambda(this, [this, Token, Revision]() { Build(Token, Revision); }));
    if (!Loading && Status == TEXT("Loading")) Status = TEXT("MeshLoadFailed");
}
void UFPSAssemblyVisuals::Build(uint64 ExpectedGeneration, int64 ExpectedRevision)
{
    if (Generation != ExpectedGeneration || !Assembly || !Assembly->Catalog) return;
    FFPSAssemblyState Snapshot; FString RootId; int64 ViewVersion = 0;
    if (!ReadSnapshot(Snapshot, RootId, ViewVersion) || ViewVersion != ExpectedRevision) return;
    fpsassembly::Catalog D; fpsassembly::State S; fpsassembly::Index Index; FString Reason;
    if (!Assembly->Catalog->Compile(D, Reason) || !Snapshot.ToRules(S, Reason) || !fpsassembly::BuildIndex(D, S, Index)) return;
    const std::string Root = TCHAR_TO_UTF8(*RootId);
    if (!Index.members.count(Root)) return;
    // Resolve all meshes before creating any component. Missing assets never leave half a gun visible.
    for (const auto& Id : Index.members.at(Root))
    {
        const auto* Def = Assembly->Catalog->Find(UTF8_TO_TCHAR(S.instances.at(Id).definition_id.c_str()));
        if (!Def || !Def->Mesh.Get()) { Status = TEXT("MeshLoadFailed"); return; }
    }
    std::map<std::string, UStaticMeshComponent*> Created;
    std::set<std::string> Remaining(Index.members.at(Root).begin(), Index.members.at(Root).end());
    while (!Remaining.empty())
    {
        bool Progress = false;
        for (auto It = Remaining.begin(); It != Remaining.end();)
        {
            const auto Id = *It;
            const fpsassembly::Link* Link = Index.parents.count(Id) ? Index.parents.at(Id) : nullptr;
            if (Link && !Created.count(Link->parent)) { ++It; continue; }
            USceneComponent* Parent = Link ? static_cast<USceneComponent*>(Created.at(Link->parent)) : this;
            const auto* Def = Assembly->Catalog->Find(UTF8_TO_TCHAR(S.instances.at(Id).definition_id.c_str()));
            FTransform Transform = FTransform::Identity;
            if (Link)
            {
                const auto* ParentDef = Assembly->Catalog->Find(UTF8_TO_TCHAR(S.instances.at(Link->parent).definition_id.c_str()));
                const auto* Slot = ParentDef->Slots.FindByPredicate([&](const auto& V) { return V.Id.Equals(UTF8_TO_TCHAR(Link->slot.c_str()), ESearchCase::CaseSensitive); });
                if (!Slot) { Clear(); Status = TEXT("InvalidVisualSlot"); return; }
                Transform = Slot->LocalTransform;
            }
            auto* Mesh = NewObject<UStaticMeshComponent>(GetOwner());
            Mesh->SetIsReplicated(false); Mesh->SetCollisionEnabled(ECollisionEnabled::NoCollision);
            Mesh->SetGenerateOverlapEvents(false); Mesh->SetCanEverAffectNavigation(false);
            Mesh->SetStaticMesh(Def->Mesh.Get()); Mesh->SetupAttachment(Parent);
            Mesh->SetRelativeTransform(Transform); Mesh->RegisterComponent();
            Meshes.Add(Mesh); Created.emplace(Id, Mesh); It = Remaining.erase(It); Progress = true;
        }
        if (!Progress) { Clear(); Status = TEXT("InvalidVisualTree"); return; }
    }
    Status = TEXT("Ready");
}
void UFPSAssemblyVisuals::EndPlay(const EEndPlayReason::Type Reason)
{
    if (Assembly)
    {
        Assembly->OnChanged.RemoveDynamic(this, &UFPSAssemblyVisuals::Refresh);
        Assembly->OnPresentationChanged.RemoveDynamic(this, &UFPSAssemblyVisuals::Refresh);
    }
    Clear(); Assembly = nullptr; Super::EndPlay(Reason);
}
