extends "res://tests/independent_tempering_authority.gd"
## Four representative field deltas across two inherited exact frozen fixtures.
func digest_value(value:Variant)->String:
 var h=HashingContext.new();h.start(HashingContext.HASH_SHA256);h.update(var_to_bytes(value));return h.finish().hex_encode()
func run()->void:
 g=load("res://scenes/main.tscn").instantiate();root.add_child(g);g.set_process(false)
 var observations:Array=[]
 for mode in ["arena","rooms"]:
  setup(mode)
  var before:Dictionary=snap()
  var accepted:bool=g._temper_weapon(0,1,g.shop_generation,"rivet_gun","rivet_gun")
  var after:Dictionary=snap()
  var b:Dictionary=before.world;var a:Dictionary=after.world;var delta:Dictionary={}
  for field in b:
   if not same(b[field],a.get(field)):
    delta[field]={"before_sha256":digest_value(b[field]),"after_sha256":digest_value(a.get(field)),"before_type":typeof(b[field]),"after_type":typeof(a.get(field))}
  for field in a:
   if not b.has(field):delta[field]={"new_key":true,"after_sha256":digest_value(a[field])}
  observations.append({"mode":mode,"action":"temper","accepted":accepted,"world_field_deltas":delta,"epoch_before":b.new_weapon_epoch,"epoch_after":a.new_weapon_epoch,"pulse_before":b.pulse_beams,"pulse_after":a.pulse_beams,"waves_before":b.seismic_waves,"waves_after":a.seismic_waves,"motion_before":b.new_weapon_motion,"motion_after":a.new_weapon_motion})
 var helper=preload("res://tests/support/audio_teardown.gd").new();helper.prepare([g]);g.queue_free();await process_frame;await helper.finish(self)
 print("AUTHORITY_DELTA "+JSON.stringify({"observations":observations,"scope":"diagnostic only; inherited original fixture setup/snap; no old expected changed, no PASS attribution"}))
 quit(0)
