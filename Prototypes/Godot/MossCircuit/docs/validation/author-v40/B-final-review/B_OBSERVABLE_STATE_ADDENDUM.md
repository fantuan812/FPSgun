# B observable state addendum — no gameplay change
2026-10-27 11:10 UTC. Existing three finalreviewfiles are unchanged. Canonical PRE admission rules override the residual Salvage phrase “nonfiniteeventpos failssemantic”: nonfinite dashorigin is PRE rejection, no sequence/charge consumption.

## Pure detached observation API
`debug_snapshot()->Dictionary` returns a deep-detached value copy of EVERY mutable B state listed below. No statewrite,clockread,RNG/worldaccess orlazy housekeeping. Mutating nested returned arrays/dictionaries cannot affectruntime. ReturnedVector2 values copied. No actor/pickup refs,Node/Resource/Callable values. The implementation maykeep equivalentprivatefields but snapshotkeynames/types/emptyrepresentations arefixed; do not deriveexpectedfrom targetoutput.
Exactlythese rootkeys, noothers:
```
configuration_open: bool
registry: Dictionary[String, {kind:String,max_stack:int}]
slot_caps: Dictionary                 # {} initially; configured {weapons:4,items:8}
definitions: Dictionary               # exactly3keys always, compact schemas below
owned_items: Dictionary[String,int]
weapon_counts: Dictionary[String,int]
equipped_types: Array[String]         # sortedascendingregisteredIDs, unique
mark: null | Dictionary
pin_ready_at: null | float
charges: int
fields: Array[Dictionary]
next_field_sequence: int
winch_count: int
pending: null | Dictionary
winch_requested_this_batch: bool
bound_epoch: int
last_sequence: int
last_now: float
last_step_serial: int
batch_serial: int
batch_time: float
batch_open: bool
```
Initialconstruction values: configuration_open=true,registry={},slot_caps={},definitions={crossfire_pin:{},salvage_capacitor:{},medic_winch:{}},owned_items={},weapon_counts={},equipped_types=[],mark=null,pin_ready_at=null,charges0,fields[],next_field_sequence0,winch_count0,pendingnull,winch_requested_this_batchfalse,bound_epoch-1,last_sequence0,last_now0.0,last_step_serial-1,batch_serial-1,batch_time0.0,batch_openfalse.

## Exact nested shapes
registry includesALL validold/new catalogIDs,onlykind andnormalizedintmax_stack perentry. No originalentryrefs.
definitions alwayskeys crossfire_pin,salvage_capacitor,medic_winch; absentcatalogrow=>{}. Enabledshape:
- crossfire_pin {mark_seconds:float,pull_distance:float,cooldown:float,requires_distinct_weapon_types:int}
- salvage_capacitor {charge_limit:int,field_limit:int,field_radius:float,field_seconds:float,field_speed_factor:float,pickup_sources:Array[String]}
- medic_winch {pickup_count:int,max_pulls_per_step:int,medical_range:float,pull_distance:float,pickup_sources:Array[String]}
Do notstoreprice/descriptions/UIassets inruntime definitions; catalog remainssole textauthority.
mark = {target_id:int,weapon:String,position:Vector2,expires:float}. Priorhandcase prosealiases target/pos mapto target_id/position; this schema isexact. null meansnone, not{}.
fields keptcreationorderascendingsequence,each {pos:Vector2,expires:float,sequence:int}. next_field_sequence starts0; firstSUCCESSFULcreation increments to1 andstores1. Failedcreation doesnotincrement/evict;expiry/sale/encounter keepscountermonotonicwithinrun; clear_run resets0.
pending = {origin:Vector2,serial:int,time:float},capturedplayerorigin+currentbatchserial/time. No index,orbID/ref,extraqueuedrequests. null meansnone.
pin_ready_at retainslastfiniteexisting value evenexpired/sold; thereisjustone boundedslot, not perenemyhistory. Onlyclear_run removesit. Normalencounter doesnot createoreraseCD.

## Boundary metadata exactness
- `clear_run(validactualepoch)` resets allinventory/physical/CD/guards and next_field_sequence toinitialvalues EXCEPT bound_epoch=input; retains prior registry,slot_caps,definitions atomically asconfigurationdata andsets configuration_open=true. NoBgameplay is admitted untilconfigure succeedsandcloseswindow; so failednewrunconfig cannot silently usepriorrunmechanics. Constructorfirstconfigure similarly required. This isconfigurefailurefailclosedclarification, not livecatalogmigration.
- configure successupdatesonlyregistry/slot_caps/definitions andconfiguration_open=false. Failurechangesnothing includingopenflag. Puredebugsnapshotworkswhileconfigurationopen.
- sync_build/begin_step/process requireconfiguration_open=false,otherwisefailwithoutwrites. bind_epoch/clear_run/cancel_pending/reset_encounter/debug remainallowed forinitialization/cleanup; movement_factor whileopen returns1,apply/flushnoaction.
- reset_encounter keepsregistry/config, next_field_sequence, pin_ready_at, bound_epoch,last_sequence,last_step_serial, batch_serial,batch_time; setslast_now=validatednow; clearsmark/charges/fields/count/pending/flagandsetsbatch_open=false. Existingcooldownnotrebased.
- cancel_pending setsbatch_open=false,pendingnull,winch_requested_this_batch=false only; keepsbatchserial/time andallclock/replay/inventory/CDfields.
- forwardbind_epoch invokescancel_pending thenupdatesbound_epoch/last_now; keepslast_sequence/last_step_serial; sameepochvalidcallonlyupdateslast_now,doesnotcancelbatch.
- successfulbegin_step updateslast_step_serial,batch_serial,time,last_now,opensbatch; pendingnull,flagfalse; housekeepingcanprunemark/fields undercontract. Duplicate/invalidbeginstep changesnothing.
- validflush closesbatch,pendingnull; keepsbatchserial/time andwinch_requested_this_batch atitsalreadyspentvalue. It doesnotconsumeeventsequence oradvanceclock. Wrongcontextflushchangesnothing. Nonplayingcorrectbatchflushdropspending/close, no otherinventoryrefund.
- Winchsale setswinch_count0,pendingnull; retainsopenbatchidentity andspentflag so samebatchrebuydoesnotrefillrequest. Nextbeginstep resetsflag. Ifnofirstthresholdoccurred, flagfalse staysfalse.
No mutable gameplaystate may be omittedfromdebugsnapshot; configurationerrors are returnednotstored. This supportswhole-snapshot equality for malformedadmission/config/sync/replay tests, anddeepdetachment tests without relyingon outputgeneratedexpected.
