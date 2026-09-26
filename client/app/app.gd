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
	if services == null:
		var root := node.get_tree().root
		services = Services.build(root, Services.server_url())
		root.add_child.call_deferred(AppLifetime.new())
