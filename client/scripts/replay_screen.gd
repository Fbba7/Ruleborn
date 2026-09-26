class_name ReplayScreen
extends Control
## A heist, replayed: the simulation re-run on the phone from its seed and
## input log, and drawn (§24.1: "the device renders the replay itself").
##
## Laid out as §21.8's heist layout reads — the clock and alarm at the top
## centre, loot at the top right — with the playback controls in the thumb
## zone (§21.1). Each second, the client's checksum is compared with the one the
## replay carries; the badge says whether this phone is showing the heist the
## server validated. It plays the heist just played, if there is one, and the
## golden replays after it.

const SPEEDS := [1, 2, 4, 8]

var replay := RulebornReplay.new()
## (name, bytes) for each replay the screen can show.
var entries: Array = []
var current := 0
var playing := true
var speed_index := 1
var _owed := 0.0

var view: RealmView
var hud: HeistHud
var name_label: Label
var badge_label: Label
var grade_label: Label
var play_button: Button
var speed_button: Button


func _ready() -> void:
	App.ready(self)
	var yours: PackedByteArray = App.services.store.get_slice(AppState.HEIST)["replay"]
	if not yours.is_empty():
		entries.append([Strings.t("REPLAY_YOURS"), yours])
	for g in find_goldens():
		entries.append([Strings.t("REPLAY_GOLDEN", g), FileAccess.get_file_as_bytes("res://goldens/%s.rbh" % g), g])
	_build()
	if entries.size() > 0:
		open_entry(0)


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


## Open a golden by name, or -1 if there is none.
func open_golden(name: String) -> int:
	for i in entries.size():
		if entries[i].size() > 2 and entries[i][2] == name:
			open_entry(i)
			return i
	return -1


func open_entry(index: int) -> bool:
	current = posmod(index, entries.size())
	var ok := replay.load(entries[current][1], PackedByteArray())
	name_label.text = entries[current][0]
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
	hud.show_state(replay)
	if replay.mismatch() > 0:
		badge_label.text = Strings.t("REPLAY_DIVERGED", [replay.mismatch() / 60, replay.mismatch() % 60])
		badge_label.add_theme_color_override("font_color", Palette.ALARM)
	else:
		badge_label.text = Strings.t("REPLAY_MATCHES", replay.seconds_agreed())
		badge_label.add_theme_color_override("font_color", Palette.SUCCESS.darkened(0.3))
	if replay.tick() >= replay.ticks() and replay.ticks() > 0:
		var o := replay.outcome()
		grade_label.text = Strings.t("REPLAY_GRADE", [Strings.term("GRADE", o["grade"]), o["banked"], o["capacity"]])
	play_button.text = Strings.t("REPLAY_PAUSE") if playing else Strings.t("REPLAY_PLAY")
	speed_button.text = "×%d" % SPEEDS[speed_index]
	view.queue_redraw()


func _build() -> void:
	var column := UI.frame(self)
	hud = HeistHud.new()
	column.add_child(hud)
	view = RealmView.new()
	view.size_flags_vertical = Control.SIZE_EXPAND_FILL
	view.gui_input.connect(_on_view_input)
	column.add_child(view)

	var status := UI.panel()
	var status_box := VBoxContainer.new()
	status.add_child(status_box)
	name_label = UI.label()
	badge_label = UI.label()
	grade_label = UI.label()
	status_box.add_child(name_label)
	status_box.add_child(badge_label)
	status_box.add_child(grade_label)
	column.add_child(status)

	var controls := UI.row()
	controls.add_child(UI.button("‹", func() -> void: open_entry(current - 1); playing = true))
	play_button = UI.button(Strings.t("REPLAY_PAUSE"), func() -> void: playing = not playing; _refresh(), true)
	controls.add_child(play_button)
	speed_button = UI.button("×2", func() -> void: speed_index = (speed_index + 1) % SPEEDS.size(); _refresh())
	controls.add_child(speed_button)
	controls.add_child(UI.button("›", func() -> void: open_entry(current + 1); playing = true))
	var back := UI.row()
	back.add_child(UI.button(Strings.t("COMMON_HOME"), func() -> void: App.services.router.go(&"home")))
	column.add_child(back)
	column.add_child(controls)


## Tap a guard to see what it sees (§21.12: one shape at a time).
func _on_view_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		view.select_guard_near(event.position)
