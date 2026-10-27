# v34 measured objective-label clarification

Original functional contract SHA256: `4d62ed5b5dc8f6e2f0827c4e5188929ce8b0125a322ed9e08046780e89e55c37` (unchanged).

The frozen contract says “existing mode/objective area”; the initial independent QA oracle interpreted that as the authored 42 px request rather than Godot’s computed minimum. The unchanged 16 px font has a 23 px line height; two lines with spacing have a 49 px minimum. AUTO retains the old 42 px request. Root approved the measured 49 px transparent two-line label on 2026-10-26 after viewing native capture 01 (SHA256 95a9b4e5b668fc89dbf9206a87dba0d971ad1bf4c474af1fe2f3ec4c44616b83). Original objective, HUD and boss bar remain unobstructed. No font shrinking or production edit was requested.

The rejected exact-42 assertion and full 342-check/12-failure run are retained. The amended independent check requires two lines and 49 px, and explicitly clicks an underlying actor within the bottom seven pixels using the actual rendered global transform across both modes, three sizes and two camera positions. Actual native checks additionally cover the scaled/letterboxed coordinate path. This addendum is a disclosed presentation clarification, not a silent rewrite of the frozen contract.

Native measurement correction: an initial Arena click at y=187 was outside the actual objective rectangle y=130..179 and correctly cleared focus. That was not a lower-edge exclusion test or a defect. The corrected y=176 checks are separately recorded for all six native mode/size cases.
