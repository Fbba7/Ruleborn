class_name Home
extends Control
## Where the app opens, once §20.1's age check has answered: the Keeper bar
## (§14.2), every screen, in a list that scrolls when §20.8's
## large text makes it long, and the heist — §21.8's large Heist button —
## fixed at the bottom where the thumb rests.

## The screens a player goes to from home, in the order they are listed.
const PLACES := [&"universe", &"weaving", &"codex", &"roster", &"hatch", &"sages", &"forms", &"builder", &"workshop",
	&"replay", &"track", &"shop", &"social", &"friends", &"settings"]
const WORDS := {&"universe": "HOME_UNIVERSE", &"weaving": "HOME_WEAVING", &"codex": "HOME_CODEX",
	&"roster": "HOME_ROSTER", &"hatch": "HOME_HATCH", &"sages": "HOME_SAGES", &"forms": "HOME_FORMS",
	&"builder": "HOME_BUILD", &"workshop": "HOME_WORKSHOP", &"replay": "HOME_WATCH", &"track": "HOME_TRACK",
	&"shop": "HOME_SHOP", &"social": "HOME_SOCIAL", &"friends": "HOME_FRIENDS", &"settings": "HOME_SETTINGS"}

var keeper_label: Label
var keeper_plate: PanelContainer


func _ready() -> void:
	App.ready(self)
	Settings.restore()
	# §20.1: the age check comes first; nothing else until it allows play.
	if not App.services.age.allows_account():
		App.services.router.go.call_deferred(&"age")
		return
	var column := UI.frame(self)
	column.add_child(UI.label(Strings.t("APP_NAME"), 48))
	column.add_child(UI.plate(UI.label(Strings.t("HOME_TAGLINE"), UI.TEXT_POINTS, true)))
	# §14.2's Keeper bar, once the server has said where the player stands.
	keeper_label = UI.label("", UI.TEXT_POINTS, true)
	keeper_plate = UI.plate(keeper_label)
	keeper_plate.visible = false
	column.add_child(keeper_plate)
	App.services.store.changed.connect(_on_changed)
	show_keeper()
	var list := UI.scroll(column)
	var places := UI.row()
	for route: StringName in PLACES:
		places.add_child(UI.button(Strings.t(WORDS[route]), func() -> void: App.services.router.go(route)))
	list.add_child(places)
	var play := UI.row(-1.0, true)
	play.add_child(UI.button(Strings.t("HOME_PLAY"), _play, true))
	column.add_child(UI.narrow(play))
	await send_waiting(column)
	if App.services.api.online() and is_inside_tree():
		await App.services.keeper_flow.load_keeper()


func _on_changed(slice: StringName) -> void:
	if slice == KeeperState.KEEPER and is_inside_tree():
		show_keeper()


## The Keeper level, its pips and the way to the next, in words.
func show_keeper() -> void:
	var b := KeeperPresenter.bar(App.services.store.get_slice(KeeperState.KEEPER))
	keeper_plate.visible = b["ready"]
	if b["ready"]:
		keeper_label.text = "%s  %s\n%s" % [b["title"], b["pips"], b["progress"]]
		keeper_label.accessibility_name = b["spoken"]


## G41: what was played offline goes by itself once the network is back, and
## the player is told. Returns how many were sent.
func send_waiting(column: VBoxContainer) -> int:
	var services: Services = App.services
	if not services.api.online() or services.outbox.pending() == 0:
		return 0
	if not (await services.sign_in()):
		return 0
	var sent := await services.outbox.flush(services.api)
	if sent > 0 and is_inside_tree():
		column.add_child(UI.banner("success", Strings.t("OFFLINE_SENT", sent)))
	return sent


## A heist on the fixture realm or a leased island: not the builder's test.
func _play() -> void:
	App.services.store.dispatch(&"heist_started", {})
	App.services.router.go(&"heist")
