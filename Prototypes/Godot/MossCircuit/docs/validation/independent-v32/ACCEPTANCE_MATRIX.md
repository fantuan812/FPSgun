# Independent v32 acceptance matrix — frozen expected semantics

Contract SHA256 `4c6431f920a43df60bb2e40e273db206908d17a1dcc2e231740c97fa67eab18c`. Root implementation go-ahead followed exact QA acceptance. This file defines expectations before candidate code/testing; it is not a pass report.

## Exact numerical oracle
Living nonboss charger only, behaviorcharge, paired valid120degree/.5 data, actual statewarning/attackcharge, finite valid lockedaim. Collision/eligibility unchanged. Strict interior source distance <16×scale−0.0001 bypasses; equality/tolerance strip stays directional. Direction length must be >0.000001, finite; otherwise full. Normalize aim and direction toward source; front if dot>=cos60°−0.000001. All other states/nonhosts/invalid runtime defense full. No target/shot/global-state mutation by pure calculation.

| Weapon | Existing base primary | Front-braced nominal | Full nominal | Source / approach |
|---|---:|---:|---:|---|
| Rivet |15|7.5|15|Actual segment start / negative travel|
| Shotgun |9 per pellet|4.5 per pellet|9 per pellet|Each pellet actual segment|
| Rail |30|15|30|Actual segment; each pierced target independent|
| Orbit Saw |20|10|20|Current player center toward target|
| Return Disc |18|9|18|Current outbound/return segment, not launch aim|
| Shock Mortar |36|18|36|Fixed blast center; direct-center target exempt|
| Cryo |9|4.5|9|Current player center; surviving chill before old hit event|
| Bankshot |18|9|18|Current leg start/negative currentdx,dy; reflected/guided legs|

These are zero-bonus base examples, not total volley/DPS or HP-clamped values. Existing additive global then electric/melee multipliers apply first; brace multiplies once. Stored shot/blast damage stays original. Overkill eventdamage remains nominal resolved amount. Zero ordinary travel vector full; nonzero dt0 launch bridge still runs by old behavior; Bankshotdt<=0 remains inert.

## Bounded gates
1. **Pure geometry/data:**8rotations at both field centers, exact±60edges,0.01°outside, front/rear/sides, strict-interior threshold equality/±0.001, exact radius, direction length threshold, NaN/INF/zero, malformedpairedfields. Current authored120/.5 exact. Old roster values/order/waves and all catalog/balance/Rooms/kits/art unchanged except exactly2newchargerfields+3copystrings.
2. **All8 real paths:** actual fire/advance/due blast, both modes; front/rear reduced/full, fractions, lethals/overkill, eventcount/order/nominaldamage; Rail guarded→unguarded retains originalstored30, distinctpellets; launchbridge anddt0; Return reversal; Bankshotreflection/Guide. Existing hitsets, quotas, pierce/lifetime, target order and travel exact.
3. **Entry partition:** unsplit versus exact entry-circle split ordinary contacts across8rotations, source boundary directional. Preserve ordinary strict collision and Bankshot distinct tolerance; no blanket moving-world dt-equivalence claim.
4. **State/lifecycle:** warning locks2Daim once; movementpush/hurt/pause no retarget/restart; brace opens at actual charging/recover; no guard Warden/Core/otherkind/dead. Initialfire andmortars preAI, bulletcontacts postAI; dtcrossing test explicitly demonstrates earlyinstant reduced/laterprojectile full. Title/dead/won/removal/newstage reset removesnewcue; menus freezevisible.
5. **Build/procs:** Cryosurvivalmark/expiry, differentweaponFracturefixed16, Echofixed12, Feedbackfixed24/otherfixedsecondary bypass, Arc40% of resolvedoriginatinghit but no secondtargetbrace; Phase and returnheal continueoldconditions. No recursiveextraevent, no newRNG/currency/reward. Primary vs secondarydeath/drop attribution preserved subjecttointendedsurvivalchange.
6. **No-brace parity:** exact immutable v31 script+24case output proof reused (crawler/spitter,all8weapons), actualcandidate replay required. No baselineengineexecutionclaim. New inactivecharger/control paths independently prove olddamage andevent behavior; intentional guardedfightoutcomes are not expected equal.
7. **Native controlled:** both modes960x540/1280x720, exactactualscale, left/right/nearvertical/up/down/diagonal, independent2Darc vs horizontallymirroredhorn, hurt→currentwarning, orange lane/otherwarnings overlap, reducedflashmode. Arc radius32×scale is indicator only, not extra collider. Guide wording/readability. No new raster or animationclaim.
8. **Exact export:** finalsourcefullsuite/ownimportedoracle/bothpresetPCK/packedmechanics, one ordinarydefaultRivet Rooms128 route towardRoom2charger. No injectedspawn/gear/outcome, no repeatedcampaign. Exactdamage comesfromcontrolledtests, notstills; ordinarycue visibilitymayremainlimited iftargetdiesfirst.
9. **Delivery:** exactunchangedELF +newfullPCK, unchangedhelperrestore/nooverwrite/negativehash/path/manualbackuprollback; GitHubonly expectedhead/nonforcepublication andfreshreachablebytes, prioroutside/sourcehistorypreserved.

## Rejected design assumptions retained before implementation
- QA initially generalized all primary damage as preAI; corrected to actual instant/mortar preAI andprojectiles postAI. Originalnote retained privately, no test/source outcome implied.
- Proposed inside/onradius+EPS exemption rejected because it can introduce static split-entrydamage differences. Finalstrictinterior policy above adopted.
- Draft point-attack 'at/inside body' wording contradicted exactboundary policy; finalcontract explicitlyusesstrictinterior.

No Windows/audio/controllerhardware/fullcampaign/all-seed/balance/fun certification. No new networking/save/unlock/dungeon or broad physics framework.
