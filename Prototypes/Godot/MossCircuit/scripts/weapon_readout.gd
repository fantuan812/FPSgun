extends RefCounted
## Read-only presentation adapter; all numeric calculations are shared with combat.
const Rules=preload("res://scripts/rules.gd")

static func describe(weapon:Dictionary,stats:Dictionary,current:bool,tier_multiplier:float=1.0)->Dictionary:
	if weapon.get("kind","")!="weapon":return {}
	var input:Dictionary=stats if current else {"damage_bonus":0.0,"electric_bonus":0.0,"melee_bonus":0.0,"haste":0.0,"range_bonus":0.0,"extra_pellets":0}
	var unit:String="per contact"
	var reach_label:String="Acquisition / range limit"
	var note:String="Primary damage only; module procs are separate. Interval is scheduled with valid targets, not guaranteed DPS."
	match str(weapon.behavior):
		"spread":unit="per pellet contact"
		"orbit":
			unit="per target / sweep"
			reach_label="Sweep radius"
			note+=" Focus Lens does not change this radius."
		"return":
			reach_label="Acquisition / outbound reach"
			note+=" Not total round-trip travel; each leg can hit each target once."
		"mortar":
			unit="per target / blast"
			reach_label="Acquisition reach"
			note+=" Reach is not blast radius; blast size and delay follow base behavior."
		"cone_chill":
			unit="per target / cone"
			reach_label="Cone reach"
			note+=" Instant cone: projectile and pierce bonuses do not apply; fixed shatter damage is separate."
		"tether_pulse":
			unit="per pulse"
			reach_label="Live lock range"
			note+=" One locked target; no transferred pulses on loss or death. No immediate hit. Projectile and pierce bonuses do not apply."
		"expanding_ring":
			unit="per target / outward leg"
			reach_label="Maximum ring radius"
			note+=" Fixed launch center; narrow moving band, not a filled blast. Enemy body radius counts: close targets can overlap the initial band. Return Collar enables a separate inward leg; this readout does not assert that module is owned. Projectile and pierce bonuses do not apply."
		"field_bankshot":
			reach_label="Acquisition reach"
			note+=" One total path across all legs, not a fresh range per bounce. Guide changes direction only."
	var result:Dictionary={"scope":"CURRENT" if current else "BASE","damage":Rules.weapon_damage(weapon,input,tier_multiplier if current else 1.0),"damage_unit":unit,"interval":Rules.weapon_interval(weapon,input),"reach":Rules.weapon_reach(weapon,input),"reach_label":reach_label,"note":note}
	if weapon.behavior=="spread":result.pellets=Rules.weapon_projectiles(weapon,input)
	if weapon.behavior=="field_bankshot":result.total_path=result.reach
	if weapon.behavior=="tether_pulse":
		result.pulse_count=int(weapon.get("pulse_count",0))
		if result.pulse_count>0:
			result.pulse_interval=float(result.interval)/float(result.pulse_count)
			result.behavior_summary="%d pulses / %.3f s between scheduled pulses; first pulse after one pulse interval." % [result.pulse_count,result.pulse_interval]
	if weapon.behavior=="expanding_ring":
		result.inner_start_radius=float(weapon.get("inner_start_radius",0.0))
		result.band_half_width=float(weapon.get("band_half_width",0.0))
		result.outward_seconds=float(weapon.get("outward_seconds",0.0))
		result.behavior_summary="Outward ring %.1f -> %.1f px / %.3f s / band half-width %.1f px." % [result.inner_start_radius,result.reach,result.outward_seconds,result.band_half_width]
	return result
