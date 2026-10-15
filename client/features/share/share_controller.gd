class_name ShareController
extends RefCounted
## The share sheet with no screen: a challenge link to the player's island
## and a personal invite, each made by the server (§17.6), and a code put
## where the player can paste it.

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


## §17.6: a personal invite; the friend who accepts it and the player both
## get the matching cosmetic at the friend's first heist.
func make_invite() -> void:
	if services.store.get_slice(ShareState.SHARE)["busy"]:
		return
	services.store.dispatch(&"share_asked")
	var r := await services.friends.invite()
	if r.ok:
		services.store.dispatch(&"share_invite", {"invite": r.value})
	else:
		services.store.dispatch(&"share_failed", {"code": r.code})


## The code made, the challenge's or the invite's, `what` says which.
func copy(what := "link") -> void:
	var made: Dictionary = services.store.get_slice(ShareState.SHARE)[what]
	if made.is_empty():
		return
	clipboard.call(SharePresenter.message(made) if what == "link" else SharePresenter.invitation(made))
	services.store.dispatch(&"share_copied")
