using UnrealBuildTool;
public class FPSAssembly : ModuleRules
{
    public FPSAssembly(ReadOnlyTargetRules Target) : base(Target)
    {
        PCHUsage = PCHUsageMode.UseExplicitOrSharedPCHs;
        CppStandard = CppStandardVersion.Cpp17;
        PublicDependencyModuleNames.AddRange(new[] { "Core", "CoreUObject", "Engine", "GameplayTags", "Niagara" });
        PrivateDependencyModuleNames.AddRange(new[] { "Json" });
    }
}
