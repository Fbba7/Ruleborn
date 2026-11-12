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
## else the drawn face.
var picture: Texture2D
var _time := 0.0
var _picture_ready := false


func _init(member_role := "", pressed_call: Callable = Callable(), member_kind := "", shown_name := "") -> void:
	role = member_role
	kind = member_kind
	if kind == "" and Cast.KIND.has(role):
		kind = String(Cast.KIND[role])
	letters = shown_name if shown_name != "" else Strings.term("ROLE", role)
	if kind != "" and CreatureModel.manifest().has(kind.replace("_", "")):
		# T1's bust: the head and body on a lit disc of the role's colour.
		var ground: Color = Palette.ROLE.get(role, Palette.STONE)
		picture = CreatureBust.of(kind, "", ground.lightened(0.15))
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


func _process(delta: float) -> void:
	if picture != null and not _picture_ready and Engine.get_process_frames() % 10 == 0 and _drawn(picture):
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


func _paint() -> void:
	var w := size.x
	var r := minf(UI.px(25), size.y - UI.px(32))
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
	FxPen.circle(self, c, r, FxSkin.INK_LINE)
	FxPen.circle(self, c, r * 0.93, FxSkin.GOLD if chosen else Color("#8A5A22"))
	FxPen.circle(self, c, r * 0.885, FxSkin.INK_LINE)
	# A cream mat inside the ring, outlined in ink both sides: the value step
	# that parts a dark portrait (a Hollow, a Bramble) from the dark ring
	# and the dark tray.
	FxPen.circle(self, c, r * 0.86, MAT)
	FxPen.circle(self, c, r * 0.815, FxSkin.INK_LINE)
	# The disc: its school's colour, lighter at the middle, as the design's.
	var ground: Color = Palette.SCHOOL.get(StageHeroFigure.school(kind), Palette.ROLE.get(role, Palette.STONE)) \
		if kind != "" else Palette.ROLE.get(role, Palette.STONE)
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
		draw_colored_polygon(_disc(c, inner), tint, _disc_uv(), picture)
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


static func _disc_uv() -> PackedVector2Array:
	var uv := PackedVector2Array()
	for i in 40:
		var a := TAU * i / 40.0
		uv.append(Vector2(0.5, 0.44) + Vector2(cos(a), sin(a)) * 0.42)
	return uv
