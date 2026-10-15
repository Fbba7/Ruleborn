class_name ShareController
extends RefCounted
## The share sheet with no screen: a challenge link to the player's island
## made by the server (§17.6), and its code put where the player can paste it.

var services: Services
## Where a copied code goes: the system clipboard, or a test's own.
var clipboard: Callable = func(text: String) -> void: DisplayServer.clipboard_set(text)


func _init(s: Services) -> void:
	services = s


func make_link() -> void:
	if services.store.get_slice(ShareState.SHARE)["busy"]:
		return
	services.store.dispatch(&"share_asked")
	var r := await services.friends.challenge()
	if r.ok:
		services.store.dispatch(&"share_link", {"link": r.value})
	else:
		services.store.dispatch(&"share_failed", {"code": r.code})


func copy() -> void:
	var link: Dictionary = services.store.get_slice(ShareState.SHARE)["link"]
	if link.is_empty():
		return
	clipboard.call(SharePresenter.message(link))
	services.store.dispatch(&"share_copied")
