class_name RealmController
extends RefCounted
## The realm view with no screen: the universe, weaving and home views, and
## the realm's published island fetched by its bundle (§24.8).

var services: Services


func _init(s: Services) -> void:
	services = s


## The view of `realm`, opened from the Universe map.
func open(realm: String) -> void:
	services.store.dispatch(&"realm_opened", {"realm": realm})
	services.router.go(&"realm")


## A load that comes back after another realm was opened says nothing: its
## island is not the open realm's (CLI-10).
func load_realm() -> void:
	var realm := str(services.store.get_slice(RealmState.REALM)["realm"])
	await services.universe_flow.load_universe()
	await services.weaving_flow.load_weaving()
	await services.roster_flow.load_roster()
	if not _still(realm):
		return
	var bundle: Variant = RealmPresenter.realm_of(services.store.get_slice(UniverseState.UNIVERSE), realm).get("island")
	if not (bundle is String):
		services.store.dispatch(&"realm_island", {"island": PackedByteArray()})
		return
	var r := await services.heists.fetch(str(bundle))
	if not _still(realm):
		return
	if r.ok:
		services.store.dispatch(&"realm_island", {"island": r.value})
	else:
		services.store.dispatch(&"realm_failed", {"code": r.code})


func _still(realm: String) -> bool:
	return str(services.store.get_slice(RealmState.REALM)["realm"]) == realm
