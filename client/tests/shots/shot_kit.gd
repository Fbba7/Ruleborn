class_name ShotKit
extends RefCounted
## What every screen shot does once its screen is up: the sky's hour from
## HOUR, the words folded away with FOLD, a few frames for the world to
## settle, the frame saved to SHOT, and each world's triangles and draw
## calls printed, split by BudgetSplit (§21.3's budgets). `prepare` takes the text size from TEXT
## (in percent), high contrast from HC and the language from LANG_SHOT, before a
## screen is made; WIDE prints every control asking for more than the phone,
## and PARTS where each world's triangles go, largest first.


static func prepare() -> void:
	Settings.path = "user://settings-shot.cfg"
	Settings.change(func() -> void:
		if OS.get_environment("TEXT") != "":
			Settings.text_scale = int(OS.get_environment("TEXT"))
		Settings.high_contrast = OS.get_environment("HC") != ""
		if OS.get_environment("LANG_SHOT") != "":
			Settings.locale = OS.get_environment("LANG_SHOT"))


static func settle(tree: SceneTree, screen: Control) -> void:
	await tree.process_frame
	var hour := int(OS.get_environment("HOUR")) if OS.get_environment("HOUR") != "" else 12
	for v: Node in screen.find_children("*", "SubViewportContainer", true, false):
		if v.get_parent() is WorldView:
			(v.get_parent() as WorldView).set_sky_hour(hour)
	if OS.get_environment("FOLD") != "":
		for b: Node in screen.find_children("*", "Button", true, false):
			if b.has_meta("fold"):
				(b as Button).pressed.emit()
	for i in 6:
		await tree.process_frame
	await RenderingServer.frame_post_draw
	tree.root.get_texture().get_image().save_png(OS.get_environment("SHOT"))
	if OS.get_environment("WIDE") != "":
		var frame := screen.get_viewport_rect().size
		for c: Node in screen.find_children("*", "Control", true, false):
			var w := (c as Control).get_combined_minimum_size().x
			if w > frame.x - UI.px(32):
				print("wide %d %s %s" % [w, screen.get_path_to(c), str(c.get("text")).left(40)])
	var worlds := false
	for v: Node in screen.find_children("*", "SubViewportContainer", true, false):
		if v.get_parent() is WorldView:
			worlds = true
	if worlds:
		await BudgetSplit.line(tree, str(screen.name))
		if OS.get_environment("PARTS") != "":
			for v: Node in screen.find_children("*", "SubViewportContainer", true, false):
				if v.get_parent() is WorldView:
					await _parts(tree, v.get_parent() as WorldView)
	print("wrote")


## Each part of `view`'s world hidden in turn, and the triangles it took.
static func _parts(tree: SceneTree, view: WorldView) -> void:
	var rid := view.viewport.get_viewport_rid()
	var total := await _count(tree, rid)
	var rows: Array = []
	var parts: Array[Node3D] = []
	for c: Node in view.world.get_children():
		if c is Node3D:
			_open(c as Node3D, parts, 3)
	for part: Node3D in parts:
		var was := part.visible
		part.visible = false
		var without := await _count(tree, rid)
		part.visible = was
		rows.append([total - without, view.world.get_path_to(part)])
	rows.sort_custom(func(a: Array, b: Array) -> bool: return a[0] > b[0])
	for r: Array in rows.slice(0, 16):
		print("part %7d %s" % [r[0], r[1]])


## `node`'s parts down to `depth` holders deep: a holder of a few is opened,
## a mesh or a crowd is counted whole.
static func _open(node: Node3D, out: Array[Node3D], depth: int) -> void:
	var kids := node.get_children().filter(func(k: Node) -> bool: return k is Node3D)
	if kids.size() == 1 and depth > 0:
		_open(kids[0] as Node3D, out, depth)
		return
	if depth <= 0 or kids.size() < 2 or kids.size() >= 60:
		out.append(node)
		return
	for k: Node in kids:
		_open(k as Node3D, out, depth - 1)


static func _count(tree: SceneTree, rid: RID) -> int:
	for i in 3:
		await tree.process_frame
	await RenderingServer.frame_post_draw
	return RenderingServer.viewport_get_render_info(rid, RenderingServer.VIEWPORT_RENDER_INFO_TYPE_VISIBLE,
		RenderingServer.VIEWPORT_RENDER_INFO_PRIMITIVES_IN_FRAME)
