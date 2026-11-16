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
## drops the movement (§20.8), the edge's flash with it: the tint only rises.

## How long a pop-up rises, in seconds.
const POP_SECONDS := 0.8
const STATE_FILL := {"Unaware": Color("#FFFFFF"), "Returning": Color("#FFFFFF"), "Suspicious": Color("#FFD34A"),
	"Investigating": Color("#FFB03A"), "Searching": Color("#FF8A3A"), "Alerted": Color("#E2536B")}
const OFF := Vector2(-99999, -99999)
## How full each state fills the pip.
const AWARE_FILL := {"Unaware": 0.0, "Returning": 0.15, "Suspicious": 0.35, "Investigating": 0.6, "Searching": 0.8,
	"Alerted": 1.0}
## How long a guard's words stay over it, in seconds.
const SAY_SECONDS := 2.0
## §12.16's guard speech, by the state a guard has just come to.
const SAYS := {"Suspicious": "GUARD_SAY_SUSPICIOUS", "Investigating": "GUARD_SAY_INVESTIGATING",
	"Alerted": "GUARD_SAY_ALERTED", "Returning": "GUARD_SAY_RETURNING"}
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
## Whether the Vault's tag is drawn: a scout or a planner knows a realm's
## counts, not where its Vault stands (§12.4).
var vault_shown := true
## What each guard is saying: guard index -> {text: String, t: float}.
var speech := {}
## A layer the screen lays above its panels, or null: the guards' words are
## drawn there, so a bubble is never clipped behind a panel. It covers the
## same rect as this one.
var speech_layer: Control:
	set(layer):
		speech_layer = layer
		if layer != null and not layer.draw.is_connected(_draw_speech_layer):
			layer.draw.connect(_draw_speech_layer)
## The screen's panels, in this layer's pixels (a Callable returning an
## Array of Rect2): a bubble moves off them to the nearest clear place.
var keep_off := Callable()
## Panels a bubble may rest on where the world shows no room (a Callable
## as keep_off's): counted at a quarter of their area, so a bubble with no
## clear place covers these before keep_off's words.
var keep_soft := Callable()
## Where the last frame drew each bubble, in this layer's pixels.
var speech_boxes: Array[Rect2] = []

var _time := 0.0
## The guards' words placed this frame (_speech_items), and whether they are
## drawn on the speech layer.
var _said: Array[Dictionary] = []
var _said_up := false
## Where the VAULT tag stands this frame, so a guard's words stay off it.
var _vault_plate := Rect2()
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
	for k: int in speech.keys():
		speech[k]["t"] = float(speech[k]["t"]) + delta
		if float(speech[k]["t"]) > SAY_SECONDS:
			speech.erase(k)
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
	_pen(self, _paint)


## Every shape a canvas item draws in one call (FxPen).
func _pen(ci: CanvasItem, paint: Callable) -> void:
	FxPen.begin(ci)
	paint.call()
	FxPen.end(ci)


func _paint() -> void:
	var replay: RulebornReplay = view.replay
	if replay == null or _cam() == null:
		return
	var m := clampf(_metre(), 18.0, 120.0)
	var calm := Settings.reduced_motion
	_draw_frame()
	_draw_edge(calm)
	_draw_pylons(replay, m)
	_draw_pick(m, calm)
	_vault_plate = Rect2()
	if vault_shown:
		_draw_vault(replay, m)
	_draw_guards(replay, m, calm)
	_draw_crew(replay, m, calm)
	_draw_pops(m, calm)
	# The guards' words here, or on the screen's layer above its panels when
	# one lies over a panel (a layer of their own costs the frame a call).
	_said = _speech_items(replay, m, calm)
	var up := speech_layer != null and _said.any(func(it: Dictionary) -> bool: return it["over"])
	if not up:
		_paint_speech(self, _said)
	if speech_layer != null and (up or _said_up):
		speech_layer.queue_redraw()
	_said_up = up
	if wipe > 0.0:
		# The crossing's cloud wipe: the swoop's middle in the rift's violet,
		# clouds rolling across it.
		var a := sin(wipe * PI) * 0.85
		FxPen.rect(self, Rect2(Vector2.ZERO, size), Color(0.36, 0.22, 0.6, a))
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
					FxPen.circle(self, c, r * blob.z, shade if pass_shade else cloud)


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
		FxPen.rect(self, Rect2(0, size.y * 0.16 * k, size.x, size.y * 0.16 / steps + 1.0), Color(ink, a))
		FxPen.rect(self, Rect2(0, size.y * (1.0 - 0.3 * k) - size.y * 0.3 / steps, size.x, size.y * 0.3 / steps + 1.0),
			Color(ink, a * 1.3))


## How strongly the edge is tinted now: the alarm's steady share, plus a flash
## that reduced motion leaves out and a slow pulse it leaves still.
func edge_alpha(calm: bool) -> float:
	var a := alarm_share * 0.32 + (0.0 if calm else flash * 0.4)
	if a > 0.01 and not calm:
		a *= 0.85 + 0.15 * sin(_time * TAU * 0.8)
	return a


func _draw_edge(calm: bool) -> void:
	if view.follow.is_empty():
		return
	var a := edge_alpha(calm)
	if a <= 0.01:
		return
	var band := minf(size.x, size.y) * (0.07 + 0.05 * alarm_share)
	var red := Color(0.89, 0.2, 0.3)
	var steps := 6
	for i in steps:
		var k := float(i) / steps
		var w := band * (1.0 - k)
		var c := Color(red, a * (1.0 - k) * 0.5)
		FxPen.rect(self, Rect2(0, 0, size.x, w), c)
		FxPen.rect(self, Rect2(0, size.y - w, size.x, w), c)
		FxPen.rect(self, Rect2(0, 0, w, size.y), c)
		FxPen.rect(self, Rect2(size.x - w, 0, w, size.y), c)


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
	FxPen.polygon(self, PackedVector2Array([tip, head + Vector2(-s * 0.36, s * 0.12),
		head + Vector2(s * 0.36, s * 0.12)]), FxSkin.INK_LINE)
	FxPen.circle(self, head, s * 0.42, FxSkin.INK_LINE)
	FxPen.polygon(self, PackedVector2Array([tip + Vector2(0, -4), head + Vector2(-s * 0.3, s * 0.1),
		head + Vector2(s * 0.3, s * 0.1)]), FxSkin.GOLD)
	FxPen.circle(self, head, s * 0.35, FxSkin.GOLD)
	FxPen.circle(self, head, s * 0.14, FxSkin.INK_LINE)
	FxPen.circle(self, head + Vector2(-s * 0.12, -s * 0.14), s * 0.08, Color(1, 1, 1, 0.6))


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
	var base := view.world_at(v["at"])
	# Higher while the crew work at it, so the tag never covers them.
	var busy := false
	for c: Node3D in view._crew:
		busy = busy or (c.visible and Vector2(c.position.x - base.x, c.position.z - base.z).length() < 1.6)
	var at := _on_screen(base + Vector3(0, 2.9 if busy else 1.9, 0))
	if at == OFF:
		return
	var font := FxSkin.numbers()
	var px := int(clampf(m * 0.36, 26.0, 64.0))
	var words := Strings.t("BUILDER_TOOL_VAULT").to_upper()
	var w := font.get_string_size(words, HORIZONTAL_ALIGNMENT_CENTER, -1, px).x + px
	var open: bool = v.get("open", false)
	var plate := Rect2(at - Vector2(w * 0.5, px * 0.8), Vector2(w, px * 1.25))
	_vault_plate = plate
	# The design's tag: a gold plate with ink words; once open, cream rimmed
	# in green, its cracking bar gone.
	var box := StyleBoxFlat.new()
	box.bg_color = FxSkin.PARCH_TOP if open else FxSkin.GOLD
	box.border_color = FxSkin.SUCCESS.darkened(0.3) if open else FxSkin.INK_LINE
	box.set_border_width_all(maxi(2, int(px * (0.14 if open else 0.09))))
	box.set_corner_radius_all(int(px * 0.4))
	box.shadow_color = Color(0, 0, 0, 0.3)
	box.shadow_size = 4
	box.shadow_offset = Vector2(0, 3)
	FxPen.style_box(self, box, plate)
	FxPen.string(self, font, Vector2(plate.position.x, plate.position.y + px * 0.98), words, HORIZONTAL_ALIGNMENT_CENTER,
		plate.size.x, px, FxSkin.PARCH_INK)
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
			FxPen.circle(self, at + Vector2(0, h * 0.5), h * 0.95, FxSkin.INK_LINE)
			FxPen.circle(self, at + Vector2(0, h * 0.5), h * 0.7, pip)
		var bag := float(mem["carried"]) / maxf(1.0, float(mem["carry"]))
		if bag > 0.0:
			FxIcons.bar(self, Rect2(at + Vector2(-w * 0.5 + h, y), Vector2(w - h, h * 0.8)), bag, FxSkin.GOLD)
			FxIcons.coin(self, at + Vector2(-w * 0.5 + h * 0.3, y + h * 0.4), h * 0.7)
		if i == chosen and not down:
			var bob := 0.0 if calm else absf(sin(_time * 3.2)) * w * 0.08
			var tip := at + Vector2(0, -h * 0.6 - bob)
			var tri := PackedVector2Array([tip, tip + Vector2(-w * 0.16, -w * 0.18), tip + Vector2(w * 0.16, -w * 0.18)])
			FxPen.polygon(self, PackedVector2Array([tri[0] + Vector2(0, 3), tri[1] + Vector2(-3, -2),
				tri[2] + Vector2(3, -2)]), FxSkin.INK_LINE)
			FxPen.polygon(self, tri, FxSkin.GOLD)
		if view.in_sight.has(i):
			# In a guard's sight: an eye beside the head, blinking open.
			var blink := 1.0 if calm else 0.85 + 0.15 * absf(sin(_time * 4.0))
			FxIcons.eye(self, at + Vector2(w * 0.62 * side, -h * 0.2), w * 0.55 * blink)
		if names_for > 0.0:
			_name_tag(at + Vector2(0, -w * 0.45), Strings.term("ROLE", str(mem["role"])))


## A round pip filled to `share` from the bottom up, in `colour` on white.
func _pip(at: Vector2, r: float, share: float, colour: Color) -> void:
	FxPen.circle(self, at, r + maxf(2.0, r * 0.25), FxSkin.INK_LINE)
	FxPen.circle(self, at, r, Color.WHITE)
	if share <= 0.0:
		return
	if share >= 1.0:
		FxPen.circle(self, at, r, colour)
		return
	# The filled part: the circle's segment below the line at `share` of its
	# height, its arc closed by the chord.
	var a0 := asin(clampf(1.0 - 2.0 * share, -1.0, 1.0))
	var pts := PackedVector2Array()
	for k in 17:
		var a := lerpf(a0, PI - a0, k / 16.0)
		pts.append(at + Vector2(cos(a), sin(a)) * r)
	FxPen.polygon(self, pts, colour.darkened(0.12) if colour == Color.WHITE else colour)


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
	FxPen.style_box(self, box, r)
	FxPen.string(self, font, Vector2(r.position.x, r.position.y + px * 0.98), words, HORIZONTAL_ALIGNMENT_CENTER,
		r.size.x, px, FxSkin.ON_DARK)


func _stars(at: Vector2, s: float, calm: bool) -> void:
	var turn := 0.0 if calm else _time * 2.4
	for k in 3:
		var a := turn + TAU * k / 3.0
		var p := at + Vector2(cos(a) * s * 0.45, sin(a) * s * 0.16 - s * 0.1)
		FxIcons.star(self, p, s * 0.14, Color("#FFE27A"), turn * 2.0)


## A guard has come to `state`: it says so, if §12.16 gives it words.
func say(guard: int, state: String) -> void:
	if SAYS.has(state):
		speech[guard] = {"text": Strings.t(SAYS[state]), "t": 0.0, "alarm": state == "Alerted"}


## The guards' words on the screen's layer above its panels.
func _draw_speech_layer() -> void:
	if not _said_up or not is_visible_in_tree() or wipe > 0.0:
		return
	_pen(speech_layer, _paint_speech.bind(speech_layer, _said))


## `box` moved up or down off the screen's panels (keep_off, keep_soft) to the nearest
## place on screen clear of them, within a few lines of where it was said.
## Where there is none, it goes where it covers the least of them (in a gap
## narrower than itself, its middle), and the speech layer draws it above the
## panels, so it is never clipped.
func _off_panels(box: Rect2, px: float) -> Rect2:
	if not keep_off.is_valid():
		return box
	var hard: Array = keep_off.call()
	var soft: Array = keep_soft.call() if keep_soft.is_valid() else []
	var panels: Array = hard + soft
	var cover := func(b: Rect2) -> float:
		var sum := 0.0
		for i in panels.size():
			var r: Rect2 = panels[i]
			if b.grow(px * 0.1).intersects(r):
				sum += b.grow(px * 0.1).intersection(r).get_area() * (1.0 if i < hard.size() else 0.25)
		return sum
	if cover.call(box) == 0.0:
		return box
	var ys: Array[float] = [box.position.y]
	for r: Rect2 in panels:
		ys.append(r.position.y - box.size.y - px * 0.2)
		ys.append(r.end.y + px * 0.2)
		for q: Rect2 in panels:
			if q.position.y > r.end.y:
				ys.append((r.end.y + q.position.y - box.size.y) * 0.5)
	# Beside a hard panel too (a portrait in the tray), not only above or
	# below one.
	var xs: Array[float] = [box.position.x]
	for r: Rect2 in hard:
		xs.append(r.position.x - box.size.x - px * 0.2)
		xs.append(r.end.x + px * 0.2)
	var best := box
	var least: float = cover.call(box)
	var far := INF
	for x: float in xs:
		if x < px * 0.2 or x + box.size.x > size.x - px * 0.2:
			continue
		for y: float in ys:
			var b := Rect2(Vector2(x, y), box.size)
			var away := absf(y - box.position.y) + absf(x - box.position.x) * 0.5
			if y < px * 0.2 or b.end.y > size.y - px * 0.2 or absf(y - box.position.y) > px * 6.0:
				continue
			var c: float = cover.call(b)
			if c < least or (c == least and away < far):
				least = c
				far = away
				best = b
	return best


## Each control's rect in `layer`'s pixels (a portrait's as it draws, its
## tag included), for keep_off and keep_soft.
static func rects_of(controls: Array, layer: Control) -> Array:
	var out: Array = []
	for c: Variant in controls:
		var ctl := c as Control
		if ctl != null and ctl.is_visible_in_tree() and ctl.size.x > 0.0:
			var r: Rect2 = ctl.call("drawn_rect") if ctl.has_method("drawn_rect") else ctl.get_global_rect()
			r.position -= layer.global_position
			out.append(r)
	return out


## The words of every label under `roots`, each as its lines stand in the
## label (not the label's whole rect), in `layer`'s pixels.
static func words_in(roots: Array, layer: Control) -> Array:
	var out: Array = []
	for root: Control in roots:
		for l: Label in root.find_children("*", "Label", true, false):
			if l.is_visible_in_tree() and l.text != "":
				var r := words_rect(l)
				r.position -= layer.global_position
				out.append(r)
	return out


## Where a label's words stand on screen: as wide as its widest line (wrapped
## at its width where it wraps), placed by its alignment, as tall as it is.
static func words_rect(l: Label) -> Rect2:
	var at := l.get_global_rect()
	var wraps := l.autowrap_mode != TextServer.AUTOWRAP_OFF
	var wide := l.get_theme_font("font").get_multiline_string_size(l.text, HORIZONTAL_ALIGNMENT_LEFT,
		at.size.x if wraps else -1.0, l.get_theme_font_size("font_size")).x
	wide = minf(wide, at.size.x)
	var x := at.position.x
	if l.horizontal_alignment == HORIZONTAL_ALIGNMENT_CENTER:
		x += (at.size.x - wide) * 0.5
	elif l.horizontal_alignment == HORIZONTAL_ALIGNMENT_RIGHT:
		x += at.size.x - wide
	elif l.horizontal_alignment == HORIZONTAL_ALIGNMENT_FILL:
		wide = at.size.x
	return Rect2(x, at.position.y, wide, at.size.y)


## The screen's panels, keep_off's and keep_soft's together.
func _all_panels() -> Array:
	var out: Array = keep_off.call() if keep_off.is_valid() else []
	if keep_soft.is_valid():
		out.append_array(keep_soft.call())
	return out


## Whether `box` lies over one of the screen's panels (keep_off, keep_soft).
func _covers_panel(box: Rect2, px: float) -> bool:
	for r: Rect2 in _all_panels():
		if box.grow(px * 0.1).intersects(r as Rect2):
			return true
	return false


## Whether `at` lies under one of the screen's panels (keep_off, keep_soft).
func _under_panel(at: Vector2) -> bool:
	for r: Rect2 in _all_panels():
		if (r as Rect2).has_point(at):
			return true
	return false


## One callout at a time, as the design keeps the middle calm: the most
## urgent state said, the newest of those; the others' pips still say
## theirs: each one's bubble placed, `over` where it lies over a panel.
func _speech_items(replay: RulebornReplay, m: float, calm: bool) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var nodes: Array[Node3D] = view._guards
	var font := FxSkin.words()
	var px := int(clampf(m * 0.36, 34.0, 46.0))
	var placed: Array[Rect2] = []
	speech_boxes = placed
	for i: int in _speaker():
		if i >= nodes.size() or i >= replay.guards().size():
			continue
		var head := _on_screen(nodes[i].position + Vector3(0, float(nodes[i].get_meta("head", 1.2)), 0))
		if head == OFF:
			continue
		var t := float(speech[i]["t"])
		var a := clampf((SAY_SECONDS - t) / 0.3, 0.0, 1.0)
		var grow := 1.0 if calm else minf(1.0, 0.6 + t * 4.0)
		var words := str(speech[i]["text"])
		var w := font.get_string_size(words, HORIZONTAL_ALIGNMENT_LEFT, -1, px).x
		var size := Vector2(w + px * 1.0, px * 1.5) * grow
		var side := 1.0 if head.x < size.x + px * 2.0 or head.x < get_viewport_rect().size.x * 0.5 else -1.0
		var corner := head + Vector2(side * px * 0.9, -px * 2.4)
		var box := Rect2(corner - Vector2(0.0 if side > 0.0 else size.x, size.y * 0.5), size)
		# Over the numbers rising nearby, clear of where they climb, so
		# neither covers the other.
		for r: Rect2 in _pop_rects(m, calm):
			if box.grow(px * 0.2).intersects(r):
				box.position.y = r.position.y - size.y - px * 0.2
		# Above the VAULT tag, never across it.
		if _vault_plate.has_area() and box.grow(px * 0.1).intersects(_vault_plate):
			box.position.y = _vault_plate.position.y - size.y - px * 0.2
		# And over another guard's words said nearby, rather than across them.
		for other: Rect2 in placed:
			if box.grow(px * 0.1).intersects(other):
				box.position.y = other.position.y - size.y - px * 0.2
		box.position.x = clampf(box.position.x, px * 0.2, get_viewport_rect().size.x - size.x - px * 0.2)
		box.position.y = maxf(box.position.y, px * 0.2)
		# Off the screen's panels where the world has room for it.
		box = _off_panels(box, px)
		placed.append(box)
		var tail := PackedVector2Array([box.get_center() + Vector2(-side * size.x * 0.25, size.y * 0.3),
			box.get_center() + Vector2(-side * size.x * 0.05, size.y * 0.3), head + Vector2(side * px * 0.2, -px * 0.3)])
		# No tail into a panel: a guard behind one says its words from the
		# nearest clear place, with no point reaching across the panel.
		var under := _under_panel(head)
		out.append({"i": i, "box": box, "tail": PackedVector2Array() if under else tail, "a": a,
			"grow": grow, "words": words, "px": px, "over": under or _covers_panel(box, px)})
	return out


## The guards' bubbles (_speech_items) drawn on `ci`: this layer, or the
## screen's speech layer.
func _paint_speech(ci: CanvasItem, items: Array[Dictionary]) -> void:
	var font := FxSkin.words()
	for it: Dictionary in items:
		var i: int = it["i"]
		var box: Rect2 = it["box"]
		var size := box.size
		var tail: PackedVector2Array = it["tail"]
		var a: float = it["a"]
		var px: int = it["px"]
		var words: String = it["words"]
		# An alert is said in paper on §21.8's alarm fill; the rest on parchment.
		var fill := FxSkin.ALARM_DEEP if speech[i].get("alarm", false) else FxSkin.PARCH_TOP
		var ink := FxSkin.PARCH_TOP if speech[i].get("alarm", false) else FxSkin.PARCH_INK
		var bubble := StyleBoxFlat.new()
		bubble.bg_color = Color(fill, a)
		bubble.border_color = Color(FxSkin.INK_LINE, a)
		bubble.set_border_width_all(maxi(2, UI.px(1.5)))
		bubble.set_corner_radius_all(int(size.y * 0.5))
		bubble.shadow_color = Color(0.05, 0.02, 0.08, 0.3 * a)
		bubble.shadow_size = 4
		if not tail.is_empty():
			FxPen.polygon(ci, _grown(tail, 3.0), Color(FxSkin.INK_LINE, a))
		FxPen.style_box(ci, bubble, box)
		if not tail.is_empty():
			FxPen.polygon(ci, tail, Color(fill, a))
		if float(it["grow"]) >= 1.0:
			FxPen.string(ci, font, Vector2(box.position.x, box.position.y + size.y * 0.5 + px * 0.36), words,
				HORIZONTAL_ALIGNMENT_CENTER, box.size.x, px, Color(ink, a))


## Which guard's words are on show: the most urgent state said (an alert
## first), the newest of those; none when none is speaking.
func _speaker() -> Array[int]:
	var best := -1
	var rank := -1
	var age := 0.0
	for i: int in speech:
		var calm_words := str(speech[i]["text"]) == Strings.t(SAYS["Returning"])
		var r := 2 if speech[i].get("alarm", false) else (0 if calm_words else 1)
		var t := float(speech[i]["t"])
		if r > rank or (r == rank and t < age):
			best = i
			rank = r
			age = t
	return [] if best < 0 else [best]


## A rising number's size in pixels: small, a figure's head or so (§21.8's
## calm middle).
static func _pop_px(m: float) -> float:
	return clampf(m * 0.36, 26.0, 46.0)


## A triangle grown outward by `by` pixels round its middle: its ink edge.
static func _grown(tri: PackedVector2Array, by: float) -> PackedVector2Array:
	var mid := (tri[0] + tri[1] + tri[2]) / 3.0
	var out := PackedVector2Array()
	for p in tri:
		out.append(p + (p - mid).normalized() * by)
	return out


## The column each rising number climbs through in its life, as
## `_draw_pops` places it: a bubble kept above it stays put.
func _pop_rects(m: float, calm: bool) -> Array[Rect2]:
	var out: Array[Rect2] = []
	var font := FxSkin.numbers()
	for p in pops:
		var at := _on_screen(p["at"])
		if at == OFF:
			continue
		var px := _pop_px(m) * 1.2
		var w := font.get_string_size(str(p["text"]), HORIZONTAL_ALIGNMENT_LEFT, -1, int(px)).x + px
		var rise := 0.0 if calm else m * 0.6
		at += Vector2(m * 0.55, -m * 0.2)
		out.append(Rect2(at + Vector2(-w * 0.5, -rise - px), Vector2(w, rise + px * 1.3)))
	return out


func _draw_pops(m: float, calm: bool) -> void:
	var font := FxSkin.numbers()
	for p in pops:
		var t := float(p["t"]) / POP_SECONDS
		var at := _on_screen(p["at"])
		if at == OFF:
			continue
		var rise := 0.0 if calm else t * m * 0.6
		var px := int(_pop_px(m) * (1.0 + (0.0 if calm else 0.2 * maxf(0.0, 1.0 - t * 4.0))))
		var a := 1.0 if t < 0.55 else 1.0 - (t - 0.55) / 0.45
		# Beside the figure, never over it: up and to its right.
		var pos := at + Vector2(m * 0.55, -m * 0.2 - rise)
		var words := str(p["text"])
		var w := font.get_string_size(words, HORIZONTAL_ALIGNMENT_LEFT, -1, px).x
		var icon := str(p["icon"])
		var x := pos.x - w * 0.5 + (px * 0.35 if icon != "" else 0.0)
		if icon == "coin":
			FxIcons.coin(self, Vector2(x - px * 0.45, pos.y - px * 0.32), px * 0.32)
		elif icon == "star":
			FxIcons.star(self, Vector2(x - px * 0.45, pos.y - px * 0.32), px * 0.36, Color("#FFE27A"))
		var colour: Color = p["colour"]
		FxPen.string_outline(self, font, Vector2(x, pos.y), words, HORIZONTAL_ALIGNMENT_LEFT, -1, px, maxi(6, px / 5),
			Color(FxSkin.INK_LINE, a))
		FxPen.string(self, font, Vector2(x, pos.y), words, HORIZONTAL_ALIGNMENT_LEFT, -1, px, Color(colour, a))
