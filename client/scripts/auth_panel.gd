class_name AuthPanel
extends VBoxContainer
## The account, Settings' Account tab (docs/security/auth.md), in the
## Settings screen's own pieces (ScreenParts): where signing in stands, in
## words — the first launch, signing in, signed in and with what, offline, a
## failure and its reason, signed out — with sign in, try again or sign out
## at its end; the devices signed in to the account, each with its model,
## when it was last used, the country it was last in and its platform, and
## a sign-out of its own; sign out every other device and everywhere; the
## ways to sign in, with the other platform offered to add (one account on
## iPhone, iPad and Android) and a linked one to remove; and how a new phone
## gets the account back. Every sign-out and removal asks first, with the
## safe answer focused. Words from AuthPresenter.

## A lesser action that sits on a card (the status card's sign-out, a
## device's, a way to sign in's removal): the kit's tertiary (K01), the dark
## card's own face lifted two value steps off it. Leather on the card stood
## only 1.6 to 1.8 steps off it (board 5's objection M); leather stays for
## the actions on the night, where it stands 2.4 steps off.
const ON_CARD := "ghost"

var status_label: Label
var detail_label: Label
var _dialog: Control


func _ready() -> void:
	App.ready(self)
	name = "AuthPanel"
	add_theme_constant_override("separation", UI.px(Tokens.number("size", "gap_points")))
	App.services.store.changed.connect(_on_changed)
	App.services.auth_flow.refresh_status()
	_build()
	if App.services.auth.fresh():
		App.services.auth_flow.devices()


## The panel can leave the tree and come back once built (the settings screen
## moves its list into a holder after building it, S3-R30): _exit_tree stopped
## listening, so listen again here, and draw what changed while it was away.
func _enter_tree() -> void:
	if not is_node_ready() or App.services == null:
		return
	if not App.services.store.changed.is_connected(_on_changed):
		App.services.store.changed.connect(_on_changed)
	_on_changed.call_deferred(AuthState.AUTH)


func _exit_tree() -> void:
	if App.services != null and App.services.store.changed.is_connected(_on_changed):
		App.services.store.changed.disconnect(_on_changed)


func _on_changed(slice: StringName) -> void:
	if slice == AuthState.AUTH and is_inside_tree():
		_build()


func _build() -> void:
	for c in get_children():
		remove_child(c)
		c.queue_free()
	var slice: Dictionary = App.services.store.get_slice(AuthState.AUTH)
	var v := AuthPresenter.panel(slice)
	add_child(ScreenParts.section(Strings.t("AUTH_TITLE")))
	add_child(_status(v, slice))
	var notice := str(slice.get("notice", ""))
	if notice != "":
		var said := UI.status("alarm" if bool(slice.get("failed", false)) else "success", notice)
		said.accessibility_live = AccessibilityServer.LIVE_POLITE
		add_child(UI.plate(said))
	if str(slice.get("status", "")) == "signed_in":
		_devices(slice)
		_methods(slice)
	var back := ScreenKit.text(Strings.t("AUTH_RECOVERY"), 13.0, "body", "card", true, true)
	back.name = "Recovery"
	add_child(ScreenKit.panel("well", back, 14.0, 10.0))


## The status card: the account's mark, where signing in stands and a second
## line, and the actions at its end.
func _status(v: Dictionary, slice: Dictionary) -> Control:
	var detail := str(v["detail"])
	if str(slice.get("status", "")) == "signed_in":
		detail = Strings.t("AUTH_WITH_GC" if App.services.auth.platform.primary() == "gc" else "AUTH_WITH_GP")
	var actions := VBoxContainer.new()
	actions.add_theme_constant_override("separation", UI.px(6))
	for a: String in v["actions"]:
		if a == "sign_out_everywhere":
			continue
		var main := a in ["sign_in", "retry"]
		actions.add_child(_button(a, AuthPresenter.action(a), _act.bind(a), "gold" if main else ON_CARD))
	# Past side by side (S3-R30), the actions go under the words, each the
	# card's width: beside them, "Abmelden" left the words too narrow at 200%.
	var card := _item("account", str(v["line"]), detail, actions if actions.get_child_count() > 0 else null)
	card.name = "Status"
	# The words the rest of the client and its tests read.
	var words := card.find_children("*", "Label", true, false)
	status_label = words[0] as Label
	status_label.accessibility_live = AccessibilityServer.LIVE_POLITE
	status_label.add_theme_color_override("font_color", _tone(str(v["kind"])))
	detail_label = (words[1] as Label) if words.size() > 1 else UI.label("")
	return card


## Moves the item's row into a column with `end` under it: a button as wide
## as the card, its words wrapping rather than widening it; anything else at
## the column's start.
func _put_under(card: PanelContainer, end: Control) -> void:
	for c in card.get_children():
		if c is HBoxContainer:
			var column := VBoxContainer.new()
			column.add_theme_constant_override("separation", UI.px(10))
			card.remove_child(c)
			column.add_child(c)
			if end is VBoxContainer:
				for b in end.get_children():
					if b is Button:
						_wide(b as Button)
			elif end is Button:
				_wide(end as Button)
			else:
				end.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
			column.add_child(end)
			card.add_child(column)
			return


## ScreenParts.item, its end beside the words; past side by side, under them
## (S3-R30): beside them, a sign-out or a link left the words too narrow at
## 200% text, and "Android-Handy" broke in two.
func _item(icon: String, title: String, line: String, end: Control) -> PanelContainer:
	var under := Settings.text_scale > KitLayout.SIDE_BY_SIDE_UP_TO and end != null
	var card := ScreenParts.item("settingsandwellbeing", icon, title, line, null if under else end)
	if under:
		_put_under(card, end)
	return card


## The devices signed in: this one first, then by last use, each but this
## one with its own sign-out; then every other, and everywhere.
func _devices(slice: Dictionary) -> void:
	var list: Array = slice.get("list", [])
	if list.is_empty():
		return
	add_child(ScreenParts.section(Strings.t("AUTH_DEVICES_TITLE"), str(list.size())))
	var rows: Array[Control] = []
	for d: Variant in list:
		var row := AuthPresenter.device_row(d)
		var end: Control = ScreenParts.pill(Strings.t("AUTH_THIS_DEVICE"), "gold")
		if not bool(row["current"]):
			end = _button("end_device", Strings.t("AUTH_SIGN_OUT"),
				ask_change.bind("device", int(row["id"]), str(row["title"])), ON_CARD)
			end.accessibility_name = "%s: %s" % [Strings.t("AUTH_SIGN_OUT"), row["title"]]
		var item := _item("account", str(row["title"]), str(row["line"]), end)
		item.accessibility_name = str(row["spoken"])
		rows.append(item)
	add_child(_group(rows, "Devices"))
	# Stacked, each the column's width: their words are long in every
	# language, and side by side they would push the screen wider.
	if list.size() > 1:
		add_child(_wide(_button("sign_out_others", Strings.t("AUTH_SIGN_OUT_OTHERS"), ask_change.bind("others"),
			"leather")))
	add_child(_wide(_button("sign_out_everywhere", Strings.t("AUTH_SIGN_OUT_ALL"), _act.bind("sign_out_everywhere"),
		"red")))


## The ways to sign in, and the other platform this device can add.
func _methods(slice: Dictionary) -> void:
	var rows := AuthPresenter.methods(slice, App.services.auth.platform.primary())
	if rows.is_empty():
		return
	add_child(ScreenParts.section(Strings.t("AUTH_METHODS_TITLE")))
	var items: Array[Control] = []
	for m: Dictionary in rows:
		var p := str(m["platform"])
		var end: Control = null
		match str(m["action"]):
			"link":
				end = _button("link", Strings.t("AUTH_LINK"), _link.bind(p), "gold")
			"unlink":
				end = _button("unlink", Strings.t("AUTH_UNLINK"), ask_change.bind("unlink", 0, str(m["title"]), p),
					ON_CARD)
		var icon := "account" if p == "gc" else "privacy"
		items.append(_item(icon, str(m["title"]), str(m["line"]), end))
	add_child(_group(items, "Methods"))


## Rows in one card, a hairline between each, as the Settings still groups
## its rows: each row keeps its words' ink for the card, its own card hidden.
func _group(rows: Array[Control], named: String) -> PanelContainer:
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 0)
	for i: int in rows.size():
		if i > 0:
			var line := ColorRect.new()
			line.color = Color(ScreenKit.ink("card", true), 0.18)
			line.custom_minimum_size.y = maxf(1.0, UI.px(1))
			line.mouse_filter = Control.MOUSE_FILTER_IGNORE
			v.add_child(line)
		var own := RbBox.of(rows[i])
		if own != null:
			own.visible = false
		v.add_child(rows[i])
	var card := ScreenKit.panel("card", v, 18.0, 4.0)
	card.name = named
	return card


## A button as wide as the column, its words wrapping rather than widening it.
func _wide(b: Button) -> Button:
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return b


## A button the tests find by its action (meta "auth").
func _button(action: String, words: String, pressed: Callable, material: String) -> Button:
	var b := ScreenKit.button(words, pressed, material)
	b.set_meta("auth", action)
	return b


## The status's colour, as UI.status gives its kinds.
func _tone(kind: String) -> Color:
	match kind:
		"success":
			return Palette.SUCCESS
		"alarm":
			return Palette.ALARM
	return ScreenKit.ink("card")


## An action pressed: signing in at once; a sign-out confirmed first.
func _act(what: String) -> void:
	match what:
		"sign_in", "retry":
			await App.services.auth_flow.sign_in()
		"sign_out", "sign_out_everywhere":
			var pending := await App.services.auth_flow.before_sign_out()
			ask(what == "sign_out_everywhere", pending)


func _link(platform: String) -> void:
	await App.services.auth_flow.link(platform)


## The confirm for this device's sign-out, or everywhere's.
func ask(everywhere: bool, pending: int) -> void:
	var c := AuthPresenter.confirm(everywhere, pending)
	c["no"] = Strings.t("AUTH_CANCEL")
	_confirm(c, _confirmed.bind(everywhere))


## The confirm for ending one device ("device", its id and name), every
## other ("others"), or removing a platform ("unlink", its name and key).
func ask_change(what: String, id := 0, title := "", platform := "") -> void:
	var c := AuthPresenter.confirm_change(what, title)
	var flow := App.services.auth_flow
	var go := func() -> void:
		_dismiss()
		match what:
			"device":
				await flow.end_device(id)
			"others":
				await flow.sign_out_others()
			_:
				await flow.unlink(platform)
	_confirm(c, go)


## A dialog over the screen this panel is on, its safe answer focused.
func _confirm(c: Dictionary, yes_pressed: Callable) -> void:
	if is_instance_valid(_dialog):
		_dialog.queue_free()
	var yes := ScreenKit.button(str(c["yes"]), yes_pressed, "red")
	yes.set_meta("auth", "confirm")
	var no := ScreenKit.button(str(c["no"]), _dismiss, "gold")
	no.set_meta("auth", "cancel")
	_dialog = KitPanels.dialog(_host(), str(c["title"]), str(c["words"]), [no, yes])
	no.grab_focus.call_deferred()


func _confirmed(everywhere: bool) -> void:
	_dismiss()
	await App.services.auth_flow.sign_out(everywhere)


func _dismiss() -> void:
	if is_instance_valid(_dialog):
		_dialog.queue_free()
	_dialog = null


## The screen this panel is on: the dialog covers all of it.
func _host() -> Control:
	var at: Node = self
	while at.get_parent() is Control:
		at = at.get_parent()
	return at as Control
