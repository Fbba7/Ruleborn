class_name CreatureTests
extends RefCounted
## The characters (world/creature_model.gd, tools/art/export.mjs): every kind
## of §21.9's list is exported within §21.3's budget, at §21.6's height, with
## the design's clips; and CreatureModel makes, places, plays, faces, takes its
## forms and its guard form, and offers its sockets.

const RULEBORN := ["featherkin", "skyskipper", "rambler", "glassgolem", "quarryback", "prismmite", "tidewalker",
	"hourkeeper", "stillwatch", "emberling", "stormhound", "sparkwright", "mossbear", "bloomling", "rootrunner",
	"echoplate", "lanternwisp", "soulmender"]
const LAUNCH := ["archivist", "tinkerer", "gardener", "wanderer", "cartographer", "collector", "stray", "reverser",
	"twinned", "unmade"]
const SHARED_CLIPS := ["idle", "idle2", "walk", "run", "carry", "climb", "leap", "slide", "wade", "hit", "ko",
	"celebrate", "nap", "work", "ability"]
const STANDARD_SOCKETS := ["head_top", "hand_R", "hand_L", "feet"]

var tree: SceneTree
var check: Callable


func _init(t: SceneTree, c: Callable) -> void:
	tree = t
	check = c


func run() -> void:
	var m := CreatureModel.manifest()
	var missing: Array[String] = []
	for k: String in RULEBORN + LAUNCH:
		if not m.has(k):
			missing.append(k)
	check.call("characters: the 18 ruleborn, the 4 launch Sages, the 3 visitors and the 3 paradox-born are exported "
		+ "(21.9)", missing.is_empty(), "missing: %s" % [missing])
	var over: Array[String] = []
	for k: String in m:
		var tris := int((m[k] as Dictionary).get("triangles", 0))
		if tris <= 0 or tris > 6000:
			over.append("%s %d" % [k, tris])
	check.call("characters: every exported kind is within 6,000 triangles, the Character screen's model too (21.3)",
		over.is_empty() and m.size() >= 43, "%d kinds; over: %s" % [m.size(), over])
	var off: Array[String] = []
	for k: String in RULEBORN:
		var e: Dictionary = m.get(k, {})
		var h := float(e.get("body_height", 0.0))
		var want := float(e.get("design_height", 1.0))
		if absf(h - want) > want * 0.12:
			off.append("%s %.2f/%.2f" % [k, h, want])
	check.call("characters: each ruleborn stands at 21.6's height, within 12% (Prism Mite and Glass Golem scaled)",
		off.is_empty(), "off: %s" % [off])
	var no_clips: Array[String] = []
	for k: String in RULEBORN:
		var clips: Dictionary = (m.get(k, {}) as Dictionary).get("clips", {})
		for c: String in SHARED_CLIPS:
			if not clips.has(c):
				no_clips.append("%s.%s" % [k, c])
	check.call("characters: each ruleborn has the shared clips and its ability (21.6's animation set)",
		no_clips.is_empty(), "missing: %s" % [no_clips])
	var no_sockets: Array[String] = []
	for k: String in m:
		var names: Array[String] = []
		for s: Dictionary in (m[k] as Dictionary).get("sockets", []):
			names.append(str(s.get("name", "")))
		for s: String in STANDARD_SOCKETS:
			if not names.has(s):
				no_sockets.append("%s.%s" % [k, s])
	check.call("characters: every kind has the standard sockets (head, hands, feet), so a Stray's bundle or a guard's "
		+ "lantern fits any kind (21.6)", no_sockets.is_empty(), "missing: %s" % [no_sockets])
	await _model()


func _model() -> void:
	var host := Node3D.new()
	tree.root.add_child(host)
	var c := CreatureModel.make(&"featherkin")
	host.add_child(c)
	c.place(Vector3(2.5, 0, 4.5), Vector3.RIGHT)
	var facing := -c.transform.basis.z
	check.call("characters: CreatureModel is made, placed in metres and faces where it is told (front is -Z)",
		c.position.is_equal_approx(Vector3(2.5, 0, 4.5)) and facing.dot(Vector3.RIGHT) > 0.99,
		"facing %s" % facing)
	var mesh := c.skeleton().find_children("*", "MeshInstance3D", true, false)[0] as MeshInstance3D
	var tris := 0
	for i in mesh.mesh.get_surface_count():
		tris += (mesh.mesh.surface_get_arrays(i)[Mesh.ARRAY_INDEX] as PackedInt32Array).size() / 3
	check.call("characters: the imported model is the exported one, triangles and bones as the manifest says",
		tris == int(c.info["triangles"]) and c.skeleton().get_bone_count() == int(c.info["bones"]),
		"%d tris, %d bones" % [tris, c.skeleton().get_bone_count()])
	c.play(&"walk")
	var walking := c.player().current_animation == "walk"
	c.play(&"no_such_clip")
	check.call("characters: play takes the design's clip names and falls back to idle",
		walking and c.clip == &"idle" and c.player().get_animation(&"walk").loop_mode == Animation.LOOP_LINEAR
		and c.player().get_animation(&"ko").loop_mode == Animation.LOOP_NONE)
	c.set_expression(&"startled")
	check.call("characters: an expression is held over a breathing stand",
		c.player().current_animation == "expr_startled")
	c.set_expression(&"")
	c.set_form(&"hush")
	var hush := float(c.material().get_shader_parameter("hush")) == 1.0 and c.socket(&"head_top").get_child_count() > 0
	c.set_form(&"spark")
	var spark := float(c.material().get_shader_parameter("spark")) == 1.0 \
		and float(c.material().get_shader_parameter("hush")) == 0.0
	c.set_form(&"echo")
	var echo := c.get_node_or_null("echo") != null
	c.set_form(&"base")
	await tree.process_frame
	check.call("characters: the forms are Hush (midnight, with a charm), Spark (lit, embers) and Echo (a twin), and "
		+ "base clears them (21.6)", hush and spark and echo and c.get_node_or_null("echo") == null)
	c.set_guard(true)
	var hand := c.socket(&"hand_R")
	var lantern := hand != null and hand.get_node_or_null("lantern") != null
	c.set_guard(false)
	await tree.process_frame
	check.call("characters: as a guard a ruleborn wears a sash and carries a lantern on its own bones, and takes them "
		+ "off (21.6)", lantern and hand.get_node_or_null("lantern") == null)
	host.queue_free()
