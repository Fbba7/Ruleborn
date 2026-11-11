class_name KitBar
extends Range
## A progress or storage bar: an ink-edged track and a fill in a gradient of
## its colour, as the designs' resource and mastery bars. Its value moves
## with Motion.fill (450 ms easing out, at once under reduced motion). The
## number it stands for is always written beside it, never left to the bar
## (§20.8).

var fill: Control = null
## How far the fill sits inside the track, in points.
var inset_points := 1.0
var _top := Color()
var _bottom := Color()


## A bar `points` tall in `tone` (Color() for gold), at `fraction` of full.
static func make(fraction := 0.0, tone := Color(), points := -1.0) -> KitBar:
	var b := KitBar.new()
	b.name = "Bar"
	b.min_value = 0.0
	b.max_value = 1.0
	b.step = 0.0
	b.value = clampf(fraction, 0.0, 1.0)
	b.custom_minimum_size = Vector2(UI.px(40), UI.px(points if points > 0 else Tokens.number("size", "bar_points")))
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.mouse_filter = Control.MOUSE_FILTER_IGNORE
	RbBox.dress(b, "bar_track")
	b.fill = Control.new()
	b.fill.name = "Fill"
	b.fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(b.fill)
	RbBox.dress(b.fill, "bar")
	b.colour(tone)
	return b


## The fill's colour: a light top over the colour itself. In the alarm's
## red the kit's own alarm fill is drawn (`bar_fill__alarm`, untinted) while
## its skin is on.
func colour(c: Color) -> void:
	var box := RbBox.of(fill)
	if box != null:
		box.skin_shape = "alarm" if c == Tokens.color("alarm") else ""
	if c == Color():
		_top = Color()
		return
	_top = c.lightened(0.35)
	_bottom = c
	if box != null:
		box.tint(_top, _bottom)


## A tick across the bar at `at` of its length (0 to 1): the share aimed
## for (the loot panel's load, §21.8). The kit's tick while its skin is on,
## else a cream line.
func aim(at: float) -> Control:
	var tick: Control = KitSkin.mark("tick")
	var half := Vector2(UI.px(1.5), UI.px(2))
	if tick == null:
		var line := ColorRect.new()
		line.color = Tokens.color("cream")
		line.mouse_filter = Control.MOUSE_FILTER_IGNORE
		tick = line
		tick.anchor_bottom = 1.0
		tick.offset_top = -half.y
		tick.offset_bottom = half.y
	else:
		half = tick.size / 2.0
		tick.anchor_top = 0.5
		tick.anchor_bottom = 0.5
		tick.offset_top = -half.y
		tick.offset_bottom = half.y
	tick.name = "Aim"
	tick.anchor_left = clampf(at, 0.0, 1.0)
	tick.anchor_right = tick.anchor_left
	tick.offset_left = -half.x
	tick.offset_right = half.x
	add_child(tick)
	return tick


func _ready() -> void:
	resized.connect(_layout)
	value_changed.connect(func(_v: float) -> void: _layout())
	_layout()


func _layout() -> void:
	if fill == null:
		return
	var inset := UI.px(inset_points)
	var ratio := 0.0 if max_value <= min_value else (value - min_value) / (max_value - min_value)
	var h := size.y - 2.0 * inset
	var w := (size.x - 2.0 * inset) * clampf(ratio, 0.0, 1.0)
	fill.visible = w > 0.5
	# Never thinner than it is tall, so a small value still reads as a pill.
	fill.position = Vector2(inset, inset)
	fill.size = Vector2(maxf(w, minf(h, size.x - 2.0 * inset)) if w > 0.5 else 0.0, h)
	if _top != Color():
		RbBox.of(fill).tint(_top, _bottom)
