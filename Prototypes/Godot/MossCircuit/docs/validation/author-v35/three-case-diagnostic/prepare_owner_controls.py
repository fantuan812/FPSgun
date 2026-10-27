from pathlib import Path
import hashlib,json,difflib
r=Path('workspace/shared');src=r/'moss-v35-final';out=r/'moss-v35-final-diagnostic';sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest();rows=[]
for name,var in [('independent_charger_lifecycle.gd','g'),('test_game.gd','game'),('test_warden_charge.gd','game')]:
 original=(src/'tests'/name).read_text();needle=f'\t{var}.queue_free();await process_frame' if name!='test_game.gd' else '\tgame.queue_free()\n\tawait process_frame'
 pos=original.rfind(needle);assert pos>=0
 replacement=f'''\tvar owner_refs:Dictionary={{}}
\tvar owner_observation:Dictionary={{"case":"{name}","before":{{}},"after_one_frame":{{}},"chunks":[],"deadline_ms":1000,"scope":"External disposal-only owner observation; original failed resource identities for non-reproduced cases remain unknown."}}
\tfor cue in {var}.feedback_audio.players:
\t\tvar stream:Resource={var}.feedback_audio.players[cue].stream
\t\towner_refs[cue]=weakref(stream)
\t\towner_observation.before[cue]={{"id":stream.get_instance_id(),"class":stream.get_class(),"path":stream.resource_path,"playing":{var}.feedback_audio.players[cue].playing}}
\t\tstream=null # Never pin the resource through the observer.
\tvar owner_capture:=AudioEffectCapture.new();owner_capture.buffer_length=2.0
\tvar owner_effect_index:int=AudioServer.get_bus_effect_count(0);AudioServer.add_bus_effect(0,owner_capture)
{needle}
\towner_observation.node_freed=not is_instance_valid({var})
\tfor cue in owner_refs:owner_observation.after_one_frame[cue]=owner_refs[cue].get_ref()!=null
\tvar owner_queued:int=owner_capture.get_frames_available()
\tif owner_queued>0:owner_capture.get_buffer(owner_queued) # Explicit pre-window drain, not fresh-silence evidence.
\towner_observation.pre_window_drained=owner_queued
\tvar owner_required:int=int(ceil(AudioServer.get_mix_rate()*.15))
\tvar owner_start:int=Time.get_ticks_usec()
\tvar owner_pushed_before:int=owner_capture.get_pushed_frames()
\tvar owner_silent_frames:int=0
\tvar owner_complete:=false
\tvar owner_invalid:int=0
\twhile Time.get_ticks_usec()-owner_start<1000000:
\t\tawait create_timer(.01).timeout
\t\tvar owner_count:int=owner_capture.get_frames_available()
\t\tvar owner_peak:=0.0
\t\tif owner_count>0:
\t\t\tvar owner_pcm:PackedVector2Array=owner_capture.get_buffer(owner_count)
\t\t\tfor frame in owner_pcm:
\t\t\t\tif not is_finite(frame.x) or not is_finite(frame.y):owner_invalid+=1
\t\t\t\towner_peak=maxf(owner_peak,maxf(absf(frame.x),absf(frame.y)))
\t\t\t\tif absf(frame.x)<=.000001 and absf(frame.y)<=.000001:owner_silent_frames+=1
\t\t\t\telse:owner_silent_frames=0
\t\tvar owner_released:=true
\t\tfor cue in owner_refs:owner_released=owner_released and owner_refs[cue].get_ref()==null
\t\towner_observation.chunks.append({{"frames":owner_count,"peak":owner_peak,"pushed":owner_capture.get_pushed_frames(),"refs_released":owner_released,"elapsed_us":Time.get_ticks_usec()-owner_start}})
\t\tif owner_observation.node_freed and owner_invalid==0 and owner_released and owner_silent_frames>=owner_required and owner_capture.get_pushed_frames()-owner_pushed_before>=owner_required and Time.get_ticks_usec()-owner_start>=150000 and Time.get_ticks_usec()-owner_start<=1000000 and owner_capture.get_discarded_frames()==0:
\t\t\towner_complete=true;break
\towner_observation.complete=owner_complete
\towner_observation.invalid_samples=owner_invalid
\towner_observation.silent_frames=owner_silent_frames
\towner_observation.discarded=owner_capture.get_discarded_frames()
\towner_observation.new_pushed=owner_capture.get_pushed_frames()-owner_pushed_before
\towner_observation.required_frames=owner_required
\towner_observation.elapsed_us=Time.get_ticks_usec()-owner_start
\tAudioServer.remove_bus_effect(0,owner_effect_index)
\towner_observation.capture_removed=AudioServer.get_bus_effect_count(0)==owner_effect_index
\tvar owner_args:=OS.get_cmdline_user_args()
\tif not owner_args.is_empty():FileAccess.open(owner_args[0],FileAccess.WRITE).store_string(JSON.stringify(owner_observation,"  ")+"\\n")
\tprint("OWNER_OBSERVATION ",JSON.stringify(owner_observation))
\tif not owner_complete or not owner_observation.capture_removed:push_error("External owner observation reached bounded deadline without complete reference release/fresh silence")'''
 revised=original[:pos]+replacement+original[pos+len(needle):];dest=out/('owner_'+name);dest.write_text(revised)
 (out/('owner_'+name+'.patch')).write_text(''.join(difflib.unified_diff(original.splitlines(True),revised.splitlines(True),fromfile='frozen/'+name,tofile='external-owner/'+name)))
 rows.append({'case':name,'source_sha256':sha(src/'tests'/name),'external_sha256':sha(dest),'only_changed_seam':'final queue_free/oneprocessframe, original assertions unchanged'})
plan={'status':'PREPARED_NOT_EXECUTED','cases':rows,'deadline_ms':1000,'completion':'all production stream weakrefs released + >=150ms (ceil mix_rate*.15) newly pushed consecutive silent frames after explicit pre-window queue drain + zero discarded + node freed; test-only capture removed','source_mutation':False,'negative_scope':'Charger/game original failure resource identity remains unknown if not reproduced. This observation is not whole-suite acceptance.'};(out/'OWNER_PLAN.json').write_text(json.dumps(plan,indent=2)+'\n');print(json.dumps(plan,indent=2))
