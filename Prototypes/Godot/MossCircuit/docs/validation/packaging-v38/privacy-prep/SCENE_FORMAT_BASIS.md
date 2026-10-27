# Exact Godot 4.6.3 source basis

Official sources inspected 2026-10-27.

- [PackedScene implementation](https://raw.githubusercontent.com/godotengine/godot/4.6.3-stable/scene/resources/packed_scene.cpp): lines 1016–1039 assign a positive generated ResourceUID-derived scene-local ID when an ID is unassigned or collides, then append it to `ids`. Lines 1626–1628 read the bundled node IDs; line 1705 serializes `ids` as `node_ids`. Instantiation lines 332–335 apply each stored ID to its node. This field is real identity metadata, not globally ignorable padding.
- [Binary resource implementation](https://raw.githubusercontent.com/godotengine/godot/4.6.3-stable/core/io/resource_format_binary.cpp): enum line 65 identifies binary type 32 as PackedInt32Array; lines 498–514 read its element count and signed 32-bit elements.

The retained main.tscn has one Node2D with a script reference and no explicit node ID. SCENE_SOURCE_IDENTITY.json binds the unchanged source, main script UID, project and export configuration. The generated-ID code explains a plausible origin for this exact field change, but this is not a measured trace of the prior export's random generator. Only the proposed single record/single element exception is under review; no permission to ignore future scene IDs is implied.

The original only-metadata-payload gate remains FAIL. Exact old/new scene hashes, four differing offsets, and decoded bundled-field comparison are separately retained.
