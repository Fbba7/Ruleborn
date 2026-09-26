class_name Home
extends Control
## Where the app opens: every screen, in a list that scrolls when §20.8's
## large text makes it long, and the heist — §21.8's large Heist button —
## fixed at the bottom where the thumb rests.

## The screens a player goes to from home, in the order they are listed.
const PLACES := [&"builder", &"replay", &"track", &"shop", &"social", &"friends", &"settings"]
const WORDS := {&"builder": "HOME_BUILD", &"replay": "HOME_WATCH", &"track": "HOME_TRACK", &"shop": "HOME_SHOP",
	&"social": "HOME_SOCIAL", &"friends": "HOME_FRIENDS", &"settings": "HOME_SETTINGS"}


func _ready() -> void:
	App.ready(self)
	Settings.restore()
	var column := UI.frame(self)
	column.add_child(UI.label(Strings.t("APP_NAME"), 48))
	column.add_child(UI.plate(UI.label(Strings.t("HOME_TAGLINE"), UI.TEXT_POINTS, true)))
	var list := UI.scroll(column)
	var places := UI.row()
	for route: StringName in PLACES:
		places.add_child(UI.button(Strings.t(WORDS[route]), func() -> void: App.services.router.go(route)))
	list.add_child(places)
	var play := UI.row(-1.0, true)
	play.add_child(UI.button(Strings.t("HOME_PLAY"), _play, true))
	column.add_child(UI.narrow(play))
	await send_waiting(column)


## G41: what was played offline goes by itself once the network is back, and
## the player is told. Returns how many were sent.
func send_waiting(column: VBoxContainer) -> int:
	var services: Services = App.services
	if not services.api.online() or services.outbox.pending() == 0:
		return 0
	var me := await services.account.sign_in(Services.credential())
	if not me.ok:
		return 0
	services.store.dispatch(&"signed_in", {"account": me.value["account"]})
	var sent := await services.outbox.flush(services.api)
	if sent > 0 and is_inside_tree():
		column.add_child(UI.banner("success", Strings.t("OFFLINE_SENT", sent)))
	return sent


## A heist on the fixture realm or a leased island: not the builder's test.
func _play() -> void:
	App.services.store.dispatch(&"heist_started", {})
	App.services.router.go(&"heist")
