#pragma once
#include "CoreMinimal.h"
#include "Engine/DataAsset.h"
#include "GameplayTagContainer.h"
#include "Rules/AssemblyRules.h"
#include "FPSAssemblyDefinition.generated.h"

class UStaticMesh;
class UAnimSequence;
class UNiagaraSystem;

USTRUCT(BlueprintType)
struct FPSASSEMBLY_API FFPSAssemblySlot
{
    GENERATED_BODY()
    UPROPERTY(EditAnywhere, BlueprintReadOnly) FString Id;
    UPROPERTY(EditAnywhere, BlueprintReadOnly) FGameplayTagContainer AcceptsAny;
    UPROPERTY(EditAnywhere, BlueprintReadOnly) bool Required = false;
    UPROPERTY(EditAnywhere, BlueprintReadOnly, meta=(ClampMin="1", ClampMax="16")) int32 Capacity = 1;
    UPROPERTY(EditAnywhere, BlueprintReadOnly) TArray<FString> OccupancyTokens;
    // Parent mesh origin -> child mesh entry origin. Unreal centimeters, left-handed +X forward/+Z up.
    UPROPERTY(EditAnywhere, BlueprintReadOnly) FTransform LocalTransform;
};

UCLASS(BlueprintType)
class FPSASSEMBLY_API UFPSAssemblyDefinition : public UPrimaryDataAsset
{
    GENERATED_BODY()
public:
    UPROPERTY(EditAnywhere, BlueprintReadOnly) FString Id;
    UPROPERTY(EditAnywhere, BlueprintReadOnly) bool WeaponRoot = false;
    UPROPERTY(EditAnywhere, BlueprintReadOnly) FGameplayTagContainer Tags;
    UPROPERTY(EditAnywhere, BlueprintReadOnly) FGameplayTagContainer RequiresAll;
    UPROPERTY(EditAnywhere, BlueprintReadOnly) FGameplayTagContainer ExcludesAny;
    UPROPERTY(EditAnywhere, BlueprintReadOnly) TArray<FFPSAssemblySlot> Slots;
    UPROPERTY(EditAnywhere, BlueprintReadOnly) TMap<FString, double> BaseStats;
    UPROPERTY(EditAnywhere, BlueprintReadOnly) TMap<FString, double> AddStats;
    UPROPERTY(EditAnywhere, BlueprintReadOnly) TMap<FString, double> MultiplyStats;
    UPROPERTY(EditAnywhere, BlueprintReadOnly, meta=(ClampMin="0")) int32 MaxDurability = 0;
    // Presentation references do not participate in rule decisions, costs or authoritative damage.
    UPROPERTY(EditAnywhere, BlueprintReadOnly) TSoftObjectPtr<UStaticMesh> Mesh;
    UPROPERTY(EditAnywhere, BlueprintReadOnly) TMap<FString, TSoftObjectPtr<UAnimSequence>> Animations;
    UPROPERTY(EditAnywhere, BlueprintReadOnly) TMap<FString, TSoftObjectPtr<UNiagaraSystem>> Effects;
    virtual FPrimaryAssetId GetPrimaryAssetId() const override { return FPrimaryAssetId(TEXT("FPSAssemblyPart"), FName(*Id)); }
};

UCLASS(BlueprintType)
class FPSASSEMBLY_API UFPSAssemblyCatalog : public UDataAsset
{
    GENERATED_BODY()
public:
    UPROPERTY(EditAnywhere, BlueprintReadOnly) TArray<TObjectPtr<UFPSAssemblyDefinition>> Definitions;
    UPROPERTY(EditAnywhere, BlueprintReadOnly, meta=(ClampMin="1", ClampMax="4096")) int32 MaxInstances = 256;
    UPROPERTY(EditAnywhere, BlueprintReadOnly, meta=(ClampMin="1", ClampMax="32")) int32 MaxDepth = 8;
    UPROPERTY(EditAnywhere, BlueprintReadOnly, meta=(ClampMin="1", ClampMax="256")) int32 MaxPartsPerWeapon = 64;
    const UFPSAssemblyDefinition* Find(const FString& Id) const;
    bool Compile(fpsassembly::Catalog& Out, FString& Reason) const;
};
