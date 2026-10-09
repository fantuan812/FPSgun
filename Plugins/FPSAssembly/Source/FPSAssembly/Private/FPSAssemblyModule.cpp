#include "Modules/ModuleManager.h"
#include "GameplayTagsManager.h"
#include "Interfaces/IPluginManager.h"
#include "Misc/Paths.h"
class FFPSAssemblyModule final : public IModuleInterface
{
public:
    virtual void StartupModule() override
    {
        const auto Plugin = IPluginManager::Get().FindPlugin(TEXT("FPSAssembly"));
        if (Plugin) UGameplayTagsManager::Get().AddTagIniSearchPath(FPaths::Combine(Plugin->GetBaseDir(), TEXT("Config/Tags")));
    }
};
IMPLEMENT_MODULE(FFPSAssemblyModule, FPSAssembly)
