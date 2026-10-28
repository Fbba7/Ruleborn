class_name UiqJuice
extends RefCounted
## T14's proof: the HUD's motion as curves of time, so a shot can draw any
## moment of it (tests/shots/uiq_motion.gd) and a screen could tween along
## the same curves. A press: the face sinks onto its lip and squashes to 92%,
## and on release springs back past its size (108%) with a back-ease and
## settles, all inside 0.4 s. Loot: coins leave the world in a stagger, fly an
## arc to the loot panel's bag, and each one that lands adds its share to the
## number and pulses the panel. A prototype: no screen of the game uses it.

const DOWN := 0.06
const UP := 0.12
const COINS := 6


## The press's scale at `t` seconds after the finger lands (let go at UP).
static func press_scale(t: float) -> float:
	if t < DOWN:
		return lerpf(1.0, 0.92, t / DOWN)
	if t < UP:
		return 0.92
	var k := clampf((t - UP) / 0.28, 0.0, 1.0)
	# Back-ease out from 92% to 100%, overshooting to about 108%.
	var c := 2.6
	var e := 1.0 + (c + 1.0) * pow(k - 1.0, 3.0) + c * pow(k - 1.0, 2.0)
	return lerpf(0.92, 1.0, e)


## Get out at `t`: its pressed face while held, scaled about its centre.
static func button_at(t: float, at: Vector2) -> Control:
	var b := TextureRect.new()
	b.texture = UiqArt.tex("btn_red_down" if t >= DOWN and t < UP else "btn_red")
	b.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	b.size = Vector2(232, 200)
	b.position = at
	b.pivot_offset = b.size / 2.0
	b.scale = Vector2.ONE * press_scale(t)
	var sunk := 9.0 if t >= DOWN and t < UP else 0.0
	b.add_child(UiqArt.sprite("icon_getout", Vector2(116, 70 + sunk), Vector2(106, 106)))
	var l := UiqArt.words(Strings.t("HEIST_GET_OUT"), 46.0)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.position = Vector2(0, 108 + sunk)
	l.size = Vector2(232, 60)
	b.add_child(l)
	return b


## The loot panel at `p` (0 to 1) through a flight of coins worth `total`.
static func loot_at(p: float, at: Vector2, total: int) -> Control:
	var root := Control.new()
	root.position = at
	var landed := 0
	for i in COINS:
		var k := clampf((p * 1.4 - 0.08 * i) / 0.8, 0.0, 1.0)
		if k >= 1.0:
			landed += 1
			continue
		if k <= 0.0:
			continue
		# A quadratic arc from the world (below left) up to the bag.
		var from := Vector2(60.0 + 22.0 * i, 470.0)
		var to := Vector2(60.0, 40.0)
		var mid := Vector2(-40.0, 200.0)
		var q := from.lerp(mid, k).lerp(mid.lerp(to, k), k)
		root.add_child(UiqArt.sprite("coin", q, Vector2(54, 54) * (1.0 - 0.3 * k)))
	var panel := UiqArt.nine("frame_panel")
	panel.size = Vector2(340, 170)
	panel.pivot_offset = Vector2(170, 85)
	# Each landing pulses the panel; it relaxes over the next coin.
	var pulse := 0.0
	if landed > 0 and landed < COINS:
		pulse = 0.07
	elif landed == COINS and p < 1.0:
		pulse = 0.04
	panel.scale = Vector2.ONE * (1.0 + pulse)
	root.add_child(panel)
	root.move_child(panel, 0)
	panel.add_child(UiqArt.sprite("icon_bag", Vector2(26, 24), Vector2(88, 88)))
	var room := UiqArt.words(Strings.t("HUD_ROOM"), 44.0, Color("#E9DAFF"))
	room.position = Vector2(60, 34)
	panel.add_child(room)
	var shown := ShopPresenter.grouped(int(round(float(total) * landed / COINS)))
	var d := UiqArt.digits(shown, "gold", 66.0)
	panel.add_child(d)
	d.reset_size()
	d.position = Vector2(318.0 - d.size.x, 52.0)
	return root
