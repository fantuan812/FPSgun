extends SceneTree
var checks := 0
var failures: Array = []
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok: failures.append(label)
func _initialize() -> void:
	var presets := ConfigFile.new()
	check(presets.load("res://export_presets.cfg") == OK, "export presets parse")
	for i in range(2):
		var section := "preset.%d" % i
		var options := section + ".options"
		check(presets.get_value(section, "platform") == ("Linux" if i == 0 else "Windows Desktop"), "intended desktop platform")
		check(presets.get_value(section, "export_filter") == "all_resources", "all dynamic resources eligible")
		check("*.json" in presets.get_value(section, "include_filter"), "runtime non-resource JSON included")
		for excluded in ["docs/*", "tests/*", "tools/*", "ui/test_ui.gd", "art_source/provenance.json", "art_source/v9-room-candidates/*", "MANIFEST.json"]:
			check(excluded in presets.get_value(section, "exclude_filter"), "no QA/source-only payload " + excluded)
		check(not presets.get_value(section, "encrypt_pck") and not presets.get_value(section, "encrypt_directory"), "no keys or encryption")
		check(presets.get_value(section, "script_export_mode") == 0, "auditable text scripts")
		check(presets.get_value(options, "binary_format/architecture") == "x86_64", "explicit supported architecture")
		check(not presets.get_value(options, "binary_format/embed_pck"), "inspectable external pack")
		check(not presets.get_value(options, "ssh_remote_deploy/enabled"), "no remote host deployment")
		check(presets.get_value(options, "custom_template/release") == "", "no machine-specific template path")
	check(not presets.get_value("preset.1.options", "codesign/enable"), "unsigned Windows output, no certificate")
	check(not presets.get_value("preset.1.options", "application/modify_resources"), "verified template executable retained")
	var manifest: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://tools/godot_templates.json"))
	check(manifest.version == "4.6.3.stable", "editor/template version pinned")
	check(manifest.archive_sha256 == "3fbe2c0e2dec9d537ab9ec97bcf8da91dcf23357fc51f67092dd068d839290a8", "official archive digest pinned")
	check(manifest.files.size() == 7, "only required desktop templates and version marker")
	for item in manifest.files:
		check(str(item.name).get_file() == item.name and str(item.sha256).length() == 64, "safe pinned template entry")
	check(FileAccess.file_exists("res://art_source/alpha_bounds.json"), "legacy geometry dependency present")
	print(JSON.stringify({"export_contract_checks": checks, "failures": failures, "scope": "source export configuration only; actual archives, pack and native GUI validated separately"}))
	quit(0 if failures.is_empty() else 1)
