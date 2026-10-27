extends SceneTree
const Readout=preload("res://scripts/weapon_readout.gd")
var failures:Array=[]
var checks:=0
func ck(value:bool,label:String)->void:
	checks+=1
	if not value:failures.append(label)
func _initialize()->void:
	var tether:Dictionary={"kind":"weapon","behavior":"tether_pulse","damage":10.0,"interval":1.2,"range":280.0,"tags":["electric"],"pulse_count":4}
	var drum:Dictionary={"kind":"weapon","behavior":"expanding_ring","damage":22.0,"interval":1.4,"range":180.0,"tags":["melee"],"inner_start_radius":24.0,"band_half_width":12.0,"outward_seconds":0.6}
	var stats:Dictionary={"damage_bonus":0.25,"electric_bonus":0.2,"melee_bonus":0.2,"haste":0.5,"range_bonus":0.1,"extra_pellets":7}
	var before:Array=[tether.duplicate(true),drum.duplicate(true),stats.duplicate(true)]
	var base:Dictionary=Readout.describe(tether,stats,false,1.6)
	ck(base.damage==10 and is_equal_approx(base.interval,1.2) and base.reach==280,"base ignores build and tier")
	ck(base.damage_unit=="per pulse" and base.pulse_count==4 and is_equal_approx(base.pulse_interval,0.3),"pulse unit/count/time")
	var current:Dictionary=Readout.describe(tether,stats,true,1.6)
	ck(is_equal_approx(current.damage,24.0) and is_equal_approx(current.interval,0.8) and is_equal_approx(current.pulse_interval,0.2),"current ordered damage and haste")
	ck(is_equal_approx(current.reach,308.0) and not current.has("pellets"),"range bonus but no invented projectile benefit")
	var ring:Dictionary=Readout.describe(drum,stats,true,1.6)
	ck(is_equal_approx(ring.damage,52.8) and ring.damage_unit=="per target / outward leg","ring primary per outward leg")
	ck(is_equal_approx(ring.inner_start_radius,24) and is_equal_approx(ring.band_half_width,12) and is_equal_approx(ring.outward_seconds,0.6),"ring geometry catalog driven")
	ck(not ring.has("inward_damage") and not ring.has("inward_seconds"),"no ownership falsely inferred from API without build")
	ck([tether,drum,stats]==before,"inputs unchanged")
	print(JSON.stringify({"checks":checks,"failures":failures,"kind":"developer fixture, not independent acceptance"}))
	quit(0 if failures.is_empty() else 1)
