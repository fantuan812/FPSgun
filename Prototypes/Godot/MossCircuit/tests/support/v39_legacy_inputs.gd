extends RefCounted
## Test-only historical fixture input, never a production loader path.
const Catalog=preload("res://tests/support/v39_catalog_projection.gd")
const Loadouts=preload("res://tests/support/v39_loadout_projection.gd")
const MARKER="__test_history_alias_39__"
static func install(game:Node)->Dictionary:
 if game.state!="title":return {"pass":false,"errors":["history installation must precede run/start"]}
 var c:Dictionary=Catalog.project(game.catalog,FileAccess.get_file_as_string("res://data/catalog.json"))
 var k:Dictionary=Loadouts.project(game.starting_loadouts,FileAccess.get_file_as_string("res://data/starting_loadouts.json"))
 if not c.pass or not k.pass:return {"pass":false,"errors":c.errors+k.errors}
 # Prove actual cache aliasing before mutation; remove marker regardless of result.
 if game.catalog.has(MARKER):return {"pass":false,"errors":["unexpected history marker"]}
 game.catalog[MARKER]=true
 var aliased:bool=game.combat_frame.catalog.get(MARKER,false)==true and game.weapon_combat.catalog.get(MARKER,false)==true
 game.catalog.erase(MARKER)
 if not aliased:return {"pass":false,"errors":["main/frame/weapon catalog aliases split"]}
 game.catalog.clear();game.catalog.merge(c.catalog,true)
 game.starting_loadouts.clear();game.starting_loadouts.merge(k.data,true)
 game.effects.configure(game.catalog)
 game.new_weapon_runtime.configure(game.catalog)
 game.ui.show_title(game.run_seed,game.mode.id,game._starting_loadout_context())
 var expected_fracture:Array=[]
 for weapon in c.catalog.weapons:
  if weapon.id!="cryo_sprayer":expected_fracture.append(str(weapon.id))
 var coherent:bool=game.catalog==c.catalog and game.combat_frame.catalog==c.catalog and game.weapon_combat.catalog==c.catalog and game.starting_loadouts==k.data and game.effects.fracture_weapons==expected_fracture and game.effects.recoil_definition.is_empty() and game.new_weapon_runtime.weapons.is_empty() and game.new_weapon_runtime.memory.is_empty() and game.new_weapon_runtime.collar.is_empty()
 return {"pass":coherent,"errors":[] if coherent else ["historical cache coherence"],"catalog_bytes":c.bytes,"loadout_bytes":k.bytes,"scope":"Explicit original8/30/12/12/3 data under current production code; not current catalog acceptance"}
