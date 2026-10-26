extends Node2D
const ModeStatus=preload("res://ui/mode_status.gd")
var mode_status:CanvasLayer
const EffectRuntime=preload("res://scripts/gameplay/effect_runtime.gd")
const CombatContext=preload("res://scripts/gameplay/combat_context.gd")
const CombatRuntime=preload("res://scripts/gameplay/combat_runtime.gd")
var effect_runtime:EffectRuntime
var combat_frame=CombatContext.new()
const ArenaMode=preload("res://scripts/modes/arena_mode.gd")
const RoomMode=preload("res://scripts/modes/room_mode.gd")
const RunFlow=preload("res://scripts/gameplay/run_flow.gd")
const FieldLayout=preload("res://scripts/gameplay/field_layout.gd")
var mode:RefCounted=ArenaMode.new()
var base_arena:Dictionary
var room_profile:Dictionary
const CharacterMotor=preload("res://scripts/gameplay/character_motor.gd")
const TargetStatus=preload("res://scripts/gameplay/target_status.gd")
const WeaponCombat=preload("res://scripts/gameplay/weapon_combat.gd")
const WeaponPresentation=preload("res://scripts/gameplay/weapon_presentation.gd")
var weapon_combat:WeaponCombat
var weapon_presentation:WeaponPresentation
const RunSession=preload("res://scripts/gameplay/run_session.gd")
var run=RunSession.new()
const CombatState=preload("res://scripts/gameplay/combat_state.gd")
var combat=CombatState.new()
const WeaponRig = preload("res://scripts/weapon_rig.gd")
var weapon_rig:Node2D
const ActorDirector = preload("res://scripts/actor_director.gd")
var actor_anim = ActorDirector.new()
var settings := {"reduced_flashes":false}
var settings_return := "title"
var visual_cooldowns:Dictionary={}
var result_pending := false
var result_wait := 0.0
const Rules = preload("res://scripts/rules.gd")
const Effects = preload("res://scripts/effects.gd")
const EnemyAI = preload("res://scripts/enemy_ai.gd")
const MossUI = preload("res://ui/moss_ui.gd")
const Telegraphs = preload("res://scripts/telegraph_layer.gd")
var telegraphs: Node2D
const VFX = preload("res://scripts/vfx_layer.gd")
var vfx: Node2D
const Art = preload("res://scripts/art.gd")
var effects = Effects.new()
var effect_sequence:int:
	get:return effect_runtime.sequence if effect_runtime else 0
	set(value):
		if effect_runtime:effect_runtime.sequence=value
var pending_blasts: Array:
	get: return combat.pending_blasts
	set(value): combat.pending_blasts=value
var hazards: Array:
	get: return combat.hazards
	set(value): combat.hazards=value
var effect_visuals: Array:
	get: return combat.effect_visuals
	set(value): combat.effect_visuals=value
var encounters: Dictionary
var enemy_bullets: Array:
	get: return combat.enemy_bullets
	set(value): combat.enemy_bullets=value
var boss_spawned: bool:
	get: return run.boss_spawned
	set(value): run.boss_spawned=value
var boss_defeated: bool:
	get: return run.boss_defeated
	set(value): run.boss_defeated=value
var boss_rewards: Dictionary:
	get: return run.boss_rewards
	set(value): run.boss_rewards=value
var rewards: Array:
	get: return run.rewards
	set(value): run.rewards=value
var codex_return := "title"
var catalog: Dictionary
var build: Dictionary:
	get: return run.build
	set(value): run.build=value
var shop_rng := RandomNumberGenerator.new()
var shop_offers: Array:
	get: return run.shop_offers
	set(value): run.shop_offers=value
var shop_generation: int:
	get: return run.shop_generation
	set(value): run.shop_generation=value
var shop_pending: bool:
	get: return run.shop_pending
	set(value): run.shop_pending=value
var weapon_clocks: Array:
	get: return combat.weapon_clocks
	set(value): combat.weapon_clocks=value
var shop_message: String:
	get: return run.shop_message
	set(value): run.shop_message=value
var inventory_return := "paused"
var config: Dictionary
var stats: Dictionary:
	get: return combat.stats
	set(value): combat.stats=value
var run_seed: int:
	get: return run.run_seed
	set(value): run.run_seed=value
var rng := RandomNumberGenerator.new()
var loot_rng := RandomNumberGenerator.new()
var map_data: Array = []
var grid_size := Vector2i.ZERO
var ground: Texture2D
var hero: AnimatedSprite2D
var camera: Camera2D
var enemies: Array:
	get: return combat.enemies
	set(value): combat.enemies=value
var bullets: Array:
	get: return combat.bullets
	set(value): combat.bullets=value
var pickups: Array:
	get: return combat.pickups
	set(value): combat.pickups=value
var flashes: Array:
	get: return combat.flashes
	set(value): combat.flashes=value
var player_pos: Vector2:
	get: return combat.player_pos
	set(value): combat.player_pos=value
var wave: int:
	get: return run.wave
	set(value): run.wave=value
var wave_time: float:
	get: return run.wave_time
	set(value): run.wave_time=value
var elapsed: float:
	get: return run.elapsed
	set(value): run.elapsed=value
var spawn_clock:float:
	get:return mode.spawn_clock
	set(value):mode.spawn_clock=value
var shot_clock := 0.0
var hurt_clock: float:
	get: return combat.hurt_clock
	set(value): combat.hurt_clock=value
var level: int:
	get: return run.level
	set(value): run.level=value
var xp: int:
	get: return run.xp
	set(value): run.xp=value
var kills: int:
	get: return run.kills
	set(value): run.kills=value
var state: String:
	get: return run.state
	set(value): run.state=value
var resume_state: String:
	get: return run.resume_state
	set(value): run.resume_state=value
var next_enemy_id: int:
	get: return combat.next_enemy_id
	set(value): combat.next_enemy_id=value
var ui: CanvasLayer
var choices: Array:
	get: return run.choices
	set(value): run.choices=value
var upgrade_pending: int:
	get: return run.upgrade_pending
	set(value): run.upgrade_pending=value
var choice_generation: int:
	get: return run.choice_generation
	set(value): run.choice_generation=value
var automation := false

func _ready() -> void:
	var raw_balance = JSON.parse_string(FileAccess.get_file_as_string("res://data/balance.json"))
	var raw_catalog = JSON.parse_string(FileAccess.get_file_as_string("res://data/catalog.json"))
	if not raw_balance is Dictionary or not raw_catalog is Dictionary:
		push_error("Configuration must be valid JSON objects")
		set_process(false)
		return
	config = raw_balance
	base_arena=config.arena.duplicate(true)
	var raw_rooms=JSON.parse_string(FileAccess.get_file_as_string("res://data/room_encounters.json"))
	if not raw_rooms is Dictionary:
		push_error("Room policy must be a JSON object")
		set_process(false)
		return
	room_profile=raw_rooms
	catalog = raw_catalog
	var catalog_errors := Rules.validate_catalog(catalog)
	if not catalog_errors.is_empty():
		push_error("Invalid catalog: " + str(catalog_errors))
		set_process(false)
		return
	effects.configure(catalog)
	var raw_encounters = JSON.parse_string(FileAccess.get_file_as_string("res://data/encounters.json"))
	if not raw_encounters is Dictionary:
		push_error("Encounters must be a JSON object")
		set_process(false)
		return
	encounters = raw_encounters
	var mode_errors:=RoomMode.validate(room_profile,encounters)
	if not mode_errors.is_empty():
		push_error("Invalid room policy: "+str(mode_errors))
		set_process(false)
		return
	if not EnemyAI.validate(encounters).is_empty() or encounters.waves.size() != int(config.waves.count):
		push_error("Invalid encounter definitions: " + str(EnemyAI.validate(encounters)))
		set_process(false)
		return
	ground = load("res://assets/ground_atlas.png")
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	camera = Camera2D.new()
	add_child(camera)
	camera.position = Vector2(config.arena.width, config.arena.height) * 0.5
	camera.zoom = Vector2.ONE
	hero = Art.actor("res://assets/hero_walk.png", 64.0, 11.0)
	add_child(hero)
	actor_anim.load_default()
	actor_anim.register_actor(0,hero,"hero",64.0)
	hero.z_index=2
	weapon_rig=WeaponRig.new()
	add_child(weapon_rig)
	weapon_rig.load_default()
	vfx = VFX.new()
	add_child(vfx)
	vfx.load_default()
	weapon_presentation=WeaponPresentation.new(combat,run,actor_anim,weapon_rig,hero)
	weapon_combat=WeaponCombat.new(combat,run,catalog,weapon_presentation,_effect_event,_vfx)
	effect_runtime=EffectRuntime.new(combat,run,effects,actor_anim,_vfx,_mechanism_vfx)
	combat_frame.world=combat;combat_frame.session=run;combat_frame.catalog=catalog
	combat_frame.weapons=weapon_combat;combat_frame.procs=effect_runtime;combat_frame.actor=actor_anim
	combat_frame.hurt=_hurt;combat_frame.spawn_kind=_spawn_kind;combat_frame.boss_killed=_boss_killed;combat_frame.play_vfx=_vfx
	telegraphs = Telegraphs.new()
	add_child(telegraphs)
	_build_ui()
	mode_status=ModeStatus.new()
	add_child(mode_status)
	_enter_field(run_seed)
	_title()
	if "--smoke" in OS.get_cmdline_user_args():
		automation = true
		_start_run(run_seed)

func _build_ui() -> void:
	ui = MossUI.new()
	add_child(ui)
	ui.intent.connect(_on_intent)


func _title() -> void:
	weapon_rig.clear()
	enemies.clear()
	bullets.clear()
	enemy_bullets.clear()
	pickups.clear()
	flashes.clear()
	pending_blasts.clear()
	hazards.clear()
	effect_visuals.clear()
	visual_cooldowns.clear()
	result_pending = false
	actor_anim.clear()
	vfx.clear()
	telegraphs.show_markers([])
	state = "title"
	ui.show_title(run_seed,mode.id)


func _start_run(seed_value: int) -> void:
	weapon_rig.clear()
	visual_cooldowns.clear()
	result_pending = false
	actor_anim.clear()
	vfx.clear()
	telegraphs.show_markers([])
	for e in enemies:
		if is_instance_valid(e.sprite):e.sprite.queue_free()
	enemies.clear()
	bullets.clear()
	pickups.clear()
	flashes.clear()
	run_seed = seed_value
	rng.seed = run_seed
	loot_rng.seed = run_seed ^ 58349
	shop_rng.seed = run_seed ^ 92137
	build = Rules.new_build(catalog)
	effects.reset(build.items)
	effect_sequence = 0
	pending_blasts.clear()
	hazards.clear()
	effect_visuals.clear()
	pending_blasts.clear()
	shop_generation += 1
	choice_generation += 1
	shop_pending = false
	boss_spawned = false
	boss_defeated = false
	boss_rewards.clear()
	rewards.clear()
	enemy_bullets.clear()
	shop_offers.clear()
	weapon_clocks = [0.0]
	_enter_field(run_seed)
	stats = Rules.derive(config.player, build, catalog)
	stats.max_hp = stats.hp
	stats.pierce = 0
	stats.dash_cooldown = 0.0
	stats.dash_time = 0.0
	player_pos = Vector2(config.arena.width, config.arena.height) * 0.5
	wave = 1
	mode.reset()
	mode.begin_stage(wave)
	resume_state="playing"
	wave_time = 0.0
	elapsed = 0.0
	spawn_clock = 0.0
	shot_clock = 0.0
	hurt_clock = 0.0
	level = 1
	xp = 0
	kills = 0
	next_enemy_id = 0
	upgrade_pending = 0
	state = "playing"
	_hide_modal()
	_update_hud()

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE:
			if state in ["playing","room_clear"]:
				resume_state=state
				state = "paused"
				_present_pause()
			elif state == "paused": _resume()
			elif state == "inventory": _on_intent("close_inventory",{})
			elif state == "codex": _on_intent("close_codex",{})
			elif state == "settings": _on_intent("close_settings",{})
		if event.keycode == KEY_I:
			_on_intent("close_inventory" if state == "inventory" else "inventory",{})
		if state == "upgrade" and event.keycode in [KEY_1, KEY_2, KEY_3]:
			_take_upgrade(int(event.keycode - KEY_1), choice_generation)


func _notification(what:int) -> void:
	# Losing application focus must never spend combat or room-clear time.
	# Focus returning is deliberately not a resume action.
	if what==NOTIFICATION_APPLICATION_FOCUS_OUT and is_instance_valid(ui):
		_on_intent("pause",{})


func _resume() -> void:
	state = resume_state if resume_state in ["playing","room_clear"] else "playing"
	_hide_modal()

func _process(delta: float) -> void:
	if state == "playing":
		weapon_rig.advance(minf(delta,.05))
		actor_anim.advance(minf(delta,.05))
		vfx.advance(minf(delta,0.05))
		_simulate(minf(delta, 0.05))
	elif state=="room_clear":
		mode.advance_clear(minf(delta,.05),combat)
		actor_anim.advance(minf(delta,.05))
		if mode.is_due(run,combat,config):_complete_wave()
	elif state in ["dead","won"]:
		actor_anim.advance(minf(delta,.05),true)
		if state=="dead" and result_pending:
			result_wait-=minf(delta,.05)
			if result_wait<=0:
				result_pending=false
				_show_result(false)
	hero.position = player_pos.round()
	_sync_weapon_rig()
	camera.position = FieldLayout.camera_position(player_pos,config.arena)
	_update_hud()
	_sync_telegraphs()
	queue_redraw()

func _simulate(dt: float) -> void:
	if state!="playing":return
	elapsed += dt
	wave_time += dt
	var direction := Vector2(float(Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT)) - float(Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT)), float(Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_DOWN)) - float(Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP))).normalized()
	if automation: direction = Vector2(cos(elapsed * 0.7), sin(elapsed * 0.7))
	var dash_origin:=player_pos
	if CharacterMotor.step(combat,config.arena,direction,Input.is_physical_key_pressed(KEY_SPACE),dt):
		_effect_event("dash",{"pos":dash_origin,"angle":direction.angle()})
	if direction != Vector2.ZERO:
		actor_anim.set_phase(0,"move")
		if direction.x != 0 and actor_anim.state_of(0)!="attack": hero.flip_h = direction.x < 0
	else: actor_anim.set_phase(0,"idle")
	hero.modulate = Color(1, 0.5, 0.45) if hurt_clock > 0.5 else Color.WHITE
	_ensure_boss()
	if mode.tick_spawn(dt,run,config):_spawn_enemy()
	combat_frame.area=config.arena
	CombatRuntime.step(combat_frame,dt)
	if state!="playing":return
	RunFlow.accrue_levels(run)
	if upgrade_pending > 0:
		_show_upgrades()
		return
	if mode.wants_clear_pause(combat):
		_begin_room_clear()
	elif mode.is_due(run,combat,config):_complete_wave()

func _spawn_enemy() -> void:
	var request:Dictionary=mode.regular_request(run,combat,config,encounters,rng)
	if request.is_empty():return
	var spawned:=_spawn_kind(request.kind,request.pos)
	mode.acknowledge(request,spawned)

func _spawn_kind(kind: String, pos: Vector2, parent_id: int = -1) -> Dictionary:
	if enemies.size() >= int(config.waves.max_enemies): return {}
	var data: Dictionary = {}
	for entry in encounters.enemies:
		if entry.id == kind: data = entry.duplicate(true); break
	if data.is_empty(): return {}
	var path := "res://assets/enemies/" + kind + ".png"
	# Until an authored sheet is supplied, the known baseline remains a clearly marked fallback.
	if not ResourceLoader.exists(path): path = "res://assets/beetle_walk.png"
	var sprite := Art.actor(path,57.0 * float(data.scale),9.0)
	sprite.modulate = Color(str(data.color)) if path.ends_with("beetle_walk.png") else Color.WHITE
	add_child(sprite)
	next_enemy_id += 1
	data.kind = kind
	data.id = next_enemy_id
	data.pos = pos
	data.hp *= 1.0 if data.boss else 1.0 + (wave - 1) * .12
	data.max_hp = data.hp
	data.sprite = sprite
	data.anim_hp = data.hp
	actor_anim.register_actor(data.id,sprite,kind,57.0*float(data.scale))
	data.parent_id = parent_id
	data.last_source = "primary"
	data.phase = 1
	data.ai_state = "move"
	data.cooldown_left = .8
	data.warning_left = 0.0
	data.recover_left = 0.0
	data.charge_left = 0.0
	data.attack_index = 0
	data.attack = ""
	data.aim = Vector2.RIGHT
	data.target = pos
	enemies.append(data)
	return data

func _ensure_boss() -> void:
	var request:Dictionary=mode.boss_request(run,combat,config.arena,encounters)
	if request.is_empty():return
	var spawned:=_spawn_kind(request.kind,request.pos)
	if not spawned.is_empty():boss_spawned=true

func _hurt(damage: float) -> void:
	if state != "playing" or hurt_clock > 0 or stats.dash_time > 0: return
	if _effect_event("before_hurt",{}):
		hurt_clock = .25
		return
	actor_anim.trigger(0,"hurt")
	_vfx("hit_spark",player_pos)
	var actual_loss := CharacterMotor.apply_damage(combat,damage)
	_effect_event("hurt",{"amount":actual_loss})
	hurt_clock = .75
	if stats.hp <= 0: _finish(false)

func _boss_killed(enemy: Dictionary) -> void:
	if RunFlow.award_boss(combat,run,enemy):
		_recompute()
		stats.hp=minf(stats.max_hp,stats.hp+25)


func _shoot() -> void:
	_fire_weapon("rivet_gun", 0)

func _fire_weapon(id: String, slot: int) -> void:
	weapon_combat.fire(id,slot)

func _complete_wave() -> void:
	if state not in ["playing","room_clear"]:return
	if not mode.can_end(run,combat,encounters):
		_ensure_boss()
		return
	var retiring:Array=enemies.duplicate()
	var outcome:=RunFlow.settle(combat,run,mode,config,effects,encounters)
	if outcome in ["invalid","ignored"]:return
	vfx.clear();telegraphs.show_markers([])
	actor_anim.clear(true,true)
	for enemy in retiring:
		if is_instance_valid(enemy.sprite):enemy.sprite.queue_free()
	if outcome=="won":_finish(true)
	elif outcome=="next":
		mode.begin_stage(wave)
		if mode.refresh_field_between_stages:_enter_field(run_seed^(wave*17041))
		if upgrade_pending>0:_show_upgrades()
		elif shop_pending:_open_shop()
		else:
			state="playing"
			_hide_modal()


func _show_upgrades() -> void:
	effects.invalidate()
	state = "upgrade"
	choice_generation += 1
	choices = Rules.choose_upgrades(config.upgrades, loot_rng)
	ui.show_upgrade(choices,choice_generation)
	if automation: call_deferred("_take_upgrade", 0, choice_generation)


func _take_upgrade(index: int, generation: int) -> void:
	if generation != choice_generation or state != "upgrade" or index < 0 or index >= choices.size(): return
	var id: String = choices[index].id
	build.levels[id] = build.levels.get(id, 0) + 1
	_recompute()
	if id == "health": stats.hp = minf(stats.max_hp, stats.hp + 30)
	choices.clear()
	upgrade_pending -= 1
	if upgrade_pending > 0: _show_upgrades()
	elif shop_pending:
		_open_shop()
	else:
		state = "playing"
		_hide_modal()

func _finish(won: bool) -> void:
	weapon_rig.clear()
	_clear_transients()
	state = "won" if won else "dead"
	stats.hp = maxf(0,stats.hp)
	if won:
		_show_result(true)
	else:
		actor_anim.die(0)
		result_pending=true
		result_wait=float(actor_anim.config.durations.death)*10.0/9.0
		ui.hide_modal()

func _show_result(won:bool) -> void:
	var view:=_view()
	view.won=won
	ui.show_result(view)


func _update_hud() -> void:
	if is_instance_valid(mode_status):mode_status.present(mode.id,state,mode.objective(run,combat,config),mode.progress())
	if not stats.is_empty(): ui.update_hud(_view())
	if is_instance_valid(mode_status):mode_status.place_below(ui.hud.get_global_rect())
	if ui.has_method("update_bosses"):
		var bars: Array = []
		for enemy in enemies:
			if enemy.boss and enemy.hp > 0 and not state in ["title","codex","won","dead"]: bars.append({"name":enemy.name,"hp":enemy.hp,"max_hp":enemy.max_hp,"phase":enemy.phase,"hint":enemy.ai_state + ": " + enemy.attack})
		ui.update_bosses(bars)


func _draw() -> void:
	if ground == null: return
	var tile: int = config.arena.tile_size
	for y in range(grid_size.y):
		for x in range(grid_size.x):
			var index: int = map_data[y * grid_size.x + x]
			var rect := Rect2(x * tile, y * tile, minf(tile, config.arena.width - x * tile), minf(tile, config.arena.height - y * tile))
			draw_texture_rect_region(ground, rect, Art.region(ground, index), Color(0.65, 0.75, 0.72))
			# Deliberate modular floor joints disguise non-identical generated edges.
			draw_rect(rect, Color(0.03, 0.08, 0.09, 0.28), false, 1.0)
	draw_rect(Rect2(0, 0, config.arena.width, config.arena.height), Color("a0b77c"), false, 4)
	for blast in pending_blasts:
		draw_circle(blast.pos,blast.radius,Color(.65,.8,1,.8),false,2)
	for hazard in hazards:
		draw_circle(hazard.pos,hazard.radius,Color(.95,.5,.12,.22) if hazard.kind in ["trail","scorch"] else Color(.9,.85,.3,.3))
		if hazard.kind == "mine": draw_rect(Rect2(hazard.pos-Vector2(6,6),Vector2(12,12)),Color("f3d66d"))
	for visual in effect_visuals:
		if visual.kind=="cryo_cone":
			var points:=PackedVector2Array([visual.pos])
			var angle:float=visual.direction.angle()
			for i in range(25):points.append(visual.pos+Vector2.from_angle(angle-visual.half_angle+2*visual.half_angle*i/24.0)*visual.radius)
			points.append(visual.pos)
			draw_colored_polygon(points,Color(.45,.88,.95,.035 if settings.reduced_flashes else .07))
			draw_polyline(points,Color(.55,.92,.98,.3 if settings.reduced_flashes else .55),1.5)
		elif visual.kind=="fracture":
			for i in range(4):
				var ray:=Vector2.from_angle(PI*.25+i*PI*.5)
				draw_line(visual.pos+ray*7,visual.pos+ray*visual.radius,Color(.64,.94,1,.4 if settings.reduced_flashes else .7),2)
		elif visual.kind == "chain": draw_line(visual.pos,visual.end,Color("79e8ff"),3)
		else: draw_circle(visual.pos,visual.radius,Color("b0e7cf"),false,3)
	if state not in ["title","dead","won"]:
		for enemy in enemies:
			if not TargetStatus.chilled(enemy,elapsed):continue
			var height:float=actor_anim.actors.get(enemy.id,{}).get("height",32.0)
			var center:Vector2=enemy.pos+Vector2(0,-height*.5-6)
			var diamond:=PackedVector2Array([center+Vector2(0,-4),center+Vector2(4,0),center+Vector2(0,4),center+Vector2(-4,0),center+Vector2(0,-4)])
			draw_polyline(diamond,Color(.57,.91,.98,.5 if settings.reduced_flashes else .85),1.5)
	if effects.shield > 0 and not build.is_empty(): draw_circle(player_pos,25,Color("a7e5ff"),false,2)
	for projectile in enemy_bullets:
		draw_circle(projectile.pos,6,Color("f6827c"))
	for p in pickups:
		if p.get("source","") == "medical":
			draw_rect(Rect2(p.pos-Vector2(5,2),Vector2(10,4)),Color("ff8ca1"))
			draw_rect(Rect2(p.pos-Vector2(2,5),Vector2(4,10)),Color("ff8ca1"))
		elif p.get("source","") == "energy":
			draw_circle(p.pos,7,Color("f3d66d"),false,2)
			draw_rect(Rect2(p.pos-Vector2(2,2),Vector2(4,4)),Color("f3d66d"))
		else: draw_rect(Rect2(p.pos - Vector2(3, 3), Vector2(6, 6)), Color("86e6c1"))
	for b in bullets:
		if b.get("weapon","") == "return_disc":
			draw_circle(b.pos,8,Color("98eaf6"),false,2)
			draw_line(b.pos-Vector2(7,0).rotated(elapsed*16),b.pos+Vector2(7,0).rotated(elapsed*16),Color("e0faff"),2)
			continue
		draw_rect(Rect2(b.pos - Vector2(3, 2), Vector2(6, 4)), Color("ffe1a3"))
	for f in flashes:
		draw_circle(f.pos, f.get("radius", 8), Color("f4d692"), false, 2)
	if state == "playing" and stats.dash_time > 0:
		draw_circle(player_pos, 24, Color("b6f2df"), false, 2)

func _recompute() -> void:
	if weapon_rig.slots.map(func(slot):return slot.id)!=build.weapons:
		weapon_rig.sync_loadout(build.weapons)
		bullets.clear()
		pending_blasts.clear()
		vfx.clear()
	var hp: float = stats.get("hp", config.player.hp)
	var dash: float = stats.get("dash_time", 0.0)
	var cooldown: float = stats.get("dash_cooldown", 0.0)
	stats = Rules.derive(config.player, build, catalog)
	stats.hp = minf(hp, stats.max_hp)
	stats.dash_time = dash
	stats.dash_cooldown = cooldown
	while weapon_clocks.size() < build.weapons.size(): weapon_clocks.append(0.0)
	weapon_clocks.resize(build.weapons.size())
	effects.sync(build.items)
	if not build.items.has("medic_seed"): pickups = pickups.filter(func(p): return p.get("source","") != "medical")
	hazards = hazards.filter(func(h): return build.items.has("dash_resin" if h.kind == "trail" else ("blast_fuse" if h.kind == "scorch" else "scrap_mine")))
	if not effects.pair("dash_resin","pulse_boots"):
		for enemy in enemies: enemy.slow_until = 0.0
		for hazard in hazards: hazard.slow = false

func _roll_offers() -> void:
	shop_offers = Rules.draw_shop(build,catalog,shop_rng,4)
	shop_generation += 1

func _open_shop() -> void:
	state = "shop"
	shop_pending = false
	shop_message = "Buy, sell or replace. Replacement discards old weapon without refund."
	_roll_offers()
	_render_shop()
	if automation: call_deferred("_leave_shop", shop_generation)

func _render_shop() -> void:
	ui.show_shop(_view())


func _buy(index: int, generation: int, replace_slot: int = -1) -> bool:
	if state != "shop" or generation != shop_generation or index < 0 or index >= shop_offers.size(): return false
	if shop_offers[index].sold: return false
	var error := Rules.transaction(build, catalog, shop_offers[index].id, replace_slot)
	if error != "":
		shop_message = error
		_render_shop()
		return false
	if replace_slot>=0 and Rules.catalog_entry(catalog,shop_offers[index].id).kind=="weapon":
		weapon_rig.clear()
		bullets.clear()
		pending_blasts.clear()
		vfx.clear()
	shop_offers[index].sold = true
	shop_generation += 1
	_recompute()
	shop_message = "Purchased."
	_render_shop()
	return true

func _refresh_shop(generation: int) -> bool:
	if state != "shop" or generation != shop_generation or build.coins < catalog.refresh_price: return false
	build.coins -= int(catalog.refresh_price)
	build.revision += 1
	_roll_offers()
	shop_message = "New stock."
	_render_shop()
	return true

func _sell_weapon(slot: int, generation: int) -> bool:
	if state != "shop" or generation != shop_generation or slot < 0 or slot >= build.weapons.size(): return false
	if build.weapons.size() <= 1:
		shop_message = "Keep at least one weapon."
		_render_shop()
		return false
	var entry := Rules.catalog_entry(catalog, build.weapons[slot])
	build.coins += floori(entry.price * stats.resale)
	build.weapons.remove_at(slot)
	weapon_clocks.remove_at(slot)
	build.revision += 1
	shop_generation += 1
	_recompute()
	_render_shop()
	return true

func _sell_item(id: String, generation: int) -> bool:
	if state != "shop" or generation != shop_generation or build.items.get(id, 0) <= 0: return false
	var entry := Rules.catalog_entry(catalog, id)
	build.coins += floori(entry.price * stats.resale)
	build.items[id] -= 1
	if build.items[id] == 0: build.items.erase(id)
	build.revision += 1
	shop_generation += 1
	_recompute()
	_render_shop()
	return true

func _leave_shop(generation: int) -> void:
	if state != "shop" or generation != shop_generation: return
	shop_generation += 1
	state = "playing"
	_hide_modal()

func _view() -> Dictionary:
	if build.is_empty(): return {"seed":run_seed,"settings":settings.duplicate(true),"mode_id":mode.id,"mode_name":mode.name,"objective":""}
	var view := {"coins":build.coins,"wave":wave,"level":level,"hp":stats.hp,"max_hp":stats.max_hp,"xp":xp,"xp_max":Rules.xp_threshold(level),"time":elapsed,"kills":kills,"seed":run_seed,"stats":stats,"weapons":[],"items":[],"synergies":stats.synergies,"generation":shop_generation,"refresh_price":catalog.refresh_price,"weapon_slots":catalog.weapon_slots,"item_slots":catalog.item_slots,"message":shop_message,"offers":[],"rewards":rewards,"synergy_status":[],"mechanics":{"shield":effects.shield,"chain_charges":effects.chain_charges,"hazards":hazards.size(),"echo_hits":effects.echo_hits,"phase_charge":effects.phase_charge,"medic_damage":effects.medic_damage,"cooldowns":{}}}
	view.mode_id=mode.id
	view.mode_name=mode.name
	view.objective=mode.objective(run,combat,config)
	view.stage_count=mode.count(config)
	view.room_clear_progress=mode.progress()
	view.actor_state=actor_anim.state_of(0)
	view.dash_cooldown=stats.get("dash_cooldown",0.0)
	view.settings=settings.duplicate(true)
	var affinity := Rules.shop_affinity(build,catalog)
	var missing_names: Array = []
	for id in affinity.missing_ids: missing_names.append(Rules.catalog_entry(catalog,id).name)
	view.shop_bias = {"preferred_tags":affinity.tags.keys(),"missing_partners":missing_names,"sources":affinity.sources,"summary":"Preference, not a guarantee. Positive exploration remains; selling affects the next refresh."}
	for pair_data in catalog.get("mechanism_synergies",[]):
		var required: Array = []
		var missing: Array = []
		for id in pair_data.requires:
			var name: String = Rules.catalog_entry(catalog,id).name
			required.append(name)
			if not Rules.owned_ids(build).has(id): missing.append(name)
		var excluded_weapon:String=str(pair_data.get("requires_other_weapon_than",""))
		if not excluded_weapon.is_empty():
			var requirement:String="a weapon type other than "+Rules.catalog_entry(catalog,excluded_weapon).name
			required.append(requirement)
			if not build.weapons.any(func(id):return id!=excluded_weapon):missing.append(requirement)
		view.synergy_status.append({"name":pair_data.name,"active":missing.is_empty(),"requires":required,"missing":missing,"description":pair_data.description})
	for id in effects.cooldowns: view.mechanics.cooldowns[id] = maxf(0,effects.cooldowns[id] - elapsed)
	for i in range(build.weapons.size()):
		var entry := Rules.catalog_entry(catalog,build.weapons[i]).duplicate(true)
		entry.slot = i
		entry.sell_price = floori(entry.price * stats.resale)
		view.weapons.append(entry)
	for id in build.items:
		var entry := Rules.catalog_entry(catalog,id).duplicate(true)
		entry.count = build.items[id]
		entry.sell_price = floori(entry.price * stats.resale)
		view.items.append(entry)
	for i in range(shop_offers.size()):
		var offer: Dictionary = shop_offers[i]
		var entry := Rules.catalog_entry(catalog,offer.id).duplicate(true)
		entry.index = i
		entry.sold = offer.sold
		entry.weight_multiplier = offer.get("weight_multiplier",1.0)
		entry.bias_reasons = offer.get("bias_reasons",[])
		entry.can_buy = not offer.sold and build.coins >= entry.price
		if entry.kind == "item":
			entry.can_buy = entry.can_buy and build.items.get(entry.id,0) < entry.max_stack and (build.items.has(entry.id) or build.items.size() < catalog.item_slots)
		view.offers.append(entry)
	return view

func _on_intent(action: String, payload: Dictionary) -> void:
	match action:
		"seed_changed":
			if state=="title" and payload.get("seed") is int:
				run_seed=payload.seed
		"select_mode":
			if state=="title" and payload.get("id","") in ["arena","rooms"]:
				run_seed=int(payload.get("seed",run_seed))
				_select_mode(str(payload.id))
		"settings":
			if state in ["title","paused"]:
				settings_return=state
				state="settings"
				ui.show_settings(_view())
		"set_setting":
			if state=="settings" and payload.get("key","")=="reduced_flashes" and payload.get("value") is bool:
				settings.reduced_flashes=payload.value
				vfx.reduced_flashes=payload.value
				actor_anim.reduced_flashes=payload.value
				vfx.refresh_style()
				actor_anim.refresh_style()
				ui.show_settings(_view())
		"close_settings":
			if state=="settings":
				if settings_return=="title":_title()
				else:
					state="paused"
					_present_pause()
		"codex":
			if state in ["title","paused"]:
				codex_return = state
				state = "codex"
				ui.show_codex(encounters.enemies)
		"close_codex":
			if state == "codex":
				if codex_return == "title": _title()
				else:
					state = "paused"
					_present_pause()
		"start":
			if state == "title": _start_run(int(payload.get("seed",run_seed)))
		"pause":
			if state in ["playing","room_clear"]:
				resume_state=state
				state = "paused"
				_present_pause()
		"resume":
			if state == "paused": _resume()
		"title": _title()
		"retry":
			if state in ["won","dead"]: _start_run(run_seed)
		"new_seed":
			if state in ["won","dead"]: _start_run(run_seed + 1)
		"buy": _buy(int(payload.get("index",-1)),int(payload.get("generation",-1)),int(payload.get("replace_slot",-1)))
		"sell_weapon": _sell_weapon(int(payload.get("slot",-1)),int(payload.get("generation",-1)))
		"sell_item": _sell_item(str(payload.get("id","")),int(payload.get("generation",-1)))
		"refresh": _refresh_shop(int(payload.get("generation",-1)))
		"continue": _leave_shop(int(payload.get("generation",-1)))
		"upgrade": _take_upgrade(int(payload.get("index",-1)),int(payload.get("generation",-1)))
		"inventory":
			if state in ["playing","paused","shop","room_clear"]:
				inventory_return = state
				state = "inventory"
				_present_inventory()
		"close_inventory":
			if state == "inventory":
				state = inventory_return
				if state == "shop": _render_shop()
				elif state == "paused": _present_pause()
				else: _hide_modal()

func _present_inventory() -> void:
	effects.invalidate()
	ui.show_inventory(_view())


func _present_pause() -> void:
	effects.invalidate()
	ui.show_pause(_view())


func _hide_modal() -> void:
	ui.hide_modal()


func _clear_transients() -> void:
	visual_cooldowns.clear()
	vfx.clear()
	telegraphs.show_markers([])
	effects.invalidate()
	effects.chain_charges = 0
	effects.echo_hits = 0
	effects.phase_charge = 0
	effects.medic_damage = 0
	pending_blasts.clear()
	hazards.clear()
	effect_visuals.clear()
	for enemy in enemies: enemy.slow_until = 0.0

func _effect_event(kind: String, data: Dictionary) -> bool:
	return effect_runtime.emit_event(kind,data)

func _update_hazards(dt: float) -> void:
	effect_runtime.advance_hazards(dt)

func _update_mortars(dt: float) -> void:
	effect_runtime.advance_mortars(dt)

func _hit_segment(b:Dictionary,start:Vector2,end:Vector2)->void:
	weapon_combat.hit_segment(b,start,end)

func _advance_bullet(b: Dictionary,dt: float) -> void:
	weapon_combat.advance_bullet(b,dt)

func _advance_disc(b: Dictionary,dt: float) -> void:
	weapon_combat.advance_disc(b,dt)

func _vfx(id: String,pos: Vector2,options: Dictionary = {}) -> void:
	if is_instance_valid(vfx): vfx.play(id,pos,options)

func _sync_telegraphs() -> void:
	var markers: Array = []
	for blast in pending_blasts:
		markers.append({"kind":"circle","pos":blast.pos,"radius":blast.radius,"color":Color("9ddcf6")})
	for enemy in enemies:
		if enemy.hp <= 0 or enemy.ai_state != "warning": continue
		var color := Color(1,.35,.18,.9)
		if enemy.attack == "charge":
			markers.append({"kind":"line","pos":enemy.pos,"end":enemy.pos+enemy.aim*enemy.charge_speed*enemy.charge_duration,"width":2*(16*enemy.scale+9),"color":color})
		else:
			markers.append({"kind":"circle","pos":enemy.target if enemy.attack=="blast" else enemy.pos,"radius":105 if enemy.attack=="blast" else 34*enemy.scale,"color":color})
	for visual in effect_visuals:
		if visual.kind in ["mine","mortar","phase"]:
			markers.append({"kind":"circle","pos":visual.pos,"radius":visual.radius,"color":Color("b0e7cf")})
	for flash in flashes:
		if flash.get("radius",0)>=70:
			markers.append({"kind":"circle","pos":flash.pos,"radius":flash.radius,"color":Color("f4d692")})
	telegraphs.show_markers(markers)

func _mechanism_vfx(source:String,id:String,pos:Vector2,options:Dictionary={}) -> void:
	if elapsed<float(visual_cooldowns.get(source,-1.0)):return
	visual_cooldowns[source]=elapsed+.08
	var decorated:=options.duplicate(true)
	decorated.source_item=source
	_vfx(id,pos,decorated)

func _launch_pose(id:String,slot:int,target:Vector2)->Dictionary:
	return weapon_presentation.pose(id,slot,target)

func _sync_weapon_rig()->void:
	if not is_instance_valid(weapon_rig):return
	if state in ["title","dead","won"] or build.is_empty():
		if not weapon_rig.slots.is_empty():weapon_rig.clear()
		return
	weapon_rig.sync_loadout(build.weapons)
	var target:Vector2=player_pos+Vector2(-100 if hero.flip_h else 100,0)
	var living:Array=enemies.filter(func(e):return e.hp>0)
	if not living.is_empty():
		var nearest:Dictionary=living[0]
		for e in living:
			if e.pos.distance_squared_to(player_pos)<nearest.pos.distance_squared_to(player_pos):nearest=e
		target=nearest.pos
	weapon_rig.update_poses(actor_anim.socket_world(0,"grip"),actor_anim.socket_world(0,"body"),target,hero.flip_h,bullets,pending_blasts,true)

func _select_mode(id:String)->bool:
	if state!="title" or id not in ["arena","rooms"]:return false
	if id=="rooms" and not RoomMode.validate(room_profile,encounters).is_empty():return false
	mode=ArenaMode.new() if id=="arena" else RoomMode.new(room_profile)
	config.arena=mode.field(base_arena)
	_enter_field(run_seed)
	_title()
	return true
func _enter_field(seed_value:int)->void:
	var field:=FieldLayout.make(config.arena,seed_value)
	grid_size=field.grid
	map_data=field.cells
	player_pos=field.center
	hero.position=player_pos
	camera.position=FieldLayout.camera_position(player_pos,config.arena)
func _begin_room_clear()->void:
	if state!="playing":return
	state="room_clear"
	bullets.clear();enemy_bullets.clear();pending_blasts.clear();hazards.clear();flashes.clear()
	_clear_transients()
	weapon_rig.clear()
	actor_anim.set_phase(0,"idle")
