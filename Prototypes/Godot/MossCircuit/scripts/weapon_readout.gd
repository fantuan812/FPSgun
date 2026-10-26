extends RefCounted
## Read-only presentation adapter; all numeric calculations are shared with combat.
const Rules=preload("res://scripts/rules.gd")

static func describe(weapon:Dictionary,stats:Dictionary,current:bool)->Dictionary:
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
		"field_bankshot":
			reach_label="Acquisition reach"
			note+=" One total path across all legs, not a fresh range per bounce. Guide changes direction only."
	var result:Dictionary={"scope":"CURRENT" if current else "BASE","damage":Rules.weapon_damage(weapon,input),"damage_unit":unit,"interval":Rules.weapon_interval(weapon,input),"reach":Rules.weapon_reach(weapon,input),"reach_label":reach_label,"note":note}
	if weapon.behavior=="spread":result.pellets=Rules.weapon_projectiles(weapon,input)
	if weapon.behavior=="field_bankshot":result.total_path=result.reach
	return result
