class_name DebugOverlay
extends CanvasLayer
## Development builds only: a panel over every screen showing the current
## route, who is signed in, what waits in the outbox, and the last actions
## and failures from the action log, so a defect is seen with the steps that
## led to it. Opened and closed with F12 on a desktop or a three-finger tap
## on a phone; a release build never adds it (`App.ready`).

const LINES := 16

var _label: Label
var _services: Services


func _init(services: Services) -> void:
	_services = services
	layer = 100
	visible = false
	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_TOP_WIDE)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var box := StyleBoxFlat.new()
	box.bg_color = Color(0, 0, 0, 0.75)
	panel.add_theme_stylebox_override("panel", box)
	_label = Label.new()
	_label.add_theme_color_override("font_color", Color.WHITE)
	_label.add_theme_font_size_override("font_size", 24)
	_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	panel.add_child(_label)
	add_child(panel)
	services.store.changed.connect(func(_slice: StringName) -> void: _refresh())


func _unhandled_input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if key != null and key.pressed and key.keycode == KEY_F12:
		toggle()
	var touch := event as InputEventScreenTouch
	if touch != null and touch.pressed and touch.index == 2:
		toggle()


func toggle() -> void:
	visible = not visible
	_refresh()


## What the panel shows, as text: a test reads it without a screen.
func text() -> String:
	var route: Dictionary = _services.store.get_slice(AppState.ROUTE)
	var session: Dictionary = _services.store.get_slice(AppState.SESSION)
	var lines: PackedStringArray = [
		"route %s   account %s   outbox %d   server %s" % [route["name"], session["account"],
			_services.outbox.pending(), "on" if _services.api.online() else "off"],
	]
	var entries := _services.store.action_log.entries()
	for e: Dictionary in entries.slice(maxi(0, entries.size() - LINES)):
		lines.append("%7d %s %s %s" % [e["ms"], e["kind"], e["what"], JSON.stringify(e["fields"])])
	return "\n".join(lines)


func _refresh() -> void:
	if visible:
		_label.text = text()
