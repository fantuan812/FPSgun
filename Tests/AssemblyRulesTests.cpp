#include "AssemblyFixtures.h"
#include <cstdlib>
#include <iostream>
#include <fstream>
#include <string>
using namespace fpsassembly;
namespace
{
std::size_t Checks = 0;
void Require(bool value, const char* name)
{
    ++Checks;
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
int main(int argc, char** argv)
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
    // Additional production-rule boundaries, without invoking UE or a database.
    s = standard; s.revision = std::numeric_limits<std::uint64_t>::max();
    ExpectRejected(c, s, {s.revision, "owner", {{"magazine", "", ""}}}, Code::Overflow, "revision overflow");
    invalid = standard; invalid.instances.at("root").durability = 101;
    Require(Validate(c, invalid).code == Code::InvalidState, "restored durability out of definition range");
    invalid = standard; invalid.instances.at("root").quality = 6;
    Require(Validate(c, invalid).code == Code::InvalidState, "restored quality out of range");
    invalid = standard; invalid.instances.at("root").id = "different";
    Require(Validate(c, invalid).code == Code::InvalidState, "persisted map and instance identity disagree");
    invalid = standard; invalid.instances.at("root").definition_id = "missing.definition";
    Require(Validate(c, invalid).code == Code::InvalidState, "unknown restored definition");
    invalid = standard; invalid.instances.at("root").affixes["bad"] = -1;
    Require(Validate(c, invalid).code == Code::InvalidState, "negative restored affix");
    invalid = standard; invalid.links.push_back({"root", "root", "optic"});
    Require(Validate(c, invalid).code == Code::Cycle, "self-cycle");
    limited = c; limited.max_instances = static_cast<std::uint32_t>(standard.instances.size() - 1);
    Require(Validate(limited, standard).code == Code::Capacity, "inventory instance bound");
    limited = c; limited.max_parts_per_weapon = static_cast<std::uint32_t>(standard.instances.size());
    Require(bool(Validate(limited, standard)), "exact assembly capacity accepted");
    limited = c; limited.max_depth = 2;
    Require(bool(Validate(limited, standard)), "exact standard depth accepted");
    s = standard; s.instances.emplace("second_sight", Part("second_sight", "shared.optic.reflex"));
    ExpectRejected(c, s, {0, "owner", {{"second_sight", "root", "optic"}}}, Code::Occupied, "slot capacity independent of token conflict");
    ExpectRejected(c, standard, {0, "owner", {{"magazine", "", "magazine"}}}, Code::InvalidRequest, "partial detach fields");
    ExpectRejected(c, standard, {0, "", {{"magazine", "", ""}}}, Code::InvalidRequest, "empty owner");
    ExpectRejected(c, standard, {0, "owner", {}}, Code::InvalidRequest, "empty batch");
    s = standard;
    s.instances.emplace("lamp", Part("lamp", "shared.light.compact"));
    s.instances.at("lamp").quality = 5; s.instances.at("lamp").durability = 23;
    s.instances.at("lamp").affixes["skin.variant"] = 9; s.instances.at("lamp").bound_owner = "owner";
    Require(bool(Prepare(c, s, {0, "owner", {{"grip_addon", "", ""}, {"lamp", "handguard.standard", "under_light"}}}, candidate)), "own binding allows replacement");
    Require(candidate.instances == s.instances, "replacement preserves all instance metadata including detached part");
    Request reversed{0, "owner", {{"lamp", "handguard.standard", "under_light"}, {"grip_addon", "", ""}}};
    State order_candidate;
    Require(bool(Prepare(c, s, reversed, order_candidate)) && SameState(candidate, order_candidate), "batch order cannot expose intermediate occupancy");
    Require(bool(Prepare(c, s, reversed, s)) && SameState(s, candidate), "output alias is atomic on success");
    auto before_alias = s;
    const auto alias_failure = Prepare(c, s, {0, "owner", {{"lamp", "", ""}}}, s);
    Require(alias_failure.code == Code::StaleRevision && SameState(s, before_alias), "output alias unchanged on failure");
    rules = c; rules.definitions.at("shared.optic.reflex").requires_all.insert("mount.universal_optic");
    Require(Validate(rules, standard).code == Code::Dependency, "node cannot satisfy its own dependency tag");
    rules = c; rules.definitions.at("shared.optic.reflex").excludes_any.insert("mount.universal_optic");
    Require(bool(Validate(rules, standard)), "exclusion applies to other nodes, not self");
    rules = c; rules.definitions.at("shared.optic.reflex").multiply_stats["handling"] = -0.1;
    Require(ValidateCatalog(rules).code == Code::InvalidDefinition, "negative multiplier rejected");
    rules = c; rules.definitions.at("kite01.core").slots.push_back(rules.definitions.at("kite01.core").slots.front());
    Require(ValidateCatalog(rules).code == Code::InvalidDefinition, "duplicate authored slot ID rejected");
    rules = c; rules.definitions.at("kite01.core").slots.front().capacity = 2;
    Require(ValidateCatalog(rules).code == Code::InvalidDefinition, "multi-capacity exclusive token slot rejected");
    Stats expected_stats;
    rules = c;
    rules.definitions.at("kite01.core").base_stats = {{"example", 10}};
    for (auto& d : rules.definitions) { d.second.add_stats.clear(); d.second.multiply_stats.clear(); }
    rules.definitions.at("shared.optic.reflex").add_stats["example"] = 2;
    rules.definitions.at("shared.optic.reflex").multiply_stats["example"] = 3;
    rules.definitions.at("kite01.magazine").add_stats["example"] = 4;
    rules.definitions.at("kite01.magazine").multiply_stats["example"] = 0.5;
    Require(bool(Evaluate(rules, standard, "root", expected_stats)) && expected_stats.at("example") == 24,
        "base plus sum then product ordering is exact");
    Stats sentinel_stats{{"sentinel", 123}};
    invalid = standard; invalid.links.erase(std::remove_if(invalid.links.begin(), invalid.links.end(),
        [](const Link& l) { return l.child == "magazine"; }), invalid.links.end());
    Require(Evaluate(c, invalid, "root", sentinel_stats).code == Code::RequiredSlot &&
        sentinel_stats == Stats{{"sentinel", 123}}, "failed stat evaluation leaves output unchanged");
    // Separate parent instances may reuse occupancy tokens without cross-weapon interference.
    State two;
    for (const auto& prefix : {std::string("a."), std::string("b.")})
    {
        for (const auto& pair : standard.instances)
        {
            auto i = pair.second; i.id = prefix + i.id; two.instances.emplace(i.id, i);
        }
        for (const auto& l : standard.links) two.links.push_back({prefix + l.child, prefix + l.parent, l.slot});
    }
    Require(bool(Validate(c, two)) && bool(ValidateReady(c, two, "a.root")) && bool(ValidateReady(c, two, "b.root")),
        "occupancy scope is parent instance, not global token");
    Require(bool(ValidateReady(c, presets.at("wisp02.side_light"), "root")), "side lamp and lower grip coexist");
    // Actual validator result matrix for all authored parent-slot/child combinations.
    struct MatrixEntry { std::string parent, slot, child; bool accepted; Code code; };
    std::vector<MatrixEntry> matrix;
    for (const auto& parent : c.definitions) for (const auto& slot : parent.second.slots)
    {
        for (const auto& child : c.definitions)
        {
            State isolated; isolated.instances.emplace("p", Part("p", parent.first)); isolated.instances.emplace("c", Part("c", child.first));
            State out;
            const auto result = Prepare(c, isolated, {0, "owner", {{"c", "p", slot.id}}}, out);
            const bool expected = !child.second.weapon_root && Intersects(child.second.tags, slot.accepts_any);
            Require(bool(result) == expected, "exhaustive isolated authored edge matrix");
            if (result) Require(out.instances == isolated.instances && out.revision == 1 && bool(Validate(c, out)), "matrix accepted edge preserves ownership");
            matrix.push_back({parent.first, slot.id, child.first, bool(result), result.code});
        }
    }
    const auto RuleChecks = Checks;
    if (argc == 3 && std::string(argv[1]) == "--report")
    {
        std::ofstream report(argv[2]); Require(bool(report), "open machine-readable rule report");
        report << "{\n  \"status\": \"PASSED_PURE_CPP_RULES_ONLY\",\n  \"assertions\": " << RuleChecks
            << ",\n  \"preset_count\": " << presets.size() << ",\n  \"matrix_cases\": " << matrix.size()
            << ",\n  \"matrix_scope\": \"Isolated unoccupied parent-slot/child edits; full-tree and failure boundaries are separate assertions, not implied by a cell\",\n  \"matrix\": [\n";
        for (std::size_t n = 0; n < matrix.size(); ++n)
        {
            const auto& m = matrix[n];
            report << "    {\"parent\":\"" << m.parent << "\",\"slot\":\"" << m.slot
                << "\",\"child\":\"" << m.child << "\",\"accepted\":" << (m.accepted ? "true" : "false")
                << ",\"code\":" << static_cast<int>(m.code) << "}" << (n + 1 == matrix.size() ? "\n" : ",\n");
        }
        report << "  ],\n  \"limitations\": [\"No UE codec execution\",\"No network or database or GAS runtime\",\"No UE mesh import\"]\n}\n";
        Require(bool(report), "write machine-readable rule report");
    }
    else Require(argc == 1, "supported command line");
    std::cout << "Assembly rule fixtures passed: " << RuleChecks << " rule assertions; " << matrix.size() << " isolated edge cases; " << presets.size() << " presets\n";
}
