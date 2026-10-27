from pathlib import Path
import json,hashlib,difflib,shutil,datetime
q=Path(__file__).parent;out=q/'authority-timing';assert not out.exists();out.mkdir();source=q/'final-gate/packed-harness/independent_feedback_authority.gd';old=source.read_text();s=old;edits=[]
def edit(a,b):
 global s
 assert s.count(a)==1,(a,s.count(a));s=s.replace(a,b,1);edits.append((a,b))
edit('var checks:=0','''var diagnostic_started:int=Time.get_ticks_usec()
var diagnostic_make_us:int=0
var diagnostic_make_count:int=0
var diagnostic_snap_us:int=0
var diagnostic_snap_count:int=0
func diagnostic_checkpoint(stage:String)->void:
 print("AUTHORITY_TIMING "+JSON.stringify({"stage":stage,"elapsed_us":Time.get_ticks_usec()-diagnostic_started,"make_us":diagnostic_make_us,"make_count":diagnostic_make_count,"snap_us":diagnostic_snap_us,"snap_count":diagnostic_snap_count,"checks_so_far":checks,"failure_count_so_far":failures.size()}))
var checks:=0''')
edit('func snap(g)->Dictionary:\n return ', 'func snap(g)->Dictionary:\n var diagnostic_t:int=Time.get_ticks_usec()\n var diagnostic_result:Dictionary=')
needle='"vfx":props(g.vfx)}\nfunc make_game';edit(needle,'"vfx":props(g.vfx)}\n diagnostic_snap_us+=Time.get_ticks_usec()-diagnostic_t;diagnostic_snap_count+=1\n return diagnostic_result\nfunc make_game')
edit('func make_game(mode:String,items:Dictionary={}):\n var g=', 'func make_game(mode:String,items:Dictionary={}):\n var diagnostic_t:int=Time.get_ticks_usec()\n var g=')
edit(' return g\nfunc record',' diagnostic_make_us+=Time.get_ticks_usec()-diagnostic_t;diagnostic_make_count+=1\n return g\nfunc record')
edit('func run()->void:\n var initial=', 'func run()->void:\n diagnostic_checkpoint("start_resource_checks")\n var initial=')
edit(' for mode in ["arena","rooms"]:\n  for spec in [', ' for mode in ["arena","rooms"]:\n  diagnostic_checkpoint(mode+"_resolved_damage")\n  for spec in [')
for a,stage in [('  var g=make_game(mode,{"mirror_shell":1});','guards'),('  for route in ["contact","hostile swept projectile","boss blast","brood annulus"]:','hostile_routes'),('  # Real Feedback Diode resolves owner damage during dash, while the old dash guard rejects HP loss.','feedback_and_medical'),('  for transition in ["pause","inventory","upgrade","shop","room_clear","title","start","finish_dead","finish_won","focus_out","no_shop_settlement","normal_settlement"]:','lifecycle'),('  for invalid in ["invalid_start","invalid_settlement","ignored_settlement","ignored_room_clear"]:','invalid_boundaries'),('  for tail_stop in ["focus_out","title","retry","mute"]:','lethal_tails'),('  g=make_game(mode);events=[];record(g,events);ck(not g.settings.mute_feedback_sounds,"fresh session defaults unmuted")','settings')]:edit(a,'  diagnostic_checkpoint(mode+"_'+stage+'")\n'+a)
edit('  await audio_teardown.finish(self)\n var result:', '  await audio_teardown.finish(self)\n  diagnostic_checkpoint(mode+"_complete")\n diagnostic_checkpoint("all_assertions_complete")\n var result:')
restored=s
for a,b in reversed(edits):assert restored.count(b)==1;restored=restored.replace(b,a,1)
assert restored==old
(out/'authority_timing.gd').write_text(s);shutil.copy2(source,out/'original_external_fixture.gd');(out/'instrumentation.patch').write_text(''.join(difflib.unified_diff(old.splitlines(True),s.splitlines(True),fromfile='original_external',tofile='timing_only')))
h=lambda p:hashlib.sha256(p.read_bytes()).hexdigest();plan={'utc':datetime.datetime.now(datetime.timezone.utc).isoformat(),'status':'FROZEN_NOT_EXECUTED','original_external_sha256':h(source),'instrumented_sha256':h(out/'authority_timing.gd'),'source_fixture_sha256':h(q/'project/tests/independent_feedback_authority.gd'),'helper_sha256':h(q/'final-gate/packed-harness/audio_teardown.gd'),'pck_sha256':h(q.parent/'moss-v36-pack/linux/MossCircuit.pck'),'inverse_exact':True,'instrumentation':'Monotonic cumulative make_game and snap CPU-wall timings; low-volume section checkpoints, check/failure counters observed only. No assertion/loop/await/fixture/production/PCK/180s-budget changes.','stopping':'Single180s maximum diagnostic. Whatever outcome, not a retry-to-PASS and original timeout persists.'};(out/'PLAN.json').write_text(json.dumps(plan,indent=2)+'\n');print(plan)
