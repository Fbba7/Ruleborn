class_name StageScreen
extends RefCounted
## A screen laid over its realm: the world full-bleed behind the screen's
## column (§21.1's diorama under §21.8's panels), the column's empty space
## letting taps through to the world, and the pins layer between them. The
## column keeps every word and control the screen had; only where it stands
## changes.


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


## How much of `view`'s height lies under `cover` (a control over it) at
## the bottom: the share the island is lifted out of.
static func covered_below(view: Control, cover: Control) -> float:
	var h := maxf(1.0, view.size.y)
	var top := cover.get_global_rect().position.y - view.get_global_rect().position.y
	return clampf((h - top) / h, 0.0, 0.8)


static func covered_above(view: Control, cover: Control) -> float:
	var h := maxf(1.0, view.size.y)
	var bottom := cover.get_global_rect().end.y - view.get_global_rect().position.y
	return clampf(bottom / h, 0.0, 0.6)
