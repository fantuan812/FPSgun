from pathlib import Path
import json,difflib,hashlib,shutil,datetime
q=Path(__file__).parent;out=q/'authority-partition';assert not out.exists();out.mkdir();original=q/'final-gate/packed-harness/independent_feedback_authority.gd';s=original.read_text();mode_line=' for mode in ["arena","rooms"]:';init=' var initial=make_game("arena");resource_checks(initial);initial.queue_free();await process_frame\n';assert s.count(mode_line)==s.count(init)==1
h=lambda p:hashlib.sha256(p.read_bytes()).hexdigest();rows=[]
for mode,count in [('arena',435),('rooms',338)]:
 new=s.replace(mode_line,' for mode in ["'+mode+'"]:',1)
 if mode=='rooms':new=new.replace(init,'',1)
 back=new.replace(' for mode in ["'+mode+'"]:',mode_line,1)
 if mode=='rooms':back=back.replace('func run()->void:\n','func run()->void:\n'+init,1)
 assert back==s
 p=out/(mode+'.gd');p.write_text(new);(out/(mode+'.patch')).write_text(''.join(difflib.unified_diff(s.splitlines(True),new.splitlines(True),fromfile='original_external',tofile=mode)));rows.append({'mode':mode,'script_sha256':h(p),'checks':count,'resource_checks':mode=='arena','mode_checks':338,'inverse_restores_original':True,'changes':'Select one original mode only; Rooms omits original one-time initial Arena resource-check setup, which Arena retains exactly'})
shutil.copy2(original,out/'original_external.gd');plan={'utc':datetime.datetime.now(datetime.timezone.utc).isoformat(),'status':'FROZEN_FORMAL_NEW_GATE_NOT_EXECUTED','original_sha256':h(original),'helper_sha256':h(q/'final-gate/packed-harness/audio_teardown.gd'),'pck_sha256':h(q.parent/'moss-v36-pack/linux/MossCircuit.pck'),'source_map_sha256':h(q/'FINAL_INPUTS.json'),'parts':rows,'coverage':{'one_time_initial_resource_assertions':97,'arena_original_mode_assertions':338,'rooms_original_mode_assertions':338,'total':773,'ordering':'Arena process (original initial resource block then original Arena body), then Rooms process(original Rooms body). Every mode case/assertion/order/cleanup unchanged; independent fresh process/profile per partition.'},'budgets':'NEW gate each180s, summed maximum360s; explicitly different from original single180s gate. Not a timeout extension/retry of original longfixture.','history':'Original180s timeout remainsFAIL;178.371s timing run remainsDIAGNOSTIC_ONLY; results all distinct.'};(out/'PLAN.json').write_text(json.dumps(plan,indent=2)+'\n');print(plan)
