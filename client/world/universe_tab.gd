class_name UniverseTab
extends Button
## One of home's five tabs (UniverseTabs): its icon over its name; raised and
## larger on a periwinkle disc when it is the one the player is on; the
## Heist's a gold ball above the bar.

var key := ""
var icon_name := ""
var words := ""
var count := ""
var active := false
var tex: Texture2D


func _init() -> void:
	flat = true
	focus_mode = Control.FOCUS_ALL
	for state: String in ["normal", "hover", "pressed", "focus", "disabled", "hover_pressed"]:
		add_theme_stylebox_override(state, StyleBoxEmpty.new())
	resized.connect(queue_redraw)
	button_down.connect(queue_redraw)
	button_up.connect(queue_redraw)


func _draw() -> void:
	var heist := key == "heist"
	var px := UI.text_px(14.0 if active else 13.0)
	var font := UniverseHud.words_font()
	var label_y := size.y - UI.px(4)
	var c := Vector2(size.x * 0.5, (label_y - px) * 0.5 + UI.px(6))
	var r := UI.px(19)
	if heist:
		r = UI.px(29)
		c.y -= UI.px(12)
	elif active:
		r = UI.px(25)
		c.y -= UI.px(9)
	if is_pressed():
		c.y += UI.px(2)
	if heist:
		UniverseHud.drop(self, c, r, UniverseHud.GOLD_DROP)
		draw_circle(c, r + UI.px(7), Color(UniverseHud.GOLD[1], 0.22), true, -1.0, true)
		UniverseHud.ball(self, c, r, UniverseHud.GOLD, UniverseHud.GOLD_RIM)
	elif active:
		draw_circle(c, r + UI.px(6), Color(0.67, 0.59, 1.0, 0.3), true, -1.0, true)
		UniverseHud.drop(self, c, r)
		UniverseHud.ball(self, c, r, UniverseHud.ACTIVE, UniverseHud.GOLD[1])
	if tex != null:
		var s := r * (1.45 if heist or active else 1.9)
		draw_texture_rect(tex, Rect2(c - Vector2(s, s) * 0.5, Vector2(s, s)), false,
			Color.WHITE if heist or active else Color(1, 1, 1, 0.92))
	var colour := UniverseHud.CREAM if active or heist else UniverseHud.SOFT_WORDS
	# A name may run past its tab's edges; the tabs' gaps hold it.
	var spill := UI.px(10)
	UniverseHud.inked(self, font, Vector2(-spill, label_y), words, px, colour, size.x + spill * 2.0,
		HORIZONTAL_ALIGNMENT_CENTER,
		UI.px(3) if active or heist else UI.px(2))
	if count != "":
		UniverseHud.badge(self, c + Vector2(r * 0.8, -r * 0.62), count)
	if has_focus():
		draw_arc(c, r + UI.px(4), 0.0, TAU, 48, UniverseHud.WORDS, UI.px(2), true)
