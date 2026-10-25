extends SceneTree
func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() != 1: quit(2); return
	var directory: String = args[0]
	var engine_license := FileAccess.open(directory.path_join("GODOT_ENGINE_LICENSE.txt"), FileAccess.WRITE)
	engine_license.store_string(Engine.get_license_text() + "\n"); engine_license.close()
	var notices := FileAccess.open(directory.path_join("GODOT_THIRD_PARTY_NOTICES.json"), FileAccess.WRITE)
	notices.store_string(JSON.stringify(Engine.get_copyright_info(), "  ") + "\n"); notices.close()
	var licenses: Dictionary = Engine.get_license_info()
	var names: Array = licenses.keys(); names.sort()
	var text: String = "Godot Engine " + str(Engine.get_version_info().string) + " — third-party license texts\n\n"
	for name in names: text += "===== " + str(name) + " =====\n" + str(licenses[name]) + "\n\n"
	var third_party := FileAccess.open(directory.path_join("GODOT_THIRD_PARTY_LICENSES.txt"), FileAccess.WRITE)
	third_party.store_string(text); third_party.close()
	print("PASS: engine license and third-party notices emitted")
	quit(0)
