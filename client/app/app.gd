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
