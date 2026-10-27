from pathlib import Path
import json,hashlib,difflib,datetime
r=Path('workspace/shared');d=Path(__file__).parent;source=r/'moss-v38-final/tests/independent_settlement_types.gd';a=source.read_text();h=lambda p:hashlib.sha256(p.read_bytes()).hexdigest();(d/'original.gd').write_text(a)
spy='''class StopAudit extends "res://scripts/feedback_audio.gd":
 var explicit_stop_all_calls:=0
 func stop_all()->void:
  explicit_stop_all_calls+=1
  super.stop_all()
var diagnostic_rows:Array=[]
'''
b=a.replace('class Policy extends RefCounted:',spy+'class Policy extends RefCounted:')
setup='''  # Observer-only replacement preserves actual base FeedbackAudio request/stream/player/stop implementations.
  var original_audio=g.feedback_audio
  var observed_audio:=StopAudit.new();g.add_child(observed_audio);g.feedback_audio=observed_audio
  original_audio.queue_free();await process_frame
'''
b=b.replace('  var policy:=Policy.new();g.mode=policy\n',setup+'  var policy:=Policy.new();g.mode=policy\n')
request='   g.feedback_audio.request("player_damage");g.feedback_audio.request("shield_block")\n'
b=b.replace(request,'   var request_started:int=Time.get_ticks_usec()\n'+request+'''   var requested_at:int=Time.get_ticks_usec();var before_calls:int=observed_audio.explicit_stop_all_calls
   var requested_playing:Array=[observed_audio.players.player_damage.playing,observed_audio.players.shield_block.playing]
''')
b=b.replace('   g._complete_wave()\n','''   g._complete_wave()
   var call_finished:int=Time.get_ticks_usec();var call_stops:int=observed_audio.explicit_stop_all_calls-before_calls
   var immediately_playing:Array=[observed_audio.players.player_damage.playing,observed_audio.players.shield_block.playing]
''')
line='   ck(snap(g)==before,"controller invalid policy remains atomic "+mode+str(i))\n'
b=b.replace(line,line+'''   var snap_finished:int=Time.get_ticks_usec()
   diagnostic_rows.append({"mode":mode,"index":i,"requested_playing":requested_playing,"immediately_playing":immediately_playing,"after_snap_playing":[observed_audio.players.player_damage.playing,observed_audio.players.shield_block.playing],"request_elapsed_us":requested_at-request_started,"call_elapsed_us":call_finished-requested_at,"snapshot_elapsed_us":snap_finished-call_finished,"total_after_request_us":snap_finished-requested_at,"explicit_stop_all_calls_during_controller":call_stops,"stop_calls_through_snapshot":observed_audio.explicit_stop_all_calls-before_calls})
''')
b=b.replace(' print(JSON.stringify(report));quit(',''' print("SETTLEMENT_TIMING "+JSON.stringify({"rows":diagnostic_rows,"scope":"Diagnostic only: same original960assertions; real baseaudio with stop_all forwarding counter, low-volume saved perdecision timing. Not original-timeout reconstruction or automatic acceptance retry."}))
 print(JSON.stringify(report));quit(''')
# Every original assertion text remains exact and in sequence.
assert [z.strip() for z in a.splitlines() if z.strip().startswith('ck(')]==[z.strip() for z in b.splitlines() if z.strip().startswith('ck(')]
(d/'instrumented.gd').write_text(b);(d/'INSTRUMENTATION.patch').write_text(''.join(difflib.unified_diff(a.splitlines(True),b.splitlines(True),fromfile='original960',tofile='external-diagnostic')))
x={'status':'PREPARED_NOT_EXECUTED_REQUIRES_ROOT_APPROVAL_AND_CPU_LANE','utc':datetime.datetime.now(datetime.timezone.utc).isoformat(),'original_sha256':h(source),'instrumented_sha256':h(d/'instrumented.gd'),'source_map_sha256':'2c82f7343613a2f130a04e541558fba5edf3150e0755295d837349e8ab710cf8','source':'evidence-workspace/moss-v38-final','per_command_seconds':180,'attempts':1,'assertions':'Original960 checks/invalid102 input matrix/assertion text+order unchanged; original scope/output retained. Added observational prefix only.','observer':'Replace only external fixture audio Node after run setup with subclass inheriting same FeedbackAudio implementation and super.stop_all forwarding counter; old idle node queue_free+one process frame before per-decision work. No production/source/stream/volume/clip-duration change.','measurements':'Actual requested/immediate/after-heavy-snap playing flags, monotonic elapsed wall timings and explicit stop_all call deltas. Natural finish remains possible; no forced long clip or artificial pause.','interpretation':'Diagnostic regardless outcome; original Rooms1/5 FAIL retained. A zero forwarded stop count localizes explicit controller stop authority; duration/playing observations must be reported, not assumed to reproduce historical timing.','no_target_mutation':True};(d/'PLAN.json').write_text(json.dumps(x,indent=2)+'\n');print(h(d/'PLAN.json'))
