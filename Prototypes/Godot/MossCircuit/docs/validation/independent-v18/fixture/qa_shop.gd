extends Node
# Controlled GUI-only shop fixture. Production files remain unchanged.
var game
var caption:Label
func _ready()->void:
	game=load("res://scenes/main.tscn").instantiate()
	add_child(game);game.set_process(false);game._start_run(1717)
	game.build.weapons=["rivet_gun","scrap_shotgun","rail_lance","orbit_saw"]
	game.build.coins=100;game._recompute();game._open_shop()
	game.shop_offers=[{"id":"shock_mortar","sold":false,"weight_multiplier":1.0,"bias_reasons":["Controlled QA fixture"]}]
	game._render_shop()
	var layer:=CanvasLayer.new();layer.layer=30;add_child(layer)
	caption=Label.new();caption.position=Vector2(16,518)
	caption.add_theme_font_size_override("font_size",11);layer.add_child(caption)
func _process(_delta:float)->void:
	if caption!=null:
		caption.text="CONTROLLED QA: full slots + forced offer | coins %s | weapons %s | generation %s"%[game.build.coins,','.join(game.build.weapons),game.shop_generation]
