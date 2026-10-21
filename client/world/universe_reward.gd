class_name UniverseReward
extends RefCounted
## Rewards fly into their counter (§21.8's motion): when home collects, each
## resource's icon leaves the Collect button and arcs into its bar at the top,
## a few at a time, and the bar pops as they land. Under reduced motion
## nothing flies; the bars simply show the new amounts (§20.8).

## How long one icon's flight takes, and the stagger between icons.
const FLIGHT_MS := 240.0
const STAGGER_MS := 45.0
## Icons per resource that fly.
const EACH := 4


## Icons of each resource in `amounts` ({"starlight": 320, …}, those above
## zero) fly from `from` to that resource's pill in `purse`, drawn on `layer`.
static func fly(layer: Control, from: Control, purse: UniversePurse, amounts: Dictionary) -> void:
	if UI.motion_ms(FLIGHT_MS) <= 0.0 or not layer.is_inside_tree():
		return
	var start := from.get_global_rect().get_center() - layer.global_position
	var k := 0
	for kind: String in UniversePurse.ORDER:
		if int(amounts.get(kind, 0)) <= 0 or not purse.pills.has(kind):
			continue
		var pill: Control = purse.pills[kind]
		var end := pill.get_global_rect().position + Vector2(UI.px(18), pill.size.y * 0.5) - layer.global_position
		var tex := Icons.texture("resources/" + kind)
		for i: int in EACH:
			_one(layer, tex, start + Vector2((i - 1.5) * UI.px(10), 0.0), end, (k * EACH + i) * STAGGER_MS)
		var pop := pill.create_tween()
		pop.tween_interval((k * EACH + EACH) * STAGGER_MS / 1000.0 + FLIGHT_MS / 1000.0)
		pop.tween_callback(func() -> void: Motion.pop(pill))
		k += 1


static func _one(layer: Control, tex: Texture2D, start: Vector2, end: Vector2, delay_ms: float) -> void:
	var icon := TextureRect.new()
	icon.texture = tex
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	var s := float(UI.px(26))
	icon.size = Vector2(s, s)
	icon.position = start - icon.size * 0.5
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon.modulate.a = 0.0
	layer.add_child(icon)
	var lift := Vector2((start.x + end.x) * 0.5, minf(start.y, end.y) - UI.px(60))
	var t := icon.create_tween()
	t.tween_interval(delay_ms / 1000.0)
	t.tween_property(icon, "modulate:a", 1.0, 0.04)
	t.tween_method(func(f: float) -> void:
		var e := 1.0 - pow(1.0 - f, 2.0)
		var a := start.lerp(lift, e)
		var b := lift.lerp(end, e)
		icon.position = a.lerp(b, e) - icon.size * 0.5
		icon.scale = Vector2.ONE * lerpf(1.0, 0.7, e), 0.0, 1.0, FLIGHT_MS / 1000.0)
	t.tween_callback(icon.queue_free)
