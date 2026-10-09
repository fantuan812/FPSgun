#pragma once
// Engine-independent, bounded game rules. No asset loading, sockets, damage or persistence side effects.
#include <algorithm>
#include <cmath>
#include <cstdint>
#include <limits>
#include <map>
#include <set>
#include <string>
#include <vector>

namespace fpsassembly
{
using Id = std::string;
using Tags = std::set<Id>;
using Stats = std::map<Id, double>;
struct Slot
{
    Id id;
    Tags accepts_any;
    bool required = false;
    std::uint32_t capacity = 1;
    // Tokens are exclusive within one parent instance, including across its different slots.
    Tags occupancy_tokens;
};
struct Definition
{
    Id id;
    bool weapon_root = false;
    Tags tags;
    Tags requires_all; // Another node in the same rooted assembly must provide each tag.
    Tags excludes_any; // Tags on any other node in the same rooted assembly.
    std::vector<Slot> slots;
    Stats base_stats; // Only weapon roots may define the base; parts contribute modifiers.
    Stats add_stats;
    Stats multiply_stats;
    std::int32_t max_durability = 0; // 0 disables wear; instances then use -1.
};
struct Catalog
{
    std::map<Id, Definition> definitions;
    std::uint32_t max_instances = 256;
    std::uint32_t max_depth = 8; // Root depth is zero.
    std::uint32_t max_parts_per_weapon = 64; // Includes root.
};
struct Instance
{
    Id id;
    Id definition_id;
    std::int32_t durability = -1;
    std::int32_t quality = 0;
    std::map<Id, std::int32_t> affixes;
    Id bound_owner;
    bool locked = false;
    bool operator==(const Instance& b) const
    {
        return id == b.id && definition_id == b.definition_id && durability == b.durability &&
            quality == b.quality && affixes == b.affixes && bound_owner == b.bound_owner && locked == b.locked;
    }
};
struct Link
{
    Id child;
    Id parent;
    Id slot;
    bool operator==(const Link& b) const { return child == b.child && parent == b.parent && slot == b.slot; }
};
struct State
{
    std::uint64_t revision = 0;
    // Every owned part remains here, attached or detached. Edits never create/delete/duplicate instances.
    std::map<Id, Instance> instances;
    std::vector<Link> links;
};
enum class Code
{
    Ok, InvalidDefinition, InvalidState, MissingInstance, UnknownSlot, Incompatible,
    Occupied, Cycle, Depth, Capacity, Dependency, Exclusion, RequiredSlot,
    StaleRevision, Locked, Bound, InvalidRequest, Overflow
};
struct Result
{
    Code code = Code::Ok;
    Id instance;
    Id detail;
    explicit operator bool() const { return code == Code::Ok; }
};
inline Result Fail(Code code, const Id& instance = {}, const Id& detail = {}) { return {code, instance, detail}; }
inline bool StableId(const Id& id)
{
    if (id.empty() || id.size() > 96) return false;
    for (const unsigned char c : id)
        if (!((c >= 'a' && c <= 'z') || (c >= '0' && c <= '9') || c == '.' || c == '_' || c == '-')) return false;
    return true;
}
inline bool ValidTags(const Tags& tags)
{
    if (tags.size() > 64) return false;
    for (const auto& tag : tags) if (!StableId(tag)) return false;
    return true;
}
inline bool Intersects(const Tags& a, const Tags& b)
{
    for (const auto& tag : a) if (b.count(tag)) return true;
    return false;
}
inline bool ValidStats(const Stats& stats, bool multiplier)
{
    if (stats.size() > 32) return false;
    for (const auto& pair : stats)
        if (!StableId(pair.first) || !std::isfinite(pair.second) ||
            (multiplier ? pair.second < 0 || pair.second > 100 : std::abs(pair.second) > 1000000)) return false;
    return true;
}
inline Result ValidateCatalog(const Catalog& c)
{
    if (c.definitions.empty() || c.definitions.size() > 4096 || c.max_instances == 0 || c.max_instances > 4096 ||
        c.max_depth == 0 || c.max_depth > 32 || c.max_parts_per_weapon == 0 || c.max_parts_per_weapon > 256)
        return Fail(Code::InvalidDefinition, {}, "catalog.bounds");
    for (const auto& pair : c.definitions)
    {
        const auto& d = pair.second;
        if (pair.first != d.id || !StableId(d.id) || !ValidTags(d.tags) || !ValidTags(d.requires_all) ||
            !ValidTags(d.excludes_any) || d.slots.size() > 32 || d.max_durability < 0 || d.max_durability > 1000000 ||
            !ValidStats(d.base_stats, false) || !ValidStats(d.add_stats, false) || !ValidStats(d.multiply_stats, true) ||
            (!d.weapon_root && !d.base_stats.empty())) return Fail(Code::InvalidDefinition, d.id);
        std::set<Id> ids;
        for (const auto& slot : d.slots)
        {
            if (!StableId(slot.id) || !ids.insert(slot.id).second || slot.accepts_any.empty() ||
                !ValidTags(slot.accepts_any) || !ValidTags(slot.occupancy_tokens) || slot.capacity == 0 || slot.capacity > 16 ||
                (slot.capacity != 1 && !slot.occupancy_tokens.empty()))
                return Fail(Code::InvalidDefinition, d.id, slot.id);
        }
    }
    return {};
}
struct Index
{
    std::map<Id, const Link*> parents;
    std::map<Id, Id> roots;
    std::map<Id, std::vector<Id>> members;
    std::map<std::pair<Id, Id>, std::uint32_t> slot_counts;
};
// Structural validity permits incomplete assemblies so players can remove a required magazine/handguard.
// Dependencies/exclusions are always checked; required slots are checked by ValidateReady at use time.
inline Result BuildIndex(const Catalog& c, const State& s, Index& out)
{
    if (const auto result = ValidateCatalog(c); !result) return result;
    if (s.instances.size() > c.max_instances || s.links.size() > s.instances.size()) return Fail(Code::Capacity);
    Index next;
    for (const auto& pair : s.instances)
    {
        const auto& i = pair.second;
        const auto found = c.definitions.find(i.definition_id);
        if (!StableId(i.id) || pair.first != i.id || found == c.definitions.end() || i.quality < 0 || i.quality > 5 ||
            i.affixes.size() > 16 || (!i.bound_owner.empty() && !StableId(i.bound_owner))) return Fail(Code::InvalidState, i.id);
        const auto& d = found->second;
        if (d.max_durability == 0 ? i.durability != -1 : i.durability < 0 || i.durability > d.max_durability)
            return Fail(Code::InvalidState, i.id, "durability");
        for (const auto& a : i.affixes)
            if (!StableId(a.first) || a.second < 0 || a.second > 1000000) return Fail(Code::InvalidState, i.id, "affix");
    }
    std::set<std::pair<Id, Id>> occupied;
    for (const auto& link : s.links)
    {
        const auto child = s.instances.find(link.child), parent = s.instances.find(link.parent);
        if (child == s.instances.end() || parent == s.instances.end()) return Fail(Code::MissingInstance, link.child);
        if (link.child == link.parent || !next.parents.emplace(link.child, &link).second) return Fail(Code::Cycle, link.child);
        const auto& cd = c.definitions.at(child->second.definition_id);
        const auto& pd = c.definitions.at(parent->second.definition_id);
        if (cd.weapon_root) return Fail(Code::Incompatible, link.child, "weapon.root.cannot.attach");
        const auto slot = std::find_if(pd.slots.begin(), pd.slots.end(), [&](const Slot& v) { return v.id == link.slot; });
        if (slot == pd.slots.end()) return Fail(Code::UnknownSlot, link.parent, link.slot);
        if (!Intersects(cd.tags, slot->accepts_any)) return Fail(Code::Incompatible, link.child, link.slot);
        auto& count = next.slot_counts[{link.parent, link.slot}];
        if (++count > slot->capacity) return Fail(Code::Occupied, link.parent, link.slot);
        for (const auto& token : slot->occupancy_tokens)
            if (!occupied.insert({link.parent, token}).second) return Fail(Code::Occupied, link.parent, token);
    }
    for (const auto& pair : s.instances)
    {
        Id cursor = pair.first;
        std::set<Id> seen;
        std::uint32_t depth = 0;
        while (next.parents.count(cursor))
        {
            if (!seen.insert(cursor).second) return Fail(Code::Cycle, pair.first);
            if (++depth > c.max_depth) return Fail(Code::Depth, pair.first);
            cursor = next.parents.at(cursor)->parent;
        }
        next.roots.emplace(pair.first, cursor);
        auto& members = next.members[cursor];
        members.push_back(pair.first);
        if (members.size() > c.max_parts_per_weapon) return Fail(Code::Capacity, cursor);
    }
    for (const auto& group : next.members)
    {
        // Detached subassemblies are permitted (e.g. an optic still mounted on its adapter).
        for (const auto& id : group.second)
        {
            const auto& d = c.definitions.at(s.instances.at(id).definition_id);
            Tags others;
            for (const auto& other : group.second) if (other != id)
            {
                const auto& tags = c.definitions.at(s.instances.at(other).definition_id).tags;
                others.insert(tags.begin(), tags.end());
            }
            for (const auto& needed : d.requires_all)
                if (!others.count(needed)) return Fail(Code::Dependency, id, needed);
            if (Intersects(d.excludes_any, others)) return Fail(Code::Exclusion, id);
        }
    }
    out = std::move(next);
    return {};
}
inline Result Validate(const Catalog& c, const State& s) { Index index; return BuildIndex(c, s, index); }
inline Result ValidateReady(const Catalog& c, const State& s, const Id& weapon)
{
    Index index;
    if (const auto result = BuildIndex(c, s, index); !result) return result;
    if (!s.instances.count(weapon)) return Fail(Code::MissingInstance, weapon);
    if (!c.definitions.at(s.instances.at(weapon).definition_id).weapon_root || index.roots.at(weapon) != weapon)
        return Fail(Code::Incompatible, weapon, "not.weapon.root");
    for (const auto& id : index.members.at(weapon))
    {
        const auto& d = c.definitions.at(s.instances.at(id).definition_id);
        for (const auto& slot : d.slots)
            if (slot.required && !index.slot_counts.count({id, slot.id})) return Fail(Code::RequiredSlot, id, slot.id);
    }
    return {};
}
struct Edit
{
    Id child;
    Id parent; // Empty means detach; slot must also be empty.
    Id slot;
};
struct Request
{
    std::uint64_t expected_revision = 0;
    Id owner;
    std::vector<Edit> edits;
};
inline bool SameLinks(std::vector<Link> a, std::vector<Link> b)
{
    const auto less = [](const Link& x, const Link& y) { return x.child < y.child; };
    std::sort(a.begin(), a.end(), less); std::sort(b.begin(), b.end(), less);
    return a == b;
}
// Produces a complete candidate. Host persists candidate atomically with inventory, then publishes.
// Output is untouched on failure. No auto-detach, hidden instance creation, partial edits or item loss.
inline Result Prepare(const Catalog& c, const State& current, const Request& request, State& output)
{
    Index before;
    if (const auto result = BuildIndex(c, current, before); !result) return result;
    if (request.expected_revision != current.revision) return Fail(Code::StaleRevision);
    if (!StableId(request.owner) || request.edits.empty() || request.edits.size() > c.max_instances)
        return Fail(Code::InvalidRequest);
    if (current.revision == std::numeric_limits<std::uint64_t>::max()) return Fail(Code::Overflow);
    State candidate = current;
    std::set<Id> edited, touched;
    for (const auto& edit : request.edits)
    {
        if (!edited.insert(edit.child).second || !current.instances.count(edit.child) ||
            (edit.parent.empty() != edit.slot.empty())) return Fail(Code::InvalidRequest, edit.child);
        if (!edit.parent.empty() && !current.instances.count(edit.parent)) return Fail(Code::MissingInstance, edit.parent);
        touched.insert(edit.child);
        if (!edit.parent.empty()) touched.insert(edit.parent);
        if (before.parents.count(edit.child)) touched.insert(before.parents.at(edit.child)->parent);
        candidate.links.erase(std::remove_if(candidate.links.begin(), candidate.links.end(),
            [&](const Link& link) { return link.child == edit.child; }), candidate.links.end());
        if (!edit.parent.empty()) candidate.links.push_back({edit.child, edit.parent, edit.slot});
    }
    Index after;
    if (const auto result = BuildIndex(c, candidate, after); !result) return result;
    // A lock/binding on any affected old or new assembly protects moves through ancestor edits too.
    std::set<Id> affected;
    for (const auto& id : touched)
    {
        const auto& old_members = before.members.at(before.roots.at(id));
        const auto& new_members = after.members.at(after.roots.at(id));
        affected.insert(old_members.begin(), old_members.end());
        affected.insert(new_members.begin(), new_members.end());
    }
    for (const auto& id : affected)
    {
        const auto& item = current.instances.at(id);
        if (item.locked) return Fail(Code::Locked, id);
        if (!item.bound_owner.empty() && item.bound_owner != request.owner) return Fail(Code::Bound, id);
    }
    if (SameLinks(current.links, candidate.links)) return Fail(Code::InvalidRequest, {}, "no.change");
    candidate.revision++;
    std::sort(candidate.links.begin(), candidate.links.end(), [](const Link& a, const Link& b) { return a.child < b.child; });
    output = std::move(candidate);
    return {};
}
inline Result Evaluate(const Catalog& c, const State& s, const Id& weapon, Stats& output)
{
    if (const auto result = ValidateReady(c, s, weapon); !result) return result;
    Index index;
    if (const auto result = BuildIndex(c, s, index); !result) return result;
    Stats sum = c.definitions.at(s.instances.at(weapon).definition_id).base_stats;
    Stats multipliers;
    // std::map instance order fixes aggregation order across authoring/network insertion order.
    for (const auto& id : index.members.at(weapon))
    {
        const auto& d = c.definitions.at(s.instances.at(id).definition_id);
        for (const auto& stat : d.add_stats) sum[stat.first] += stat.second;
        for (const auto& stat : d.multiply_stats)
        {
            auto found = multipliers.emplace(stat.first, 1.0).first;
            found->second *= stat.second;
            if (!std::isfinite(found->second)) return Fail(Code::Overflow, id, stat.first);
        }
    }
    for (auto& stat : sum)
    {
        if (multipliers.count(stat.first)) stat.second *= multipliers.at(stat.first);
        if (!std::isfinite(stat.second)) return Fail(Code::Overflow, weapon, stat.first);
    }
    output = std::move(sum);
    return {};
}
} // namespace fpsassembly
