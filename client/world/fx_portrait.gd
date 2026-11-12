class_name FxPortrait
extends Button
## A crew member's portrait in the heist's row (§21.8: "crew portraits at the
## bottom left"), as the design's heist draws it: the member's own character,
## rendered from its model (T1's `Portrait`), filling a disc of its school's
## colour inside an ink and gold-brown ring; its ability's two pips on a dark
## tag at the top right with the number of uses left (§21.8, 12.6); a health
## bar beneath and its name under that. The role is said in the name a screen
## reader hears, and a crew member played by role alone (no kind in the
## manifest) shows its role's letters as its name. The chosen one is ringed
## in gold, glows and is lifted; one that is down flashes red, one caught is
## grey; an ability armed to aim rings it in white. A tap chooses it.

## §12.6: every ability has two uses a heist; the pips show what is left.
const PIPS := 2
## The mat between the ring and the portrait (stage_hero_sculpt's cream).
const MAT := Color("#F6E6C8")
## A digit's strokes, as fractions of its cell: (x0, y0, x1, y1) each.
const SEGMENTS := {0: [[0, 0, 1, 0], [1, 0, 1, 1], [1, 1, 0, 1], [0, 1, 0, 0]], 1: [[0.5, 0, 0.5, 1]],
	2: [[0, 0, 1, 0], [1, 0, 1, 0.5], [1, 0.5, 0, 0.5], [0, 0.5, 0, 1], [0, 1, 1, 1]],
	3: [[0, 0, 1, 0], [1, 0, 1, 1], [0, 0.5, 1, 0.5], [0, 1, 1, 1]], 4: [[0, 0, 0, 0.5], [0, 0.5, 1, 0.5],
	[1, 0, 1, 1]], 5: [[1, 0, 0, 0], [0, 0, 0, 0.5], [0, 0.5, 1, 0.5], [1, 0.5, 1, 1], [1, 1, 0, 1]],
	6: [[1, 0, 0, 0], [0, 0, 0, 1], [0, 1, 1, 1], [1, 1, 1, 0.5], [1, 0.5, 0, 0.5]], 7: [[0, 0, 1, 0], [1, 0, 1, 1]],
	8: [[0, 0, 1, 0], [1, 0, 1, 1], [1, 1, 0, 1], [0, 1, 0, 0], [0, 0.5, 1, 0.5]],
	9: [[1, 0.5, 0, 0.5], [0, 0.5, 0, 0], [0, 0, 1, 0], [1, 0, 1, 1], [1, 1, 0, 1]]}
## How far the disc stands off the figure, in CIE L* (AD-R13 asks 20 or more).
const VALUE_STEP := 30.0
## The figures painted flat (AD-R17): a grained or glassy model (a Bramble's
## furred shell, a Hollow's faceted glass) minifies into mottle at a
## portrait's size, so these are filled in three tones of their own colour,
## lit from the upper left as the toon models are, with only their strong
## marks (eyes, gems, an emblem) kept. "crop" is the bust's part shown, as
## (centre x, centre y, radius) of its side; a tall figure is framed head
## and shoulders, as a Mo is, so its disc shows round its head. "form" is
## how much the light on the silhouette's swell weighs against the model's
## own (0.65 unless given); a faceted figure leans on the swell, since its
## own light is all facets.
const TOON := {"quarryback": {}, "glass_golem": {"crop": Vector3(0.5, 0.32, 0.32), "form": 0.85}}
## The bust's part every other portrait shows (`_disc_uv`'s).
const CROP := Vector3(0.5, 0.44, 0.42)
## The composed portraits, by kind, school and pixel size, and what each
## measured: {key: {"figure": L*, "disc": L*, "least": L*}} (the gate's notes).
static var measured := {}
static var _composed := {}

var role := ""
## Its kind (`RulebornReplay.crew()`'s, from the manifest), "" when played by
## role; and the name shown under it.
var kind := ""
var letters := ""
var chosen := false
var health := 1.0
var carried := 0.0
var standing := "Active"
## Ability uses left and whether it is one of the ready ones (12.6); -1 uses
## for a member with no ability (no kind), which shows no pips.
var uses := -1
var is_ready := true
var armed := false
## The portrait rendered from the character model, when the build has it;
## else the drawn face. `figure()` is the model alone on a clear ground; once
## it is drawn, `picture` is the figure set on its own disc (`compose`).
var picture: Texture2D
## Whether the build has the model's bust. The bust itself stays in
## CreatureBust's cache and is only read to compose, so the portrait holds
## one texture, its composed disc, at the size it is drawn.
var _has_figure := false
var _time := 0.0
var _picture_ready := false


func _init(member_role := "", pressed_call: Callable = Callable(), member_kind := "", shown_name := "") -> void:
	role = member_role
	kind = member_kind
	if kind == "" and Cast.KIND.has(role):
		kind = String(Cast.KIND[role])
	letters = shown_name if shown_name != "" else Strings.term("ROLE", role)
	if kind != "" and CreatureModel.manifest().has(kind.replace("_", "")):
		# T1's bust: the head and body alone, set on its disc by `compose`.
		_has_figure = true
		CreatureBust.of(kind, "", Color(0, 0, 0, 0))
	text = ""
	var side := UI.px(50)
	# As wide as its name, so with large text names never run together.
	var name_w := FxSkin.words().get_string_size(letters, HORIZONTAL_ALIGNMENT_LEFT, -1, UI.text_px(13.0)).x
	# At 100% a name may reach a little past its disc, as the design's do, so
	# five fit beside the hand; with large text names keep apart.
	var spare := UI.px(4) if Settings.text_scale > 100 else -UI.px(4)
	# As tall as its disc, its bar and its name at the player's text size,
	# so a second row of portraits never lies over a name.
	custom_minimum_size = Vector2(maxf(side, name_w + spare), side + UI.px(15) + ceilf(UI.text_px(13.0) * 1.35))
	focus_mode = Control.FOCUS_ALL
	var clear := StyleBoxFlat.new()
	# A dark fill, so a screen's checks find what is behind its words.
	clear.bg_color = Color(FxSkin.CARD_BOTTOM, 0.01)
	for state: String in ["normal", "hover", "pressed", "focus", "disabled"]:
		add_theme_stylebox_override(state, clear)
	add_theme_color_override("font_color", FxSkin.ON_DARK)
	if pressed_call.is_valid():
		pressed.connect(func() -> void: Haptics.play("tap"))
		pressed.connect(pressed_call)
	button_down.connect(func() -> void: pivot_offset = size / 2.0; scale = Vector2(0.94, 0.94))
	button_up.connect(func() -> void: scale = Vector2.ONE)


func show_member(m: Dictionary, is_chosen: bool) -> void:
	chosen = is_chosen
	health = clampf(float(m.get("health", 0)) / maxf(1.0, float(m.get("max_health", m.get("health", 1)))), 0.0, 1.0)
	carried = float(m.get("carried", 0)) / maxf(1.0, float(m.get("carry", 1)))
	standing = str(m.get("standing", "Active"))
	uses = int(m.get("uses", 0)) if str(m.get("kind", "")) != "" else -1
	is_ready = bool(m.get("ready", true))
	queue_redraw()


## Whether a rendered portrait has been drawn yet (it fills in a frame or
## two after it is asked for).
static func _drawn(t: Texture2D) -> bool:
	return t.get_image() != null and not t.get_image().is_invisible()


## The model alone on a clear ground, from CreatureBust's cache; null when
## the build has no model for this kind.
func figure() -> Texture2D:
	return CreatureBust.of(kind, "", Color(0, 0, 0, 0)) if _has_figure else null


func _process(delta: float) -> void:
	if _has_figure and size.y > 0.0 and Engine.get_process_frames() % 10 == 0 and _drawn(figure()):
		var side := ceili(_radius() * 0.79 * 2.0)
		var key := "%s/%s/%d" % [kind, school_ground().to_html(), side]
		if not _picture_ready or picture != _composed.get(key):
			if not _composed.has(key):
				_composed[key] = compose(figure().get_image(), school_ground(), side, key, kind)
			picture = _composed[key]
			_picture_ready = true
			queue_redraw()
	if standing != "Active" or chosen or armed:
		_time += delta
		queue_redraw()


func _draw() -> void:
	# Every shape in one call (FxPen); the portrait and the words after.
	FxPen.begin(self)
	_paint()
	FxPen.end(self)


## The disc's radius at the portrait's size.
func _radius() -> float:
	return minf(UI.px(25), size.y - UI.px(32))


## Its school's colour (its role's when played by role alone).
func school_ground() -> Color:
	return Palette.SCHOOL.get(StageHeroFigure.school(kind), Palette.ROLE.get(role, Palette.STONE)) \
		if kind != "" else Palette.ROLE.get(role, Palette.STONE)


func _paint() -> void:
	var w := size.x
	var r := _radius()
	var c := Vector2(w * 0.5, r + UI.px(2))
	var out := standing in ["Out", "Gone", "Caught"]
	var down := standing != "Active" and not out
	if chosen:
		c.y -= UI.px(3)
	# The drop, a glow when chosen, the ink edge and the gold-brown ring.
	FxPen.circle(self, c + Vector2(0, UI.px(3)), r * 1.02, Color(0.05, 0.0, 0.1, 0.45))
	if chosen:
		FxPen.circle(self, c, r * 1.16, Color(FxSkin.GOLD, 0.4))
	if armed:
		var beat := 0.5 + 0.5 * sin(_time * 6.0) if not Settings.reduced_motion else 1.0
		FxPen.circle(self, c, r * 1.2, Color(1, 1, 1, 0.35 + 0.4 * beat))
	# The ring, then a cream mat inside it, outlined in ink both sides: the
	# value step that parts a dark portrait (a Hollow, a Bramble) from the
	# dark ring and the dark tray.
	var rim: Color = FxSkin.GOLD if chosen else Color("#8A5A22")
	var rings := [[1.0, FxSkin.INK_LINE], [0.93, rim], [0.885, FxSkin.INK_LINE], [0.86, MAT], [0.815, FxSkin.INK_LINE]]
	for ring: Array in rings:
		FxPen.circle(self, c, r * float(ring[0]), ring[1])
	# The disc: its school's colour, lighter at the middle, as the design's.
	var ground := school_ground()
	if out:
		ground = Color("#5A5468")
	elif down:
		ground = FxSkin.ALARM_DEEP if fmod(_time, 1.0) < 0.5 or Settings.reduced_motion else FxSkin.ALARM_DEEP.darkened(0.25)
	var inner := r * 0.79
	for step: Array in [[0.0, 1.0, -0.12], [0.12, 0.78, 0.12], [0.22, 0.48, 0.3]]:
		var tone := ground.darkened(-step[2]) if step[2] < 0.0 else ground.lightened(step[2])
		FxPen.circle(self, c + Vector2(0, -inner * step[0]), inner * step[1], tone)
	if _picture_ready:
		# The model's head and shoulders filling the disc, cut to its round.
		var tint := Color(0.55, 0.55, 0.6) if out else (Color(1.0, 0.72, 0.72) if down else Color.WHITE)
		FxPen.flush(self)
		draw_colored_polygon(_disc(c, inner), tint, _disc_uv(0.5, 0.5, 0.5), picture)
	else:
		FxIcons.face(self, c + Vector2(0, r * 0.12), r * 0.6, ground if not out else Color("#7A7488"), role,
			down or out)
	# A gloss on the ring's upper left.
	FxPen.arc(self, c, r * 0.9, PI * 1.05, PI * 1.45, 10, Color(1, 1, 1, 0.35), UI.px(2))
	# The bag, at the lower left, when it holds anything.
	if carried > 0.0:
		FxIcons.sack(self, c + Vector2(-r * 0.78, r * 0.6), r * 0.5, carried)
	# Its school's mark at the lower right, a shape of its own (the gate's
	# colour roles: the rings are never told apart by their hue alone).
	if kind != "" and not out:
		var at := c + Vector2(r * 0.74, r * 0.66)
		for coat: Array in [[r * 0.36, FxSkin.INK_LINE], [r * 0.26, ground.lightened(0.45)]]:
			FxPen.polygon(self, mark(StageHeroFigure.school(kind), at, coat[0]), coat[1])
	var tag := c + Vector2(r * 0.36, -r * 0.9)
	if uses >= 0:
		_pips(tag, r)
	# The health bar beneath: green, amber, red as it falls.
	var bar := Rect2(Vector2(w * 0.5 - r * 0.98, c.y + r + UI.px(5)), Vector2(r * 1.96, UI.px(8)))
	FxIcons.bar(self, bar, health, FxSkin.SUCCESS if health > 0.5 else (FxSkin.GOLD if health > 0.25 else FxSkin.ALARM))
	# The words last, together, so the shapes above go as one draw.
	if uses >= 0:
		_pips_number(tag, r)
	# Its name under the bar, ink-outlined, centred on the portrait.
	var font := FxSkin.words()
	var px := UI.text_px(13.0)
	var wide := font.get_string_size(letters, HORIZONTAL_ALIGNMENT_LEFT, -1, px).x
	var base := Vector2(w * 0.5 - wide * 0.5, bar.end.y + px * 1.05)
	FxPen.string_outline(self, font, base, letters, HORIZONTAL_ALIGNMENT_LEFT, -1, px, UI.px(4), FxSkin.INK_LINE)
	FxPen.string(self, font, base, letters, HORIZONTAL_ALIGNMENT_LEFT, -1, px, FxSkin.GOLD if chosen else FxSkin.ON_DARK)


## The ability's tag: a dark pill with two diamonds, filled for each use
## left (dimmed while it waits its turn to be ready), and the number left.
func _pips(at: Vector2, r: float) -> void:
	var h := r * 0.62
	var pill := Rect2(at - Vector2(h * 1.5, h * 0.5), Vector2(h * 3.0, h))
	var box := StyleBoxFlat.new()
	box.bg_color = FxSkin.INK_LINE
	box.set_corner_radius_all(int(h * 0.5))
	FxPen.style_box(self, box, pill.grow(UI.px(1)))
	box.bg_color = Color("#2A1E40")
	FxPen.style_box(self, box, pill)
	for i in PIPS:
		var p := pill.position + Vector2(h * (0.56 + 0.78 * i), h * 0.5)
		var d := h * 0.4
		var shape := PackedVector2Array([p + Vector2(0, -d), p + Vector2(d, 0), p + Vector2(0, d), p + Vector2(-d, 0)])
		var full := i < uses
		var lit := Color(FxSkin.PARCH_TOP, 1.0 if is_ready else 0.55)
		FxPen.polygon(self, shape, lit if full else Color(FxSkin.ON_DARK_SOFT, 0.25))


## §21.8 (12.6): the pips carry the number too, so uses never rest on shape.
## Drawn as strokes, with the shapes, so it costs no draw of its own.
func _pips_number(at: Vector2, r: float) -> void:
	var h := r * 0.62
	var pill := Rect2(at - Vector2(h * 1.5, h * 0.5), Vector2(h * 3.0, h))
	var cell := Rect2(pill.position + Vector2(h * 2.08, h * 0.2), Vector2(h * 0.4, h * 0.6))
	var ink := maxf(1.5, h * 0.16)
	for seg: Array in SEGMENTS.get(mini(uses, 9), []):
		var a: Vector2 = cell.position + cell.size * Vector2(seg[0], seg[1])
		var b: Vector2 = cell.position + cell.size * Vector2(seg[2], seg[3])
		FxPen.line(self, a, b, FxSkin.GOLD, ink)


## A school's mark as a polygon of radius `r` at `at`, each school its own
## shape: motion a triangle pointing on, matter a square, time an hourglass,
## energy a diamond, life a round, spirit a star.
static func mark(school: String, at: Vector2, r: float) -> PackedVector2Array:
	var unit: Array = {
		"motion": [[-0.8, -1], [1, 0], [-0.8, 1]],
		"matter": [[-0.85, -0.85], [0.85, -0.85], [0.85, 0.85], [-0.85, 0.85]],
		"time": [[-0.9, -1], [0.9, -1], [0.18, 0], [0.9, 1], [-0.9, 1], [-0.18, 0]],
		"energy": [[0, -1.1], [0.8, 0], [0, 1.1], [-0.8, 0]],
	}.get(school, [])
	var pts := PackedVector2Array()
	if school == "spirit":
		for i in 10:
			var a := -PI / 2.0 + TAU * i / 10.0
			pts.append(at + Vector2(cos(a), sin(a)) * r * (1.1 if i % 2 == 0 else 0.48))
	elif unit.is_empty():
		for i in 16:
			pts.append(at + Vector2(cos(TAU * i / 16.0), sin(TAU * i / 16.0)) * r * 0.9)
	for u: Array in unit:
		pts.append(at + Vector2(u[0], u[1]) * r)
	return pts


## A disc's outline as a polygon, and its texture coordinates: the upper
## part of the rendered portrait, its head and shoulders, as the design's.
static func _disc(c: Vector2, r: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in 40:
		var a := TAU * i / 40.0
		pts.append(c + Vector2(cos(a), sin(a)) * r)
	return pts


static func _disc_uv(x := 0.5, y := 0.44, r := 0.42) -> PackedVector2Array:
	var uv := PackedVector2Array()
	for i in 40:
		var a := TAU * i / 40.0
		uv.append(Vector2(x, y) + Vector2(cos(a), sin(a)) * r)
	return uv


## The portrait as it is drawn, `side` pixels across (AD-R13): the model's
## head and shoulders (the bust's upper part, as `_disc_uv`'s) taken from
## `bust`, a figure on a clear ground, and resampled once to the size it is
## drawn at, so a furred or grained figure (a Bramble) is never minified on
## the screen into noise. Behind it a disc of its school's hue stood
## VALUE_STEP L* off the figure's mean (lighter, unless that would be near
## white), lit at its upper middle; around it an ink silhouette, so a figure
## whose colour is its school's (a Hollow) still parts from its disc. Cut to
## its round. An `of_kind` in TOON is framed and painted flat (`_toon`). Its
## measures go in `measured`, under `key`.
static func compose(bust: Image, school: Color, side: int, key := "", of_kind := "") -> Texture2D:
	var src := bust.duplicate() as Image
	src.convert(Image.FORMAT_RGBA8)
	var n := src.get_width()
	var part: Vector3 = TOON.get(of_kind, {}).get("crop", CROP)
	var corner := Vector2i(roundi(n * (part.x - part.z)), roundi(n * (part.y - part.z)))
	var crop := Rect2i(corner, Vector2i.ONE * roundi(n * part.z * 2.0))
	var img := src.get_region(crop)
	side = maxi(side, 16)
	img.resize(side, side, Image.INTERPOLATE_LANCZOS)
	if TOON.has(of_kind):
		_toon(img, TOON[of_kind].get("form", 0.65))
	var half := side * 0.5
	var centre := Vector2(half, half)
	# The figure's value: its mean L* where it is solid, inside the round.
	var sum := 0.0
	var count := 0
	for y in side:
		for x in side:
			var p := img.get_pixel(x, y)
			if p.a > 0.5 and Vector2(x + 0.5, y + 0.5).distance_to(centre) < half:
				sum += ColourCheck._lab(Color(p, 1.0)).x
				count += 1
	var figure_l := sum / maxf(1.0, count)
	# Lighter where there is room (a pale disc reads as the design's lit
	# one), else darker; the light at the middle and the shade at the rim
	# both lean away from the figure, so the step holds across the disc.
	var lighter := figure_l + VALUE_STEP - 6.0 <= 96.0
	var disc := _at_lightness(school, minf(figure_l + VALUE_STEP, 96.0) if lighter else figure_l - VALUE_STEP)
	var lit := disc.lerp(Color.WHITE, 0.12) if lighter else disc
	var rim := disc.darkened(0.03) if lighter else disc.darkened(0.12)
	# The ink silhouette: the figure's alpha grown by `ink` pixels.
	var ink := maxf(1.5, side / 48.0)
	var reach := ceili(ink)
	var grown := PackedFloat32Array()
	grown.resize(side * side)
	for y in side:
		for x in side:
			var most := 0.0
			for dy in range(-reach, reach + 1):
				var yy := y + dy
				if yy < 0 or yy >= side:
					continue
				for dx in range(-reach, reach + 1):
					var xx := x + dx
					if xx < 0 or xx >= side:
						continue
					var d := sqrt(float(dx * dx + dy * dy))
					if d > ink + 0.5:
						continue
					# Solid figure only: the bust's soft shadow gets no line.
					most = maxf(most, smoothstep(0.4, 0.7, img.get_pixel(xx, yy).a) * clampf(ink + 0.5 - d, 0.0, 1.0))
			grown[y * side + x] = most
	var out := Image.create(side, side, false, Image.FORMAT_RGBA8)
	var light_at := Vector2(half, half * 0.8)
	var disc_sum := 0.0
	var disc_count := 0
	var least := 100.0
	for y in side:
		for x in side:
			var p := Vector2(x + 0.5, y + 0.5)
			var edge := clampf(half - p.distance_to(centre) + 0.5, 0.0, 1.0)
			if edge <= 0.0:
				out.set_pixel(x, y, Color(0, 0, 0, 0))
				continue
			var t := clampf(p.distance_to(light_at) / (half * 1.15), 0.0, 1.0)
			var back := lit.lerp(disc, smoothstep(0.0, 0.7, t)).lerp(rim, smoothstep(0.7, 1.0, t))
			var f := img.get_pixel(x, y)
			if f.a < 0.05:
				var bl := ColourCheck._lab(back).x
				disc_sum += bl
				disc_count += 1
				least = minf(least, absf(bl - figure_l))
			var c := back.lerp(FxSkin.INK_LINE, grown[y * side + x])
			c = c.lerp(Color(f, 1.0), f.a)
			out.set_pixel(x, y, Color(c, edge))
	var disc_l := disc_sum / maxf(1.0, disc_count)
	if key != "":
		measured[key] = {"figure": snappedf(figure_l, 0.1), "disc": snappedf(disc_l, 0.1),
			"step": snappedf(absf(disc_l - figure_l), 0.1), "least": snappedf(least, 0.1)}
	return ImageTexture.create_from_image(out)


## Paints `img`, a figure on a clear ground, flat (AD-R17): solid where it
## is more than half opaque and thicker than a line, clear elsewhere (a
## glass figure's see-through spikes and thin rods go); each solid pixel one
## of three tones of the figure's median colour, chosen by a light from the
## upper left on its silhouette's swell and by the model's own light seen
## broadly (weighed `form` to 1 - `form`), so the grain and the facets'
## glints are gone; and its strong marks, where the figure stands well off
## its broad light (eyes, a gem, an emblem), kept as they are.
static func _toon(img: Image, form: float) -> void:
	var side := img.get_width()
	var count := side * side
	var scale := side / 119.0
	var solid := PackedFloat32Array()
	var lights := PackedFloat32Array()
	var weighted := PackedFloat32Array()
	solid.resize(count)
	lights.resize(count)
	weighted.resize(count)
	var reds := PackedFloat32Array()
	var greens := PackedFloat32Array()
	var blues := PackedFloat32Array()
	for i in count:
		solid[i] = 1.0 if img.get_pixel(i % side, i / side).a > 0.55 else 0.0
	# Thin bits (a Hollow's rods, a whisker) go: what a little blur leaves
	# under half is no body to fill.
	var body := _blur(solid, side, 1.6 * scale)
	for i in count:
		if body[i] < 0.5:
			solid[i] = 0.0
	for i in count:
		var p := img.get_pixel(i % side, i / side)
		if solid[i] > 0.0:
			lights[i] = ColourCheck._lab(Color(p, 1.0)).x
			weighted[i] = lights[i]
			reds.append(p.r)
			greens.append(p.g)
			blues.append(p.b)
	if reds.size() < 16:
		return
	reds.sort()
	greens.sort()
	blues.sort()
	var mid := reds.size() / 2
	var base := Color(reds[mid], greens[mid], blues[mid])
	# The silhouette's swell, its model's light seen broadly (where the
	# figure is), and the light its marks are measured against.
	var swell := _blur(solid, side, 7.0 * scale)
	var mass3 := _blur(solid, side, 3.0 * scale)
	var broad := _blur(weighted, side, 3.0 * scale)
	var mass5 := _blur(solid, side, 5.0 * scale)
	var wide := _blur(weighted, side, 5.0 * scale)
	var sun := Vector3(-0.55, -0.8, 0.6).normalized()
	var reach := 7.0 * scale * 2.5
	var shades := PackedFloat32Array()
	var broads := PackedFloat32Array()
	shades.resize(count)
	broads.resize(count)
	var shade_sum := Vector2.ZERO
	var broad_sum := Vector2.ZERO
	var solid_n := 0.0
	for i in count:
		if solid[i] == 0.0:
			continue
		var x := i % side
		var y := i / side
		var gx := (swell[y * side + mini(x + 1, side - 1)] - swell[y * side + maxi(x - 1, 0)]) * 0.5
		var gy := (swell[mini(y + 1, side - 1) * side + x] - swell[maxi(y - 1, 0) * side + x]) * 0.5
		shades[i] = Vector3(-gx * reach, -gy * reach, 0.6).normalized().dot(sun)
		broads[i] = broad[i] / maxf(mass3[i], 0.001)
		shade_sum += Vector2(shades[i], shades[i] * shades[i])
		broad_sum += Vector2(broads[i], broads[i] * broads[i])
		solid_n += 1.0
	var shade_mean := shade_sum.x / solid_n
	var shade_dev := sqrt(maxf(shade_sum.y / solid_n - shade_mean * shade_mean, 0.0)) + 0.000001
	var broad_mean := broad_sum.x / solid_n
	var broad_dev := sqrt(maxf(broad_sum.y / solid_n - broad_mean * broad_mean, 0.0)) + 0.000001
	var lit := PackedFloat32Array()
	for i in count:
		if solid[i] > 0.0:
			shades[i] = form * (shades[i] - shade_mean) / shade_dev + (1.0 - form) * (broads[i] - broad_mean) / broad_dev
			lit.append(shades[i])
	lit.sort()
	var dark_below := lit[int(lit.size() * 0.22)]
	var light_above := lit[int(lit.size() * 0.85)]
	var tones := [base.darkened(0.2), base, base.lerp(Color.WHITE, 0.26)]
	for i in count:
		var x := i % side
		var y := i / side
		if solid[i] == 0.0:
			img.set_pixel(x, y, Color(0, 0, 0, 0))
			continue
		var own := img.get_pixel(x, y)
		if absf(lights[i] - wide[i] / maxf(mass5[i], 0.001)) > 22.0:
			img.set_pixel(x, y, Color(own, 1.0))
			continue
		var tone: Color = tones[0 if shades[i] < dark_below else (2 if shades[i] >= light_above else 1)]
		img.set_pixel(x, y, Color(tone, 1.0))


## `values` (a `side`-wide square) blurred about as a Gaussian of `sigma`
## pixels would: three box passes each way.
static func _blur(values: PackedFloat32Array, side: int, sigma: float) -> PackedFloat32Array:
	var half := maxi(1, roundi((sqrt(4.0 * sigma * sigma + 1.0) - 1.0) * 0.5))
	var out := values.duplicate()
	for axis in 2:
		for _pass in 3:
			var next := PackedFloat32Array()
			next.resize(out.size())
			for line in side:
				var run := 0.0
				for k in range(-half, half + 1):
					run += out[_at(line, clampi(k, 0, side - 1), side, axis)]
				for j in side:
					next[_at(line, j, side, axis)] = run / (2 * half + 1)
					run += out[_at(line, clampi(j + half + 1, 0, side - 1), side, axis)]
					run -= out[_at(line, clampi(j - half, 0, side - 1), side, axis)]
			out = next
	return out


static func _at(line: int, j: int, side: int, axis: int) -> int:
	return line * side + j if axis == 0 else j * side + line


## `colour`'s hue lightened or darkened until its L* is `l`.
static func _at_lightness(colour: Color, l: float) -> Color:
	var lo := -1.0
	var hi := 1.0
	var c := colour
	for i in 24:
		var mid := (lo + hi) * 0.5
		c = colour.lightened(mid) if mid >= 0.0 else colour.darkened(-mid)
		if ColourCheck._lab(c).x < l:
			lo = mid
		else:
			hi = mid
	return c
