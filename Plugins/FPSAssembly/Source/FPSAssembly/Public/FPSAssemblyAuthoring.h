#pragma once
#include "CoreMinimal.h"
#include "Kismet/BlueprintFunctionLibrary.h"
#include "FPSAssemblyAuthoring.generated.h"
class UFPSAssemblyCatalog;
// Converts authored JSON to the same definition types used by assets. Creates transient objects only.
UCLASS()
class FPSASSEMBLY_API UFPSAssemblyAuthoring : public UBlueprintFunctionLibrary
{
    GENERATED_BODY()
public:
    UFUNCTION(BlueprintCallable, Category="FPS Assembly", meta=(DefaultToSelf="Outer"))
    static UFPSAssemblyCatalog* CreateTransientCatalog(UObject* Outer, const FString& Json, FString& Reason);
};
