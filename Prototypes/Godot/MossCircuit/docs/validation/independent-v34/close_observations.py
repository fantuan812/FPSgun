#!/usr/bin/env python3
"""Close read-only hashes and recorded observations; does not drive the game."""
import argparse,hashlib,json
from pathlib import Path
from PIL import Image
p=argparse.ArgumentParser();p.add_argument('qa',type=Path);p.add_argument('pack',type=Path);a=p.parse_args();q=a.qa
H=lambda b:hashlib.sha256(b).hexdigest()
def write(p,x): p.write_text(json.dumps(x,indent=2,ensure_ascii=False)+'\n')
def index(folder,descriptions):
 rows=[]
 for f in sorted((folder/'captures').glob('*.jpg')):
  b=f.read_bytes();rows.append({'path':'captures/'+f.name,'bytes':len(b),'sha256':H(b),'dimensions':list(Image.open(f).size),'observation':descriptions.get(f.name,'See report; filename is not an outcome assertion.')})
 write(folder/'CAPTURE_INDEX.json',{'files':rows});return rows
ordinary_desc={
'01-title-seed.jpg':'Default Rivet selected, Arena seed433 entered using actual controls.',
'02-start.jpg':'Actual run initial35 scrap,100HP,Rivet,wave1.',
'03-live-before-pause.jpg':'Despite provisional filename, this is a natural queued upgrade page after wave1,122scrap; not a live/pause proof.',
'04-after-repair.jpg':'Next queued upgrade page after targeted Repair click; later120maxHP confirms a Repair effect, not an exhaustive click ledger.',
'05-after-magnet.jpg':'Next queued upgrade page after targeted Magnet click.',
'06-first-shop.jpg':'Despite provisional filename, this is another queued upgrade page,132scrap after a targeted salvage; NOT a shop.',
'07-after-light-feet.jpg':'Repair/LightFeet/Rapid page remained visible-looking after targeted action; no success inferred.',
'08-next-resolution.jpg':'Same-looking queued page with salvage highlighted. Intervening input timing is ambiguous.',
'09-resolution-settled.jpg':'Actual settled Purchased shop,100scrap,2 weapons. Unplanned real Bankshot purchase retained; no undo/reset or defect inferred.',
'10-wave2-before-pause.jpg':'Actual wave2,LV5,120maxHP,100scrap; Rivet and Bankshot retained.',
'11-first-mark-attempt.jpg':'First attempted target already absent; no ordinary mark established here.',
'12-reposition.jpg':'Actual movement/fire with Ram warning and Spitter; no forced combat state.',
'13-spitter-mark.jpg':'Attempt only: no priority text visible despite provisional filename.',
'14-priority-observed.jpg':'DIRECT ordinary priority proof: Violet Spitter,2/2 aimed weapons in range, pale brackets,37s,38kills.',
'15-build-inspection.jpg':'Actual inspected build contains STANDARD Rivet and Bankshot. Origin remains Rivet starter.',
'16-resumed-priority.jpg':'Despite provisional filename, priority is ALREADY ABSENT after resume;38s/40kills. No retention or removal cause asserted.',
'17-empty-auto.jpg':'No priority text after empty-ground input, but previous frame was already AUTO; not causal clear proof.',
'18-paused-final.jpg':'Fresh confirmed pause after final short mark/empty-input batch. That batch\'s two live captures were not preserved after capture-save argument-size error.',
'19-returned-title.jpg':'Actual visible RETURN TO TITLE outcome; no new run started.'}
rows=index(q/'ordinary',ordinary_desc)
write(q/'ordinary'/'REVIEW.json',{'scope':'One exact release-ELF ordinary Arena/Rivet seed433 attempt; automated CUA and tactical pauses, no state injection/reset/undo/retry. Finite early encounter, not full campaign.','pck_sha256':'250ea5966ff7ca35b42a13cd813ba5ff156288cfc97110a411dd73664ccbbe02','observed':['Actual initial35scrap/100HP/Rivet start.','Natural wave1 settlement and queued upgrades; later wave2 LV5,120maxHP,100scrap.','One real Spitter priority with2/2 in-range aimed weapons directly visible in capture14.','Actual pause/build inspection/back/resume and returned-title navigation.','Unplanned real Bankshot purchase kept alongside Rivet; not a Rivet-only encounter.'],'not_established':['Ordinary manual target-change attribution.','Ordinary causal empty-ground clear: next recorded frame was already AUTO.','Ordinary pause retention: marked target disappeared between observations while kills increased.','Exact intervening upgrade/purchase input chronology under ambiguous/stale-looking menu frames.','Successful final two live mark/clear observations: capture-save request exceeded argument-size limit after CUA actions; no outcome inferred.'],'closure':{'returned_to_title':True,'external_terminal_ctrl_c':True,'window_absence_confirmed':True,'exit_code':None,'exit_receipt_present':(q/'ordinary'/'runtime.exit').exists(),'graceful_or_exit_zero_claim':False},'diagnostics':['ALSA ERR_CANT_OPEN and dummy-driver fallback; unsupported VSync warning.','No GDScript runtime error observed.'],'capture_count':len(rows),'capture_index_sha256':H((q/'ordinary'/'CAPTURE_INDEX.json').read_bytes()),'limits':'No full campaign, victory, balance, Windows execution, audio output or physical-controller claim; stronger controlled action/transform proofs remain separately labeled.'})
pack_desc={'01-arena-clipped.jpg':'Actual CUA selects clipped on-screen Spitter in external exact-PCK controlled fixture.','02-arena-offscreen.jpg':'Fixture F8 relocates marked actor offscreen; priority persists2/3. This is injected fixture relocation, not ordinary movement.','03-rooms-clipped.jpg':'Actual CUA selects clipped actor in Rooms edge-camera letterbox fixture.','04-rooms-offscreen.jpg':'Fixture F8 relocates actor above viewport; priority persists0/3; letterbox/lower-objective clicks blocked.'}
pr=index(q/'pack-native',pack_desc)
write(q/'pack-native'/'REVIEW.json',{'scope':'Editor engine loads exact PCK via --main-pack from empty reader; external controlled script injects build/actors and disables normal process. NOT ordinary accepted-release-ELF gameplay.','pck_sha256':'250ea5966ff7ca35b42a13cd813ba5ff156288cfc97110a411dd73664ccbbe02','cases':['Arena960 clipped actor and offscreen relocation','Rooms1180x812 letterbox/edge camera clipped actor and offscreen relocation'],'observed':['Actual CUA clipped on-screen actor selection.','Externally relocated offscreen living marks persist; per-weapon eligibility2/3 then0/3.','Actual objective bottom7px and black letterbox reject click leakage.','Actual empty field clear in controlled fixture.'],'window_focus_loss':'Terminal-directed click did not establish actual WM focus loss; no native focus-loss claim. Direct notification/lifecycle tested headlessly.','closure':{'external_fixture_f9_quit':True,'exit_code':int((q/'pack-native'/'controlled.exit').read_text().strip()),'window_absence_confirmed':True,'shipped_quit_control':False},'capture_count':len(pr),'capture_index_sha256':H((q/'pack-native'/'CAPTURE_INDEX.json').read_bytes()),'diagnostics':['ALSA device unavailable/dummy fallback and VSync warning; no GDScript runtime error.']})
inputs=json.loads((q/'FINAL_INPUTS.json').read_text());changes=[]
for rel,h in inputs.items():
 if H((q/'project'/rel).read_bytes())!=h: changes.append(rel)
art={}
for name in ['MossCircuit.pck','MossCircuit.x86_64']:
 b=(a.pack/'linux'/name).read_bytes();art[name]={'bytes':len(b),'sha256':H(b)}
write(q/'POST_CLOSE.json',{'phase':'After controlled exact-pack fixture and single ordinary attempt both closed; no further game attempt','source_inputs':len(inputs),'input_changes':changes,'artifacts':art,'both_preset_packs_equal':H((a.pack/'windows'/'MossCircuit.pck').read_bytes())==art['MossCircuit.pck']['sha256'],'source_oracle_reference':'final-gate/SUMMARY.json','ordinary_exit_code':None,'ordinary_window_absent':True,'pack_fixture_exit_code':0})
assert not changes
assert art['MossCircuit.pck']['sha256']=='250ea5966ff7ca35b42a13cd813ba5ff156288cfc97110a411dd73664ccbbe02'
assert art['MossCircuit.x86_64']['sha256']=='2c78919325d7f29fa7607287c7c1eeac367ea4c94e7b8b6f5f4c6b20492f73d0'
print('CLOSED_SOURCE_664_AND_RUNTIME_EXACT')
