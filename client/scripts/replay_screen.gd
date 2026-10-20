class_name ReplayScreen
extends Control
## A heist, replayed: the simulation re-run on the phone from its seed and
## input log, and drawn (§24.1: "the device renders the replay itself").
##
## Laid out as §21.8's heist layout reads — the clock and alarm at the top
## centre, loot at the top right — with the playback controls in the thumb
## zone (§21.1). Each second, the client's checksum is compared with the one the
## replay carries; the badge says whether this phone is showing the heist the
## server validated. It plays a raid on the player's universe opened from the
## defence log, on the island it was played on; else the heist just played,
## if there is one; and the golden replays after it.

const SPEEDS := [1, 2, 4, 8]

var replay := RulebornReplay.new()
## (name, bytes, golden name, island) for each replay the screen can show:
## a golden's name, and a raid's island, where it has them.
var entries: Array = []
var current := 0
var playing := true
var speed_index := 1

var view: WorldView
var hud: HeistHud
var name_label: Label
var badge_label: Label
var grade_label: Label
var play_button: Button
var speed_button: Button

var _owed := 0.0


func _ready() -> void:
	App.ready(self)
	var watching: Dictionary = App.services.store.get_slice(DefencesState.DEFENCES)["watching"]
	if not watching.is_empty():
		entries.append([Strings.t("REPLAY_RAID"), watching["replay"], "", watching["island"]])
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
	var island: PackedByteArray = entries[current][3] if entries[current].size() > 3 else PackedByteArray()
	var ok := replay.load(entries[current][1], island)
	name_label.text = entries[current][0]
	grade_label.text = ""
	_owed = 0.0
	view.show_replay(replay)
	view.follow = range(replay.crew().size())
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
		FxSkin.set_status(badge_label, "alarm",
			Strings.t("REPLAY_DIVERGED", [replay.mismatch() / 60, replay.mismatch() % 60]))
	else:
		FxSkin.set_status(badge_label, "success", Strings.t("REPLAY_MATCHES", replay.seconds_agreed()))
	if replay.tick() >= replay.ticks() and replay.ticks() > 0:
		var o := replay.outcome()
		grade_label.text = Strings.t("REPLAY_GRADE", [Strings.term("GRADE", o["grade"]), o["banked"], o["capacity"]])
	UI.relabel(play_button, Strings.t("REPLAY_PAUSE") if playing else Strings.t("REPLAY_PLAY"))
	UI.relabel(speed_button, "×%d" % SPEEDS[speed_index])
	speed_button.accessibility_name = Strings.t("REPLAY_SPEED", SPEEDS[speed_index])
	view.describe()
	view.queue_redraw()


func _build() -> void:
	# The world fills the screen, as in the heist; the HUD and the playback
	# controls float over it inside §21.1's safe areas.
	view = WorldView.new()
	view.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	view.tapped.connect(_on_view_tap)
	add_child(view)
	var columns := FxSkin.frame(self)
	hud = HeistHud.new()
	columns[0].add_child(hud)
	var column := columns[1]

	var status := FxSkin.panel("card", 16.0, 8.0)
	var status_box := VBoxContainer.new()
	status_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	status_box.add_theme_constant_override("separation", 0)
	status.add_child(status_box)
	name_label = FxSkin.label("", UI.TEXT_POINTS + 2.0, "glass", true)
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	badge_label = FxSkin.label("", 14.0)
	badge_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	grade_label = FxSkin.label("", 14.0)
	grade_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status_box.add_child(name_label)
	status_box.add_child(badge_label)
	status_box.add_child(grade_label)
	column.add_child(status)

	var controls := UI.row(-1.0, true)
	controls.mouse_filter = Control.MOUSE_FILTER_IGNORE
	controls.add_child(_button("‹", func() -> void: open_entry(current - 1); playing = true, "leather",
			Strings.t("REPLAY_PREVIOUS")))
	play_button = _button(Strings.t("REPLAY_PAUSE"), func() -> void: playing = not playing; _refresh(), "gold")
	controls.add_child(play_button)
	speed_button = _button("×2", func() -> void: speed_index = (speed_index + 1) % SPEEDS.size(); _refresh(),
			"leather", Strings.t("REPLAY_SPEED", SPEEDS[speed_index]))
	controls.add_child(speed_button)
	controls.add_child(_button("›", func() -> void: open_entry(current + 1); playing = true, "leather",
			Strings.t("REPLAY_NEXT")))
	# Home rides with the playback controls: one row fewer, so the realm
	# keeps its room when §20.8's large text makes the words take more.
	controls.add_child(_button(Strings.t("COMMON_HOME"), func() -> void: App.services.router.go(&"home"), "card"))
	column.add_child(UI.narrow(controls))
	column.add_child(FxSkin.corner_clear())


## A playback button in the heist's skin.
func _button(words: String, call: Callable, kind: String, spoken := "") -> Button:
	var b := UI.button(words, call, false, Color(), spoken)
	FxSkin.style_button(b, kind)
	UI.fit(b)
	return b


## Tap a guard to see what it sees (§21.12: one shape at a time).
func _on_view_tap(at: Vector2) -> void:
	view.select_guard_near(at)
