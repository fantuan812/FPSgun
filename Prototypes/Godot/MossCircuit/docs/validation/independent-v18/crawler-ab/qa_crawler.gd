extends Node
# Controlled true-spawn-scale presentation probe, not ordinary combat.
var game
var crawlers:Array=[]
var caption:Label
var last_trigger:=[]
func _ready()->void:
	game=load("res://scenes/main.tscn").instantiate();add_child(game);game.set_process(false)
	var layer:=CanvasLayer.new();layer.layer=30;add_child(layer)
	caption=Label.new();caption.position=Vector2(20,430);caption.add_theme_font_size_override("font_size",13);layer.add_child(caption)
	reset()
func reset()->void:
	game._title();game._start_run(1818);game.spawn_clock=999;game.weapon_clocks=[999.0]
	game.stats.hp=10000;game.stats.max_hp=10000;crawlers.clear();last_trigger=[]
	for x in [-180,180]:
		var e:Dictionary=game._spawn_kind("crawler",game.player_pos+Vector2(x,0))
		e.sprite.position=e.pos;e.sprite.flip_h=x<0
		game.actor_anim.set_phase(e.id,"move");crawlers.append(e)
	show_label()
func step(dt:float)->void:
	game.actor_anim.advance(dt);show_label()
func show_label()->void:
	var e:Dictionary=crawlers[0];var a:Dictionary=game.actor_anim.actors[e.id]
	caption.text="CONTROLLED QA ONLY: stationary presentation; actual crawler spawn scale %.5f\n%s | state %s | frame %s | age %.3f | both horizontal facings\nH: trigger hurt (repeat guard)   N: next frame/expiry   T: +0.01s   R: reset\nLast trigger accepted: %s | frozen gameplay; no combat/balance claim"%[a.height,"ALIGNED" if ProjectSettings.globalize_path("res://").contains("aligned") else "BASELINE",a.state,e.sprite.frame,a.age,last_trigger]
func _input(event:InputEvent)->void:
	if not(event is InputEventKey) or not event.pressed or event.echo:return
	match event.keycode:
		KEY_R:reset()
		KEY_H:
			last_trigger=[]
			for e in crawlers:last_trigger.append(game.actor_anim.trigger(e.id,"hurt"))
			show_label()
		KEY_T:step(.01)
		KEY_N:
			var e:Dictionary=crawlers[0];var f:int=e.sprite.frame;var s:String=game.actor_anim.state_of(e.id)
			for i in range(100):
				step(.005)
				if e.sprite.frame!=f or game.actor_anim.state_of(e.id)!=s:break
