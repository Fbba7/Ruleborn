class_name StageScreen
extends RefCounted
## A screen laid over its realm: the world full-bleed behind the screen's
## column (§21.1's diorama under §21.8's panels), the column's empty space
## letting taps through to the world, and the pins layer between them. The
## column keeps every word and control the screen had; only where it stands
## changes.

static var _night: ImageTexture
## Whether the player folded the words away, kept from screen to screen so
## the world keeps the phone once they ask for it.
static var folded := false


## The view behind `screen`'s frame, which `UI.frame` built: put over the
## frame's sky and under its column, with a pins layer over it. The column
## and its margins let a tap fall through wherever they draw nothing.
static func mount(screen: Control, column: VBoxContainer) -> StageView:
	var view := StageView.new()
	view.name = "Stage"
	view.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var sky := screen.get_node_or_null("Sky")
	screen.add_child(view)
	screen.move_child(view, sky.get_index() + 1 if sky != null else 0)
	var pins := OverlayPins.new(view)
	screen.add_child(pins)
	screen.move_child(pins, view.get_index() + 1)
	view.set_meta("pins", pins)
	var n: Node = column
	while n != null and n != screen:
		if n is Container:
			(n as Control).mouse_filter = Control.MOUSE_FILTER_IGNORE
		n = n.get_parent()
	return view


static func pins_of(view: StageView) -> OverlayPins:
	return view.get_meta("pins") as OverlayPins


## An empty stretch of the column that shows the world and passes taps to
## it, `ratio` times as tall as the column's other stretching parts.
static func window(column: VBoxContainer, ratio := 1.0) -> Control:
	var c := Control.new()
	c.name = "Window"
	c.size_flags_vertical = Control.SIZE_EXPAND_FILL
	c.size_flags_stretch_ratio = ratio
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(c)
	return c


## The list `UI.scroll` made, as a sheet that takes `ratio` of the column's
## stretch and lets taps through between its plates.
static func sheet(body: VBoxContainer, ratio := 0.8) -> ScrollContainer:
	var s := body.get_parent() as ScrollContainer
	if s == null:
		s = body.get_parent().get_parent() as ScrollContainer
	s.size_flags_stretch_ratio = ratio
	body.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return s


## A key that folds the sheet away, and back: the world takes the phone,
## the words wait one tap away (and a screen reader still reads the realm).
static func fold_key(words: ScrollContainer) -> Button:
	var b := UI.button("", func() -> void: pass)
	var apply := func() -> void:
		words.visible = not folded
		UI.relabel(b, Strings.t("STAGE_SHOW_WORDS" if folded else "STAGE_HIDE_WORDS"), true)
	b.pressed.connect(func() -> void:
		folded = not folded
		apply.call())
	UI.fit_to(b, [Strings.t("STAGE_SHOW_WORDS"), Strings.t("STAGE_HIDE_WORDS")])
	apply.call()
	b.set_meta("key", "fold")
	return b


## The fold key as the sheet's handle: on its own row just above the words,
## so the screen's dock keeps its rows and the key stays where the words
## were once they are folded.
static func handle(column: VBoxContainer, words: ScrollContainer) -> Control:
	var row := UI.row()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(fold_key(words))
	var holder := UI.narrow(row)
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(holder)
	column.move_child(holder, words.get_index())
	OverlaySheet.dress(holder)
	return holder


## How much of `view`'s height lies under `cover` (a control over it) at
## the bottom: the share the island is lifted out of.
static func covered_below(view: Control, cover: Control, folded_to: Control = null) -> float:
	if folded_to != null and not cover.is_visible_in_tree():
		cover = folded_to
	var h := maxf(1.0, view.size.y)
	var top := cover.get_global_rect().position.y - view.get_global_rect().position.y
	return clampf((h - top) / h, 0.0, 0.8)


static func covered_above(view: Control, cover: Control) -> float:
	var h := maxf(1.0, view.size.y)
	var bottom := cover.get_global_rect().end.y - view.get_global_rect().position.y
	return clampf(bottom / h, 0.0, 0.6)


## The frame's sky turned to night with stars, for a screen that looks out
## at other universes (the design's Observatory: islands hanging in a galaxy
## sky). Drawn once, in code: a gradient and seeded points of light.
static func night_sky(screen: Control) -> void:
	var sky := screen.get_node_or_null("Sky") as TextureRect
	if sky == null:
		return
	sky.texture = night_texture()
	sky.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR


## The night sky with its stars and the galaxy's band, made once.
static func night_texture() -> ImageTexture:
	if _night != null:
		return _night
	var w := 270
	var h := 585
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	var top := Color("#1A1134")
	var mid := Color("#3A2466")
	var low := Color("#7A3F7E")
	for y in h:
		var f := float(y) / h
		var c := top.lerp(mid, f * 1.6) if f < 0.62 else mid.lerp(low, (f - 0.62) / 0.38)
		for x in w:
			img.set_pixel(x, y, c)
	var rng := RandomNumberGenerator.new()
	rng.seed = 731
	for i in 260:
		var x := rng.randi_range(0, w - 1)
		var y := rng.randi_range(0, h - 1)
		var b := rng.randf_range(0.35, 1.0)
		img.set_pixel(x, y, img.get_pixel(x, y).lerp(Color(1.0, 0.95, 1.0), b))
	# A faint band of the galaxy across the sky.
	for i in 900:
		var t := rng.randf()
		var x := int(t * w)
		var y := int(h * (0.2 + 0.5 * t) + rng.randfn(0.0, 18.0))
		if y >= 0 and y < h:
			img.set_pixel(x, y, img.get_pixel(x, y).lerp(Color("#E8C8FF"), 0.35))
	_night = ImageTexture.create_from_image(img)
	return _night
