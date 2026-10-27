from pathlib import Path
import hashlib,json,difflib,datetime
r=Path('workspace/shared');d=Path(__file__).parent;s=r/'moss-v38-final';h=lambda p:hashlib.sha256(p.read_bytes()).hexdigest();orig=(s/'tests/independent_feedback_authority.gd').read_text();assert h(s/'tests/independent_feedback_authority.gd')=='e733fc08d6ca4d3c16c6f3e8ae5a7abc415b5b96b4c20823da1b5ac5a96ba690';(d/'original.gd').write_text(orig)
initial=' var initial=make_game("arena");resource_checks(initial);initial.queue_free();await process_frame\n';loop=' for mode in ["arena","rooms"]:\n';assert orig.count(initial)==orig.count(loop)==1
rows=[]
for mode in ['arena','rooms']:
 new=orig.replace(loop,' for mode in ["'+mode+'"]:\n')
 if mode=='rooms':new=new.replace(initial,'')
 inv=new.replace(' for mode in ["'+mode+'"]:\n',loop)
 if mode=='rooms':inv=inv.replace(loop,initial+loop)
 assert inv==orig
 historical=(r/('moss-v36-qa/authority-partition/'+mode+'.gd')).read_text().replace('evidence-workspace/moss-v36-qa/final-gate/packed-harness/audio_teardown.gd','res://tests/support/audio_teardown.gd');assert new==historical
 (d/(mode+'.gd')).write_text(new);(d/(mode+'.patch')).write_text(''.join(difflib.unified_diff(orig.splitlines(True),new.splitlines(True),fromfile='original773',tofile=mode)))
 rows.append({'mode':mode,'sha256':h(d/(mode+'.gd')),'checks':435 if mode=='arena' else 338,'inverse_exact':True,'historical_accepted_partition_exact_except_helper_path':True})
run=(s/'tests/run_regression.py').read_text();old='    except subprocess.TimeoutExpired as error:\n        log, code = str(error), 124\n';new='''    except subprocess.TimeoutExpired as error:
        # Preserve partial timeout streams; timeout remains native124 and rejected.
        partial_stdout = error.stdout or b""
        partial_stderr = error.stderr or b""
        stdout_bytes = partial_stdout.encode("utf-8") if isinstance(partial_stdout, str) else partial_stdout
        stderr_bytes = partial_stderr.encode("utf-8") if isinstance(partial_stderr, str) else partial_stderr
        (output / (label + ".timeout.stdout")).write_bytes(stdout_bytes)
        (output / (label + ".timeout.stderr")).write_bytes(stderr_bytes)
        log, code = stdout_bytes.decode("utf-8", errors="replace") + stderr_bytes.decode("utf-8", errors="replace") + "\\n" + str(error), 124
''';assert run.count(old)==1;logging=run.replace(old,new);(d/'run_regression.logging_only.py').write_text(logging);(d/'logging_only.patch').write_text(''.join(difflib.unified_diff(run.splitlines(True),logging.splitlines(True),fromfile='original-runner',tofile='logging-only')))
combined=logging.replace('"independent_feedback_authority.gd", "independent_feedback_mixer.gd"','"independent_feedback_authority.gd", "independent_feedback_authority_rooms.gd", "independent_feedback_mixer.gd"');assert combined!=logging;(d/'run_regression.proposed.py').write_text(combined);(d/'rooms_dispatch.patch').write_text(''.join(difflib.unified_diff(logging.splitlines(True),combined.splitlines(True),fromfile='logging-only',tofile='logging-and-rooms-output')))
x={'status':'PROPOSAL_ONLY_CURRENT_AGGREGATE_STILL_RUNNING_NOT_APPLIED','utc':datetime.datetime.now(datetime.timezone.utc).isoformat(),'original_source_fixture_sha256':h(s/'tests/independent_feedback_authority.gd'),'current_timeout_partial_streams':'NOT_CAPTURED by original generic runner; cannot infer last phase or absence of prior errors','historical_timing':'Existing v36 instrumented exact fixture shows make_game/snap wall timings for that prior run only; not current v38 causal diagnosis. No new long timing rerun proposed.','parts':rows,'coverage':'Arena original initial resource97 + original mode338 =435; Rooms original mode338. Every case/assert/order/await/cleanup and resulting72 observations retained, fresh process per mode.','proposed_paths':{'tests/independent_feedback_authority.gd':'Arena partition retains old filename/UID','tests/independent_feedback_authority_rooms.gd':'new Rooms partition','tests/support/historical_feedback_authority_v35.gd':'byte-exact original773 script retained, excluded from top-level standalone discovery'},'budget':'Explicit NEW source functional gate each180,totalmax360 instead of original single180. Original v38 source timeout remainsFAIL. Generic per-command180 unchanged but total gate budget is changed and must be approved, not hidden.','discovery':'Current137standalone+import138 becomes138standalone+import139; actual discovery must verify. No production changes.','runner_changes':['Logging-only preserve TimeoutExpired stdout/stderr exact bytes pluscombined log; native124 and error/success/cap/continue rules unchanged','Add new Rooms filename to existing four-file JSON-output dispatch so36 observations saved; old original predicates unchanged'],'required_before_adoption':['original138 terminal','explicit scope approval','small synthetic timeout-stream preservation validation, not rerunning longfixture','new candidate only; all original768/raw immutable','independent static inverse/pin review and new full aggregate'],'files':{p.name:h(p) for p in d.iterdir() if p.is_file()}};(d/'PLAN.json').write_text(json.dumps(x,indent=2)+'\n');print(h(d/'PLAN.json'))
