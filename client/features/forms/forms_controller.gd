class_name FormsController
extends RefCounted
## The Forms album with no screen: asks the home repository and dispatches
## the answer.

var services: Services


func _init(s: Services) -> void:
	services = s


func load_album() -> void:
	if str(services.store.get_slice(FormsState.FORMS)["busy"]) != "":
		return
	services.store.dispatch(&"forms_asked")
	var r := await services.home.album()
	if r.ok:
		services.store.dispatch(&"forms_loaded", {"view": r.value})
	else:
		services.store.dispatch(&"forms_failed", {"code": r.code})


## §23.2's "Show mine": only the forms the player has, or all again.
func show_mine(on: bool) -> void:
	services.store.dispatch(&"forms_mine", {"mine": on})
