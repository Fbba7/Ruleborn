class_name Router
extends RefCounted
## The screens and the one way between them. A screen asks for a route by
## name; the router records it in the store and swaps the scene, so the
## screen history is in the action log and a test can follow a flow without
## a scene tree (`change` is swapped for a recorder).

const ROUTES := {
	&"home": "res://scenes/home.tscn",
	&"age": "res://scenes/age.tscn",
	&"heist": "res://scenes/heist_screen.tscn",
	&"result": "res://scenes/result_screen.tscn",
	&"replay": "res://scenes/replay_screen.tscn",
	&"settings": "res://scenes/settings.tscn",
	&"builder": "res://scenes/builder.tscn",
	&"track": "res://scenes/track.tscn",
	&"shop": "res://scenes/shop.tscn",
	&"social": "res://scenes/social.tscn",
	&"friends": "res://scenes/friends.tscn",
	&"workshop": "res://scenes/workshop.tscn",
	&"universe": "res://scenes/universe.tscn",
	&"roster": "res://scenes/roster.tscn",
	&"character": "res://scenes/character.tscn",
	&"sages": "res://scenes/sage_hall.tscn",
	&"forms": "res://scenes/forms.tscn",
	&"hatch": "res://scenes/hatch.tscn",
	&"weaving": "res://scenes/weaving.tscn",
	&"codex": "res://scenes/codex.tscn",
	&"harmony": "res://scenes/harmony.tscn",
	&"observatory": "res://scenes/observatory.tscn",
	&"lab": "res://scenes/lab.tscn",
	&"curation": "res://scenes/curation.tscn",
	&"law": "res://scenes/law.tscn",
	&"profile": "res://scenes/profile.tscn",
	&"planner": "res://scenes/planner.tscn",
	&"map": "res://scenes/map.tscn",
	&"realm": "res://scenes/realm.tscn",
	&"share": "res://scenes/share.tscn",
	&"first": "res://scenes/first.tscn",
	&"defences": "res://scenes/defences.tscn",
	&"scout": "res://scenes/scout.tscn",
}

## The five tabs of the design's bar (SCREENS.md): Islands opens the
## universe, Laws the Laws hub, Heist the Observatory, Crew the Crew hub and
## Friends the friends list.
const TABS := {"islands": &"home", "laws": &"codex", "heist": &"observatory", "crew": &"roster",
	"friends": &"friends"}
## The hubs a tab opens, chosen by the gold control under the header: their
## screens, in order, with the words on each segment.
const HUBS := {
	"laws": [{"route": &"codex", "words": "HUB_ALL_LAWS"}, {"route": &"harmony", "words": "HUB_HARMONY"},
		{"route": &"lab", "words": "HUB_LAB"}],
	"crew": [{"route": &"roster", "words": "HUB_ROSTER"}, {"route": &"sages", "words": "HUB_SAGES"},
		{"route": &"forms", "words": "HUB_FORMS"}],
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
