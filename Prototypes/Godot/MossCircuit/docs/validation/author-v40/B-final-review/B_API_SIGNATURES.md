# Exact B API surface for final review
Status proposed, not implemented. Inputs deliberately Variant at validationboundary so wrongtype negativefixtures returnfailclosed ratherthan GDScript parametercoercion/errors. Internal normalizedfields typed. No API acceptsUI callbacks, RNG ordamageauthority.

`configure(catalog:Variant)->Dictionary`
Returns {ok:bool,errors:Array[String]}; only configuration_open trustedinitial/newrunwindow. Atomic registry/definitioncommit orunchangedfailure. Successcloseswindow. Must be calledbefore initialsync; legacycatalogwithoutBvalid. DuplicateB/anyIDs reject.

`clear_run(authoritative_epoch:Variant)->bool`
Trusted main newrun afteractualEffects.reset andcoherentlywith EffectRuntime.sequence=0. Requiresactualint>=0; invalidinput unchangedfalse. Clears allBphysical/inventory/CD/replay/time/batchstate, setsboundepoch,opensconfigurationwindow. Onlythis method resetslast_sequence0 andlaststep-1; epochcannotbe suppliedbyeventtoinvokeit.

`bind_epoch(authoritative_epoch:Variant,now:Variant)->bool`
Trusted adapter ACTUAL engine.epoch only. Epochactualint>=0,notrollback; nownumericfinite>=lastnow. Updatesboundepoch/time, forwardepochcancelspending/closesbatch but DOES NOT resetlast_sequence,laststep orinventory/CD. Sameepoch validreturns true. Invalidunchangedfalse.

`sync_build(items:Variant,weapons:Variant,now:Variant)->bool`
Whole registry/slot/count/timevalidation beforeanywrite. Copiesprimitiveownership/types. Sale/loss/origintyperemoval consumesmark andCD policy; Winchsaleclearscount+pending butdoesnotrefreshspentbatchflag; Salvagesaleclearscharge/fields. Retainedordinarysync preservesstocks. Failureunchangedfalse.

`begin_step(now:Variant,serial:Variant,enemies:Variant,area:Variant)->bool`
Trusted CombatRuntime afterworld.combat_tick_serial increment andbeforeoldweapons. Serialactualint>=0 strictlygreaterlaststep, nownumericfinite>=lastnow,enemiesArray,areaDictionary required (dimensioninvalid doesnotblock clock/batch; geometrylaterfailsclosed). Onceperstep opensbatch/clearsstaleWinchpending andperbatchflag,prunesexpiry/invalidmark. Doesnoterase prior-main-dashfieldexceptlegitimateexpiry. Invalidunchangedfalse.

`process(event:Variant,context:Variant)->Array`
Explicitadmissionthenconsumedsemantic order fromcontract; acceptedunknownsemanticspentseq. Returns atmostone Pin control orSalvage visualization record; Winchonlystoresonependingrequest. Canonicalcontext exactkeys:playing(bool true),time(finitenumber>=lastnow),effect_epoch(actualint>=0),step_serial(actualint>=0),player_pos(finiteVector2),dash_active(bool),enemies(Array),area(Dictionary). Required eventfields:kind/sourceString,depthactualint,epochactualint>=0,sequenceactualint>=1; hit additionallyweaponString,targetactualint;dash posfiniteVector2. Noenemycopies.
Pin command {kind:"pin_pull",target_id:int>=1,anchor:Vector2,distance:float,source_item:"crossfire_pin"}; valuesonly. CD/markalreadyconsumed; applylaterrechecksactualtarget.
Salvage visual record {kind:"salvage_field_created",sequence:int,pos:Vector2,radius:float,expires:float,source_item:"salvage_capacitor"}; emittedonlyaftervalidhelper-ownedfieldcreated. Adaptermustnot appenddamagehazard or newevent. Rendereruseshelperfields forpersistentboundaries,visualrecordnotauthority.
NoWinchcommand returnedperpickup,preventing earlycollectionloopmutation. Return[] onrejection,neverthrowforbadtype.

`movement_factor(enemy:Variant,now:Variant,area:Variant)->float`
Pure read,returns1.0 orvalidatedfieldfactor; invaliddata neutral1.0. No timeguardwrite/no consumedstatus. Callerusesmin(existingStatus.movement_factor(...),result) once beforeAI,restoresoriginalspeedafter. Charge_speed untouched.

`apply_control(command:Variant,enemies:Variant,area:Variant)->Dictionary`
Pin only, returns {moved:bool,target_id:int,from:Vector2,to:Vector2,reason:String}; onmalformedinput/failure usemovedfalse,target_id-1,zeroVector2from/to andfixedreason. Re-resolveuniquetarget, onlyposmutated; totaldistance/notfarther/zeroanchor/insetrulesexactcontract. No cooldownrefund/no event/no successVFXonfailure. Returnedfrom/to onlypresentationnotfutureauthority.

`flush_pickups(context:Variant,pickups:Variant)->Dictionary`
Returns {accepted:bool,moved_index:int,reason:String}. Contextsamekeys asprocess exceptplaying mayfalse toclose/discardcorrectbatch. ValidatepickupsArray beforeconsumption. Matchingserial/time/epoch/openbatch required; wrongcontext leavescurrentrequestunchanged. Validbatchcloses/consumesrequest thenarea/medicinechecks. moved_index actualcurrentindexonlyforimmediatepresentation,neverstored; -1meansnoactualchange. No pickupremove/heal/reward/event.

`cancel_pending()->void`
Closesbatch anddropsrequest/flag; keepscount/charge/fields/mark/CD/guards. Calledmain nonplayingtransitions plusruntimeobservednonplayingfallback; sale-specificsyncdropdoesnot resetspentbatchflag. Noengine/timecall.

`reset_encounter(now:Variant)->bool`
Validatedmonotonictime; clearallBinventory/physicalstates includingmark,charge,fields,count,pending,flags; preserveexistingPinCD (noCDmanufacturedfrommark),last_sequence,boundepoch,laststep. Calledafteractualsettlementcleanup; alsoterminal/titlephysicalcleanup. OldEffects.reset unchanged. Invalidunchangedfalse.

`distinct_weapon_types(weapons:Variant,registry:Dictionary)->Dictionary`
Pure sharedforecasthelper returns {valid:bool,ids:Array[String]} sortedstableIDs; validatesregisteredweaponIDs/counts/slots,notjustsetsize. Forecastmustusevalidateddetachedcatalogregistry,neverconfigurelivehelper. Doesnotmutateinput orruntime. Eligibilityids.size>=2; Pinmarkoriginpresence separatelychecked.

## Integration call order
Newrun oldEffects.reset/sequence0 -> B.clear_run(actualepoch) -> B.configure(actualcatalog) -> B.sync_build(actualbuild,elapsed0). Ordinary_recompute -> B.sync_build only (notclear); successfulsell/weaponchange usesactualnewbuild. Existingpause/upgrade/shop/settings/codex/inventory transitions -> B.cancel_pending alongsideexistinginvalidation; trustedepochbinding happenswhenactualengineepochchanges withoutsequence reset.
Main elapsedincrement thenCharacterMotor realdashcallback canprocessBdashbeforeCombatRuntime.begin_step. CombatRuntime beginonce afterserialincrement,thenold/newweapons andAI; damageold/A commands fullyapply beforeBcanonicalprocess; actualpickup loop processesnormalcounters,thenflushonce BEFOREsupportPhaseB. Settlement floorawards noBprocess; afterwardexplicitreset_encounter. Native/GUI/forecast never createsgameplayevents.
