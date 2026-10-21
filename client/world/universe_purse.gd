class_name UniversePurse
extends Control
## Home's full-width row of resources (§21.8's home layout): Starlight, Aether
## and Essence, each a glass bar with its icon, the amount held, and a line
## along its foot that fills as that resource's producers fill (§9.3's
## twelve hours), marked FULL in words once they are nearly full, so a player
## sees what is waiting to be collected. An amount the server has not given
## is a dash, never a guess.

const ORDER := ["starlight", "aether", "essence"]
## The share at which producers are said to be full.
const FULL := 0.9

## Per resource: {"amount": int or -1, "ready": int, "holds": int}.
var rows := {}
var _icons := {}


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	for k: String in ORDER:
		_icons[k] = UniverseHud.icon("res_" + k)
	resized.connect(queue_redraw)


## What the store holds (UniverseStore.purse).
func show_purse(purse: Dictionary) -> void:
	rows = purse
	custom_minimum_size.y = _bar_h() + UI.px(6)
	var said := PackedStringArray()
	for k: String in ORDER:
		var r: Dictionary = rows.get(k, {})
		var amount := int(r.get("amount", -1))
		said.append(Strings.t("HOME_PURSE_SPOKEN", [Strings.t("HOME_RES_" + k.to_upper()),
			UniverseHud.grouped(amount) if amount >= 0 else Strings.t("HOME_UNKNOWN"),
			UniverseHud.grouped(int(r.get("ready", 0)))]))
	accessibility_name = Strings.t("HOME_PURSE")
	accessibility_description = "\n".join(said)
	queue_redraw()


func _bar_h() -> float:
	return maxf(UI.px(32), UI.text_px(15.0) * 1.75)


func _draw() -> void:
	if rows.is_empty():
		return
	var gap := UI.px(8)
	var h := _bar_h()
	var w := (size.x - gap * 2.0) / 3.0
	for i: int in ORDER.size():
		_bar(ORDER[i], Rect2(Vector2(i * (w + gap), UI.px(2)), Vector2(w, h)))


func _bar(kind: String, box: Rect2) -> void:
	var r: Dictionary = rows.get(kind, {})
	var colour: Color = UniverseHud.RESOURCES[kind]
	var h := box.size.y
	var inner := Rect2(box.position + Vector2(h * 0.42, 0.0), box.size - Vector2(h * 0.42, 0.0))
	UniverseHud.glass(h * 0.5).draw(get_canvas_item(), inner)
	# The fill along the foot: what the producers hold of what they can.
	var holds := int(r.get("holds", 0))
	var share := clampf(float(r.get("ready", 0)) / holds, 0.0, 1.0) if holds > 0 else 0.0
	var line := UI.px(4)
	var track := Rect2(inner.position + Vector2(h * 0.5, h - line - UI.px(3)), Vector2(inner.size.x - h * 0.8, line))
	draw_rect(track, Color(0, 0, 0, 0.45))
	if share > 0.0:
		draw_rect(Rect2(track.position, Vector2(track.size.x * share, line)), colour)
		draw_rect(Rect2(track.position, Vector2(track.size.x * share, line * 0.4)), colour.lightened(0.45))
	# The icon, over the bar's left end.
	var tex: Texture2D = _icons.get(kind)
	var s := h * 1.12
	if tex != null:
		draw_texture_rect(tex, Rect2(Vector2(box.position.x - UI.px(1), box.get_center().y - s * 0.5),
			Vector2(s, s)), false)
	var font := UniverseHud.words_font()
	var px := UI.text_px(15.0)
	var amount := int(r.get("amount", -1))
	var text := UniverseHud.grouped(amount) if amount >= 0 else "–"
	var x := box.position.x + s * 0.92
	var base := box.position.y + h * 0.5 + font.get_ascent(px) * 0.3
	draw_string(font, Vector2(x, base), text, HORIZONTAL_ALIGNMENT_LEFT, box.end.x - x - UI.px(6), px,
		UniverseHud.WORDS)
	if share >= FULL:
		var tag := Strings.t("HOME_FULL")
		var tpx := UI.text_px(13.0)
		var tw := font.get_string_size(tag, HORIZONTAL_ALIGNMENT_LEFT, -1, tpx).x + UI.px(10)
		var plate := Rect2(Vector2(box.end.x - tw - UI.px(2), box.position.y - tpx * 0.55), Vector2(tw, tpx * 1.25))
		UniverseHud.plate(UniverseHud.ALARM_FILL, plate.size.y * 0.5).draw(get_canvas_item(), plate)
		draw_string(font, Vector2(plate.position.x, plate.position.y + plate.size.y * 0.5
			+ font.get_ascent(tpx) * 0.36), tag, HORIZONTAL_ALIGNMENT_CENTER, plate.size.x, tpx, Color.WHITE)
