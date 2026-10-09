#pragma once
#include "CoreMinimal.h"
#include "Components/ActorComponent.h"
#include "FPSAssemblyDefinition.h"
#include "FPSAssemblyState.h"
#include "FPSAssemblyPresentation.h"
#include "FPSAssemblyComponent.generated.h"

DECLARE_DYNAMIC_MULTICAST_DELEGATE(FFPSAssemblyChanged);
// The existing server inventory/transaction owner binds this, persists using expected revision CAS,
// and returns true ONLY after durable acceptance. No async true-before-commit is permitted.
DECLARE_DELEGATE_RetVal_ThreeParams(bool, FFPSAssemblyCommit, int64, const FFPSAssemblyState&, FString&);

UCLASS(ClassGroup=(FPS), meta=(BlueprintSpawnableComponent))
class FPSASSEMBLY_API UFPSAssemblyComponent : public UActorComponent
{
    GENERATED_BODY()
public:
    UFPSAssemblyComponent();
    UPROPERTY(EditAnywhere, BlueprintReadOnly) TObjectPtr<UFPSAssemblyCatalog> Catalog;
    UPROPERTY(BlueprintAssignable) FFPSAssemblyChanged OnChanged;
    UPROPERTY(BlueprintAssignable) FFPSAssemblyChanged OnPresentationChanged;
    FFPSAssemblyCommit CommitCandidate;
    // Trusted host equipment owner selects its already-committed visible root; no client RPC.
    bool SelectPresentation(const FString& WeaponInstance, FString& Reason);
    UFUNCTION(BlueprintPure) FFPSAssemblyPresentation GetPresentation() const { return Presentation; }
    // Server-only initialization/recovery. Caller is the trusted existing inventory owner.
    // No player RPC or client-supplied owner identity is exposed by this plugin.
    bool RestoreCommitted(const FFPSAssemblyState& Loaded, FString& Reason);
    bool TryApply(int64 ExpectedRevision, const FString& AuthorizedOwner, const TArray<FFPSAssemblyLink>& Edits, FString& Reason);
    UFUNCTION(BlueprintPure) FFPSAssemblyState GetState() const { return State; }
    UFUNCTION(BlueprintPure) bool IsReady(const FString& Weapon, FString& Reason) const;
    bool EvaluateStats(const FString& Weapon, TMap<FString, double>& Out, FString& Reason) const;
    virtual void GetLifetimeReplicatedProps(TArray<FLifetimeProperty>& Out) const override;
private:
    // Owner-only inventory data; remote world visuals require a host-produced public presentation DTO.
    UPROPERTY(ReplicatedUsing=OnRep_State) FFPSAssemblyState State;
    UPROPERTY(ReplicatedUsing=OnRep_Presentation) FFPSAssemblyPresentation Presentation;
    FString PresentedWeapon;
    bool MakePresentation(const fpsassembly::Catalog& D, const fpsassembly::State& S, const FString& Weapon,
        FFPSAssemblyPresentation& Out, FString& Reason) const;
    UFUNCTION() void OnRep_Presentation();
    bool Initialized = false;
    bool Committing = false;
    UFUNCTION() void OnRep_State();
    bool Native(fpsassembly::Catalog& Definitions, fpsassembly::State& Value, FString& Reason) const;
};
