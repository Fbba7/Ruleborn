class_name AppLifetime
extends Node
## The app's life on the phone: a session starts as it comes to the
## foreground and ends as it goes (TD.74, Services.foreground and
## .background), and the services are let go as the scene tree is torn down —
## a static that still holds objects when the engine frees its own memory
## corrupts the heap on exit.

## How often an open session is marked seen (CLI-14): one the app never
## closes, killed or crashed, is ended at the next launch at its last mark.
const SEEN_EVERY := 30.0

var _since_seen := 0.0


func _ready() -> void:
	if App.services != null:
		App.services.foreground()


func _process(delta: float) -> void:
	_since_seen += delta
	if _since_seen < SEEN_EVERY or App.services == null:
		return
	_since_seen = 0.0
	App.services.notices.seen(int(Time.get_unix_time_from_system() * 1000))


func _notification(what: int) -> void:
	if App.services == null:
		return
	if what == NOTIFICATION_APPLICATION_RESUMED:
		App.services.foreground()
	elif what == NOTIFICATION_APPLICATION_PAUSED:
		App.services.background()
	elif what == NOTIFICATION_PREDELETE or what == NOTIFICATION_WM_CLOSE_REQUEST:
		# The end is kept on the phone before anything is let go; it is sent
		# at the next launch.
		App.services.notices.stop(int(Time.get_unix_time_from_system() * 1000))
		App.services.close()
		App.services = null
