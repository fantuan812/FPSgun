#include "FPSAssemblyState.h"
#include "Misc/AutomationTest.h"
#if WITH_DEV_AUTOMATION_TESTS
IMPLEMENT_SIMPLE_AUTOMATION_TEST(FFPSAssemblyCodecTest, "FPSAssembly.Codec.AtomicRoundTrip", EAutomationTestFlags::EditorContext | EAutomationTestFlags::EngineFilter)
bool FFPSAssemblyCodecTest::RunTest(const FString& Parameters)
{
    fpsassembly::Catalog Catalog; fpsassembly::Definition Definition;
    Definition.id = "test.root"; Definition.weapon_root = true; Definition.max_durability = 100;
    Catalog.definitions.emplace(Definition.id, Definition);
    FFPSAssemblyState State; State.Revision = 9007199254740993LL;
    FFPSPartInstance Item; Item.Id = TEXT("root"); Item.DefinitionId = TEXT("test.root");
    Item.Durability = 73; Item.Quality = 4; Item.BoundOwner = TEXT("owner"); Item.Locked = true;
    Item.Affixes.Add(TEXT("affix.test"), 7); State.Instances.Add(Item);
    FString Json, Reason;
    TestTrue(TEXT("Encode"), FPSAssemblyCodec::Encode(State, Catalog, Json, Reason));
    FFPSAssemblyState Decoded;
    TestTrue(TEXT("Decode"), FPSAssemblyCodec::Decode(Json, Catalog, Decoded, Reason));
    TestEqual(TEXT("Revision does not round through JSON double"), Decoded.Revision, State.Revision);
    if (Decoded.Instances.Num() != 1) { AddError(TEXT("Missing decoded instance")); return false; }
    TestEqual(TEXT("Durability"), Decoded.Instances[0].Durability, 73);
    TestEqual(TEXT("Quality"), Decoded.Instances[0].Quality, 4);
    TestEqual(TEXT("Affix"), Decoded.Instances[0].Affixes.FindRef(TEXT("affix.test")), 7);
    TestEqual(TEXT("Bound owner"), Decoded.Instances[0].BoundOwner, FString(TEXT("owner")));
    TestTrue(TEXT("Locked preserved"), Decoded.Instances[0].Locked);
    const FString Duplicate = TEXT("{\"schema_version\":1,\"revision\":\"0\",\"revision\":\"1\",\"instances\":[],\"links\":[]}");
    TestFalse(TEXT("Duplicate field rejected"), FPSAssemblyCodec::Decode(Duplicate, Catalog, Decoded, Reason));
    TestEqual(TEXT("Rejected decode leaves revision"), Decoded.Revision, State.Revision);
    TestEqual(TEXT("Rejected decode leaves item"), Decoded.Instances[0].Durability, 73);
    TestFalse(TEXT("Truncated JSON rejected"), FPSAssemblyCodec::Decode(Json.Left(Json.Len()/2), Catalog, Decoded, Reason));
    TestEqual(TEXT("Truncated decode unchanged"), Decoded.Revision, State.Revision);
    const FString Future = TEXT("{\"schema_version\":2,\"revision\":\"0\",\"instances\":[],\"links\":[]}");
    TestFalse(TEXT("Unknown version rejected"), FPSAssemblyCodec::Decode(Future, Catalog, Decoded, Reason));
    return true;
}
#endif
