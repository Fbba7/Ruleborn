class_name App
extends RefCounted
## The composition root: the one place the app's services live. The first
## screen to open builds them (`ready`); tests build their own and put them
## here before a screen is mounted. A plain class rather than an autoload, so
## a test script and a screen see the same thing.

static var services: Services


## Build the services if nothing has yet: the real network, and the server
## the environment or the project names.
static func ready(node: Node) -> void:
	# The realm's actors are the design's characters (world/cast.gd).
	if not WorldView.figure_maker.is_valid():
		WorldView.figure_maker = Cast.figure
	if services == null:
		var root := node.get_tree().root
		services = Services.build(root, Services.server_url())
		services.auth_flow.reset = restart.bind(root)
		root.add_child.call_deferred(AppLifetime.new())
		root.add_child.call_deferred(GoBack.new())
		# Development builds only: the state and the last actions, on F12 or a
		# three-finger tap (ui/debug_overlay.gd).
		if OS.is_debug_build():
			root.add_child.call_deferred(DebugOverlay.new(services))


## Signed out (AuthController): the services built anew, so nothing the
## account's session held stays in memory, the panel's `shown` status in the
## new ones, and the player back at the first screen.
static func restart(shown: Dictionary, root: Window) -> void:
	if services != null:
		services.close()
	services = Services.build(root, Services.server_url())
	services.auth_flow.reset = restart.bind(root)
	services.store.dispatch(&"auth_status", shown)
	services.router.go(&"home")


## The phone's back and Escape, for the whole app: both go to the router's
## one back table (Router.go_back), and the game never quits on a back alone.
## On home the back asks first, in the kit's question: Quit or Stay, Stay the
## default and focused, so a stray back never ends the game; a second back
## closes it, as Stay does, and with home's menu open the back closes the
## menu. One back a frame, so a key and the phone's request together count
## once.
class GoBack:
	extends Node

	## Home's question whether to quit, while it shows.
	var question: Control
	var _frame := -1

	func _ready() -> void:
		name = "GoBack"
		process_mode = Node.PROCESS_MODE_ALWAYS
		get_tree().set_quit_on_go_back(false)

	func _notification(what: int) -> void:
		if what == NOTIFICATION_WM_GO_BACK_REQUEST:
			back()

	func _unhandled_input(event: InputEvent) -> void:
		if event.is_action_pressed("ui_cancel") and not event.is_echo():
			get_viewport().set_input_as_handled()
			back()

	## Goes back once, whatever asked.
	func back() -> void:
		var frame := Engine.get_process_frames()
		if frame == _frame or App.services == null:
			return
		_frame = frame
		if is_instance_valid(question):
			stay()
			return
		var home := get_tree().current_scene as Home
		if App.services.router.go_back() and home != null:
			if home.menu != null and home.menu.visible:
				home.menu.close()
			else:
				ask(home)

	## The question, over home.
	func ask(home: Control) -> void:
		var router: Router = App.services.router
		var leave := UI.action(Strings.t("HOME_QUIT"), func() -> void: router.quit.call())
		leave.name = "Quit"
		var keep := UI.action(Strings.t("HOME_STAY"), stay, "gold")
		keep.name = "Stay"
		question = KitPanels.dialog(home, Strings.t("HOME_QUIT_TITLE"), "", [leave, keep], "confirm")
		keep.grab_focus.call_deferred()

	func stay() -> void:
		if is_instance_valid(question):
			question.queue_free()
		question = null
