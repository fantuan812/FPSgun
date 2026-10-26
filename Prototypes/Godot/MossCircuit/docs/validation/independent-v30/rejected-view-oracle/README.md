# Rejected UI oracle, no product change

Initial UI run returned 504/512 assertions. The eight failures were the first-purchase visibility assertion in full-loadout profiles. The harness concatenated every BUY button before every REPLACE button, so a later item offer was incorrectly called the first purchase when the actual first weapon offer correctly used REPLACE. The corrected oracle filters both labels in original UI tree order. All initial script/log/result bytes are retained here; candidate production is unchanged. A subsequent result is required before accepting the correction.
