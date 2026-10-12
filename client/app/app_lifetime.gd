class_name AppLifetime
extends Node
## The app's life on the phone: a session starts as it comes to the
## foreground and ends as it goes (TD.74, Services.foreground and
## .background), and the services are let go as the scene tree is torn down —
## a static that still holds objects when the engine frees its own memory
## corrupts the heap on exit.

func _ready() -> void:
	if App.services != null:
		App.services.foreground()


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
