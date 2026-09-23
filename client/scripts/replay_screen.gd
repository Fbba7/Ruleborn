class_name ReplayScreen
extends Control
## A heist, replayed: the simulation re-run on the phone from its seed and
## input log, and drawn (§24.1: "the device renders the replay itself").
##
## Laid out as §21.8's heist layout reads — the clock and alarm at the top
## centre, loot at the top right — with the playback controls in the thumb
## zone (§21.1). Each second, the client's checksum is compared with the one the
## replay carries; the badge says whether this phone is showing the heist the
## server validated.

## §21.1: "Primary controls are at least 9 mm across — about 48 points". The
## base frame is 1080 pixels for a 360-point-wide phone, so 3 pixels a point.
const PX_PER_POINT := 3.0
const CONTROL_POINTS := 48.0
## §21.8: body text "at least 16 pixels", nothing smaller than 13 points.
const TEXT_POINTS := 16.0
const SPEEDS := [1, 2, 4, 8]

var replay := RulebornReplay.new()
var goldens: PackedStringArray = []
var current := 0
var playing := true
var speed_index := 1
var _owed := 0.0

var view: RealmView
var clock_label: Label
var alarm_label: Label
var loot_label: Label
var badge_label: Label
var name_label: Label
var grade_label: Label
var play_button: Button
var speed_button: Button


func _ready() -> void:
	goldens = find_goldens()
	_build()
	if goldens.size() > 0:
		open_golden(0)


static func find_goldens() -> PackedStringArray:
	var out: PackedStringArray = []
	var dir := DirAccess.open("res://goldens")
	if dir == null:
		return out
	for f in dir.get_files():
		if f.ends_with(".rbh"):
			out.append(f.get_basename())
	out.sort()
	return out


func open_golden(index: int) -> bool:
	current = posmod(index, goldens.size())
	var bytes := FileAccess.get_file_as_bytes("res://goldens/%s.rbh" % goldens[current])
	var ok := replay.load(bytes, PackedByteArray())
	name_label.text = goldens[current]
	grade_label.text = ""
	_owed = 0.0
	view.show_replay(replay)
	_refresh()
	return ok


## Run `ticks` ticks of the heist, as the playback clock does.
func advance(ticks: int) -> void:
	for i in ticks:
		if not replay.step():
			playing = false
			break
	_refresh()


func _process(delta: float) -> void:
	if not playing or replay.ticks() == 0:
		return
	_owed += delta * RulebornReplay.ticks_per_second() * SPEEDS[speed_index]
	var whole := int(_owed)
	_owed -= whole
	advance(whole)


func _refresh() -> void:
	var tps := RulebornReplay.ticks_per_second()
	var now := replay.tick() / tps
	var total := replay.ticks() / tps
	clock_label.text = "%d:%02d / %d:%02d" % [now / 60, now % 60, total / 60, total % 60]
	var alarm := replay.alarm()
	alarm_label.text = "Alarm %s%s" % ["●".repeat(alarm), "○".repeat(6 - alarm)]
	alarm_label.add_theme_color_override("font_color", Palette.ALARM if alarm > 0 else Palette.INK)
	var carried := 0
	var carry := 0
	for m in replay.crew():
		carried += int(m["carried"])
		carry += int(m["carry"])
	loot_label.text = "Bags %d / %d\nVault %d left" % [carried, carry, int(replay.vault().get("exposed", 0))]
	if replay.mismatch() > 0:
		badge_label.text = "Diverged at %d:%02d" % [replay.mismatch() / 60, replay.mismatch() % 60]
		badge_label.add_theme_color_override("font_color", Palette.ALARM)
	else:
		badge_label.text = "Matches the server: %d s" % replay.seconds_agreed()
		badge_label.add_theme_color_override("font_color", Palette.SUCCESS.darkened(0.3))
	if replay.tick() >= replay.ticks() and replay.ticks() > 0:
		var o := replay.outcome()
		grade_label.text = "%s — %d of %d banked" % [o["grade"], o["banked"], o["capacity"]]
	play_button.text = "Pause" if playing else "Play"
	speed_button.text = "×%d" % SPEEDS[speed_index]
	view.queue_redraw()


# -- layout ------------------------------------------------------------------

func _label(text_points := TEXT_POINTS) -> Label:
	var l := Label.new()
	l.add_theme_font_size_override("font_size", int(text_points * PX_PER_POINT))
	l.add_theme_color_override("font_color", Palette.INK)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return l


func _panel() -> PanelContainer:
	var p := PanelContainer.new()
	var box := StyleBoxFlat.new()
	box.bg_color = Palette.PANEL
	box.set_corner_radius_all(int(12 * PX_PER_POINT))
	box.set_content_margin_all(int(8 * PX_PER_POINT))
	p.add_theme_stylebox_override("panel", box)
	return p


## §21.8: ink on paper, "gold for main actions".
func _button(text: String, pressed: Callable, main := false) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2.ONE * CONTROL_POINTS * PX_PER_POINT
	b.add_theme_font_size_override("font_size", int(TEXT_POINTS * PX_PER_POINT))
	for state in ["normal", "hover", "pressed", "focus"]:
		var box := StyleBoxFlat.new()
		box.bg_color = Palette.MOTION if main else Palette.PANEL
		if state == "pressed":
			box.bg_color = box.bg_color.darkened(0.12)
		box.set_corner_radius_all(int(12 * PX_PER_POINT))
		box.border_color = Palette.INK
		box.set_border_width_all(int(PX_PER_POINT))
		b.add_theme_stylebox_override(state, box)
	for colour in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		b.add_theme_color_override(colour, Palette.INK)
	b.pressed.connect(pressed)
	return b


func _build() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var sky := TextureRect.new()
	var gradient := Gradient.new()
	gradient.set_color(0, Palette.SKY_TOP)
	gradient.set_color(1, Palette.SKY_BOTTOM)
	var texture := GradientTexture2D.new()
	texture.gradient = gradient
	texture.fill_from = Vector2(0, 0)
	texture.fill_to = Vector2(0, 1)
	sky.texture = texture
	sky.stretch_mode = TextureRect.STRETCH_SCALE
	sky.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(sky)

	# Everything inside §21.1's safe areas: 44 points clear of the notch and
	# the home bar, and a margin at the sides.
	var safe := MarginContainer.new()
	safe.set_anchors_preset(Control.PRESET_FULL_RECT)
	var inset := int(44 * PX_PER_POINT)
	safe.add_theme_constant_override("margin_top", inset)
	safe.add_theme_constant_override("margin_bottom", inset)
	safe.add_theme_constant_override("margin_left", int(16 * PX_PER_POINT))
	safe.add_theme_constant_override("margin_right", int(16 * PX_PER_POINT))
	add_child(safe)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", int(8 * PX_PER_POINT))
	safe.add_child(column)

	# Top: the clock and alarm in the centre, loot at the right (§21.8).
	var top := HBoxContainer.new()
	column.add_child(top)
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(spacer)
	var centre := _panel()
	var centre_box := VBoxContainer.new()
	centre.add_child(centre_box)
	clock_label = _label()
	alarm_label = _label()
	centre_box.add_child(clock_label)
	centre_box.add_child(alarm_label)
	top.add_child(centre)
	var right := _panel()
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	loot_label = _label()
	loot_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	right.add_child(loot_label)
	top.add_child(right)

	view = RealmView.new()
	view.size_flags_vertical = Control.SIZE_EXPAND_FILL
	view.gui_input.connect(_on_view_input)
	column.add_child(view)

	var status := _panel()
	var status_box := VBoxContainer.new()
	status.add_child(status_box)
	name_label = _label()
	badge_label = _label()
	grade_label = _label()
	status_box.add_child(name_label)
	status_box.add_child(badge_label)
	status_box.add_child(grade_label)
	column.add_child(status)

	# The controls, in the thumb zone and clear of the corners (§21.1).
	var controls := HBoxContainer.new()
	controls.alignment = BoxContainer.ALIGNMENT_CENTER
	controls.add_theme_constant_override("separation", int(12 * PX_PER_POINT))
	column.add_child(controls)
	controls.add_child(_button("‹", func(): open_golden(current - 1); playing = true))
	play_button = _button("Pause", func(): playing = not playing; _refresh(), true)
	controls.add_child(play_button)
	speed_button = _button("×2", func(): speed_index = (speed_index + 1) % SPEEDS.size(); _refresh())
	controls.add_child(speed_button)
	controls.add_child(_button("›", func(): open_golden(current + 1); playing = true))
	var foot := Control.new()
	foot.custom_minimum_size = Vector2(0, 8 * PX_PER_POINT)
	column.add_child(foot)


## Tap a guard to see what it sees (§21.12: one shape at a time).
func _on_view_input(event: InputEvent) -> void:
	if not (event is InputEventMouseButton and event.pressed):
		return
	var guards := replay.guards()
	var best := -1
	var best_d := INF
	for gi in guards.size():
		var d := view.to_screen(guards[gi]["at"]).distance_to(event.position)
		if d < best_d:
			best_d = d
			best = gi
	view.selected_guard = best
	view.queue_redraw()
