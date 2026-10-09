#pragma once
#include "CoreMinimal.h"
#include "Components/SceneComponent.h"
#include "FPSAssemblyVisuals.generated.h"
class UFPSAssemblyComponent;
class UStaticMeshComponent;
struct FStreamableHandle;
struct FFPSAssemblyState;

// Read-only presentation. Mount this scene component at the host's already-authorized weapon grip.
// Missing mesh, asset load failure, or removing this component never changes rules or damage.
UCLASS(ClassGroup=(FPS), meta=(BlueprintSpawnableComponent))
class FPSASSEMBLY_API UFPSAssemblyVisuals : public USceneComponent
{
    GENERATED_BODY()
public:
    // Private inventory preview for the owning player.
    UFUNCTION(BlueprintCallable) void Bind(UFPSAssemblyComponent* Source, const FString& WeaponInstance);
    // Multiplayer world view: consumes only the public selected-assembly projection.
    UFUNCTION(BlueprintCallable) void BindPresentation(UFPSAssemblyComponent* Source);
    UPROPERTY(BlueprintReadOnly) FString Status;
    virtual void EndPlay(const EEndPlayReason::Type Reason) override;
private:
    UPROPERTY(Transient) TObjectPtr<UFPSAssemblyComponent> Assembly;
    UPROPERTY(Transient) TArray<TObjectPtr<UStaticMeshComponent>> Meshes;
    FString Weapon;
    bool PublicView = false;
    bool ReadSnapshot(FFPSAssemblyState& Out, FString& Root, int64& Version) const;
    uint64 Generation = 0;
    TSharedPtr<FStreamableHandle> Loading;
    UFUNCTION() void Refresh();
    void Build(uint64 ExpectedGeneration, int64 ExpectedRevision);
    void Clear();
};
