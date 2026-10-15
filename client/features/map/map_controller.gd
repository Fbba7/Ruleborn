class_name MapController
extends RefCounted
## The Universe map with no screen: it reads what other flows hold — the
## weaving view, the home, the wallet and the raid badge — and asks each
## afresh when the map opens.

var services: Services


func _init(s: Services) -> void:
	services = s


func load_all() -> void:
	await services.weaving_flow.load_weaving()
	await services.roster_flow.load_roster()
	await services.shop_flow.load_wallet()
	await services.defences_flow.load_badge()
