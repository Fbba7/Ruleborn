class_name Home
extends Control
## Where the app opens, once §20.1's age check has answered (§23.2: "Home.
## See every realm and link at once"): the player's universe in 3D behind
## everything, on its night sky (§21.2: menus "stand on a night backdrop");
## the Keeper bar (§14.2) on top; every screen in a compact menu of the
## design's icons over the world, which scrolls when §20.8's large text makes
## it long; and the heist — §21.8's large Heist button — fixed at the bottom
## where the thumb rests.

## The screens a player goes to from home, in the order they are listed.
const PLACES := [&"map", &"observatory", &"defences", &"universe", &"weaving", &"codex", &"lab", &"roster", &"hatch",
	&"sages", &"forms", &"builder", &"workshop", &"replay", &"profile", &"share", &"track", &"shop", &"social",
	&"friends", &"settings"]
const WORDS := {&"map": "HOME_MAP", &"observatory": "HOME_OBSERVATORY", &"defences": "HOME_DEFENCES",
	&"universe": "HOME_UNIVERSE", &"weaving": "HOME_WEAVING", &"codex": "HOME_CODEX", &"lab": "HOME_LAB",
	&"roster": "HOME_ROSTER", &"hatch": "HOME_HATCH", &"sages": "HOME_SAGES", &"forms": "HOME_FORMS",
	&"builder": "HOME_BUILD", &"workshop": "HOME_WORKSHOP", &"replay": "HOME_WATCH", &"profile": "HOME_PROFILE",
	&"share": "HOME_SHARE", &"track": "HOME_TRACK", &"shop": "HOME_SHOP", &"social": "HOME_SOCIAL",
	&"friends": "HOME_FRIENDS", &"settings": "HOME_SETTINGS"}
## The menu's tiles: a night plate edged in gold, words in paper on it.
const TILE := Color("#24164F")
const TILE_EDGE := Color("#F2B43C")
const DOCK := Color("#120A30")
## How many rows of the menu show before it scrolls.
const ROWS_SHOWN := 2.3
## The menu's and the Keeper bar's words: small, never under §21.8's 13.
const TILE_POINTS := 13.0
const BAR_POINTS := 14.0

var keeper_label: Label
var keeper_plate: PanelContainer
## The defence log's button, which carries the raid badge (TD.66).
var defences_button: Button
## The universe behind the menus.
var world: UniverseView

var _top: Control
var _dock: Control
## The realm the world is closed in on: one more tap there opens it.
var _close := ""


func _ready() -> void:
	App.ready(self)
	Settings.restore()
	# TD.26: the first launch's beats come first, the age check among them
	# (§20.1); nothing else until they are done.
	if not App.services.first.done():
		App.services.router.go.call_deferred(&"first")
		return
	if not App.services.age.allows_account():
		App.services.router.go.call_deferred(&"age")
		return
	var column := UI.frame(self)
	world = UniverseView.behind(self, column)
	world.next_chosen.connect(func() -> void: App.services.router.go(&"universe"))
	world.realm_chosen.connect(_on_realm)
	# The game's name and what it is, said aloud; the world shows the rest.
	accessibility_name = Strings.t("APP_NAME")
	accessibility_description = Strings.t("HOME_TAGLINE")
	# §14.2's Keeper bar, once the server has said where the player stands.
	keeper_label = UI.label("", BAR_POINTS, true)
	keeper_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	keeper_label.add_theme_color_override("font_color", Palette.PAPER)
	keeper_label.add_theme_font_override("font", UI.bold_font())
	keeper_label.set_meta("bold", true)
	keeper_label.set_meta("points", BAR_POINTS)
	keeper_plate = _night(Color(DOCK, 0.9), TILE_EDGE)
	keeper_plate.add_child(keeper_label)
	keeper_plate.visible = false
	keeper_plate.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(keeper_plate)
	_top = keeper_plate
	var room := UI.grow()
	room.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(room)
	_dock = _menu()
	column.add_child(_dock)
	var play := UI.row(-1.0, true)
	var heist := UI.button(Strings.t("HOME_PLAY"), _play, true)
	heist.icon = load("res://world/universe_icons/heist.svg")
	heist.add_theme_constant_override("icon_max_width", UI.px(40))
	heist.add_theme_font_size_override("font_size", UI.text_px(UI.TEXT_POINTS * 1.35))
	heist.set_meta("points", UI.TEXT_POINTS * 1.35)
	heist.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	heist.custom_minimum_size = Vector2(UI.px(236), UI.px(64))
	play.add_child(heist)
	column.add_child(UI.narrow(play))
	column.sort_children.connect(_frame_world)
	App.services.store.changed.connect(_on_changed)
	show_keeper()
	_draw_world()
	# Home opens on the Heart, its neighbours round it (§21.1's realm zoom);
	# a pinch out shows the whole universe.
	world.focus_realm.call_deferred("heart", 1)
	await send_waiting(column)
	if App.services.api.online() and is_inside_tree():
		await App.services.keeper_flow.load_keeper()
	if App.services.api.online() and is_inside_tree():
		await App.services.defences_flow.load_badge()
	if App.services.api.online() and is_inside_tree():
		await App.services.universe_flow.load_universe()


## A realm tapped in the world: closer, and once close, its realm view.
func _on_realm(id: String) -> void:
	if _close == id:
		_close = ""
		App.services.realm_flow.open(id)
		return
	_close = id if world.zoom == 2 else ""


## The universe framed into the room between the top bar and the menu.
func _frame_world() -> void:
	world.fit_between(_top, _dock)


## Every place, a tile with its icon and its name, in a dock that scrolls.
func _menu() -> PanelContainer:
	var dock := _night(Color(DOCK, 0.88), Color(TILE_EDGE, 0.55))
	var scroller := ScrollContainer.new()
	scroller.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	var grid := GridContainer.new()
	grid.add_theme_constant_override("h_separation", UI.px(6))
	grid.add_theme_constant_override("v_separation", UI.px(6))
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var widest := 0.0
	for route: StringName in PLACES:
		var b := _tile(Strings.t(WORDS[route]), route)
		if route == &"defences":
			defences_button = b
		grid.add_child(b)
		widest = maxf(widest, _longest_word(b))
	# As many columns as the longest word allows (§20.8's large text), up to four.
	var room := 360.0 * UI.PX_PER_POINT - UI.px(Tokens.number("size", "safe_side_points")) * 2.0 - UI.px(24)
	grid.columns = clampi(floori(room / (maxf(widest, UI.CONTROL_POINTS * UI.PX_PER_POINT) + UI.px(12))), 1, 4)
	scroller.add_child(grid)
	var row_px := _tile_height() + UI.px(6)
	scroller.custom_minimum_size.y = row_px * ROWS_SHOWN
	dock.add_child(scroller)
	return dock


func _tile(text: String, route: StringName) -> Button:
	var b := UI.button(text, func() -> void: App.services.router.go(route))
	b.icon = load("res://world/universe_icons/%s.svg" % route)
	b.expand_icon = true
	b.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	b.vertical_icon_alignment = VERTICAL_ALIGNMENT_TOP
	b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.custom_minimum_size = Vector2(UI.CONTROL_POINTS * UI.PX_PER_POINT, _tile_height())
	b.add_theme_constant_override("icon_max_width", UI.px(40))
	for state: String in ["normal", "hover", "pressed", "focus", "disabled"]:
		var box := StyleBoxFlat.new()
		box.bg_color = TILE.lightened(0.12) if state == "pressed" else TILE
		box.border_color = TILE_EDGE if state != "focus" else Palette.PAPER
		box.set_border_width_all(UI.px(1) if state != "focus" else UI.px(2))
		box.set_corner_radius_all(UI.px(10))
		box.content_margin_top = UI.px(4)
		box.content_margin_bottom = UI.px(4)
		box.content_margin_left = UI.px(2)
		box.content_margin_right = UI.px(2)
		box.shadow_color = Color(0, 0, 0, 0.4)
		box.shadow_size = UI.px(2)
		b.add_theme_stylebox_override(state, box)
	for colour: String in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color",
			"font_disabled_color"]:
		b.add_theme_color_override(colour, Palette.PAPER)
	b.add_theme_font_size_override("font_size", UI.text_px(TILE_POINTS))
	b.set_meta("points", TILE_POINTS)
	return b


## The widest word on a tile, which it cannot wrap inside.
static func _longest_word(b: Button) -> float:
	var font := b.get_theme_font("font")
	var widest := 0.0
	for word: String in b.text.split(" "):
		widest = maxf(widest, font.get_string_size(word, HORIZONTAL_ALIGNMENT_LEFT, -1,
			b.get_theme_font_size("font_size")).x)
	return widest + UI.px(8)


## A tile: its icon over two lines of words.
static func _tile_height() -> float:
	return maxf(UI.CONTROL_POINTS * UI.PX_PER_POINT, UI.px(50) + UI.text_px(TILE_POINTS) * 2.5)


## A rounded night plate edged in `edge`.
static func _night(fill: Color, edge: Color) -> PanelContainer:
	var p := PanelContainer.new()
	var box := StyleBoxFlat.new()
	box.bg_color = fill
	box.border_color = edge
	box.set_border_width_all(UI.px(1))
	box.set_corner_radius_all(UI.px(14))
	box.set_content_margin_all(UI.px(8))
	p.add_theme_stylebox_override("panel", box)
	return p


func _on_changed(slice: StringName) -> void:
	if slice == KeeperState.KEEPER and is_inside_tree():
		show_keeper()
	if slice == DefencesState.DEFENCES and is_inside_tree() and defences_button != null:
		# A tile keeps its width in the grid: only its words change.
		UI.relabel(defences_button, DefencesPresenter.place(
			int(App.services.store.get_slice(DefencesState.DEFENCES)["unseen"])), true)
	if slice in UniverseStore.SLICES and is_inside_tree():
		_draw_world()


## The universe as the store has it, and said in words.
func _draw_world() -> void:
	var store := App.services.store
	var view := UniverseStore.view(store)
	world.show_universe(view, UniverseStore.extras(store))
	world.accessibility_name = Strings.t("HOME_UNIVERSE")
	world.accessibility_description = UniverseStore.spoken(view)


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
