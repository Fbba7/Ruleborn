extends RefCounted
## The kit tests' checks of the third wave's polish (tests/ui_kit_tests.gd;
## S3-R32, S2-R35): a panel scrolled far above its list still draws its face,
## and the baked numbers are drawn from mipmapped pages. Board 5's kit
## features (S3-R9 to S3-R14): the segmented control's two forms, the ability
## card's and the compact fact's measures, kickers that lose their tracking
## when tight, the hexagon that grows with the text and the stage's foot in
## the menus' night. A helper, not a shot: each check is said through the kit
## tests' `check`.


static func run(tree: SceneTree, check: Callable) -> void:
	await _scrolled(tree, check)
	_mipmapped(check)
	await _segment_forms(tree, check)
	_ability_measures(check)
	await _compact_fact(tree, check)
	await _untracked(tree, check)
	_hex_grows(check)
	await _foot_night(tree, check)


## A parchment panel taller than its list, scrolled until its top is far
## above the list (S3-R32): its face from the atlas still draws, culled by
## the rect it drew, which covers the panel's part still in the list. Before,
## the renderer culled the face by a rect worked out from its scaled 9-slice,
## and a long panel scrolled to its end lost its whole face.
static func _scrolled(tree: SceneTree, check: Callable) -> void:
	var screen := Control.new()
	screen.size = Vector2(540, 600)
	tree.root.add_child(screen)
	var list := ScrollContainer.new()
	list.size = Vector2(540, 600)
	list.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	screen.add_child(list)
	var column := VBoxContainer.new()
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_child(column)
	var parchment := UI.panel("parchment")
	var tall := Control.new()
	tall.custom_minimum_size = Vector2(400, 1800)
	parchment.add_child(tall)
	column.add_child(parchment)
	await tree.process_frame
	await tree.process_frame
	list.scroll_vertical = 1500
	for i in 3:
		await tree.process_frame
	var box := RbBox.of(parchment)
	var said := "no box"
	var ok := false
	if box != null:
		var shown := parchment.get_global_rect().intersection(list.get_global_rect())
		var face := box._face
		var culled := Rect2()
		if face != null:
			culled = face.get_global_transform() * box._drawn
		var top := list.get_global_rect().position.y - parchment.get_global_rect().position.y
		var above := top > 0.5 * parchment.size.y
		ok = face != null and not box.piece().is_empty() and above and culled.encloses(shown)
		said = "face %s, piece %s, top above by half %s, culled by %s, shown %s" % [face != null,
			not box.piece().is_empty(), above, culled, shown]
	screen.queue_free()
	await tree.process_frame
	check.call("a panel scrolled more than half above its list still draws its face from the atlas: the face is "
			+ "culled by the rect it drew, which covers the part still in the list (S3-R32)", ok, said)


## Drawn a tenth of their baked height, the glyphs are averaged from their
## pages' mipmaps, so their stroke, drop and gradient survive (S2-R35): a row
## of numbers filters with mipmaps, and every page a glyph sits on, in both
## twins, is imported with them.
static func _mipmapped(check: Callable) -> void:
	var bad := []
	var shipped: Dictionary = (JSON.parse_string(FileAccess.get_file_as_string(KitSkin.MANIFEST)) as Dictionary)["pieces"]
	var pages := {}
	for finish: String in KitNumerals.FINISHES:
		for glyph: String in KitNumerals.GLYPHS.values():
			var key := "%s_%s" % [finish, glyph]
			if shipped.has(key):
				pages[int((shipped[key] as Dictionary).get("page", 1))] = true
	var row := KitNumerals.Row.new()
	if row.texture_filter != CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS:
		bad.append("a row of numbers filters with %d, not with mipmaps" % row.texture_filter)
	row.free()
	if pages.is_empty():
		bad.append("no numeral sits on a page of the atlas")
	for page: int in pages:
		for twin: String in ["", "_hc"]:
			var file := "%s/kit%s%s.webp.import" % [KitSkin.MANIFEST.get_base_dir(),
				"" if page == 1 else "_%d" % page, twin]
			if not "\nmipmaps/generate=true\n" in FileAccess.get_file_as_string(file):
				bad.append("%s, a page of the numerals, is imported without mipmaps" % file)
	check.call("the baked numbers are drawn with mipmaps from pages imported with them, so a number drawn small "
			+ "keeps its stroke and drop (S2-R35; kit-spec.md section 6.1)", bad.is_empty(), "; ".join(bad))


## `what` in a phone-wide screen in the tree, laid out over a few frames.
static func _laid_out(tree: SceneTree, what: Control, wide := 1080.0) -> Control:
	var screen := Control.new()
	screen.size = Vector2(wide, 2340)
	tree.root.add_child(screen)
	what.size = Vector2(wide, 0)
	screen.add_child(what)
	for i: int in 4:
		await tree.process_frame
	return screen


## The segmented control's [words, icon] forms (S3-R9; key frame 04): off,
## the icon over its words as before; at 100% each icon beside its words on
## one line, whole, the segment 56 points tall; at 200% all three on one
## line, the chosen in its words and the others as 32-point icons 48 wide,
## each named by its words, and a tap moves the words to the tapped one.
static func _segment_forms(tree: SceneTree, check: Callable) -> void:
	var bad := []
	var was := Settings.text_scale
	var options := [["Heist", "heistcontrols/ability"], ["Grow", "resources/essence"], ["Home", "hud/shield"]]
	var none := func(_i: int) -> void: pass
	Settings.text_scale = 100
	var before := KitNav.segmented(options, 0, none, true)
	for b: Node in before.find_children("*", "Button", true, false):
		if b.get_node_or_null("Form") != null or b.find_children("*", "VBoxContainer", true, false).is_empty():
			bad.append("off, a segment is not its icon over its words")
	before.free()
	for scale: int in [100, 200]:
		Settings.text_scale = scale
		var strip := KitNav.segmented(options, 1, none, true, true)
		var screen := await _laid_out(tree, strip)
		var row := strip.get_child(0)
		var buttons := strip.find_children("*", "Button", true, false)
		if scale == 200 and row is GridContainer and (row as GridContainer).columns != options.size():
			bad.append("200%: the segments take %d to a line" % (row as GridContainer).columns)
		var top := (buttons[0] as Control).get_global_rect().position.y
		for i: int in buttons.size():
			var b := buttons[i] as Button
			var form := b.get_node_or_null("Form") as HBoxContainer
			if form == null:
				bad.append("%d%%: segment %d has no form" % [scale, i])
				continue
			var icon := form.get_child(0) as Control
			var l := form.get_child(1) as Label
			var said := "%d%% %s" % [scale, l.text]
			if b.accessibility_name != l.text:
				bad.append("%s is named %s" % [said, b.accessibility_name])
			if absf(b.get_global_rect().position.y - top) > 0.5:
				bad.append("%s is not on the first segment's line" % said)
			if scale == 100:
				var beside := icon.get_global_rect().end.x <= l.get_global_rect().position.x + 0.5 \
					and absf(icon.get_global_rect().get_center().y - l.get_global_rect().get_center().y) < UI.px(2)
				if not (icon.visible and l.visible and beside):
					bad.append("%s: its icon is not beside its words" % said)
				if l.clip_text or l.text_overrun_behavior != TextServer.OVERRUN_NO_TRIMMING:
					bad.append("%s: its words may be trimmed" % said)
				if absf(b.size.y - UI.px(UI.CONTROL_POINTS)) > 0.5:
					bad.append("%s is %.0f tall, not %d points" % [said, b.size.y, UI.CONTROL_POINTS])
			elif i == 1 and (icon.visible or not l.visible):
				bad.append("%s, chosen, is not in its words alone" % said)
			elif i != 1 and (not icon.visible or l.visible or absf(icon.size.x - UI.px(32)) > 0.5
					or absf(b.custom_minimum_size.x - UI.px(UI.CONTROL_POINTS)) > 0.5):
				bad.append("%s is not a 32-point icon on a 48-point segment" % said)
		if scale == 200:
			(buttons[2] as Button).pressed.emit()
			var shown := []
			for b: Node in buttons:
				shown.append((b.get_node("Form").get_child(1) as Label).visible)
			if shown != [false, false, true]:
				bad.append("200%: a tap on Home shows the words of %s" % [shown])
		screen.queue_free()
		await tree.process_frame
	Settings.text_scale = was
	check.call("with forms, the segmented control's [words, icon] options take key frame 04's two forms: at 100% "
			+ "each icon beside its whole words on a 48-point line, at 200% all on one line, the chosen in words and "
			+ "the others as icons named by their words; off, each icon stands over its words (S3-R9)", bad.is_empty(),
			"; ".join(bad))


## The content margins of `box`'s panel, in pixels: [side, top].
static func _margins(box: PanelContainer) -> Array:
	var style := box.get_theme_stylebox("panel")
	return [style.content_margin_left, style.content_margin_top]


## `points`, a nest of arrays of points, in pixels: the margins as floats,
## the separations as whole pixels, as the theme gives them.
static func _in_px(points: Array) -> Array:
	return [[float(UI.px(points[0][0])), float(UI.px(points[0][1]))], [float(UI.px(points[1][0])),
		float(UI.px(points[1][1]))], UI.px(points[2]), UI.px(points[3])]


## The ability card at key frame 04's measures (S3-R10): off, as before
## (padding 10/8, the square's 10, 12 points between square and words, 6
## between kicker and tag); with `measures`, 8/8, 4, 8 and 4.
static func _ability_measures(check: Callable) -> void:
	var bad := []
	for measures: bool in [false, true]:
		var card := KitCards.ability("heistcontrols/ability", "motion", "Ability", "Once a heist", "Swift",
			"Runs.", measures)
		var row := card.get_child(0) as HBoxContainer
		var square := row.get_child(0) as PanelContainer
		var head := card.find_child("Flow", true, false) as HFlowContainer
		var got := [_margins(card), _margins(square), row.get_theme_constant("separation"),
			head.get_theme_constant("h_separation")]
		var want := [[8, 8], [4, 4], 8, 4] if measures else [[10, 8], [10, 10], 12, 6]
		if str(got) != str(_in_px(want)):
			bad.append("measures %s: padding, square, gap and tag gap are %s, not %s" % [measures, got, want])
		card.free()
	check.call("the ability card keeps its measures unless asked, and with measures takes key frame 04's: padding "
			+ "8/8, the icon's square 4, 8 points to the words and 4 to the tag (S3-R10)", bad.is_empty(),
			"; ".join(bad))


## The compact fact (S3-R13): off, the disc beside a column of kicker and
## words as before; compact, 6 points of padding, the disc beside the kicker
## and the words under both, across the tile at 13 points in the body face.
static func _compact_fact(tree: SceneTree, check: Callable) -> void:
	var bad := []
	var plain := KitCards.fact("hud/shield", "Resists", "Fire", "motion")
	if not plain.get_child(0) is HBoxContainer or _margins(plain) != [float(UI.px(10)), float(UI.px(8))]:
		bad.append("off, the fact is not its disc beside a column, padded 10/8")
	plain.free()
	var tile := KitCards.fact("hud/shield", "Resists", "Fire and frost", "motion", true)
	var screen := await _laid_out(tree, tile, UI.px(160))
	var stack := tile.get_child(0) as VBoxContainer
	if stack == null or stack.get_child_count() != 2:
		bad.append("compact, the tile is not a row over its words")
	else:
		var row := stack.get_child(0) as HBoxContainer
		var disc := row.get_child(0) as PanelContainer
		var kicker := (row.get_child(1) as Container).get_child(0) as Label
		var words := stack.get_child(1) as Label
		if _margins(tile) != [float(UI.px(6)), float(UI.px(6))] or _margins(disc) != [float(UI.px(1.5)),
				float(UI.px(1.5))]:
			bad.append("padding %s and the disc's %s, not 6 and 1.5 points" % [_margins(tile), _margins(disc)])
		if absf(disc.get_global_rect().get_center().y - kicker.get_global_rect().get_center().y) > UI.px(2):
			bad.append("the kicker is not beside the disc")
		if words.get_global_rect().position.y < disc.get_global_rect().end.y - 0.5:
			bad.append("the words are not under the disc")
		if absf(words.get_global_rect().position.x - disc.get_global_rect().position.x) > 0.5:
			bad.append("the words do not start under the disc")
		if words.get_theme_font_size("font_size") != UI.text_px(13) or words.theme_type_variation != "" \
				or float(words.get_meta("points")) != 13.0 or bool(words.get_meta("bold")):
			bad.append("the words are not 13 points in the body face")
	screen.queue_free()
	await tree.process_frame
	check.call("a compact fact is key frame 04's tile: padded 6 points, its disc beside the kicker and the words "
			+ "under both at 13 points in the body face; off, the fact is as before (S3-R13)", bad.is_empty(),
			"; ".join(bad))


## Card kickers untrack when tight (S3-R14): a compact fact's kicker whose
## longest word is wider than its room, and an ability's kicker that with its
## tag is wider than their line, are set untracked; with room, tracked.
static func _untracked(tree: SceneTree, check: Callable) -> void:
	var bad := []
	for wide: bool in [false, true]:
		var tile := KitCards.fact("hud/shield", "Eigenschaften", "Flink", "motion", true)
		var kicker := tile.find_children("*", "Label", true, false)[0] as Label
		var screen := await _laid_out(tree, tile)
		var need := KitCards.kicker_need(kicker)
		tile.size.x = need + UI.px(60 if wide else 20)
		for i: int in 3:
			await tree.process_frame
		if (kicker.theme_type_variation == "Kicker") != wide:
			bad.append("a fact's kicker %.0f wide in a tile %.0f wide is %s" % [need, tile.size.x,
				kicker.theme_type_variation])
		screen.queue_free()
		var card := KitCards.ability("heistcontrols/ability", "motion", "Habilidade", "Uma vez por golpe", "Ágil",
			"Corre.", true)
		var head := card.find_child("Flow", true, false) as HFlowContainer
		var k := head.get_child(0) as Label
		var held := await _laid_out(tree, card)
		var with_tag := KitCards.kicker_need(k, head.get_child(1) as Control, UI.px(4))
		card.size.x = card.size.x - head.size.x + with_tag + UI.px(40 if wide else -10)
		for i: int in 3:
			await tree.process_frame
		if (k.theme_type_variation == "Kicker") != wide:
			bad.append("an ability's kicker and tag %.0f wide on a line %.0f wide is %s" % [with_tag, head.size.x,
				k.theme_type_variation])
		held.queue_free()
		await tree.process_frame
	check.call("a compact fact's kicker and a measured ability's kicker drop their tracking once the longest word, "
			+ "or the kicker and its tag, is wider than their room, and keep it with room (S3-R14)", bad.is_empty(),
			"; ".join(bad))


## The hexagon grows with the text (S3-R12): at 100% the size asked; at
## 200% twice the 52 points its words are set for, once, even when the
## caller grows it itself; and LV, NV and ST over 20 lie inside it there,
## where the 52 points of 100% would cut them.
static func _hex_grows(check: Callable) -> void:
	var bad := []
	var was := Settings.text_scale
	Settings.text_scale = 100
	for points: float in [52.0, 40.0, 80.0]:
		var h := KitHex.make("LV", "5", points)
		if h.custom_minimum_size != Vector2(UI.px(points * 0.88), UI.px(points)):
			bad.append("100%%: a %.0f-point hexagon is %s" % [points, h.custom_minimum_size])
		h.free()
	Settings.text_scale = 200
	var grown := 52.0 * float(UI.text_px(22)) / UI.px(22)
	for points: float in [52.0, grown]:
		var h := KitHex.make("LV", "5", points)
		if absf(h.custom_minimum_size.y - UI.px(grown)) > 1.0:
			bad.append("200%%: asked %.0f points, the hexagon is %.0f pixels tall, not %d" % [points,
				h.custom_minimum_size.y, UI.px(grown)])
		h.free()
	for kicker: String in ["LV", "NV", "ST"]:
		var h := KitHex.make(kicker, "20")
		h.size = h.custom_minimum_size
		if not h.words_inside():
			bad.append("200%%: %s 20 spills out of the hexagon" % kicker)
		h.free()
		var fixed := KitHex.new()
		fixed.kicker = kicker
		fixed.number = "20"
		fixed.size = Vector2(UI.px(52 * 0.88), UI.px(52))
		if fixed.words_inside():
			bad.append("200%%: %s 20 lies inside even the 52-point hexagon, so the check measures nothing" % kicker)
		fixed.free()
	Settings.text_scale = was
	check.call("the level hexagon grows with the text, once: at 100% the size asked, at 200% twice its words' 52 "
			+ "points, so LV, NV and ST over 20 lie inside it (S3-R12)", bad.is_empty(), "; ".join(bad))


## The stage's foot (S3-R11): off, it fades into the night's foot; with
## `blend_foot`, into the menus' night where the stage ends down the window,
## and it follows the stage as the page moves.
static func _foot_night(tree: SceneTree, check: Callable) -> void:
	var bad := []
	var stage := StageHero.new()
	stage.moving = false
	stage.custom_minimum_size = Vector2(UI.px(300), UI.px(150))
	var screen := await _laid_out(tree, stage, UI.px(300))
	var tall := maxf(1.0, stage.get_viewport_rect().size.y)
	stage.blend()
	if stage.foot_night() != StageHeroBackdrop.NIGHT_FOOT or stage._foot_ramp.get_color(1) != StageHeroBackdrop.NIGHT_FOOT:
		bad.append("off, the foot fades into %s" % stage._foot_ramp.get_color(1).to_html())
	stage.blend_foot = true
	for y: float in [0.0, tall * 0.4]:
		stage.position.y = y
		for i: int in 2:
			await tree.process_frame
		var want := Tokens.gradient("night").sample(clampf(stage.get_global_rect().end.y / tall, 0.0, 1.0))
		var foot := stage._foot_ramp
		if not foot.get_color(1).is_equal_approx(want) or not foot.get_color(0).is_equal_approx(Color(want, 0.0)):
			bad.append("at %.0f the foot fades into %s, not the night's %s there" % [y,
				foot.get_color(1).to_html(), want.to_html()])
		if want.is_equal_approx(StageHeroBackdrop.NIGHT_FOOT):
			bad.append("at %.0f the night there is the night's foot, so the check measures nothing" % y)
	screen.queue_free()
	await tree.process_frame
	check.call("with blend_foot the stage's foot fades into the menus' night where the stage ends on the screen "
			+ "and follows it as the page moves; off, into the night's foot (S3-R11)", bad.is_empty(), "; ".join(bad))
