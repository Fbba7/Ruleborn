class_name Router
extends RefCounted
## The screens and the one way between them. A screen asks for a route by
## name; the router records it in the store and swaps the scene, so the
## screen history is in the action log and a test can follow a flow without
## a scene tree (`change` is swapped for a recorder).

const ROUTES := {
	&"home": "res://scenes/home.tscn",
	&"heist": "res://scenes/heist_screen.tscn",
	&"result": "res://scenes/result_screen.tscn",
	&"replay": "res://scenes/replay_screen.tscn",
	&"settings": "res://scenes/settings.tscn",
	&"builder": "res://scenes/builder.tscn",
}

var store: Store
## How a scene is shown; a test replaces it.
var change: Callable = func(path: String) -> void:
	(Engine.get_main_loop() as SceneTree).change_scene_to_file(path)


func _init(s: Store) -> void:
	store = s


func go(name: StringName, params := {}) -> void:
	assert(ROUTES.has(name), "no route %s" % name)
	if not ROUTES.has(name):
		push_error("no route %s" % name)
		return
	store.dispatch(&"navigated", {"name": name, "params": params})
	change.call(ROUTES[name])


func current() -> StringName:
	return store.get_slice(AppState.ROUTE)["name"]
