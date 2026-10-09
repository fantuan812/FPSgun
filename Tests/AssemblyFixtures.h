#pragma once
#include "Rules/AssemblyRules.h"
// Generated authored data; not evidence that these fixtures passed.
inline fpsassembly::Catalog AuthoredCatalog() {
fpsassembly::Catalog c;
c.max_instances = 256;
c.max_depth = 8;
c.max_parts_per_weapon = 64;
{ fpsassembly::Definition d;
d.id = "kite01.charging_handle";
d.weapon_root = false;
d.tags.insert("mount.kite01.charging_handle");
d.tags.insert("platform.kite01");
d.max_durability = 100;
d.add_stats["handling"] = -1.0;
c.definitions.emplace(d.id, d); }
{ fpsassembly::Definition d;
d.id = "kite01.core";
d.weapon_root = true;
d.tags.insert("mount.kite01.core");
d.tags.insert("platform.kite01");
d.max_durability = 100;
d.base_stats["handling"] = 50.0;
d.base_stats["stability"] = 50.0;
{ fpsassembly::Slot s;
s.id = "charging_handle";
s.required = true;
s.capacity = 1;
s.accepts_any.insert("mount.kite01.charging_handle");
s.occupancy_tokens.insert("charging_handle");
d.slots.push_back(s); }
{ fpsassembly::Slot s;
s.id = "grip";
s.required = true;
s.capacity = 1;
s.accepts_any.insert("mount.kite01.grip");
s.occupancy_tokens.insert("grip");
d.slots.push_back(s); }
{ fpsassembly::Slot s;
s.id = "handguard.standard";
s.required = true;
s.capacity = 1;
s.accepts_any.insert("mount.kite01.handguard.standard");
s.occupancy_tokens.insert("handguard.standard");
d.slots.push_back(s); }
{ fpsassembly::Slot s;
s.id = "magazine";
s.required = true;
s.capacity = 1;
s.accepts_any.insert("mount.kite01.magazine");
s.occupancy_tokens.insert("magazine");
d.slots.push_back(s); }
{ fpsassembly::Slot s;
s.id = "muzzle";
s.required = true;
s.capacity = 1;
s.accepts_any.insert("mount.kite01.muzzle");
s.occupancy_tokens.insert("muzzle");
d.slots.push_back(s); }
{ fpsassembly::Slot s;
s.id = "optic";
s.required = false;
s.capacity = 1;
s.accepts_any.insert("mount.universal_optic");
s.occupancy_tokens.insert("optic");
d.slots.push_back(s); }
{ fpsassembly::Slot s;
s.id = "stock.standard";
s.required = true;
s.capacity = 1;
s.accepts_any.insert("mount.kite01.stock.standard");
s.occupancy_tokens.insert("stock.standard");
d.slots.push_back(s); }
{ fpsassembly::Slot s;
s.id = "trigger";
s.required = true;
s.capacity = 1;
s.accepts_any.insert("mount.kite01.trigger");
s.occupancy_tokens.insert("trigger");
d.slots.push_back(s); }
c.definitions.emplace(d.id, d); }
{ fpsassembly::Definition d;
d.id = "kite01.grip";
d.weapon_root = false;
d.tags.insert("mount.kite01.grip");
d.tags.insert("platform.kite01");
d.max_durability = 100;
d.add_stats["handling"] = -1.0;
c.definitions.emplace(d.id, d); }
{ fpsassembly::Definition d;
d.id = "kite01.handguard.standard";
d.weapon_root = false;
d.tags.insert("mount.kite01.handguard.standard");
d.tags.insert("platform.kite01");
d.max_durability = 100;
d.add_stats["handling"] = -1.0;
{ fpsassembly::Slot s;
s.id = "under_grip";
s.required = false;
s.capacity = 1;
s.accepts_any.insert("mount.under_grip");
s.occupancy_tokens.insert("under_shared");
d.slots.push_back(s); }
{ fpsassembly::Slot s;
s.id = "under_light";
s.required = false;
s.capacity = 1;
s.accepts_any.insert("mount.utility");
s.occupancy_tokens.insert("under_shared");
d.slots.push_back(s); }
c.definitions.emplace(d.id, d); }
{ fpsassembly::Definition d;
d.id = "kite01.magazine";
d.weapon_root = false;
d.tags.insert("mount.kite01.magazine");
d.tags.insert("platform.kite01");
d.max_durability = 100;
d.add_stats["handling"] = -1.0;
c.definitions.emplace(d.id, d); }
{ fpsassembly::Definition d;
d.id = "kite01.muzzle";
d.weapon_root = false;
d.tags.insert("mount.kite01.muzzle");
d.tags.insert("platform.kite01");
d.max_durability = 100;
d.add_stats["handling"] = -1.0;
c.definitions.emplace(d.id, d); }
{ fpsassembly::Definition d;
d.id = "kite01.stock.standard";
d.weapon_root = false;
d.tags.insert("mount.kite01.stock.standard");
d.tags.insert("platform.kite01");
d.max_durability = 100;
d.add_stats["handling"] = -1.0;
c.definitions.emplace(d.id, d); }
{ fpsassembly::Definition d;
d.id = "kite01.trigger";
d.weapon_root = false;
d.tags.insert("mount.kite01.trigger");
d.tags.insert("platform.kite01");
d.max_durability = 100;
d.add_stats["handling"] = -1.0;
c.definitions.emplace(d.id, d); }
{ fpsassembly::Definition d;
d.id = "mote03.core";
d.weapon_root = true;
d.tags.insert("mount.mote03.core");
d.tags.insert("platform.mote03");
d.max_durability = 100;
d.base_stats["handling"] = 50.0;
d.base_stats["stability"] = 50.0;
{ fpsassembly::Slot s;
s.id = "magazine";
s.required = true;
s.capacity = 1;
s.accepts_any.insert("mount.mote03.magazine");
s.occupancy_tokens.insert("magazine");
d.slots.push_back(s); }
{ fpsassembly::Slot s;
s.id = "slide";
s.required = true;
s.capacity = 1;
s.accepts_any.insert("mount.mote03.slide");
s.occupancy_tokens.insert("slide");
d.slots.push_back(s); }
{ fpsassembly::Slot s;
s.id = "trigger";
s.required = true;
s.capacity = 1;
s.accepts_any.insert("mount.mote03.trigger");
s.occupancy_tokens.insert("trigger");
d.slots.push_back(s); }
{ fpsassembly::Slot s;
s.id = "under_light";
s.required = false;
s.capacity = 1;
s.accepts_any.insert("mount.utility");
s.occupancy_tokens.insert("under_shared");
d.slots.push_back(s); }
c.definitions.emplace(d.id, d); }
{ fpsassembly::Definition d;
d.id = "mote03.magazine";
d.weapon_root = false;
d.tags.insert("mount.mote03.magazine");
d.tags.insert("platform.mote03");
d.max_durability = 100;
d.add_stats["handling"] = -1.0;
c.definitions.emplace(d.id, d); }
{ fpsassembly::Definition d;
d.id = "mote03.slide";
d.weapon_root = false;
d.tags.insert("mount.mote03.slide");
d.tags.insert("platform.mote03");
d.max_durability = 100;
d.add_stats["handling"] = -1.0;
{ fpsassembly::Slot s;
s.id = "optic";
s.required = false;
s.capacity = 1;
s.accepts_any.insert("mount.micro_optic");
s.occupancy_tokens.insert("optic");
d.slots.push_back(s); }
c.definitions.emplace(d.id, d); }
{ fpsassembly::Definition d;
d.id = "mote03.trigger";
d.weapon_root = false;
d.tags.insert("mount.mote03.trigger");
d.tags.insert("platform.mote03");
d.max_durability = 100;
d.add_stats["handling"] = -1.0;
c.definitions.emplace(d.id, d); }
{ fpsassembly::Definition d;
d.id = "shared.adapter.universal_micro";
d.weapon_root = false;
d.tags.insert("mount.universal_optic");
d.max_durability = 100;
d.add_stats["handling"] = -1.0;
{ fpsassembly::Slot s;
s.id = "micro";
s.required = false;
s.capacity = 1;
s.accepts_any.insert("mount.micro_optic");
s.occupancy_tokens.insert("micro");
d.slots.push_back(s); }
c.definitions.emplace(d.id, d); }
{ fpsassembly::Definition d;
d.id = "shared.grip.stub";
d.weapon_root = false;
d.tags.insert("mount.under_grip");
d.max_durability = 100;
d.add_stats["handling"] = -1.0;
c.definitions.emplace(d.id, d); }
{ fpsassembly::Definition d;
d.id = "shared.light.compact";
d.weapon_root = false;
d.tags.insert("mount.utility");
d.max_durability = 100;
d.add_stats["handling"] = -1.0;
c.definitions.emplace(d.id, d); }
{ fpsassembly::Definition d;
d.id = "shared.optic.micro";
d.weapon_root = false;
d.tags.insert("mount.micro_optic");
d.max_durability = 100;
d.add_stats["handling"] = -1.0;
c.definitions.emplace(d.id, d); }
{ fpsassembly::Definition d;
d.id = "shared.optic.reflex";
d.weapon_root = false;
d.tags.insert("mount.universal_optic");
d.max_durability = 100;
d.add_stats["handling"] = -1.0;
c.definitions.emplace(d.id, d); }
{ fpsassembly::Definition d;
d.id = "wisp02.charging_handle";
d.weapon_root = false;
d.tags.insert("mount.wisp02.charging_handle");
d.tags.insert("platform.wisp02");
d.max_durability = 100;
d.add_stats["handling"] = -1.0;
c.definitions.emplace(d.id, d); }
{ fpsassembly::Definition d;
d.id = "wisp02.core";
d.weapon_root = true;
d.tags.insert("mount.wisp02.core");
d.tags.insert("platform.wisp02");
d.max_durability = 100;
d.base_stats["handling"] = 50.0;
d.base_stats["stability"] = 50.0;
{ fpsassembly::Slot s;
s.id = "charging_handle";
s.required = true;
s.capacity = 1;
s.accepts_any.insert("mount.wisp02.charging_handle");
s.occupancy_tokens.insert("charging_handle");
d.slots.push_back(s); }
{ fpsassembly::Slot s;
s.id = "grip";
s.required = true;
s.capacity = 1;
s.accepts_any.insert("mount.wisp02.grip");
s.occupancy_tokens.insert("grip");
d.slots.push_back(s); }
{ fpsassembly::Slot s;
s.id = "handguard.standard";
s.required = true;
s.capacity = 1;
s.accepts_any.insert("mount.wisp02.handguard.standard");
s.occupancy_tokens.insert("handguard.standard");
d.slots.push_back(s); }
{ fpsassembly::Slot s;
s.id = "magazine";
s.required = true;
s.capacity = 1;
s.accepts_any.insert("mount.wisp02.magazine");
s.occupancy_tokens.insert("magazine");
d.slots.push_back(s); }
{ fpsassembly::Slot s;
s.id = "muzzle";
s.required = true;
s.capacity = 1;
s.accepts_any.insert("mount.wisp02.muzzle");
s.occupancy_tokens.insert("muzzle");
d.slots.push_back(s); }
{ fpsassembly::Slot s;
s.id = "optic";
s.required = false;
s.capacity = 1;
s.accepts_any.insert("mount.universal_optic");
s.occupancy_tokens.insert("optic");
d.slots.push_back(s); }
{ fpsassembly::Slot s;
s.id = "stock.standard";
s.required = true;
s.capacity = 1;
s.accepts_any.insert("mount.wisp02.stock.standard");
s.occupancy_tokens.insert("stock.standard");
d.slots.push_back(s); }
{ fpsassembly::Slot s;
s.id = "trigger";
s.required = true;
s.capacity = 1;
s.accepts_any.insert("mount.wisp02.trigger");
s.occupancy_tokens.insert("trigger");
d.slots.push_back(s); }
c.definitions.emplace(d.id, d); }
{ fpsassembly::Definition d;
d.id = "wisp02.grip";
d.weapon_root = false;
d.tags.insert("mount.wisp02.grip");
d.tags.insert("platform.wisp02");
d.max_durability = 100;
d.add_stats["handling"] = -1.0;
c.definitions.emplace(d.id, d); }
{ fpsassembly::Definition d;
d.id = "wisp02.handguard.standard";
d.weapon_root = false;
d.tags.insert("mount.wisp02.handguard.standard");
d.tags.insert("platform.wisp02");
d.max_durability = 100;
d.add_stats["handling"] = -1.0;
{ fpsassembly::Slot s;
s.id = "side_light";
s.required = false;
s.capacity = 1;
s.accepts_any.insert("mount.utility");
s.occupancy_tokens.insert("side_utility");
d.slots.push_back(s); }
{ fpsassembly::Slot s;
s.id = "under_grip";
s.required = false;
s.capacity = 1;
s.accepts_any.insert("mount.under_grip");
s.occupancy_tokens.insert("under_shared");
d.slots.push_back(s); }
{ fpsassembly::Slot s;
s.id = "under_light";
s.required = false;
s.capacity = 1;
s.accepts_any.insert("mount.utility");
s.occupancy_tokens.insert("under_shared");
d.slots.push_back(s); }
c.definitions.emplace(d.id, d); }
{ fpsassembly::Definition d;
d.id = "wisp02.magazine";
d.weapon_root = false;
d.tags.insert("mount.wisp02.magazine");
d.tags.insert("platform.wisp02");
d.max_durability = 100;
d.add_stats["handling"] = -1.0;
c.definitions.emplace(d.id, d); }
{ fpsassembly::Definition d;
d.id = "wisp02.muzzle";
d.weapon_root = false;
d.tags.insert("mount.wisp02.muzzle");
d.tags.insert("platform.wisp02");
d.max_durability = 100;
d.add_stats["handling"] = -1.0;
c.definitions.emplace(d.id, d); }
{ fpsassembly::Definition d;
d.id = "wisp02.stock.standard";
d.weapon_root = false;
d.tags.insert("mount.wisp02.stock.standard");
d.tags.insert("platform.wisp02");
d.max_durability = 100;
d.add_stats["handling"] = -1.0;
c.definitions.emplace(d.id, d); }
{ fpsassembly::Definition d;
d.id = "wisp02.trigger";
d.weapon_root = false;
d.tags.insert("mount.wisp02.trigger");
d.tags.insert("platform.wisp02");
d.max_durability = 100;
d.add_stats["handling"] = -1.0;
c.definitions.emplace(d.id, d); }
return c; }
inline std::map<std::string, fpsassembly::State> AuthoredPresets() {
std::map<std::string, fpsassembly::State> states;
{ fpsassembly::State s;
s.revision = 0;
{ fpsassembly::Instance i;
i.id = "adapter";
i.definition_id = "shared.adapter.universal_micro";
i.durability = 100;
i.quality = 0;
s.instances.emplace(i.id, i); }
{ fpsassembly::Instance i;
i.id = "charging_handle";
i.definition_id = "kite01.charging_handle";
i.durability = 100;
i.quality = 0;
s.instances.emplace(i.id, i); }
{ fpsassembly::Instance i;
i.id = "grip";
i.definition_id = "kite01.grip";
i.durability = 100;
i.quality = 0;
s.instances.emplace(i.id, i); }
{ fpsassembly::Instance i;
i.id = "handguard.standard";
i.definition_id = "kite01.handguard.standard";
i.durability = 100;
i.quality = 0;
s.instances.emplace(i.id, i); }
{ fpsassembly::Instance i;
i.id = "light";
i.definition_id = "shared.light.compact";
i.durability = 100;
i.quality = 0;
s.instances.emplace(i.id, i); }
{ fpsassembly::Instance i;
i.id = "magazine";
i.definition_id = "kite01.magazine";
i.durability = 100;
i.quality = 0;
s.instances.emplace(i.id, i); }
{ fpsassembly::Instance i;
i.id = "muzzle";
i.definition_id = "kite01.muzzle";
i.durability = 100;
i.quality = 0;
s.instances.emplace(i.id, i); }
{ fpsassembly::Instance i;
i.id = "root";
i.definition_id = "kite01.core";
i.durability = 100;
i.quality = 0;
s.instances.emplace(i.id, i); }
{ fpsassembly::Instance i;
i.id = "sight";
i.definition_id = "shared.optic.micro";
i.durability = 100;
i.quality = 0;
s.instances.emplace(i.id, i); }
{ fpsassembly::Instance i;
i.id = "stock.standard";
i.definition_id = "kite01.stock.standard";
i.durability = 100;
i.quality = 0;
s.instances.emplace(i.id, i); }
{ fpsassembly::Instance i;
i.id = "trigger";
i.definition_id = "kite01.trigger";
i.durability = 100;
i.quality = 0;
s.instances.emplace(i.id, i); }
s.links.push_back({"adapter","root","optic"});
s.links.push_back({"charging_handle","root","charging_handle"});
s.links.push_back({"grip","root","grip"});
s.links.push_back({"handguard.standard","root","handguard.standard"});
s.links.push_back({"light","handguard.standard","under_light"});
s.links.push_back({"magazine","root","magazine"});
s.links.push_back({"muzzle","root","muzzle"});
s.links.push_back({"sight","adapter","micro"});
s.links.push_back({"stock.standard","root","stock.standard"});
s.links.push_back({"trigger","root","trigger"});
states.emplace("kite01.compact_optic", s); }
{ fpsassembly::State s;
s.revision = 0;
{ fpsassembly::Instance i;
i.id = "charging_handle";
i.definition_id = "kite01.charging_handle";
i.durability = 100;
i.quality = 0;
s.instances.emplace(i.id, i); }
{ fpsassembly::Instance i;
i.id = "grip";
i.definition_id = "kite01.grip";
i.durability = 100;
i.quality = 0;
s.instances.emplace(i.id, i); }
{ fpsassembly::Instance i;
i.id = "grip_addon";
i.definition_id = "shared.grip.stub";
i.durability = 100;
i.quality = 0;
s.instances.emplace(i.id, i); }
{ fpsassembly::Instance i;
i.id = "handguard.standard";
i.definition_id = "kite01.handguard.standard";
i.durability = 100;
i.quality = 0;
s.instances.emplace(i.id, i); }
{ fpsassembly::Instance i;
i.id = "magazine";
i.definition_id = "kite01.magazine";
i.durability = 100;
i.quality = 0;
s.instances.emplace(i.id, i); }
{ fpsassembly::Instance i;
i.id = "muzzle";
i.definition_id = "kite01.muzzle";
i.durability = 100;
i.quality = 0;
s.instances.emplace(i.id, i); }
{ fpsassembly::Instance i;
i.id = "root";
i.definition_id = "kite01.core";
i.durability = 100;
i.quality = 0;
s.instances.emplace(i.id, i); }
{ fpsassembly::Instance i;
i.id = "sight";
i.definition_id = "shared.optic.reflex";
i.durability = 100;
i.quality = 0;
s.instances.emplace(i.id, i); }
{ fpsassembly::Instance i;
i.id = "stock.standard";
i.definition_id = "kite01.stock.standard";
i.durability = 100;
i.quality = 0;
s.instances.emplace(i.id, i); }
{ fpsassembly::Instance i;
i.id = "trigger";
i.definition_id = "kite01.trigger";
i.durability = 100;
i.quality = 0;
s.instances.emplace(i.id, i); }
s.links.push_back({"charging_handle","root","charging_handle"});
s.links.push_back({"grip","root","grip"});
s.links.push_back({"grip_addon","handguard.standard","under_grip"});
s.links.push_back({"handguard.standard","root","handguard.standard"});
s.links.push_back({"magazine","root","magazine"});
s.links.push_back({"muzzle","root","muzzle"});
s.links.push_back({"sight","root","optic"});
s.links.push_back({"stock.standard","root","stock.standard"});
s.links.push_back({"trigger","root","trigger"});
states.emplace("kite01.standard", s); }
{ fpsassembly::State s;
s.revision = 0;
{ fpsassembly::Instance i;
i.id = "light";
i.definition_id = "shared.light.compact";
i.durability = 100;
i.quality = 0;
s.instances.emplace(i.id, i); }
{ fpsassembly::Instance i;
i.id = "magazine";
i.definition_id = "mote03.magazine";
i.durability = 100;
i.quality = 0;
s.instances.emplace(i.id, i); }
{ fpsassembly::Instance i;
i.id = "root";
i.definition_id = "mote03.core";
i.durability = 100;
i.quality = 0;
s.instances.emplace(i.id, i); }
{ fpsassembly::Instance i;
i.id = "sight";
i.definition_id = "shared.optic.micro";
i.durability = 100;
i.quality = 0;
s.instances.emplace(i.id, i); }
{ fpsassembly::Instance i;
i.id = "slide";
i.definition_id = "mote03.slide";
i.durability = 100;
i.quality = 0;
s.instances.emplace(i.id, i); }
{ fpsassembly::Instance i;
i.id = "trigger";
i.definition_id = "mote03.trigger";
i.durability = 100;
i.quality = 0;
s.instances.emplace(i.id, i); }
s.links.push_back({"light","root","under_light"});
s.links.push_back({"magazine","root","magazine"});
s.links.push_back({"sight","slide","optic"});
s.links.push_back({"slide","root","slide"});
s.links.push_back({"trigger","root","trigger"});
states.emplace("mote03.compact_optic", s); }
{ fpsassembly::State s;
s.revision = 0;
{ fpsassembly::Instance i;
i.id = "light";
i.definition_id = "shared.light.compact";
i.durability = 100;
i.quality = 0;
s.instances.emplace(i.id, i); }
{ fpsassembly::Instance i;
i.id = "magazine";
i.definition_id = "mote03.magazine";
i.durability = 100;
i.quality = 0;
s.instances.emplace(i.id, i); }
{ fpsassembly::Instance i;
i.id = "root";
i.definition_id = "mote03.core";
i.durability = 100;
i.quality = 0;
s.instances.emplace(i.id, i); }
{ fpsassembly::Instance i;
i.id = "slide";
i.definition_id = "mote03.slide";
i.durability = 100;
i.quality = 0;
s.instances.emplace(i.id, i); }
{ fpsassembly::Instance i;
i.id = "trigger";
i.definition_id = "mote03.trigger";
i.durability = 100;
i.quality = 0;
s.instances.emplace(i.id, i); }
s.links.push_back({"light","root","under_light"});
s.links.push_back({"magazine","root","magazine"});
s.links.push_back({"slide","root","slide"});
s.links.push_back({"trigger","root","trigger"});
states.emplace("mote03.standard", s); }
{ fpsassembly::State s;
s.revision = 0;
{ fpsassembly::Instance i;
i.id = "adapter";
i.definition_id = "shared.adapter.universal_micro";
i.durability = 100;
i.quality = 0;
s.instances.emplace(i.id, i); }
{ fpsassembly::Instance i;
i.id = "charging_handle";
i.definition_id = "wisp02.charging_handle";
i.durability = 100;
i.quality = 0;
s.instances.emplace(i.id, i); }
{ fpsassembly::Instance i;
i.id = "grip";
i.definition_id = "wisp02.grip";
i.durability = 100;
i.quality = 0;
s.instances.emplace(i.id, i); }
{ fpsassembly::Instance i;
i.id = "handguard.standard";
i.definition_id = "wisp02.handguard.standard";
i.durability = 100;
i.quality = 0;
s.instances.emplace(i.id, i); }
{ fpsassembly::Instance i;
i.id = "light";
i.definition_id = "shared.light.compact";
i.durability = 100;
i.quality = 0;
s.instances.emplace(i.id, i); }
{ fpsassembly::Instance i;
i.id = "magazine";
i.definition_id = "wisp02.magazine";
i.durability = 100;
i.quality = 0;
s.instances.emplace(i.id, i); }
{ fpsassembly::Instance i;
i.id = "muzzle";
i.definition_id = "wisp02.muzzle";
i.durability = 100;
i.quality = 0;
s.instances.emplace(i.id, i); }
{ fpsassembly::Instance i;
i.id = "root";
i.definition_id = "wisp02.core";
i.durability = 100;
i.quality = 0;
s.instances.emplace(i.id, i); }
{ fpsassembly::Instance i;
i.id = "sight";
i.definition_id = "shared.optic.micro";
i.durability = 100;
i.quality = 0;
s.instances.emplace(i.id, i); }
{ fpsassembly::Instance i;
i.id = "stock.standard";
i.definition_id = "wisp02.stock.standard";
i.durability = 100;
i.quality = 0;
s.instances.emplace(i.id, i); }
{ fpsassembly::Instance i;
i.id = "trigger";
i.definition_id = "wisp02.trigger";
i.durability = 100;
i.quality = 0;
s.instances.emplace(i.id, i); }
s.links.push_back({"adapter","root","optic"});
s.links.push_back({"charging_handle","root","charging_handle"});
s.links.push_back({"grip","root","grip"});
s.links.push_back({"handguard.standard","root","handguard.standard"});
s.links.push_back({"light","handguard.standard","under_light"});
s.links.push_back({"magazine","root","magazine"});
s.links.push_back({"muzzle","root","muzzle"});
s.links.push_back({"sight","adapter","micro"});
s.links.push_back({"stock.standard","root","stock.standard"});
s.links.push_back({"trigger","root","trigger"});
states.emplace("wisp02.compact_optic", s); }
{ fpsassembly::State s;
s.revision = 0;
{ fpsassembly::Instance i;
i.id = "charging_handle";
i.definition_id = "wisp02.charging_handle";
i.durability = 100;
i.quality = 0;
s.instances.emplace(i.id, i); }
{ fpsassembly::Instance i;
i.id = "grip";
i.definition_id = "wisp02.grip";
i.durability = 100;
i.quality = 0;
s.instances.emplace(i.id, i); }
{ fpsassembly::Instance i;
i.id = "grip_addon";
i.definition_id = "shared.grip.stub";
i.durability = 100;
i.quality = 0;
s.instances.emplace(i.id, i); }
{ fpsassembly::Instance i;
i.id = "handguard.standard";
i.definition_id = "wisp02.handguard.standard";
i.durability = 100;
i.quality = 0;
s.instances.emplace(i.id, i); }
{ fpsassembly::Instance i;
i.id = "magazine";
i.definition_id = "wisp02.magazine";
i.durability = 100;
i.quality = 0;
s.instances.emplace(i.id, i); }
{ fpsassembly::Instance i;
i.id = "muzzle";
i.definition_id = "wisp02.muzzle";
i.durability = 100;
i.quality = 0;
s.instances.emplace(i.id, i); }
{ fpsassembly::Instance i;
i.id = "root";
i.definition_id = "wisp02.core";
i.durability = 100;
i.quality = 0;
s.instances.emplace(i.id, i); }
{ fpsassembly::Instance i;
i.id = "side_light";
i.definition_id = "shared.light.compact";
i.durability = 100;
i.quality = 0;
s.instances.emplace(i.id, i); }
{ fpsassembly::Instance i;
i.id = "sight";
i.definition_id = "shared.optic.reflex";
i.durability = 100;
i.quality = 0;
s.instances.emplace(i.id, i); }
{ fpsassembly::Instance i;
i.id = "stock.standard";
i.definition_id = "wisp02.stock.standard";
i.durability = 100;
i.quality = 0;
s.instances.emplace(i.id, i); }
{ fpsassembly::Instance i;
i.id = "trigger";
i.definition_id = "wisp02.trigger";
i.durability = 100;
i.quality = 0;
s.instances.emplace(i.id, i); }
s.links.push_back({"charging_handle","root","charging_handle"});
s.links.push_back({"grip","root","grip"});
s.links.push_back({"grip_addon","handguard.standard","under_grip"});
s.links.push_back({"handguard.standard","root","handguard.standard"});
s.links.push_back({"magazine","root","magazine"});
s.links.push_back({"muzzle","root","muzzle"});
s.links.push_back({"side_light","handguard.standard","side_light"});
s.links.push_back({"sight","root","optic"});
s.links.push_back({"stock.standard","root","stock.standard"});
s.links.push_back({"trigger","root","trigger"});
states.emplace("wisp02.side_light", s); }
{ fpsassembly::State s;
s.revision = 0;
{ fpsassembly::Instance i;
i.id = "charging_handle";
i.definition_id = "wisp02.charging_handle";
i.durability = 100;
i.quality = 0;
s.instances.emplace(i.id, i); }
{ fpsassembly::Instance i;
i.id = "grip";
i.definition_id = "wisp02.grip";
i.durability = 100;
i.quality = 0;
s.instances.emplace(i.id, i); }
{ fpsassembly::Instance i;
i.id = "grip_addon";
i.definition_id = "shared.grip.stub";
i.durability = 100;
i.quality = 0;
s.instances.emplace(i.id, i); }
{ fpsassembly::Instance i;
i.id = "handguard.standard";
i.definition_id = "wisp02.handguard.standard";
i.durability = 100;
i.quality = 0;
s.instances.emplace(i.id, i); }
{ fpsassembly::Instance i;
i.id = "magazine";
i.definition_id = "wisp02.magazine";
i.durability = 100;
i.quality = 0;
s.instances.emplace(i.id, i); }
{ fpsassembly::Instance i;
i.id = "muzzle";
i.definition_id = "wisp02.muzzle";
i.durability = 100;
i.quality = 0;
s.instances.emplace(i.id, i); }
{ fpsassembly::Instance i;
i.id = "root";
i.definition_id = "wisp02.core";
i.durability = 100;
i.quality = 0;
s.instances.emplace(i.id, i); }
{ fpsassembly::Instance i;
i.id = "sight";
i.definition_id = "shared.optic.reflex";
i.durability = 100;
i.quality = 0;
s.instances.emplace(i.id, i); }
{ fpsassembly::Instance i;
i.id = "stock.standard";
i.definition_id = "wisp02.stock.standard";
i.durability = 100;
i.quality = 0;
s.instances.emplace(i.id, i); }
{ fpsassembly::Instance i;
i.id = "trigger";
i.definition_id = "wisp02.trigger";
i.durability = 100;
i.quality = 0;
s.instances.emplace(i.id, i); }
s.links.push_back({"charging_handle","root","charging_handle"});
s.links.push_back({"grip","root","grip"});
s.links.push_back({"grip_addon","handguard.standard","under_grip"});
s.links.push_back({"handguard.standard","root","handguard.standard"});
s.links.push_back({"magazine","root","magazine"});
s.links.push_back({"muzzle","root","muzzle"});
s.links.push_back({"sight","root","optic"});
s.links.push_back({"stock.standard","root","stock.standard"});
s.links.push_back({"trigger","root","trigger"});
states.emplace("wisp02.standard", s); }
return states; }
