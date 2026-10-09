#pragma once
#include "CoreMinimal.h"
#include "Rules/AssemblyRules.h"
#include "FPSAssemblyState.h"
#include "FPSAssemblyPresentation.generated.h"
USTRUCT(BlueprintType)
struct FPSASSEMBLY_API FFPSPresentedPart
{
    GENERATED_BODY()
    UPROPERTY(BlueprintReadOnly) FString Id;
    UPROPERTY(BlueprintReadOnly) FString DefinitionId;
};
// Public, read-only projection of exactly one selected assembly. Never carries private item metadata.
USTRUCT(BlueprintType)
struct FPSASSEMBLY_API FFPSAssemblyPresentation
{
    GENERATED_BODY()
    UPROPERTY(BlueprintReadOnly) int64 Serial = 0;
    UPROPERTY(BlueprintReadOnly) int64 SourceRevision = 0;
    UPROPERTY(BlueprintReadOnly) FString Weapon;
    UPROPERTY(BlueprintReadOnly) TArray<FFPSPresentedPart> Parts;
    UPROPERTY(BlueprintReadOnly) TArray<FFPSAssemblyLink> Links;
    bool ToRules(const fpsassembly::Catalog& Catalog, fpsassembly::State& Out, FString& Reason) const;
};
