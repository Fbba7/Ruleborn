extends RefCounted
## The kit tests' check of the parts switched on last (tests/ui_kit_tests.gd,
## kit-spec.md sections 5, 6.7 and 8.2; AIA-R16, AIA-R18, K1-R14): a helper,
## not a shot.


## Returns what is wrong, one line each: the popup's box and its margin, a
## rank's ring, the theme's cuts, the sheet's handles, the toggle's track, a
## bar's alarm fill and tick and the attention dot, each from the atlas while
## its skin is on and drawn in code while it is off.
static func run(tree: SceneTree) -> Array:
	var bad := []
	KitSkin.reset()
	var pieces: Dictionary = (JSON.parse_string(FileAccess.get_file_as_string(KitSkin.MANIFEST)) as Dictionary)[
		"pieces"]
	var px := float((JSON.parse_string(FileAccess.get_file_as_string(KitSkin.MANIFEST)) as Dictionary)[
		"px_per_point"])
	# Another skin's shape by name, and nothing for a skin switched off or a
	# shape the atlas lacks (logged once).
	for pair: Array in [["popup", "box"], ["toggle", "track_on"], ["toggle", "track_off"], ["toggle", "knob"],
			["slider", "track"], ["slider", "fill"], ["slider", "knob"], ["sheet", "handle"],
			["sheet", "handle_parchment"], ["header", "name_plate"], ["ribbon", "chapter"]]:
		var key := "%s__%s__normal" % pair
		if KitSkin.face(pair[0], pair[1]) != pieces.get(key, {"lost": key}):
			bad.append("KitSkin.face does not give %s" % key)
	if KitSkin.piece("card", "normal", "", "popup/box") != pieces.get("popup__box__normal", {"lost": true}):
		bad.append("a card that names popup/box does not draw the popup's box")
	if not KitSkin.missing.is_empty():
		bad.append("a baked shape is logged missing: %s" % ", ".join(KitSkin.missing))
	if not KitSkin.face("toggle", "no_such_shape").is_empty() or KitSkin.missing != ["toggle__no_such_shape__normal"]:
		bad.append("a shape the atlas lacks is not empty and logged once")
	KitSkin.missing.clear()
	# A piece's reach outside its host: 1 point and the lip by default, the
	# popup's own margin (8, 4, 8 and 12 points plus its 5-point lip), a
	# rank's ring 4 points each side.
	var popup: Dictionary = pieces["popup__box__normal"]
	if KitSkin.margins(popup) != [8.0 * px, 4.0 * px, 8.0 * px, 17.0 * px]:
		bad.append("the popup's margins are %s" % [KitSkin.margins(popup)])
	var card: Dictionary = pieces["panel_dark__box__normal"]
	var lip := float(card["slice"]["b"]) - float(card["slice"]["t"])
	if KitSkin.margins(card) != [px, px, px, px + lip]:
		bad.append("a box's margins are not 1 point and its lip: %s" % [KitSkin.margins(card)])
	# A rank's frame: a hollow ring (its middle clear) drawn over the
	# code-drawn box, 4 points past the portrait each side.
	for k: String in KitSkin.RINGS:
		var ring_piece: Dictionary = pieces.get("%s__box__normal" % k, {})
		if ring_piece.is_empty() or middle(ring_piece).a > 0.05:
			bad.append("%s's box is not a hollow ring" % k)
			continue
		if not KitSkin.piece(k).is_empty() or KitSkin.frame_ring(k) != ring_piece:
			bad.append("%s is not its ring over its code-drawn box" % k)
		if KitSkin.margins(ring_piece) != [4.0 * px, 4.0 * px, 4.0 * px, 4.0 * px]:
			bad.append("%s's ring does not reach 4 points past the portrait" % k)
	if not KitSkin.frame_ring("card").is_empty():
		bad.append("a card has a ring")
	# The theme's cuts: a piece as a texture of its own at the screen's
	# scale, a 9-slice as a style box; nothing for no piece.
	var knob: Dictionary = pieces["slider__knob__normal"]
	var cut := KitSkin.cut(knob)
	if cut == null or Vector2(cut.get_size()) != (KitSkin.region(knob).size * KitSkin.scale()).round():
		bad.append("a cut piece is not its size at the screen's scale")
	if KitSkin.cut(knob) != cut:
		bad.append("a piece is cut twice")
	var track := KitSkin.stylebox(pieces["slider__track__normal"])
	if track == null or track.texture == null:
		bad.append("the slider's track is not a style box")
	if KitSkin.cut({}) != null or KitSkin.stylebox({}) != null or KitSkin.stylebox(knob) != null:
		bad.append("no piece, or a sprite, makes a style box")
	var screen := Control.new()
	screen.size = Vector2(1080, 2340)
	tree.root.add_child(screen)
	# The sheet's grab handle, on its dark and its parchment face.
	for pair: Array in [["sheet", "handle"], ["sheet_parchment", "handle_parchment"]]:
		var sheet := KitPanels.sheet("Sheet", pair[0])
		screen.add_child(sheet)
		var want := KitSkin.region(pieces["sheet__%s__normal" % pair[1]]).size * KitSkin.scale()
		var grip := sheet.find_child(str(pair[1]).capitalize(), true, false) as Control
		if grip == null or not grip.custom_minimum_size.is_equal_approx(want):
			bad.append("the %s has no baked %s" % pair)
	# A dialog's card draws the popup's box; a switch its track.
	var dialog := KitPanels.dialog(screen, "Title", "Words", [])
	var toggle := KitSwitch.make(true, "On", "Off", "A switch", func(_on: bool) -> void: pass)
	screen.add_child(toggle)
	# A bar: the alarm's own fill in the alarm's red, the tinted fill in any
	# other colour; the tick it is aimed at.
	var red := KitBar.make(0.5, Tokens.color("alarm"))
	var gold := KitBar.make(0.5)
	var green := KitBar.make(0.5, Tokens.color("success"))
	for b: KitBar in [red, gold, green]:
		screen.add_child(b)
	var aim := green.aim(0.25)
	for i: int in 2:
		await tree.process_frame
	var popup_box: RbBox = null
	for n: Node in dialog.find_children("*", "PanelContainer", true, false):
		var b := RbBox.of(n as Control)
		if b != null and b.skin_shape == "popup/box":
			popup_box = b
	if popup_box == null or popup_box.piece() != popup:
		bad.append("a dialog's card does not draw the popup's box")
	if RbBox.of(toggle).piece() != pieces["toggle__track_on__normal"]:
		bad.append("a switch that is on does not draw toggle__track_on")
	if RbBox.of(red.fill).piece() != pieces["bar_fill__alarm__normal"]:
		bad.append("an alarm bar does not draw the kit's alarm fill")
	for b: KitBar in [gold, green]:
		if RbBox.of(b.fill).piece() != pieces["bar_fill__box__normal"]:
			bad.append("a bar in another colour does not draw the tinted fill")
	var tick: Dictionary = pieces["bar_track__tick__normal"]
	if aim.name != "Aim" or not aim.size.is_equal_approx(KitSkin.region(tick).size * KitSkin.scale()) \
			or not is_equal_approx(aim.anchor_left, 0.25):
		bad.append("a bar's aim is not the kit's tick at its share")
	var dot := KitStatus.attention(12.0)
	if dot.name != "Dot" or not is_equal_approx(dot.custom_minimum_size.y, UI.px(12.0)) or dot is KitRing:
		bad.append("the attention dot is not the kit's dot, 12 points tall")
	dot.free()
	# Switched off, each is the caller's to draw in code again.
	for k: String in ["sheet", "popup", "toggle", "bar_track", "badge", "slider"]:
		KitSkin.switch(k, false)
	var plain := KitPanels.sheet("Sheet")
	screen.add_child(plain)
	if plain.find_child("Handle", true, false) != null:
		bad.append("a sheet switched off still has the baked handle")
	if not popup_box.piece().is_empty() and popup_box.piece() == popup:
		bad.append("a dialog switched off still draws the popup's box")
	if RbBox.of(toggle).piece() == pieces["toggle__track_on__normal"]:
		bad.append("a switch switched off still draws the baked track")
	var line := gold.aim(0.5)
	if not line is ColorRect:
		bad.append("a bar's aim is not a cream line while its skin is off")
	dot = KitStatus.attention()
	if not dot is KitRing:
		bad.append("the attention dot is not drawn in code while its skin is off")
	dot.free()
	if KitSkin.cut(KitSkin.face("slider", "knob")) != null:
		bad.append("the slider switched off still has a cut knob")
	if not KitSkin.missing.is_empty():
		bad.append("a part switched off is logged: %s" % ", ".join(KitSkin.missing))
	screen.queue_free()
	KitSkin.reset()
	await tree.process_frame
	return bad


## The colour at the middle of piece `p` in the page it is cut from.
static func middle(p: Dictionary) -> Color:
	var tex := KitSkin.texture(p)
	if tex == null:
		return Color(0, 0, 0, 0)
	var at := Vector2i(int(p["x"]) + int(p["w"]) / 2, int(p["y"]) + int(p["h"]) / 2)
	return tex.get_image().get_pixelv(at)
