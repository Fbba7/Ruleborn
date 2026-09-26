class_name AppLifetime
extends Node
## Lets go of the app's services as the scene tree is torn down: a static
## that still holds objects when the engine frees its own memory corrupts
## the heap on exit.

func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE or what == NOTIFICATION_WM_CLOSE_REQUEST:
		if App.services != null:
			App.services.close()
		App.services = null
