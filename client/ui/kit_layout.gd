class_name KitLayout
## How the kit's pieces sit together at every text size (§20.8): rows that
## wrap, columns that stack, grids that lose a column as words grow, and a
## whole card made one control. Folded in from T10's ScreenParts, so every
## screen lays out the same way at 150% and 200% text.

## The largest text size, in percent, at which side-by-side columns stay so.
const SIDE_BY_SIDE_UP_TO := 125


## A row of pieces (chips, pills, tags) that wraps onto a second line when
## they do not fit the phone's width.
static func flow(separation := 6.0) -> HFlowContainer:
	var r := HFlowContainer.new()
	r.name = "Flow"
	r.add_theme_constant_override("h_separation", UI.px(separation))
	r.add_theme_constant_override("v_separation", UI.px(separation))
	return r


## A row of pieces that runs past the phone's edge and scrolls sideways
## (the designs' filter chips, a deck of cards): its row is the child named
## "Row". It never wraps, so large text makes it longer, not taller.
static func strip(separation := 6.0) -> ScrollContainer:
	var s := ScrollContainer.new()
	s.name = "Strip"
	s.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	s.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
	s.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var r := HBoxContainer.new()
	r.name = "Row"
	r.add_theme_constant_override("separation", UI.px(separation))
	s.add_child(r)
	return s


## `children` side by side, each an equal share; stacked at large text,
## where side by side they would not fit.
static func columns(children: Array, separation := 8.0) -> BoxContainer:
	var r: BoxContainer = VBoxContainer.new()
	if Settings.text_scale <= SIDE_BY_SIDE_UP_TO:
		r = HBoxContainer.new()
	r.name = "Columns"
	r.add_theme_constant_override("separation", UI.px(separation))
	for c: Control in children:
		c.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		r.add_child(c)
	return r


## Columns for a grid of tiles: `most` at normal text, fewer as larger text
## makes each tile's words wider.
static func grid_columns(most: int) -> int:
	if Settings.text_scale > 150:
		return maxi(1, most - 2)
	if Settings.text_scale > 110:
		return maxi(1, most - 1)
	return most


## A grid of `most` columns at normal text, fewer at large text.
static func grid(most: int, separation := 8.0) -> GridContainer:
	var g := GridContainer.new()
	g.name = "Grid"
	g.columns = grid_columns(most)
	g.add_theme_constant_override("h_separation", UI.px(separation))
	g.add_theme_constant_override("v_separation", UI.px(separation))
	return g


## Makes a whole card one control: a clear button over it, named for a
## screen reader, that presses as the kit's buttons do. Returns the button.
static func tap(panel: Control, pressed: Callable, spoken: String) -> Button:
	var b := UI.action("", pressed, "ghost", spoken)
	b.name = "Tap"
	var box := RbBox.of(b)
	if box != null:
		box.visible = false
	b.custom_minimum_size = Vector2.ZERO
	b.set_anchors_preset(Control.PRESET_FULL_RECT)
	# The card squashes and sinks as a button does (§21.8), in place of the
	# clear button's own press, which UI.action connected. Godot tells two
	# connections of one signal apart by their method alone, not by what is
	# bound to it, so the card's would be refused beside the button's
	# ("already connected") and the card would never press (S2-R26): the
	# button's is taken off first, and the card's made once.
	for sig: Signal in [b.button_down, b.button_up]:
		var down := sig == b.button_down
		var mine := Motion.press.bind(panel, down)
		if sig.is_connected(mine):
			sig.disconnect(mine)
		sig.connect(mine)
	panel.add_child(b)
	return b
