class_name FxAnchors
extends Control
## The HUD that stands on the world (§21.8, §21.12): each piece is drawn where
## the camera puts a point of the world (`Camera3D.unproject_position`), so it
## follows its figure as the camera follows the crew.
##
##   crew      a health bar and a bag bar over the head; a gold chevron over
##             the chosen one; spinning stars over one that is down
##   guards    the awareness pip over the head, filling white, yellow, red
##             (§21.6), as a speech bubble with "?" or "!" drawn as shapes
##             once a guard suspects (§12.16); stars and "z" when knocked out
##   the Vault its tag, and its cracking as a bar under it
##   pylons    the law's school shape floating over its pylon
##   pop-ups   loot, hits and the alarm as numbers and marks that rise and fade
##   names     every crew member's role over its head while the world is held
##
## The alarm tints the screen's edge red, more as it rises, and flashes when a
## guard is alerted: a screen-space tint, never a full-screen pass, never over
## the middle where the play is (§21.3). Reduced motion keeps every mark and
## drops the movement (§20.8).

## How long a pop-up rises, in seconds.
const POP_SECONDS := 1.1
const STATE_FILL := {"Unaware": Color("#FFFFFF"), "Returning": Color("#FFFFFF"), "Suspicious": Color("#FFD34A"),
	"Investigating": Color("#FFB03A"), "Searching": Color("#FF8A3A"), "Alerted": Color("#E2536B")}
const OFF := Vector2(-99999, -99999)
## How full each state fills the pip.
const AWARE_FILL := {"Unaware": 0.0, "Returning": 0.15, "Suspicious": 0.35, "Investigating": 0.6, "Searching": 0.8,
	"Alerted": 1.0}
const STATE_MARK := {"Suspicious": "?", "Investigating": "??", "Searching": "?", "Alerted": "!"}

var view: WorldView
## The pop-ups on show: {at: Vector3, text: String, colour: Color, t: float,
## icon: String}.
var pops: Array[Dictionary] = []
## Seconds left showing every crew member's name (a long press).
var names_for := 0.0
## The edge's flash, 1 at a fresh alert, falling to 0.
var flash := 0.0
## How far the alarm has risen, 0 to 1, for the edge's steady tint.
var alarm_share := 0.0
## A crossing's wipe, 1 to 0 (`WorldView.swoop`).
var wipe := 0.0
var _time := 0.0
## Each figure's most health seen, its bar's whole.
var _most := {}


func _init(world_view: WorldView = null) -> void:
	view = world_view
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)


## A number or mark rising from a point of the world.
func pop(at: Vector3, text: String, colour: Color, icon := "") -> void:
	pops.append({"at": at, "text": text, "colour": colour, "t": 0.0, "icon": icon})
	if pops.size() > 24:
		pops.pop_front()


func tick(delta: float) -> void:
	_time += delta
	names_for = maxf(0.0, names_for - delta)
	flash = maxf(0.0, flash - delta * 1.4)
	wipe = maxf(0.0, wipe - delta * 1.2)
	for p in pops:
		p["t"] = float(p["t"]) + delta
	pops = pops.filter(func(p: Dictionary) -> bool: return float(p["t"]) < POP_SECONDS)
	queue_redraw()


func _cam() -> Camera3D:
	return view.camera


## Where a point of the world is drawn, or `OFF` when it is not on screen.
func _on_screen(at: Vector3) -> Vector2:
	var cam := _cam()
	if cam == null or cam.is_position_behind(at):
		return OFF
	var p := cam.unproject_position(at)
	if p.x < -64 or p.y < -64 or p.x > size.x + 64 or p.y > size.y + 64:
		return OFF
	return p


## Pixels a metre is drawn at, for marks sized to the world.
func _metre() -> float:
	var cam := _cam()
	if cam == null or cam.size <= 0.0:
		return 40.0
	if cam.projection == Camera3D.PROJECTION_ORTHOGONAL:
		return size.y / cam.size
	# In perspective, a metre at the point the camera looks at.
	var at := view._aim
	if cam.is_position_behind(at):
		return 40.0
	return cam.unproject_position(at).distance_to(cam.unproject_position(at + cam.global_basis.x))


func _draw() -> void:
	var replay: RulebornReplay = view.replay
	if replay == null or _cam() == null:
		return
	var m := clampf(_metre(), 18.0, 120.0)
	var calm := Settings.reduced_motion
	_draw_frame()
	_draw_edge(calm)
	_draw_pylons(replay, m)
	_draw_pick(m, calm)
	_draw_vault(replay, m)
	_draw_guards(replay, m, calm)
	_draw_crew(replay, m, calm)
	_draw_pops(m, calm)
	if wipe > 0.0:
		# The crossing's cloud wipe: the swoop's middle in the rift's violet,
		# clouds rolling across it.
		var a := sin(wipe * PI) * 0.85
		draw_rect(Rect2(Vector2.ZERO, size), Color(0.36, 0.22, 0.6, a))
		var u := 1.0 - wipe
		for k in 9:
			var row := float(k % 3) / 2.0
			var x := lerpf(-0.4, 1.4, fmod(u * (1.0 + 0.2 * k) + k * 0.37, 1.0)) * size.x
			var y := lerpf(0.15, 0.85, (row + float(k) / 9.0) * 0.5 + 0.2) * size.y
			var r := size.x * (0.16 + 0.05 * (k % 4))
			var cloud := Color(0.93, 0.9, 1.0, clampf(a * 1.6, 0.0, 1.0))
			var shade := Color(0.72, 0.64, 0.9, cloud.a)
			# Opaque puffs, so where they meet is one cloud: its underside
			# first, a shade deeper, then its body.
			for pass_shade: bool in [true, false]:
				for blob: Vector3 in [Vector3(0, 0, 1.0), Vector3(0.7, 0.15, 0.75), Vector3(-0.7, 0.18, 0.7)]:
					var c := Vector2(x + blob.x * r, y + blob.y * r + (r * 0.12 if pass_shade else 0.0))
					draw_circle(c, r * blob.z, shade if pass_shade else cloud)


## A soft shade of the night's ink at the top and bottom of a heist, behind
## the HUD, so its pills read on any sky and the eye goes to the middle,
## where the play is: a screen-space tint, never a full-screen pass (§21.3).
func _draw_frame() -> void:
	if not view.heist or view.follow.is_empty():
		return
	var ink := Color("#1A1134")
	var steps := 8
	for i in steps:
		var k := float(i) / steps
		var a := 0.2 * (1.0 - k) * (1.0 - k)
		draw_rect(Rect2(0, size.y * 0.16 * k, size.x, size.y * 0.16 / steps + 1.0), Color(ink, a))
		draw_rect(Rect2(0, size.y * (1.0 - 0.3 * k) - size.y * 0.3 / steps, size.x, size.y * 0.3 / steps + 1.0),
			Color(ink, a * 1.3))


func _draw_edge(calm: bool) -> void:
	if view.follow.is_empty():
		return
	var a := alarm_share * 0.32 + flash * 0.4
	if a <= 0.01:
		return
	if not calm:
		a *= 0.85 + 0.15 * sin(_time * TAU * 0.8)
	var band := minf(size.x, size.y) * (0.07 + 0.05 * alarm_share)
	var red := Color(0.89, 0.2, 0.3)
	var steps := 6
	for i in steps:
		var k := float(i) / steps
		var w := band * (1.0 - k)
		var c := Color(red, a * (1.0 - k) * 0.5)
		draw_rect(Rect2(0, 0, size.x, w), c)
		draw_rect(Rect2(0, size.y - w, size.x, w), c)
		draw_rect(Rect2(0, 0, w, size.y), c)
		draw_rect(Rect2(size.x - w, 0, w, size.y), c)


## §5.4's spot on show in the landing picker: a gold pin over it, bobbing,
## so the choice reads at a glance among the edge's rings.
func _draw_pick(m: float, calm: bool) -> void:
	var marks: Array = view.landing_marks
	var k: int = view.landing_pick
	if marks.is_empty() or k < 0 or k >= marks.size():
		return
	var spot: Dictionary = marks[k]
	var at := _on_screen(view.world_at(Vector2(spot["at"]) + Vector2(0.5, 0.5)) + Vector3(0, 0.2, 0))
	if at == OFF:
		return
	var s := clampf(m * 0.7, 36.0, 90.0)
	var bob := 0.0 if calm else absf(sin(_time * 3.0)) * s * 0.25
	var tip := at + Vector2(0, -bob)
	var head := tip + Vector2(0, -s * 0.9)
	draw_colored_polygon(PackedVector2Array([tip, head + Vector2(-s * 0.36, s * 0.12),
		head + Vector2(s * 0.36, s * 0.12)]), FxSkin.INK_LINE)
	draw_circle(head, s * 0.42, FxSkin.INK_LINE)
	draw_colored_polygon(PackedVector2Array([tip + Vector2(0, -4), head + Vector2(-s * 0.3, s * 0.1),
		head + Vector2(s * 0.3, s * 0.1)]), FxSkin.GOLD)
	draw_circle(head, s * 0.35, FxSkin.GOLD)
	draw_circle(head, s * 0.14, FxSkin.INK_LINE)
	draw_circle(head + Vector2(-s * 0.12, -s * 0.14), s * 0.08, Color(1, 1, 1, 0.6))


func _draw_pylons(replay: RulebornReplay, m: float) -> void:
	for p: Dictionary in replay.pylons():
		if not p.get("standing", false):
			continue
		var at := _on_screen(view.world_at(p["at"]) + Vector3(0, 2.1, 0))
		if at == OFF:
			continue
		FxIcons.school(self, at, m * 0.62, str(p.get("school", "")))


func _draw_vault(replay: RulebornReplay, m: float) -> void:
	var v := replay.vault()
	if not v.has("at"):
		return
	var at := _on_screen(view.world_at(v["at"]) + Vector3(0, 1.9, 0))
	if at == OFF:
		return
	var font := FxSkin.numbers()
	var px := int(clampf(m * 0.36, 26.0, 64.0))
	var words := Strings.t("BUILDER_TOOL_VAULT").to_upper()
	var w := font.get_string_size(words, HORIZONTAL_ALIGNMENT_CENTER, -1, px).x + px
	var open: bool = v.get("open", false)
	var plate := Rect2(at - Vector2(w * 0.5, px * 0.8), Vector2(w, px * 1.25))
	var box := StyleBoxFlat.new()
	box.bg_color = FxSkin.GOLD if open else FxSkin.CARD_TOP
	box.border_color = FxSkin.INK_LINE
	box.set_border_width_all(maxi(2, int(px * 0.09)))
	box.set_corner_radius_all(int(px * 0.4))
	box.shadow_color = Color(0, 0, 0, 0.3)
	box.shadow_size = 4
	box.shadow_offset = Vector2(0, 3)
	draw_style_box(box, plate)
	draw_string(font, Vector2(plate.position.x, plate.position.y + px * 0.98), words, HORIZONTAL_ALIGNMENT_CENTER,
		plate.size.x, px, FxSkin.PARCH_INK if open else FxSkin.GOLD)
	var health := int(v.get("health", 0))
	_most["vault"] = maxi(int(_most.get("vault", 0)), health)
	var whole := int(_most["vault"])
	if not open and whole > 0 and health < whole:
		FxIcons.bar(self, Rect2(plate.position + Vector2(0, plate.size.y + px * 0.2), Vector2(w, px * 0.36)),
			1.0 - float(health) / whole, Color("#9B8CF0"))


func _draw_guards(replay: RulebornReplay, m: float, calm: bool) -> void:
	var nodes: Array[Node3D] = view._guards
	var guards := replay.guards()
	for i in mini(guards.size(), nodes.size()):
		var g: Dictionary = guards[i]
		var node := nodes[i]
		var head := node.position + Vector3(0, float(node.get_meta("head", 1.2)) + 0.25, 0)
		var at := _on_screen(head)
		if at == OFF:
			continue
		var s := clampf(m * 0.52, 28.0, 72.0)
		if g["down"]:
			_stars(at, s, calm)
			FxIcons.bubble(self, at + Vector2(s * 0.5, -s * 0.5), s * 0.7, "z", Color("#DDE3F2"))
			continue
		var state := str(g["state"])
		var fill: Color = STATE_FILL.get(state, Color.WHITE)
		# §21.6's pip over the head, filling white, then yellow, then red with
		# awareness; once the guard suspects, its mark rides above it.
		_pip(at + Vector2(0, s * 0.1), s * 0.22, float(AWARE_FILL.get(state, 0.0)), fill)
		if STATE_MARK.has(state):
			var bob := 0.0 if calm else sin(_time * 6.0 + i) * s * 0.06
			var grow := 1.0
			if state == "Alerted" and not calm:
				grow = 1.0 + 0.12 * absf(sin(_time * 5.0))
			FxIcons.bubble(self, at + Vector2(0, bob - s * 0.8), s * grow, STATE_MARK[state], fill)


func _draw_crew(replay: RulebornReplay, m: float, calm: bool) -> void:
	var nodes: Array[Node3D] = view._crew
	var crew := replay.crew()
	var chosen: int = view.chosen
	for i in mini(crew.size(), nodes.size()):
		var node := nodes[i]
		if not node.visible:
			continue
		var mem: Dictionary = crew[i]
		var at := _on_screen(node.position + Vector3(0, float(node.get_meta("head", 0.95)) + 0.2, 0))
		if at == OFF:
			continue
		var w := clampf(m * 0.8, 40.0, 110.0)
		# Sharing its spot with a guard (grabbed, or fighting), its marks step
		# to the side so they never pile on the guard's.
		var side := 1.0
		for gn: Node3D in view._guards:
			if gn.position.distance_to(node.position) < 0.7:
				at += Vector2(-w * 1.05, w * 0.3)
				side = -1.0
				break
		var h := maxf(7.0, w * 0.13)
		var key := "c%d" % i
		_most[key] = maxi(int(_most.get(key, 0)), int(mem["health"]))
		var share := float(mem["health"]) / maxf(1.0, float(_most[key]))
		var down: bool = mem["standing"] != "Active"
		if down:
			_stars(at, w * 0.6, calm)
		var y := 0.0
		if share < 0.999 or i == chosen or down:
			var col := FxSkin.SUCCESS if share > 0.5 else (FxSkin.GOLD if share > 0.25 else FxSkin.ALARM)
			FxIcons.bar(self, Rect2(at + Vector2(-w * 0.5, y), Vector2(w, h)), share, col)
			y += h + 3.0
		else:
			# The designs' pip over each of the crew, in its role's colour: whose
			# side it is on reads at a glance.
			var pip: Color = Palette.ROLE.get(str(mem["role"]), Palette.PAPER)
			draw_circle(at + Vector2(0, h * 0.5), h * 0.95, FxSkin.INK_LINE)
			draw_circle(at + Vector2(0, h * 0.5), h * 0.7, pip)
		var bag := float(mem["carried"]) / maxf(1.0, float(mem["carry"]))
		if bag > 0.0:
			FxIcons.bar(self, Rect2(at + Vector2(-w * 0.5 + h, y), Vector2(w - h, h * 0.8)), bag, FxSkin.GOLD)
			FxIcons.coin(self, at + Vector2(-w * 0.5 + h * 0.3, y + h * 0.4), h * 0.7)
		if i == chosen and not down:
			var bob := 0.0 if calm else absf(sin(_time * 3.2)) * w * 0.08
			var tip := at + Vector2(0, -h * 0.6 - bob)
			var tri := PackedVector2Array([tip, tip + Vector2(-w * 0.16, -w * 0.18), tip + Vector2(w * 0.16, -w * 0.18)])
			draw_colored_polygon(PackedVector2Array([tri[0] + Vector2(0, 3), tri[1] + Vector2(-3, -2),
				tri[2] + Vector2(3, -2)]), FxSkin.INK_LINE)
			draw_colored_polygon(tri, FxSkin.GOLD)
		if view.in_sight.has(i):
			# In a guard's sight: an eye beside the head, blinking open.
			var blink := 1.0 if calm else 0.85 + 0.15 * absf(sin(_time * 4.0))
			FxIcons.eye(self, at + Vector2(w * 0.62 * side, -h * 0.2), w * 0.55 * blink)
		if names_for > 0.0:
			_name_tag(at + Vector2(0, -w * 0.45), Strings.term("ROLE", str(mem["role"])))


## A round pip filled to `share` from the bottom up, in `colour` on white.
func _pip(at: Vector2, r: float, share: float, colour: Color) -> void:
	draw_circle(at, r + maxf(2.0, r * 0.25), FxSkin.INK_LINE)
	draw_circle(at, r, Color.WHITE)
	if share <= 0.0:
		return
	if share >= 1.0:
		draw_circle(at, r, colour)
		return
	# The filled part: the circle's segment below the line at `share` of its
	# height, its arc closed by the chord.
	var a0 := asin(clampf(1.0 - 2.0 * share, -1.0, 1.0))
	var pts := PackedVector2Array()
	for k in 17:
		var a := lerpf(a0, PI - a0, k / 16.0)
		pts.append(at + Vector2(cos(a), sin(a)) * r)
	draw_colored_polygon(pts, colour.darkened(0.12) if colour == Color.WHITE else colour)


func _name_tag(at: Vector2, words: String) -> void:
	var font := FxSkin.words()
	var px := 30
	var w := font.get_string_size(words, HORIZONTAL_ALIGNMENT_CENTER, -1, px).x + px
	var r := Rect2(at - Vector2(w * 0.5, px * 1.2), Vector2(w, px * 1.3))
	var box := StyleBoxFlat.new()
	box.bg_color = Color(FxSkin.GLASS, 0.9)
	box.border_color = FxSkin.INK_LINE
	box.set_border_width_all(2)
	box.set_corner_radius_all(int(px * 0.6))
	draw_style_box(box, r)
	draw_string(font, Vector2(r.position.x, r.position.y + px * 0.98), words, HORIZONTAL_ALIGNMENT_CENTER, r.size.x, px,
		FxSkin.ON_DARK)


func _stars(at: Vector2, s: float, calm: bool) -> void:
	var turn := 0.0 if calm else _time * 2.4
	for k in 3:
		var a := turn + TAU * k / 3.0
		var p := at + Vector2(cos(a) * s * 0.45, sin(a) * s * 0.16 - s * 0.1)
		FxIcons.star(self, p, s * 0.14, Color("#FFE27A"), turn * 2.0)


func _draw_pops(m: float, calm: bool) -> void:
	var font := FxSkin.numbers()
	for p in pops:
		var t := float(p["t"]) / POP_SECONDS
		var at := _on_screen(p["at"])
		if at == OFF:
			continue
		var rise := 0.0 if calm else t * m * 1.1
		var px := int(clampf(m * 0.5, 30.0, 72.0) * (1.0 + (0.0 if calm else 0.25 * maxf(0.0, 1.0 - t * 4.0))))
		var a := 1.0 if t < 0.65 else 1.0 - (t - 0.65) / 0.35
		var pos := at + Vector2(0, -rise)
		var words := str(p["text"])
		var w := font.get_string_size(words, HORIZONTAL_ALIGNMENT_LEFT, -1, px).x
		var icon := str(p["icon"])
		var x := pos.x - w * 0.5 + (px * 0.35 if icon != "" else 0.0)
		if icon == "coin":
			FxIcons.coin(self, Vector2(x - px * 0.45, pos.y - px * 0.32), px * 0.32)
		elif icon == "star":
			FxIcons.star(self, Vector2(x - px * 0.45, pos.y - px * 0.32), px * 0.36, Color("#FFE27A"))
		var colour: Color = p["colour"]
		draw_string_outline(font, Vector2(x, pos.y), words, HORIZONTAL_ALIGNMENT_LEFT, -1, px, maxi(6, px / 5),
			Color(FxSkin.INK_LINE, a))
		draw_string(font, Vector2(x, pos.y), words, HORIZONTAL_ALIGNMENT_LEFT, -1, px, Color(colour, a))
