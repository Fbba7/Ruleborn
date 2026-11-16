extends RefCounted
## The kit tests' check of the buttons that grow to their words and of the
## reward under high contrast, run from tests/ui_kit_tests.gd (S1-R15,
## S1-R23, S3-R3, S1-R32): a helper, not a shot.


static func run(tree: SceneTree, check: Callable) -> void:
	var bad: Array = await words(tree)
	check.call("action2, big_action and upgrade grow to their words: at 200% text in Portuguese and English every "
			+ "word lies whole inside its button, action2's inside its padding, upgrade's left of its price (RAID "
			+ "AGAIN, ASSALTAR, 3 s, SUBIR DE NÍVEL); at 100% each keeps its size (S1-R15, S1-R23, S3-R3; §20.8)",
			bad.is_empty(), "; ".join(bad))
	var after: Array = await contrast(tree)
	check.call("under high contrast KitNav.reward and KitNav.celebrate leave the sky's dress unchanged, no rays "
			+ "behind the words (S1-R32; §20.8)", after == ["night", "night", "night"],
			"the sky's dress after reward, after celebrate, and its look: %s" % [after])


## Returns what is wrong, one line each: at 200% text in Portuguese and
## English every word of action2 (beside Home and alone), big_action and
## upgrade lies whole inside its button, action2's inside its 9-point
## padding, upgrade's left of its price; at 100% each keeps its size.
static func words(tree: SceneTree) -> Array:
	var bad := []
	var was := [Settings.text_scale, TranslationServer.get_locale()]
	var none := func() -> void: pass
	for case: Array in [[200, "pt_BR"], [200, "en"], [100, "pt_BR"], [100, "en"]]:
		Strings.set_locale(str(case[1]))
		Settings.text_scale = case[0]
		var screen := Control.new()
		tree.root.add_child(screen)
		var column := UI.frame(screen)
		screen.size = Vector2(1080, 2340)
		var row := HBoxContainer.new()
		row.add_child(UI.action(Strings.t("COMMON_HOME"), none, "ghost"))
		var again := KitControls.action2(Strings.t("RESULT_RAID_AGAIN"), Strings.t("RESULT_IDLE_CREW", 3), none)
		again.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(again)
		column.add_child(row)
		var up := KitControls.upgrade(Strings.t("CHARACTER_UPGRADE"), Strings.t("CHARACTER_UPGRADE_LINE", [1, 2]),
			"resources/essence", "1200", none, "gold")
		up.custom_minimum_size.x = UI.px(180)
		up.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var alone := KitControls.action2(Strings.t("RESULT_RAID_AGAIN"), "", none)
		alone.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var play := KitControls.big_action("hud/play", Strings.t("RESULT_THREE_SECONDS"), none, "gold")
		play.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		# Each button, laid out as the screens lay it out (the result's row
		# beside Home, the character's upgrade across the column): its size
		# at 100% text (x -1: any), the padding its words keep at either side.
		var kept := {
			again: [Vector2(-1, UI.px(56)), 9],
			alone: [Vector2(-1, UI.px(56)), 9],
			play: [Vector2(UI.px(76), UI.px(64)), 0],
			up: [Vector2(-1, UI.px(64)), 0],
		}
		for b: Button in [alone, play, up]:
			column.add_child(b)
		for i: int in 6:
			await tree.process_frame
		for b: Button in kept:
			_inside(b, "%d%% %s %s" % [case[0], case[1], b.name], UI.px(kept[b][1]), bad)
			var want: Vector2 = kept[b][0]
			if case[0] == 100 and ((want.x >= 0 and absf(b.size.x - want.x) > 0.5) or absf(b.size.y - want.y) > 0.5):
				bad.append("%d%% %s %s is %s, not its present %s" % [case[0], case[1], b.name, b.size, want])
		if column.size.x < UI.px(300):
			bad.append("%d%% %s: the column is %.0f wide, not the phone's" % [case[0], case[1], column.size.x])
		screen.queue_free()
		await tree.process_frame
	Settings.text_scale = was[0]
	Strings.set_locale(was[1])
	return bad


## Each visible word of button `b` whole on its line, each line not cut, and
## each label inside the button less `pad` at either side and left of its
## price, which lies inside the button.
static func _inside(b: Button, tag: String, pad: float, bad: Array) -> void:
	var r := b.get_global_rect()
	var room := r.grow_individual(-pad + 0.5, 0.5, -pad + 0.5, 0.5)
	var cost := b.get_node_or_null("Price") as Control
	if cost != null:
		room.end.x = minf(room.end.x, cost.get_global_rect().position.x + 0.5)
		if not r.grow(0.5).encloses(cost.get_global_rect()):
			bad.append("%s's price %s lies outside it %s" % [tag, cost.get_global_rect(), r])
	for l: Label in b.find_children("*", "Label", true, false):
		if not l.is_visible_in_tree() or (cost != null and cost.is_ancestor_of(l)):
			continue
		var font := l.get_theme_font("font")
		for w: String in (l.text.to_upper() if l.uppercase else l.text).split(" ", false):
			var wide := font.get_string_size(w, HORIZONTAL_ALIGNMENT_LEFT, -1, l.get_theme_font_size("font_size")).x
			if wide > l.size.x + 0.5:
				bad.append("%s's '%s' breaks (%.0f wide in %.0f)" % [tag, w, wide, l.size.x])
		if l.get_combined_minimum_size().y > l.size.y + 0.5:
			bad.append("%s's '%s' is cut (%.0f tall in %.0f)" % [tag, l.text, l.get_combined_minimum_size().y,
				l.size.y])
		if not room.encloses(l.get_global_rect()):
			bad.append("%s's '%s' %s lies outside %s" % [tag, l.text, l.get_global_rect(), room])


## Returns the sky's dress after KitNav.reward and after KitNav.celebrate
## under high contrast, and its look then: each "night" when the sky is
## left plain.
static func contrast(tree: SceneTree) -> Array:
	var was := [Settings.high_contrast, Tokens.high_contrast]
	Settings.high_contrast = true
	Tokens.high_contrast = true
	var screen := Control.new()
	var sky := Control.new()
	sky.name = "Sky"
	screen.add_child(sky)
	tree.root.add_child(screen)
	RbBox.dress(sky, "night", 0)
	KitNav.reward(screen)
	var after := [str(sky.get_meta("rb_material", ""))]
	KitNav.celebrate(screen)
	after.append_array([str(sky.get_meta("rb_material", "")), RbBox.of(sky).look])
	Settings.high_contrast = was[0]
	Tokens.high_contrast = was[1]
	screen.queue_free()
	await tree.process_frame
	return after
