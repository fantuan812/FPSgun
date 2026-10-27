# Independent v38 hand-case draft — not yet a frozen executable oracle

Written from C1 contract numbers before target implementation. Freeze only after pending schema/state clarification. No expectations derived from target execution.

Base source: uniqueID10, stitch_drone/support_repair, pos(0,0), hp=max_hp34, parent-1, radius150, channel1.2, cooldown5, retry1, heal10. Ordinary target fields include finitepos, nonboss, parent-1 and distinct positiveIDs.

## Target choice and exclusions
- ID2 HP5/10 at(60,0), ID3 HP10/20 at(40,0): equalratio.5, chooseID3 bydistance.
- SameHP ratios and positions(40,0) forID2/ID3: chooseID2, regardless array order.
- AddID4 HP5/20 at(149,0): ratio.25 wins despite longer distance.
- Exactly(150,0) eligible; (150.0001,0) outside. (90,120) exactly150 eligible; squared geometry, not Manhattan.
- FullHP, zeroHP, negativeHP, boss, parentedchild, sourceitself, another support source excluded; onlyexcluded => -1.
- Nonfinite/invalid numeric orposition, duplicate/nonpositive/nonintegeridentity set failsclosed without mutating originals.

## Repair and ordering
- Target17/20, successfulpulse =>20, amount3, no maxHP/status/attack/reward mutation. target.anim_hp=20 without actor animationreset.
- Source34snapshot34 remains =>eligible. Source33snapshot34 =>cancel, targetunchanged. A damagecommand resolvingzeroHPchange doesnotcancel.
- Targetnonlethaldamage17->12 while sourceunchanged =>stillrepairable, resulting20 amount8. Target0 atsettlementneverheals, even if dictionary remainsinarray.
- Two sourceIDs10/11 same target75/100: process10 then11 =>85 then95, amounts10/10. Target95/100 =>ID10heals5,ID11cancelnowfull. Reverseenemyarray/dueIDorder mustnotchange result.
- Pre-entry source damage34->33 followedbyacquisition snapshots33, notretroactivelycancelled. Post-entry33->32, including latephase same tick, cancels.
- Source/targetlethal latekillchain orpickup proc beatsrepair; source death no cancelburst. No second deathflush to fabricateimmediate reward.

## Discrete timers
- Initialcooldown.8; A(dt.8) acquires and leaves warning_left1.2; Bsame step noheal. Entrytickneveruses .8 asecondtime.
- Existingwarning_left1.2; A(dt1.2) due, Bvalidhealonce; setcooldown5/recover.7. Bcalledagain cannotheal.
- Existingwarning_left1.2; A(dt100) stillonecompletionmax, no newchannel/catchup; cooldownset5notminusovershoot.
- A cancellation resets5/.7 and cannotreacquireinA; B emitsonependingcancel then clearsit. Newchannel cannotreuse stale due intent.
- Noeligibleatacquisition =>retry1/move, no channel/pulse. Pause retainsstatewithnocalls; terminalcancel noheal/transient.
- Rangeexit detectedatA orB cancels; no continuouscrossingclaimbetweenphaseobservations. Latepush geometryatB notsilentlyclamped.

## Integration proof still required
Policy tables do not prove runtimephase placement, everyHP path, actualenemyspawns/Roomcompletion, nativeasset identity or eventprocessing. Bind those to the frozen contract and separately reviewed real-runtime scripts before implementation/run.
