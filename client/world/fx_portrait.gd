class_name FxPortrait
extends Button
## A crew member's portrait in the heist's row (§21.8: "crew portraits at the
## bottom left"): its face on its role's colour, a health ring round the edge,
## its bag's fill as a sack, and its role's two letters on a tag beneath, so
## the role never rests on colour (§20.8). The chosen one is ringed in gold
## and lifted; one that is down shows crossed eyes on red, one taken shows
## grey. A tap chooses it. Its name for a screen reader is set by the screen.

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
	letters = Strings.term("ROLE", role).substr(0, 2)
	if Cast.KIND.has(role) and CreatureModel.manifest().has(String(Cast.KIND[role])):
		picture = Portrait.of(String(Cast.KIND[role]))
	text = ""
	var side := UI.CONTROL_POINTS * UI.PX_PER_POINT * 1.2
	custom_minimum_size = Vector2(side, side * 1.12)
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
	var w := size.x
	var r := minf(w, size.y / 1.12) * 0.46
	var c := Vector2(w * 0.5, r + 2.0)
	var colour: Color = Palette.ROLE.get(role, Palette.STONE)
	var out := standing in ["Out", "Gone", "Captured"]
	var down := standing != "Active" and not out
	# The drop shadow and the disc.
	draw_circle(c + Vector2(0, r * 0.1), r * 1.04, Color(0.05, 0.0, 0.1, 0.35))
	var lift := -r * 0.06 if chosen else 0.0
	c.y += lift
	draw_circle(c, r, FxSkin.INK_LINE)
	# A rendered portrait stands on its role's colour, as the cards put a
	# school-coloured ground behind one.
	var disc := colour.darkened(0.2) if _picture_ready and not out else FxSkin.CARD_TOP
	if down:
		disc = FxSkin.ALARM_DEEP if fmod(_time, 1.0) < 0.5 or Settings.reduced_motion else FxSkin.ALARM_DEEP.darkened(0.25)
	draw_circle(c, r * 0.9, disc)
	draw_circle(c + Vector2(0, -r * 0.3), r * 0.55, Color(1, 1, 1, 0.06))
	# The health ring: green, amber, red as it falls; the share is its length.
	var ring_col := FxSkin.SUCCESS if health > 0.5 else (FxSkin.GOLD if health > 0.25 else FxSkin.ALARM)
	draw_arc(c, r * 0.9, -PI / 2.0, -PI / 2.0 + TAU, 48, Color("#2A1E40"), r * 0.14, true)
	if health > 0.0:
		draw_arc(c, r * 0.9, -PI / 2.0, -PI / 2.0 + TAU * health, 48, ring_col, r * 0.14, true)
	var face_col := colour if not out else Color("#7A7488")
	if _picture_ready:
		# The model's own head and shoulders, inside the disc; greyed when out.
		var side := r * 1.62
		var tint := Color(0.55, 0.55, 0.6) if out else (Color(1.0, 0.75, 0.75) if down else Color.WHITE)
		draw_texture_rect(picture, Rect2(c - Vector2(side, side) * 0.5 + Vector2(0, r * 0.05), Vector2(side, side)),
			false, tint)
	else:
		FxIcons.face(self, c + Vector2(0, r * 0.12), r * 0.62, face_col, role, down or out)
	if chosen:
		draw_arc(c, r * 1.02, 0, TAU, 56, FxSkin.GOLD, r * 0.13, true)
		draw_arc(c, r * 1.1, 0, TAU, 56, FxSkin.INK_LINE, r * 0.05, true)
	# The bag, at the lower right, when it holds anything.
	if carried > 0.0:
		FxIcons.sack(self, c + Vector2(r * 0.72, r * 0.62), r * 0.6, carried)
	# The role's letters on their tag.
	var font := FxSkin.words()
	var px := int(r * 0.42)
	var tag_w := font.get_string_size(letters, HORIZONTAL_ALIGNMENT_CENTER, -1, px).x + r * 0.5
	var tag := Rect2(Vector2(w * 0.5 - tag_w * 0.5, c.y + r * 0.72), Vector2(tag_w, px * 1.25))
	var box := StyleBoxFlat.new()
	box.bg_color = FxSkin.GOLD if chosen else FxSkin.CARD_BOTTOM
	box.border_color = FxSkin.INK_LINE
	box.set_border_width_all(2)
	box.set_corner_radius_all(int(px * 0.6))
	draw_style_box(box, tag)
	draw_string(font, Vector2(tag.position.x, tag.position.y + px * 0.98), letters, HORIZONTAL_ALIGNMENT_CENTER,
		tag.size.x, px, FxSkin.PARCH_INK if chosen else FxSkin.ON_DARK)
