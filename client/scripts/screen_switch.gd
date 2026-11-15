class_name ScreenSwitch
extends Control
## Key frame 05's switch at the end of a settings row, from the kit's
## materials alone: a pill track, green when on and dark plate when off,
## with a parchment knob at the right when on and at the left when off. The
## row's words say On or Off too, so the state never rests on colour or the
## knob's place alone (§20.8). It takes no taps: the row is the control.

var on := false


static func make(state: bool) -> ScreenSwitch:
	var s := ScreenSwitch.new()
	s.name = "Switch"
	s.on = state
	s.custom_minimum_size = Vector2(UI.px(46), UI.px(28))
	s.mouse_filter = Control.MOUSE_FILTER_IGNORE
	s.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	UI.dress(s, "green" if state else "plate_dark", 999)
	var knob := Control.new()
	knob.name = "Knob"
	knob.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var side := UI.px(18)
	var inset := UI.px(5)
	knob.size = Vector2(side, side)
	# Anchored to the track's end, so the knob keeps its place as the row
	# lays the track out.
	knob.anchor_top = 0.5
	knob.anchor_bottom = 0.5
	knob.anchor_left = 1.0 if state else 0.0
	knob.anchor_right = knob.anchor_left
	knob.offset_top = -side * 0.5
	knob.offset_bottom = side * 0.5
	knob.offset_left = -side - inset if state else inset
	knob.offset_right = knob.offset_left + side
	UI.dress(knob, "plate", 999)
	s.add_child(knob)
	return s
