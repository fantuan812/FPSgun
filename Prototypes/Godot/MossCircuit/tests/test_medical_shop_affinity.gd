extends SceneTree
## Controlled current-catalog acquisition checks, also runnable against an exported PCK.
const Rules = preload("res://scripts/rules.gd")
const Hold = preload("res://scripts/gameplay/shop_reservation.gd")
const Forecast = preload("res://scripts/gameplay/build_forecast.gd")
var checks := 0
var failures: Array = []
var game

func ck(ok: bool, label: String) -> void:
	checks += 1
	if not ok: failures.append(label)

func row(pool: Array, id: String) -> Dictionary:
	for offer in pool:
		if offer.id == id: return offer
	return {}

func neutral(catalog: Dictionary) -> Dictionary:
	var build := Rules.new_build(catalog)
	build.weapons = ["rivet_gun"]
	return build

func seed_for(build: Dictionary, catalog: Dictionary, id: String) -> int:
	var rng := RandomNumberGenerator.new()
	for seed_value in range(256):
		rng.seed = seed_value
		if not row(Rules.draw_shop(build, catalog, rng), id).is_empty(): return seed_value
	return -1

func open_for(id: String) -> int:
	var seed_value := seed_for(game.build, game.catalog, id)
	ck(seed_value >= 0, "bounded seeded shop contains " + id)
	if seed_value < 0: return -1
	game.shop_rng.seed = seed_value
	game._open_shop()
	for i in range(game.shop_offers.size()):
		if game.shop_offers[i].id == id: return i
	return -1

func _initialize() -> void: call_deferred("run")

func run() -> void:
	var catalog: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/catalog.json"))
	var original := catalog.duplicate(true)
	var previous := catalog.duplicate(true)
	ck(catalog.affinity_links.size() == 15 and catalog.affinity_links[-1] == ["medic_winch", "medic_seed"], "single appended Medical Recovery link")
	previous.affinity_links.pop_back()
	ck(Rules.validate_catalog(catalog).is_empty(), "current catalog valid")
	ck(catalog.shop_weighting == {"base":1.0,"shared_tag_step":0.35,"tag_bonus_cap":2.0,"missing_partner_bonus":2.5,"duplicate_weapon_bonus":0.5,"total_cap":6.0}, "unchanged weighting policy")
	for pair in [["medic_winch", "medic_seed"], ["medic_seed", "medic_winch"]]:
		var owner: String = pair[0]
		var partner: String = pair[1]
		var build := neutral(catalog)
		var clean := build.duplicate(true)
		ck(Rules.shop_affinity(build, catalog).missing_ids.is_empty(), "neither owned gives no partner bias " + owner)
		ck(Rules.weighted_pool(build, catalog) == Rules.weighted_pool(build, previous), "neutral pool exact prior behavior " + owner)
		build.items[owner] = 1
		var before := build.duplicate(true)
		var pool := Rules.weighted_pool(build, catalog)
		var old_pool := Rules.weighted_pool(build, previous)
		ck(Rules.shop_affinity(build, catalog).missing_ids == [partner], "bidirectional missing partner " + owner)
		ck(row(pool, partner).weight == 3.5 and row(old_pool, partner).weight == 1.0, "exact 1.0 to 3.5 weight, not probability " + owner)
		ck(row(pool, partner).bias_reasons == ["Missing synergy partner"], "one precise reason without shared tag " + owner)
		ck(row(pool, owner).is_empty(), "owned unique excluded " + owner)
		ck(pool.all(func(offer): return offer.weight >= 1.0 and offer.weight <= 6.0), "bounded positive exploration " + owner)
		for offer in pool:
			if offer.id != partner: ck(offer == row(old_pool, offer.id), "unrelated offer exact " + owner + ":" + offer.id)
		var rng := RandomNumberGenerator.new()
		var control := RandomNumberGenerator.new()
		for seed_value in range(64):
			rng.seed = seed_value; control.seed = seed_value
			var offers := Rules.draw_shop(build, catalog, rng)
			ck(offers == Rules.draw_shop(build, catalog, control) and rng.state == control.state, "same seed offers and RNG " + owner + ":" + str(seed_value))
			var ids: Dictionary = {}
			for offer in offers: ids[offer.id] = true
			ck(ids.size() == 4 and not ids.has(owner), "four unique eligible offers " + owner + ":" + str(seed_value))
			for slot in range(4):
				var held_offer := row(pool, partner).duplicate(true); held_offer.sold = false
				var held := Hold.create(build, catalog, held_offer, slot, 10)
				rng.seed = seed_value; control.seed = seed_value
				var expected := Rules.draw_shop(build, catalog, control, 3, [partner]); expected.insert(slot, held.offer.duplicate(true))
				var actual := Hold.draw(build, catalog, rng, held)
				ck(not actual.clear and actual.offers == expected and rng.state == control.state, "held exact three fresh and original metadata " + owner + ":" + str(seed_value) + ":" + str(slot))
		ck(build == before, "pure draws and reservation leave ownership unchanged " + owner)
		build.items[partner] = 1
		ck(Rules.shop_affinity(build, catalog).missing_ids.is_empty(), "completion clears missing status " + owner)
		ck(row(Rules.weighted_pool(build, catalog), owner).is_empty() and row(Rules.weighted_pool(build, catalog), partner).is_empty(), "both unique maxima excluded " + owner)
		ck(Rules.weighted_pool(build, catalog) == Rules.weighted_pool(build, previous), "completed pool exact prior behavior " + owner)
		for seed_value in range(32):
			for unchanged in [clean, build]:
				rng.seed = seed_value; control.seed = seed_value
				ck(Rules.draw_shop(unchanged, catalog, rng) == Rules.draw_shop(unchanged, previous, control) and rng.state == control.state, "unaffected ownership prior replay " + owner + ":" + str(seed_value))
		build.items.erase(partner)
		ck(Rules.shop_affinity(build, catalog).missing_ids == [partner], "removing counterpart restores missing status " + owner)
		build.items.erase(owner)
		ck(Rules.weighted_pool(build, catalog) == Rules.weighted_pool(clean, catalog), "removing both restores neutral pool " + owner)
	ck(catalog == original, "all pure operations preserve catalog")
	game = load("res://scenes/main.tscn").instantiate(); root.add_child(game); game.set_process(false)
	for mode in ["arena", "rooms"]:
		for pair in [["medic_winch", "medic_seed"], ["medic_seed", "medic_winch"]]:
			var owner: String = pair[0]; var partner: String = pair[1]
			var label: String = mode + ":" + owner
			game._title(); game._select_mode(mode); game._start_run(5801); game.set_process(false)
			game.build.items = {owner:1}; game.build.coins = 100; game._recompute()
			var slot := open_for(partner)
			ck(slot >= 0, "actual generated partner stock " + label)
			if slot < 0: continue
			var before: Dictionary = game.build.duplicate(true)
			var world_rng: Array = [game.rng.state, game.loot_rng.state]
			ck(game.shop_offers[slot].bias_reasons == ["Missing synergy partner"], "generated stock carries medical reason " + label)
			ck(game._reserve_offer(slot, game.shop_generation), "reserve actual generated medical offer " + label)
			var held: Dictionary = game.reserved_offer.duplicate(true)
			ck(game.build == before and Rules.shop_affinity(game.build, catalog).missing_ids == [partner], "reservation is not ownership " + label)
			var control := RandomNumberGenerator.new(); control.state = game.shop_rng.state
			var expected := Hold.draw(game.build, catalog, control, held)
			ck(game._refresh_shop(game.shop_generation), "refresh with missing medical hold " + label)
			ck(game.shop_offers == expected.offers and game.shop_rng.state == control.state and game.build.coins == 95, "real refresh exact offers RNG and price " + label)
			var coins: int = game.build.coins
			ck(game._sell_item(owner, game.shop_generation), "sell actual owner while partner held " + label)
			ck(game.build.coins == coins + floori(Rules.catalog_entry(catalog, owner).price * game.stats.resale), "unchanged owner refund " + label)
			ck(Rules.shop_affinity(game.build, catalog).missing_ids.is_empty() and row(Rules.weighted_pool(game.build, catalog), partner).weight == 1.0, "sale removes live missing bonus " + label)
			ck(game.reserved_offer == held, "sale retains original held snapshot " + label)
			ck(game._refresh_shop(game.shop_generation) and game.shop_offers[slot] == held.offer, "held original reason survives later neutral draw " + label)
			coins = game.build.coins
			ck(game._buy(slot, game.shop_generation), "buy held partner through actual handler " + label)
			ck(game.build.coins == coins - int(Rules.catalog_entry(catalog, partner).price) and game.build.items.get(partner, 0) == 1 and game.reserved_offer.is_empty() and game.shop_offers[slot].sold, "held purchase exact price and single ownership " + label)
			ck(Rules.shop_affinity(game.build, catalog).missing_ids == [owner], "purchased lone partner reverses missing direction " + label)
			slot = open_for(owner)
			if slot < 0: continue
			coins = game.build.coins
			ck(game._buy(slot, game.shop_generation), "complete medical pair through actual handler " + label)
			ck(game.build.coins == coins - int(Rules.catalog_entry(catalog, owner).price) and Forecast.mechanism_status(game.build, catalog)[16].active, "unchanged completion price and existing mechanism " + label)
			ck(Rules.shop_affinity(game.build, catalog).missing_ids.is_empty() and row(Rules.weighted_pool(game.build, catalog), owner).is_empty() and row(Rules.weighted_pool(game.build, catalog), partner).is_empty(), "actual completed pair has no missing or maxed offers " + label)
			ck([game.rng.state, game.loot_rng.state] == world_rng, "shop activity never consumes world or loot RNG " + label)
			ck(game._sell_item(partner, game.shop_generation) and not Forecast.mechanism_status(game.build, catalog)[16].active and Rules.shop_affinity(game.build, catalog).missing_ids == [partner], "actual sale disables pair and restores target bias " + label)
	var helper_path := "res://tests/support/audio_teardown.gd"
	if not OS.get_cmdline_user_args().is_empty(): helper_path = OS.get_cmdline_user_args()[0]
	var helper = load(helper_path).new(); helper.prepare([game]); game.queue_free(); await process_frame
	var teardown: Dictionary = await helper.finish(self)
	ck(teardown.complete, "observed released audio owners and fresh silence")
	print(JSON.stringify({"checks":checks,"failures":failures,"scope":"Current-catalog pure weights, seeded draws and controlled actual shop handlers in Arena/Rooms. Original held metadata remains historical. No ordinary-play probability, balance or new combat claim."}))
	quit(0 if failures.is_empty() else 1)
