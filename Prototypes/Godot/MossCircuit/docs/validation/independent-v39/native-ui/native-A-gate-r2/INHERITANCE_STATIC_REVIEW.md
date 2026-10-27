# Observer wrapper path review (static only)

Godot official4.6 source GDScriptAnalyzer::resolve_class_inheritance leaves an absolute extends_path unchanged and only joins relative paths to the current script's directory before requesting dependent parser:
https://raw.githubusercontent.com/godotengine/godot/4.6-stable/modules/gdscript/gdscript_analyzer.cpp (lines397–406).
Official GDScript reference documents path-based inheritance:
https://docs.godotengine.org/en/4.4/tutorials/scripting/gdscript/gdscript_basics.html

This supports the absolute-path wrapper choice but does NOT prove the current4.6.3 runtime/cache/environment will parse this exact external parent. Original fixture bytes remain pinned; parent already extends SceneTree, wrapper overrides only_initialize/screenshot to attach read-only dimensions observations then delegates super. No override of run, case assertions or input helpers. If actual first native load fails, preserve raw parse failure and stop; no unrecorded path retry or changing original cases.
