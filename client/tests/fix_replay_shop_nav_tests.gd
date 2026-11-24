class_name FixReplayShopNavTests
extends RefCounted
## The November bug report's replay, shop and navigation defects (FX4-3): a
## leased heist's replay shown on the test island (RB-43), the free hatch
## outfit that cannot be worn (RB-20), the phone's back that forgets the
## roster (RB-58), and the action log that loses the screen's name (RB-59).

var tree: SceneTree
var check: Callable


func _init(t: SceneTree, c: Callable) -> void:
	tree = t
	check = c


func run() -> void:
	await _leased_replay_is_not_shown_on_the_test_island()
	_hatch_outfit_is_wearable()
	_back_keeps_the_roster()
	_navigation_is_logged_by_name()


## An island that is not the fixture realm: a Heart with a guard posted.
static func _other_island() -> PackedByteArray:
	var i := RulebornIsland.new()
	i.reset(3)
	i.post_guard(0, 4, 4)
	return i.bytes()


## RB-43: a heist leased from the Observatory or the planner starts with no
## island in the HEIST state, so the result screen hands `load` empty island
## bytes. A replay played on another island must not load on the fixture
## realm: the result screen leaves the night empty. A replay played on the
## fixture realm, as the goldens are, still loads with no island.
func _leased_replay_is_not_shown_on_the_test_island() -> void:
	var island := _other_island()
	var played := RulebornReplay.new()
	var started := played.start(HeistController.SEED, HeistController.TICKS, HeistController.CREW, island)
	var replay := played.record()
	var on_its_own := RulebornReplay.new().load(replay, island)
	var on_fixture := RulebornReplay.new().load(replay, PackedByteArray())
	var golden := RulebornReplay.new().load(
		FileAccess.get_file_as_bytes("res://goldens/planned-clean.rbh"), PackedByteArray())
	var store: Store = App.services.store
	store.dispatch(&"heist_started", {"target": {"bundle": "b-leased", "trace": false}})
	store.dispatch(&"heist_finished", {"replay": replay, "verdict": {"ok": true, "grade": "Clean", "banked": 0}})
	var result: ResultScreen = load("res://scenes/result_screen.tscn").instantiate()
	tree.root.add_child(result)
	await tree.process_frame
	var night := {"moments": result._moments.size(), "ticks": result._ticks}
	result.queue_free()
	store.dispatch(&"heist_started", {})
	await tree.process_frame
	check.call("RB-43: a leased heist's replay does not load on the fixture realm, so the result screen leaves "
			+ "the night empty; a fixture replay still loads with no island",
		started and on_its_own and not on_fixture and golden and night == {"moments": 0, "ticks": 0},
		"started %s, on its island %s, on the fixture %s, golden %s, result night %s"
			% [started, on_its_own, on_fixture, golden, night])


## RB-20: §19.20's free outfit with the first hatch (home.mjs grants
## `hatch-outfit`) is not in the catalogue; the server's kindOf reads it as an
## outfit, so the shop shows it wearable, worn by a crew role.
func _hatch_outfit_is_wearable() -> void:
	var shown := ShopPresenter.shop({"items": [{"id": "robe", "kind": "sage_robe", "price": 500}],
		"owned": ["hatch-outfit"], "equipped": {}, "loaded": true}, StorePurchases.new())
	var mine: Array = shown.get("owned", [])
	var hatch: Dictionary = mine[0] if mine.size() == 1 else {}
	check.call("RB-20: the free hatch outfit is an outfit, wearable from the shop as the server's kindOf reads it",
		ShopPresenter.kind_of("hatch-outfit", []) == "outfit" and hatch.get("kind") == "outfit"
			and hatch.get("wearable") == true,
		"kind_of '%s', shown %s" % [ShopPresenter.kind_of("hatch-outfit", []), hatch])


## RB-58: roster, a stage and a filter chosen, a character opened, then the
## phone's back (or Escape): the roster comes back as it was left (AD-R51),
## as the character screen's own back button brings it.
func _back_keeps_the_roster() -> void:
	var store := Store.new()
	AppState.register(store)
	var router := Router.new(store)
	router.change = func(_path: String) -> void: pass
	var left := {"chosen": 2, "filter": "scout", "scroll": 120}
	router.go(&"roster")
	router.go(&"character", {"id": "c1", "roster": left})
	var quits := router.go_back()
	var route: Dictionary = store.get_slice(AppState.ROUTE)
	check.call("RB-58: the phone's back from a character brings the roster back with its stage and filter",
		not quits and route["name"] == &"roster" and route["params"].get("roster") == left,
		"%s" % [route])


## RB-59: the router names a screen with a StringName; the action log keeps
## it, so a defect report carries the screen history.
func _navigation_is_logged_by_name() -> void:
	var store := Store.new()
	AppState.register(store)
	var router := Router.new(store)
	router.change = func(_path: String) -> void: pass
	store.action_log.clear()
	router.go(&"shop")
	var logged: Array = store.action_log.entries().filter(
		func(e: Dictionary) -> bool: return e["what"] == "navigated")
	var fields: Dictionary = logged[-1]["fields"] if not logged.is_empty() else {}
	check.call("RB-59: a navigation in the action log names the screen",
		fields.get("name") == "shop" and fields.get("name") is String, "%s" % [logged])
