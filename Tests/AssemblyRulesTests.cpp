#include "AssemblyFixtures.h"
#include <cstdlib>
#include <iostream>
using namespace fpsassembly;
namespace
{
void Require(bool value, const char* name)
{
    if (!value) { std::cerr << "FAILED: " << name << '\n'; std::exit(1); }
}
bool SameState(const State& a, const State& b)
{
    return a.revision == b.revision && a.instances == b.instances && SameLinks(a.links, b.links);
}
Instance Part(const std::string& id, const std::string& definition)
{
    Instance i; i.id = id; i.definition_id = definition; i.durability = 100; return i;
}
void ExpectRejected(const Catalog& c, const State& s, Request r, Code expected, const char* name)
{
    const State before = s; State output = s; output.revision = 777; const State sentinel = output;
    const auto result = Prepare(c, s, r, output);
    Require(result.code == expected, name);
    Require(SameState(output, sentinel), "failure leaves candidate output unchanged");
    Require(SameState(s, before), "failure leaves original unchanged");
}
}
int main()
{
    const auto c = AuthoredCatalog(); const auto presets = AuthoredPresets();
    Require(bool(ValidateCatalog(c)), "authored catalog");
    Require(presets.size() == 7, "seven authored combinations");
    for (const auto& preset : presets)
    {
        Require(bool(Validate(c, preset.second)), preset.first.c_str());
        Require(bool(ValidateReady(c, preset.second, "root")), "all required authored slots populated");
        Stats values; Require(bool(Evaluate(c, preset.second, "root", values)), "finite authored stats");
    }
    const auto standard = presets.at("kite01.standard");
    State s = standard;
    s.instances.emplace("wrong_mag", Part("wrong_mag", "wisp02.magazine"));
    ExpectRejected(c, s, {0, "owner", {{"magazine", "", ""}, {"wrong_mag", "root", "magazine"}}}, Code::Incompatible, "cross-platform magazine");
    s = standard;
    s.instances.emplace("other_core", Part("other_core", "wisp02.core"));
    ExpectRejected(c, s, {0, "owner", {{"other_core", "root", "optic"}}}, Code::Incompatible, "core cannot attach");
    s = standard;
    s.instances.emplace("lamp", Part("lamp", "shared.light.compact"));
    ExpectRejected(c, s, {0, "owner", {{"lamp", "handguard.standard", "under_light"}}}, Code::Occupied, "under light and grip conflict");
    State candidate;
    Require(bool(Prepare(c, s, {0, "owner", {{"grip_addon", "", ""}, {"lamp", "handguard.standard", "under_light"}}}, candidate)), "atomic replacement");
    Require(candidate.instances == s.instances && candidate.revision == 1, "replacement conserves every instance and increments once");
    Require(bool(ValidateReady(c, candidate, "root")), "replacement ready");
    ExpectRejected(c, candidate, {0, "owner", {{"lamp", "", ""}}}, Code::StaleRevision, "stale command");
    s = standard;
    s.instances.emplace("micro", Part("micro", "shared.optic.micro"));
    ExpectRejected(c, s, {0, "owner", {{"sight", "", ""}, {"micro", "root", "optic"}}}, Code::Incompatible, "micro needs compatible adapter slot");
    s.instances.emplace("adapter", Part("adapter", "shared.adapter.universal_micro"));
    Require(bool(Prepare(c, s, {0, "owner", {{"sight", "", ""}, {"adapter", "root", "optic"}, {"micro", "adapter", "micro"}}}, candidate)), "nested adapter attach");
    Require(bool(ValidateReady(c, candidate, "root")), "adapter assembly ready");
    s = standard;
    Require(bool(Prepare(c, s, {0, "owner", {{"magazine", "", ""}}}, candidate)), "incomplete build is editable");
    Require(ValidateReady(c, candidate, "root").code == Code::RequiredSlot, "incomplete weapon cannot be used");
    s.instances.at("grip_addon").locked = true;
    ExpectRejected(c, s, {0, "owner", {{"handguard.standard", "", ""}}}, Code::Locked, "locked descendant protects whole subtree");
    s.instances.at("grip_addon").locked = false; s.instances.at("grip_addon").bound_owner = "other";
    ExpectRejected(c, s, {0, "owner", {{"handguard.standard", "", ""}}}, Code::Bound, "bound descendant cannot move through parent");
    ExpectRejected(c, standard, {0, "owner", {{"magazine", "unknown", "magazine"}}}, Code::MissingInstance, "unknown parent");
    ExpectRejected(c, standard, {0, "owner", {{"magazine", "root", "bogus"}}}, Code::UnknownSlot, "unknown slot");
    ExpectRejected(c, standard, {0, "owner", {{"magazine", "", ""}, {"magazine", "root", "magazine"}}}, Code::InvalidRequest, "duplicate edit");
    ExpectRejected(c, standard, {0, "owner", {{"magazine", "root", "magazine"}}}, Code::InvalidRequest, "no-op does not advance revision");
    auto invalid = standard; invalid.links.push_back(invalid.links.front());
    Require(!Validate(c, invalid), "duplicate child ownership rejected");
    invalid = standard; invalid.links[0].parent = "missing";
    Require(Validate(c, invalid).code == Code::MissingInstance, "dangling persisted reference rejected");
    auto limited = c; limited.max_parts_per_weapon = 2;
    Require(Validate(limited, standard).code == Code::Capacity, "bounded assembly size");
    limited = c; limited.max_depth = 1;
    Require(Validate(limited, standard).code == Code::Depth, "bounded nested depth");
    auto rules = c;
    auto& adapter = rules.definitions.at("shared.adapter.universal_micro");
    adapter.tags.insert("fixture.recursive"); adapter.slots[0].accepts_any.insert("fixture.recursive");
    State cycle; cycle.instances.emplace("a", Part("a", adapter.id)); cycle.instances.emplace("b", Part("b", adapter.id));
    cycle.links = {{"a", "b", "micro"}, {"b", "a", "micro"}};
    Require(Validate(rules, cycle).code == Code::Cycle, "cycle rejected");
    rules = c; rules.definitions.at("shared.optic.reflex").requires_all.insert("fixture.provider");
    Require(Validate(rules, standard).code == Code::Dependency, "missing dependency");
    rules.definitions.at("kite01.core").tags.insert("fixture.provider");
    Require(bool(Validate(rules, standard)), "data-only dependency provider");
    rules.definitions.at("shared.optic.reflex").excludes_any.insert("platform.kite01");
    Require(Validate(rules, standard).code == Code::Exclusion, "data-only exclusion");
    rules = c; rules.definitions.at("shared.optic.reflex").add_stats["handling"] = 5;
    rules.definitions.at("shared.optic.reflex").multiply_stats["handling"] = 0.5;
    Stats a, b; Require(bool(Evaluate(rules, standard, "root", a)), "data-only modifiers");
    auto reordered = standard; std::reverse(reordered.links.begin(), reordered.links.end());
    Require(bool(Evaluate(rules, reordered, "root", b)) && a == b, "deterministic aggregation");
    rules.definitions.at("shared.optic.reflex").multiply_stats["handling"] = std::numeric_limits<double>::infinity();
    Require(ValidateCatalog(rules).code == Code::InvalidDefinition, "nonfinite definition rejected");
    std::cout << "Assembly rule fixtures passed\n";
}
