extends SceneTree
const Rules = preload("res://scripts/rules.gd")
var passed := 0
var failures: Array = []
func check(v: bool,s: String) -> void:
	if v: passed += 1
	else: failures.append(s)
func row(pool: Array,id: String) -> Dictionary:
	for entry in pool:
		if entry.id == id: return entry
	return {}
func _initialize() -> void:call_deferred("run")
func run() -> void:
	var c: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/catalog.json"))
	var build: Dictionary = Rules.new_build(c)
	build.weapons = []
	build.items = {}
	var neutral: Dictionary = build.duplicate(true)
	var pool: Array = Rules.weighted_pool(build,c)
	check(pool.size() == c.weapons.size()+c.items.size(),"neutral pool includes all")
	check(pool.all(func(e):return is_equal_approx(e.weight,1.0)),"neutral exploration exactly1")
	build.weapons = ["return_disc"]
	pool = Rules.weighted_pool(build,c)
	check(is_equal_approx(row(pool,"return_spool").weight,3.85),"missing spool tag+partner exact3.85")
	check(is_equal_approx(row(pool,"return_disc").weight,2.2),"duplicate disc two tags plus duplicate exact2.2")
	check(row(pool,"return_spool").bias_reasons.has("Missing synergy partner"),"reason includes actual missing partner")
	check(pool.all(func(e):return e.weight >= c.shop_weighting.base and e.weight <= c.shop_weighting.total_cap),"positive bounded weights")
	build.items.return_spool = 1
	pool = Rules.weighted_pool(build,c)
	check(row(pool,"return_spool").is_empty(),"capped unique removed")
	build.items.clear();build.weapons.clear()
	check(is_equal_approx(row(Rules.weighted_pool(build,c),"return_spool").weight,1),"sell rebuild restores neutral")
	build.weapons = ["return_disc","return_disc","return_disc","return_disc"]
	build.coins = 0
	pool = Rules.weighted_pool(build,c)
	check(not row(pool,"shock_mortar").is_empty(),"full slots still include replacement weapon")
	check(not row(pool,"return_spool").is_empty(),"unaffordable remains eligible")
	check(row(pool,"return_disc").is_empty(),"max weapon copies removed")
	var boosted: Dictionary = neutral.duplicate(true)
	boosted.weapons = ["return_disc"]
	var hits_neutral := 0
	var hits_boosted := 0
	for seed_value in range(4000):
		var r := RandomNumberGenerator.new();r.seed = seed_value
		if Rules.draw_shop(neutral,c,r,1)[0].id == "return_spool":hits_neutral += 1
		r.seed = seed_value
		if Rules.draw_shop(boosted,c,r,1)[0].id == "return_spool":hits_boosted += 1
		if seed_value < 100:
			r.seed = seed_value
			var offers: Array = Rules.draw_shop(boosted,c,r,4)
			var ids := {}
			for e in offers:ids[e.id] = true
			check(ids.size() == 4,"without replacement " + str(seed_value))
			r.seed = seed_value
			check(offers == Rules.draw_shop(boosted,c,r,4),"same seed same offers " + str(seed_value))
	check(hits_boosted > hits_neutral*1.8,"fixed-seed ensemble affinity increases first-slot frequency")
	var g = load("res://scenes/main.tscn").instantiate()
	root.add_child(g);g.set_process(false);g._start_run(42);g._open_shop()
	g.build.coins = 100
	var gen: int = g.shop_generation
	check(g._refresh_shop(gen),"paid refresh")
	var coins: int = g.build.coins
	check(coins == 100-int(c.refresh_price),"exact refresh price")
	check(not g._refresh_shop(gen) and g.build.coins == coins,"stale refresh atomic")
	var offers: Array = g.shop_offers.duplicate(true)
	g._start_run(42);g._open_shop();g.build.coins = 100;g._refresh_shop(g.shop_generation)
	check(g.shop_offers == offers,"same seed same operations replay")
	g.queue_free();await process_frame
	print(JSON.stringify({"independent_shop_passed":passed,"failures":failures,"samples":4000,"neutral_firstslot_spool":hits_neutral,"boosted_firstslot_spool":hits_boosted,"scope":"fixed seeded first-slot ensemble, not exact four-slot inclusion probability or guaranteed offer"}))
	quit(0 if failures.is_empty() else 1)
