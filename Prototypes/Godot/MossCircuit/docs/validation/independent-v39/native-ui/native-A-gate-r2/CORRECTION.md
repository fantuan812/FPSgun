# One-line fixture coordinate correction; original failure retained

Original native-A-gate actual_ui:150checks/6FAIL, realexit1/24.42156s, stricthelper true,853double source andallpins unchanged. HUD140 never ran due firstfailure stop.960window cases complete;1280window case dispatch selected wrong/default choice and cascaded missingSTART/next selected choice. Dimensions observer proved viewport960x540 while OSwindow1280x720. No production failure asserted from this.

Author and QA independently checked official Godot4.6 Viewport.push_input documentation:
https://docs.godotengine.org/en/4.6/classes/class_viewport.html#class-viewport-method-push-input
false(default) converts embedder event positions into viewport coordinates;true accepts viewport coordinates. The fixture feeds Control.get_global_rect centers in logicalviewport coordinates. The corrected one-line dispatch `root.push_input(e,true)` avoids applying stretch twice. Samewheel/click/wholecard/178assertions; no production/source853 change. Originalfe132fixture/oldwrapper/oldgate unchanged; r2uses newfilename/newgate/newwrapper parentbinding. HUD140 raw76e46cb0 unchanged. This is a fixture-only correction, not retrying unchanged conditions or relaxing assertions.
