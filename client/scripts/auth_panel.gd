class_name AuthPanel
extends VBoxContainer
## The account's sign-in, on Settings' Account section (docs/security/auth.md):
## where signing in stands, in words — the first launch, signing in, signed
## in (and on how many devices), offline, a failure and its reason, signed
## out — and its actions: sign in, try again, sign out, sign out everywhere.
## Each sign-out asks first, in a dialog naming what still waits to be sent,
## which stays on the phone for this account. Built from the UI kit; the
## words from AuthPresenter.

var status_label: Label
var detail_label: Label
var _dialog: Control


func _ready() -> void:
	App.ready(self)
	name = "AuthPanel"
	add_theme_constant_override("separation", UI.px(8))
	App.services.store.changed.connect(_on_changed)
	App.services.auth_flow.refresh_status()
	_build()
	if App.services.auth.fresh():
		App.services.auth_flow.devices()


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
	var v := AuthPresenter.panel(App.services.store.get_slice(AuthState.AUTH))
	add_child(KitNav.rule())
	var heading := UI.label(Strings.t("AUTH_TITLE"), float(Tokens.type_role("heading")["points"]), true)
	heading.theme_type_variation = "Heading"
	add_child(heading)
	status_label = UI.status(str(v["kind"]), str(v["line"]))
	status_label.accessibility_live = AccessibilityServer.LIVE_POLITE
	add_child(UI.plate(status_label))
	detail_label = UI.label(str(v["detail"]), -1.0, true)
	detail_label.visible = str(v["detail"]) != ""
	add_child(detail_label)
	var r := UI.row()
	for a: String in v["actions"]:
		var b := UI.button(AuthPresenter.action(a), _act.bind(a), a in ["sign_in", "retry"])
		b.set_meta("auth", a)
		r.add_child(b)
	add_child(r)


## An action pressed: signing in at once; a sign-out confirmed first.
func _act(what: String) -> void:
	match what:
		"sign_in", "retry":
			await App.services.auth_flow.sign_in()
		"sign_out", "sign_out_everywhere":
			var pending := await App.services.auth_flow.before_sign_out()
			ask(what == "sign_out_everywhere", pending)


## The confirm: the dialog over the screen this panel is on.
func ask(everywhere: bool, pending: int) -> void:
	if is_instance_valid(_dialog):
		_dialog.queue_free()
	var c := AuthPresenter.confirm(everywhere, pending)
	var yes := UI.button(str(c["yes"]), _confirmed.bind(everywhere), false, Palette.ALARM)
	yes.set_meta("auth", "confirm")
	var no := UI.button(Strings.t("AUTH_CANCEL"), _dismiss, true)
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
