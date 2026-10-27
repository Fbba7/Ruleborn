class_name FxPortrait
extends Button
## A crew member's portrait in the heist's row (§21.8: "crew portraits at the
## bottom left"), as the designs draw it: its face on its role's colour in a
## gold-brown ring, a health bar beneath and its role's name under that, so
## the role never rests on colour (§20.8); its bag's fill as a sack. The
## chosen one is ringed in gold, glows and is lifted; one that is down
## flashes red, one caught is grey. A tap chooses it. Its name for a screen
## reader is set by the screen.

var role := ""
var letters := ""
var chosen := false
var health := 1.0
var carried := 0.0
var standing := "Active"
## The portrait rendered from the role's character model (T1's `Portrait`),
## when the cast has one; else the drawn face.
var picture: Texture2D
var _time := 0.0
var _picture_ready := false


func _init(member_role := "", pressed_call: Callable = Callable()) -> void:
	role = member_role
	letters = Strings.term("ROLE", role)
	if Cast.KIND.has(role) and CreatureModel.manifest().has(String(Cast.KIND[role])):
		picture = Portrait.of(String(Cast.KIND[role]))
	text = ""
	var side := UI.px(54)
	# As wide as its role's name, so with large text names never run together.
	var name_w := FxSkin.words().get_string_size(letters, HORIZONTAL_ALIGNMENT_LEFT, -1, UI.text_px(13.0)).x
	custom_minimum_size = Vector2(maxf(side, name_w + UI.px(4)), side + UI.px(30))
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
	queue_redraw()


## Whether a rendered portrait has been drawn yet (it fills in a frame or
## two after it is asked for).
static func _drawn(t: Texture2D) -> bool:
	return t.get_image() != null and not t.get_image().is_invisible()


func _process(delta: float) -> void:
	if picture != null and not _picture_ready and Engine.get_process_frames() % 10 == 0 and _drawn(picture):
		_picture_ready = true
		queue_redraw()
	if standing != "Active" or chosen:
		_time += delta
		queue_redraw()


func _draw() -> void:
	# Every shape in one call (FxPen).
	FxPen.begin(self)
	_paint()
	FxPen.end(self)


func _paint() -> void:
	var w := size.x
	var r := minf(UI.px(27), size.y - UI.px(30)) * 0.9
	var c := Vector2(w * 0.5, r + UI.px(3))
	var colour: Color = Palette.ROLE.get(role, Palette.STONE)
	var out := standing in ["Out", "Gone", "Caught"]
	var down := standing != "Active" and not out
	var lift := -float(UI.px(3)) if chosen else 0.0
	c.y += lift
	# The drop, a glow when chosen, the ink edge and the gold-brown ring.
	FxPen.circle(self, c + Vector2(0, UI.px(3)), r * 1.02, Color(0.05, 0.0, 0.1, 0.4))
	if chosen:
		FxPen.circle(self, c, r * 1.16, Color(FxSkin.GOLD, 0.35))
	FxPen.circle(self, c, r, FxSkin.INK_LINE)
	FxPen.circle(self, c, r * 0.94, FxSkin.GOLD if chosen else Color("#9A6A2C"))
	# A rendered portrait stands on its role's colour, as the cards put a
	# school-coloured ground behind one.
	var disc := colour.lightened(0.15) if not out else Color("#5A5468")
	if down:
		disc = FxSkin.ALARM_DEEP if fmod(_time, 1.0) < 0.5 or Settings.reduced_motion else FxSkin.ALARM_DEEP.darkened(0.25)
	FxPen.circle(self, c, r * 0.82, disc)
	FxPen.circle(self, c + Vector2(-r * 0.2, -r * 0.3), r * 0.4, Color(1, 1, 1, 0.16))
	if _picture_ready:
		# The model's own head and shoulders, inside the disc; greyed when out.
		var side := r * 1.5
		var tint := Color(0.55, 0.55, 0.6) if out else (Color(1.0, 0.75, 0.75) if down else Color.WHITE)
		FxPen.texture_rect(self, picture, Rect2(c - Vector2(side, side) * 0.5 + Vector2(0, r * 0.08), Vector2(side, side)),
			false, tint)
	else:
		FxIcons.face(self, c + Vector2(0, r * 0.12), r * 0.6, colour if not out else Color("#7A7488"), role, down or out)
	# The bag, at the lower right, when it holds anything.
	if carried > 0.0:
		FxIcons.sack(self, c + Vector2(r * 0.72, r * 0.62), r * 0.55, carried)
	# The health bar beneath: green, amber, red as it falls.
	var bar := Rect2(Vector2(w * 0.5 - r * 0.95, c.y + r + UI.px(4)), Vector2(r * 1.9, UI.px(7)))
	FxIcons.bar(self, bar, health, FxSkin.SUCCESS if health > 0.5 else (FxSkin.GOLD if health > 0.25 else FxSkin.ALARM))
	# Its role's name under the bar, ink-outlined, centred on the portrait.
	var font := FxSkin.words()
	var px := UI.text_px(13.0)
	var wide := font.get_string_size(letters, HORIZONTAL_ALIGNMENT_LEFT, -1, px).x
	var base := Vector2(w * 0.5 - wide * 0.5, bar.end.y + px * 1.05)
	FxPen.string_outline(self, font, base, letters, HORIZONTAL_ALIGNMENT_LEFT, -1, px, UI.px(3), FxSkin.INK_LINE)
	FxPen.string(self, font, base, letters, HORIZONTAL_ALIGNMENT_LEFT, -1, px, FxSkin.GOLD if chosen else FxSkin.ON_DARK)
