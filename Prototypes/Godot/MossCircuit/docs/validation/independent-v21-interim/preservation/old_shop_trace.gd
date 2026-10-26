extends SceneTree
const Rules=preload("res://scripts/rules.gd")
const OLD_WEAPONS=["rivet_gun","scrap_shotgun","rail_lance","orbit_saw","return_disc","shock_mortar"]
const OLD_ITEMS=["power_coil","cooling_fan","iron_plate","moss_patch","running_boots","salvage_magnet","lucky_chip","lens","capacitor","gear","pellet_pouch","recycler","arc_relay","kill_cell","dash_resin","mirror_shell","thorn_crown","blood_valve","scrap_mine","pulse_boots","return_spool","blast_fuse","echo_chamber","gravity_anchor","medic_seed","phase_capacitor"]
func _initialize()->void:
	var catalog:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/catalog.json"))
	catalog.weapons=catalog.weapons.filter(func(e):return e.id in OLD_WEAPONS)
	catalog.items=catalog.items.filter(func(e):return e.id in OLD_ITEMS)
	catalog.mechanism_synergies=catalog.mechanism_synergies.filter(func(e):return e.id!="cold_snap")
	catalog.affinity_links=catalog.affinity_links.filter(func(e):return not "cryo_sprayer" in e and not "fracture_coil" in e)
	var actual_weapons:Array=catalog.weapons.map(func(e):return e.id);actual_weapons.sort()
	var actual_items:Array=catalog.items.map(func(e):return e.id);actual_items.sort()
	var expected_weapons:Array=OLD_WEAPONS.duplicate();expected_weapons.sort();var expected_items:Array=OLD_ITEMS.duplicate();expected_items.sort()
	if actual_weapons!=expected_weapons or actual_items!=expected_items or not Rules.validate_catalog(catalog).is_empty():push_error("exact old catalog projection invalid");quit(1);return
	var profiles:Array=[{"weapons":["rivet_gun"],"items":{},"coins":35},{"weapons":["return_disc"],"items":{},"coins":0},{"weapons":["shock_mortar","return_disc","rail_lance","scrap_shotgun"],"items":{"arc_relay":1,"kill_cell":1,"gravity_anchor":1},"coins":1000},{"weapons":["rail_lance","rail_lance","rail_lance","rail_lance"],"items":{"capacitor":4,"return_spool":1,"blast_fuse":1,"mirror_shell":1,"blood_valve":1,"medic_seed":1,"phase_capacitor":1,"recycler":2},"coins":10}]
	var records:Array=[]
	for profile in profiles:
		var build:Dictionary=Rules.new_build(catalog);build.merge(profile.duplicate(true),true)
		var draws:Array=[]
		for seed_value in range(100):
			var rng:=RandomNumberGenerator.new();rng.seed=seed_value
			var stock: Array=Rules.draw_shop(build,catalog,rng,4)
			draws.append({"seed":seed_value,"offers":stock,"rng":str(rng.state)})
		var transactions:Array=[]
		for entry in catalog.weapons+catalog.items:
			for slot in [-1,0,4]:
				var probe:Dictionary=build.duplicate(true);var message:String=Rules.transaction(probe,catalog,entry.id,slot)
				transactions.append({"id":entry.id,"replace":slot,"result":message,"build":probe})
		records.append({"build":build,"affinity":Rules.shop_affinity(build,catalog),"pool":Rules.weighted_pool(build,catalog),"draws":draws,"transactions":transactions})
	var report:Dictionary={"scope":"exact old32 catalog projection; four build profiles,400 seeded draws+384 transaction probes; expanded native v21 pool intentionally excluded","definitions":{"weapons":catalog.weapons,"items":catalog.items,"shop_weighting":catalog.shop_weighting,"affinity_links":catalog.affinity_links,"mechanism_synergies":catalog.mechanism_synergies,"synergies":catalog.synergies},"records":records}
	FileAccess.open(OS.get_cmdline_user_args()[0],FileAccess.WRITE).store_string(JSON.stringify(report));print("OLD_SHOP_TRACE 400 seeded draws / 384 transactions / exact6+26 ID set");quit()
