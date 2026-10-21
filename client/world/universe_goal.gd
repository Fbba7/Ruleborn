class_name UniverseGoal
extends Button
## §14.8's nearest goal, above home's tabs (§21.8's home layout): whichever
## goal the store holds is closest to done, whatever its kind, said as what is
## left ("760 to go"), never as a percentage; a thin bar shows the share done
## beside the words. A tap opens where that goal is worked on.

## The goal shown: {"text", "share", "route", "icon"}; empty for none.
var goal := {}
var _tex: Texture2D


func _init() -> void:
	flat = true
	focus_mode = Control.FOCUS_ALL
	for state: String in ["normal", "hover", "pressed", "focus", "disabled", "hover_pressed"]:
		add_theme_stylebox_override(state, StyleBoxEmpty.new())
	resized.connect(queue_redraw)
	accessibility_name = Strings.t("HOME_GOAL_SPOKEN", "")
	button_down.connect(queue_redraw)
	button_up.connect(queue_redraw)


## The goals the store's slices hold, nearest to done first: the Keeper's next
## level (§14.2) and the season track's next tier. Each is the slices' own
## numbers; nothing is decided here.
static func goals(keeper: Dictionary, track: Dictionary) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var k: Dictionary = keeper.get("view", {})
	if not k.is_empty() and k.get("toNext") != null and int(k.get("toNext", 0)) > 0:
		var need := int(k["toNext"])
		var have := clampi(int(k.get("xp", 0)), 0, need)
		out.append({"text": Strings.t("HOME_GOAL_KEEPER", [UniverseHud.grouped(need - have), int(k["level"]) + 1]),
			"share": float(have) / need, "route": &"profile", "icon": "levelup"})
	var t: Dictionary = track.get("view", {})
	var next: Variant = t.get("next")
	if next is Dictionary and int((next as Dictionary).get("cost", 0)) > 0:
		var cost := int(next["cost"])
		var stars := clampi(int(t.get("stars", 0)), 0, cost)
		out.append({"text": Strings.t("HOME_GOAL_TRACK", [UniverseHud.grouped(cost - stars), int(next["tier"])]),
			"share": float(stars) / cost, "route": &"track", "icon": "track"})
	out.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return float(a["share"]) > float(b["share"]))
	return out


func show_goal(g: Dictionary) -> void:
	goal = g
	visible = not g.is_empty()
	if g.is_empty():
		return
	accessibility_name = Strings.t("HOME_GOAL_SPOKEN", str(g["text"]))
	_tex = UniverseHud.icon(str(g["icon"]))
	var font := UniverseHud.words_font()
	var w := font.get_string_size(str(g["text"]), HORIZONTAL_ALIGNMENT_LEFT, -1, _px()).x
	custom_minimum_size = Vector2(minf(w + UI.px(110), 330.0 * UI.PX_PER_POINT),
		maxf(UI.CONTROL_POINTS * UI.PX_PER_POINT, _px() * 3.1))
	queue_redraw()


func _px() -> int:
	return UI.text_px(14.0)


func _draw() -> void:
	if goal.is_empty():
		return
	var h := size.y - UI.px(6)
	var pill := Rect2(Vector2(h * 0.4, UI.px(3)), Vector2(size.x - h * 0.4, h))
	if is_pressed():
		pill.position.y += UI.px(1.5)
	UniverseHud.glass(UI.px(14)).draw(get_canvas_item(), pill)
	var c := Vector2(h * 0.5, pill.get_center().y)
	UniverseHud.ball(self, c, h * 0.5, UniverseHud.GOLD, UniverseHud.GOLD_RIM)
	var tex := _tex
	if tex != null:
		var s := h * 0.7
		draw_texture_rect(tex, Rect2(c - Vector2(s, s) * 0.5, Vector2(s, s)), false)
	var font := UniverseHud.words_font()
	var x := c.x + h * 0.62
	var px := _px()
	var kicker := Strings.t("HOME_GOAL")
	var kpx := UI.text_px(13.0)
	draw_string(UniverseHud.words_font(), Vector2(x, pill.position.y + kpx * 1.15), kicker, HORIZONTAL_ALIGNMENT_LEFT,
		-1, kpx, UniverseHud.GOLD[1])
	draw_string(font, Vector2(x, pill.position.y + kpx * 1.15 + px * 1.2), str(goal["text"]),
		HORIZONTAL_ALIGNMENT_LEFT, pill.end.x - x - UI.px(10), px, UniverseHud.WORDS)
	var track := Rect2(Vector2(x, pill.end.y - UI.px(9)), Vector2(pill.end.x - x - UI.px(14), UI.px(4)))
	draw_rect(track, Color(0, 0, 0, 0.5))
	draw_rect(Rect2(track.position, Vector2(track.size.x * float(goal["share"]), track.size.y)), UniverseHud.GOLD[1])
	if has_focus():
		var ring := UniverseHud.glass(UI.px(16))
		ring.draw_center = false
		ring.border_color = UniverseHud.WORDS
		ring.shadow_size = 0
		ring.draw(get_canvas_item(), pill.grow(UI.px(3)))
