from pathlib import Path
import json,hashlib,datetime
p=Path(__file__).parent;r=Path('<WORKSPACE_ROOT>/shared');h=lambda f:hashlib.sha256(f.read_bytes()).hexdigest();c=r/'moss-build-expansion-design-20261027/A_C2_REVIEW_CONTRACT.md'
assert h(c)=='e4c4563933ef077cdad36c2b0e156944738e5ca6b70fe46d0b4e486a2c16aafe'
T=[
 dict(name='launch_is_endpoint',clock=-2,dt=4,expected_launches=1,expected_age=0,expected_hits=0,expected_clock=1.2),
 dict(name='first_quarter',interval=1.2,active_before=0,dt=.3,expected_pulses=[1],expected_active=.3),
 dict(name='just_before_quarter',interval=1.2,active_before=0,dt=.299,expected_pulses=[]),
 dict(name='haste_half_interval',interval=.6,active_before=0,dt=.3,expected_pulses=[1,2]),
 dict(name='slow_double_interval',interval=2.4,active_before=0,dt=.6,expected_pulses=[1]),
 dict(name='overdue_four_once',interval=1.2,active_before=0,dt=10,expected_pulses=[1,2,3,4],removed=True,proc_time='same actual session.elapsed for allcontacts'),
 dict(name='hp25_stops_after3',hp=25,damage=10,active_before=0,dt=1.2,expected_pulses=[1,2,3],expected_hp=-5,removed=True),
 dict(name='last_pulse_before_new_launch',active_before=.9,wall_before=.9,clock=.3,dt=.3,expected_order=['oldpulse4','oldremove','newlaunch'],new_age=0),
 dict(name='memory_firstinvalid_large',grace=.2,dt=.3,valid=False,expected_hits=0,removed=True),
 dict(name='memory_exact_invalid',grace=.2,dt=.2,valid=False,expected_grace_left=0,expected_active_delta=0,removed=False),
 dict(name='memory_recover_zero',grace_left=0,spent=True,was_outside=True,dt=.1,valid=True,expected_active_delta=.1,removed=False),
 dict(name='memory_no_recover_negative',grace_left=-.001,spent=True,was_outside=True,dt=.1,valid=True,removed=True),
 dict(name='memory_second_separation',spent=True,was_outside=False,valid=False,dt=.01,removed=True),
 dict(name='memory_hardclip_fourth',interval=1.2,wall=1.1,active=.9,dt=.4,valid=True,expected_wall=1.4,expected_active=1.2,expected_pulses=[4],removed=True),
 dict(name='memory_hardclip_no_fourth',interval=1.2,wall=1.1,active=.89,dt=.4,valid=True,expected_wall=1.4,expected_active=1.19,expected_pulses=[],removed=True),
 dict(name='invalid_target_no_grace',target_status=['dead','missing','invalid_id'],memory=True,removed=True),
 dict(name='range_closed_live_player',range=280,player=[20,20],target=[300,20],expected_valid=True),
 dict(name='range_outside_live_player',range=280,player=[20,20],target=[301,20],expected_valid=False),
 dict(name='focus_acquisition_priority',candidates=[{'id':8,'distance':100,'focus':False},{'id':9,'distance':200,'focus':True}],expected_target=9),
 dict(name='nearest_id_tie',candidates=[{'id':8,'distance':100},{'id':3,'distance':100}],expected_target=3),
 dict(name='no_midbeam_retarget',target_id=9,new_focus=3,expected_target_id=9),
 dict(name='arc_overdue_clock',due_contacts=4,actual_elapsed=10,expected_arc_max=1,no_synthetic_backdating=True),
 dict(name='echo_contact_count',prior_primary_hits=4,beam_contacts=1,expected_echo_due=True),
 dict(name='drum_tempered_inward_once',base=22,tier_factor=1.6,other_damage_multiplier=1,expected_outward=35.2,expected_inward=17.6),
 dict(name='drum_cap_per_slot',existing=3,clock=0,dt=.01,expected_new=0,expected_clock=1.4),
 dict(name='drum_expiry_frees_cap_before_attempt',existing=3,one_expires=True,clock=0,expected_new=1,expected_live=3),
 dict(name='turning_same_id_twolegs',hp=100,expected_outward_hits=1,expected_inward_hits=1,expected_hp=67,no_rehit_nextstep=True),
 dict(name='same_tick_duplicate',tick=7,calls=2,expected_advance_calls=1),
 dict(name='next_fullstep_same_dt',ticks=[7,8],dt=.1,expected_advance_calls=2),
 dict(name='clear_then_same_tick',tick=7,clear_between_calls=True,expected_advance_calls=1),
]
L=[]
for event in ['item_buy','item_sell','upgrade','boss_stat_award','recompute_same_arrays','same_id_replace','successful_empty_move','successful_empty_temper','title','retry','new_run','finish','settle','room_boundary']:
 L.append(dict(event=event,expected_new_entities=0,epoch_must_advance=True,no_new_shot=True,no_old_clock_change_beyond_existing_semantics=True))
for event in ['rejected_transaction','rejected_inflight_move','rejected_inflight_temper','pause','build_overlay']:
 L.append(dict(event=event,expected_epoch_change=0,expected_entity_mutation=False,expected_time_advance=0))
R=[dict(name='closed_radius',player=[100,100],enemy=[200,100],expected=[255,100],hp_unchanged=True),dict(name='outside_radius',player=[100,100],enemy=[201,100],expected=[201,100]),dict(name='same_position_right',player=[100,100],enemy=[100,100],expected=[155,100]),dict(name='boundary_clamp',player=[900,100],enemy=[960,100],area=[980,600],expected=[960,100]),dict(name='boss_excluded',boss=True,expected_push=False),dict(name='dead_excluded',hp=0,expected_push=False),dict(name='summon_support_allowed',kinds=['summoned_crawler','stitch_drone'],expected_push=True,damage=0),dict(name='lethal_player_no_trigger',player_hp=0,amount=10,expected_command=0),dict(name='block_zero_no_trigger',amount=0,expected_command=0),dict(name='nested_no_trigger',depth=1,amount=10,expected_command=0),dict(name='wrong_source_no_trigger',source='secondary',expected_command=0),dict(name='bool_nan_inf_reject',values=['bool_true','nan','inf','string'],expected_command=0),dict(name='tombstone_sell_rebuy',elapsed=[10,11,12],events=['trigger','sell_rebuy_hurt','hurt'],expected_commands=[1,0,1]),dict(name='tombstone_room_reset',elapsed=[10,11],events=['trigger','encounter_reset_then_hurt'],expected_commands=[1,0]),dict(name='newrun_clears_tombstone',events=['trigger_at10','newrun','hurt_at0'],expected_commands=[1,1]),dict(name='ordinary_neverowns_empty',expected_recoil_dict={}),dict(name='invalid_area_consumes',area={},elapsed=[10,10.1],expected_movement=0,expected_ready_at=12),dict(name='push_only_support_inrange',expected_hp_loss=0,expected_repair_cancel=False),dict(name='push_support_outofrange',expected_hp_loss=0,expected_repair_cancel=True),dict(name='committed_charge_preserved',fields_unchanged=['ai_state','velocity','warning_left','attack_left','recover_left'])]
G=json.load(open(p/'GEOMETRY_CASES.json'))
# Transform independent full-frame radius model to exact proposed geometry API.
for row in G['cases']:
 x=row['input'];dt=x['dt'];lo=x.get('lo',0);hi=x.get('hi',dt);rv=(x['r1']-x['r0'])/dt if dt else 0
 row['api_args']={'center':x.get('center',[0,0]),'p0':x['p0'],'p1':x['p1'],'frame_dt':dt,'t_start':lo,'t_end':hi,'r_start':x['r0']+rv*lo,'r_end':x['r0']+rv*hi,'half_width':12,'enemy_radius':16*x.get('scale',1)}
(p/'GEOMETRY_API_CASES.json').write_text(json.dumps(G,indent=2)+'\n')
(p/'POLICY_HAND_CASES.json').write_text(json.dumps({'tether_wave':T,'lifecycle':L,'recoil':R,'negative_geometry':['nonfinitecenter','nonfinitep0','nonfinitep1','negative_dt','negative_start','end_after_dt','reversed_interval','negative_radius','negative_width','negative_enemy_radius','zero_interval_unequal_radius','overflow_intermediate'],'numeric_policy':'Accept C2 stated tolerances as bounded comparisonpolicy, not physicalCCD guarantee. Highprecision core cases avoid policy boundary ambiguity; separate tangent/degenerate/near-end controls must assert policy explicitly.'},indent=2)+'\n')
assert not (r/'moss-v39-work').exists()
files=[f for f in p.iterdir() if f.is_file() and f.name!='FREEZE.json'];freeze={'status':'INDEPENDENT_PRETARGET_CORE_FROZEN','utc':datetime.datetime.now(datetime.timezone.utc).isoformat(),'contract_sha256':h(c),'baseline_map_sha256':h(r/'moss-v38-svg-candidate-prep/FINAL_INPUTS.json'),'geometry_cases':len(G['cases']),'geometry_hand_cases':16,'discontinuity_cases':5,'tether_wave_hand_cases':len(T),'lifecycle_hand_cases':len(L),'recoil_hand_cases':len(R),'target_imports':0,'target_work_absent':True,'files':{f.name:h(f) for f in files},'scope':'Core independent expected inputs/outputs frozen before production. Portable actualtarget fixtures will use this oracle without derivingexpected from target. UI/B not a blocker for A; no full runtime/native pass claimed.'};(p/'FREEZE.json').write_text(json.dumps(freeze,indent=2)+'\n');print(json.dumps({k:v for k,v in freeze.items() if k!='files'}))
