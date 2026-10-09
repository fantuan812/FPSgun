#pragma once
#include "CoreMinimal.h"
#include "Rules/AssemblyRules.h"
#include "FPSAssemblyState.generated.h"

USTRUCT(BlueprintType)
struct FPSASSEMBLY_API FFPSPartInstance
{
    GENERATED_BODY()
    UPROPERTY(EditAnywhere, BlueprintReadOnly, SaveGame) FString Id;
    UPROPERTY(EditAnywhere, BlueprintReadOnly, SaveGame) FString DefinitionId;
    UPROPERTY(EditAnywhere, BlueprintReadOnly, SaveGame) int32 Durability = -1;
    UPROPERTY(EditAnywhere, BlueprintReadOnly, SaveGame) int32 Quality = 0;
    UPROPERTY(EditAnywhere, BlueprintReadOnly, SaveGame) TMap<FString, int32> Affixes;
    UPROPERTY(EditAnywhere, BlueprintReadOnly, SaveGame) FString BoundOwner;
    UPROPERTY(EditAnywhere, BlueprintReadOnly, SaveGame) bool Locked = false;
};
USTRUCT(BlueprintType)
struct FPSASSEMBLY_API FFPSAssemblyLink
{
    GENERATED_BODY()
    UPROPERTY(EditAnywhere, BlueprintReadWrite, SaveGame) FString Child;
    UPROPERTY(EditAnywhere, BlueprintReadWrite, SaveGame) FString Parent;
    UPROPERTY(EditAnywhere, BlueprintReadWrite, SaveGame) FString Slot;
};
USTRUCT(BlueprintType)
struct FPSASSEMBLY_API FFPSAssemblyState
{
    GENERATED_BODY()
    UPROPERTY(VisibleAnywhere, BlueprintReadOnly, SaveGame) int64 Revision = 0;
    UPROPERTY(EditAnywhere, BlueprintReadOnly, SaveGame) TArray<FFPSPartInstance> Instances;
    UPROPERTY(EditAnywhere, BlueprintReadOnly, SaveGame) TArray<FFPSAssemblyLink> Links;
    bool ToRules(fpsassembly::State& Out, FString& Reason) const;
    static FFPSAssemblyState FromRules(const fpsassembly::State& Source);
};
namespace FPSAssemblyCodec
{
    // Explicit DTO version; does not serialize UObject pointers, asset paths or definition values.
    inline constexpr int32 SchemaVersion = 1;
    inline constexpr int32 MaxBytes = 2 * 1024 * 1024;
    FPSASSEMBLY_API bool Encode(const FFPSAssemblyState& State, const fpsassembly::Catalog& Catalog, FString& Out, FString& Reason);
    FPSASSEMBLY_API bool Decode(const FString& Json, const fpsassembly::Catalog& Catalog, FFPSAssemblyState& Out, FString& Reason);
}
