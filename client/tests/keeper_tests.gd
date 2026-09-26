class_name KeeperTests
extends RefCounted
## The Keeper bar (§14.2): its reducers and words headless, and the server's
## level fetched through a FakeTransport.

var tree: SceneTree
var check: Callable
var mount: Callable


func _init(t: SceneTree, c: Callable, m: Callable) -> void:
	tree = t
	check = c
	mount = m


func run() -> void:
	_reducers()
	_bar()
	_earned()
	_repeated()
	await _fetched()
	await _on_screen()


func _reducers() -> void:
	var store := Store.new()
	KeeperState.register(store)
	store.dispatch(&"keeper_loaded", {"view": {"level": 1, "xp": 36, "toNext": 140, "cap": 40}})
	store.dispatch(&"keeper_failed", {"code": "unreachable"})
	var failed: Dictionary = store.get_slice(KeeperState.KEEPER)
	store.dispatch(&"keeper_earned", {"keeper": {"gained": 120, "level": 2, "xp": 16, "toNext": 90, "levelled": 1}})
	var earned: Dictionary = store.get_slice(KeeperState.KEEPER)
	check.call("the Keeper reducers keep the bar on show when a fetch fails, and a heist's answer moves it "
			+ "without asking again (14.2)",
		failed["view"]["xp"] == 36 and failed["error"] == "unreachable" and earned["view"]["level"] == 2
			and earned["view"]["xp"] == 16 and earned["view"]["toNext"] == 90 and earned["view"]["cap"] == 40,
		"%s | %s" % [failed, earned])


func _bar() -> void:
	var first := KeeperPresenter.bar({"view": {"level": 1, "xp": 36, "toNext": 140, "cap": 40}})
	var tenth := KeeperPresenter.bar({"view": {"level": 10, "xp": 1050, "toNext": 2230, "cap": 40}})
	var top := KeeperPresenter.bar({"view": {"level": 40, "xp": 0, "toNext": null, "cap": 40}})
	Strings.set_locale("pt_BR")
	var pt := KeeperPresenter.bar({"view": {"level": 10, "xp": 1050, "toNext": 2230, "cap": 40}})
	Strings.set_locale("en")
	var none := KeeperPresenter.bar({"view": {}, "error": "offline"})
	check.call("the Keeper bar says the level, fills ten pips by the share of the way to the next, and gives the "
			+ "numbers in the player's own way of writing them; the top level says so; nothing is shown before "
			+ "the server has said (14.2, 20.8)",
		first["title"] == "Keeper 1" and first["pips"] == "●●○○○○○○○○"
			and first["progress"] == "36 of 140 experience to Keeper 2" and first["spoken"].contains("Keeper 1")
			and tenth["pips"] == "●●●●○○○○○○" and tenth["progress"].contains("1,050") and tenth["progress"].contains("2,230")
			and pt["progress"].contains("1.050") and top["pips"] == "●●●●●●●●●●"
			and top["progress"] == Strings.t("KEEPER_TOP", 40) and not none["ready"],
		"%s | %s | %s | %s" % [first, tenth, top, pt])


func _earned() -> void:
	var gained := KeeperPresenter.earned({"gained": 36, "level": 1, "xp": 36, "toNext": 140, "levelled": 0})
	var up := KeeperPresenter.earned({"gained": 60, "level": 6, "xp": 40, "toNext": 1050, "levelled": 1})
	var settled := HeistController.settled(Result.success({"validated": true, "verdict": {"grade": "clean",
		"banked": 508}, "haul": {"total": 11250}, "fee": 0, "keeper": {"gained": 36, "level": 1}}), {})
	check.call("a heist's result says the Keeper experience it earned and the level it reached; a heist that earned "
			+ "none says nothing about it (14.2)",
		gained == Strings.t("RESULT_KEEPER", "36") and up.contains(Strings.t("RESULT_KEEPER_UP", 6))
			and KeeperPresenter.earned(null) == "" and KeeperPresenter.earned({"gained": 0}) == ""
			and settled["keeper"]["gained"] == 36,
		"%s | %s | %s" % [gained, up, settled])


func _fetched() -> void:
	var transport := FakeTransport.new()
	var s := Fixtures.answered(Services.build(tree.root, "https://edge.example", transport,
		"user://outbox-keeper-test.json"))
	s.api.token = "t"
	transport.on("GET /v1/keeper", {"level": 3, "xp": 12, "toNext": 270, "cap": 40})
	await s.keeper_flow.load_keeper()
	var shown := KeeperPresenter.bar(s.store.get_slice(KeeperState.KEEPER))
	transport.on("GET /v1/keeper", {"error": "internal"}, 500)
	await s.keeper_flow.load_keeper()
	var after: Dictionary = s.store.get_slice(KeeperState.KEEPER)
	check.call("the Keeper bar is the server's level, and a failed fetch leaves the last one on show (14.2)",
		shown["ready"] and shown["title"] == "Keeper 3" and shown["progress"].contains("12 of 270")
			and after["view"]["level"] == 3 and after["error"] == "internal",
		"%s | %s" % [shown, after])
	s.close()


## An answer the server gave before earned its experience then: it carries
## none, and the lease it settled leaves the offline stock.
func _repeated() -> void:
	var again := HeistController.settled(Result.success({"validated": true, "repeated": true, "verdict": {
		"grade": "clean", "banked": 508}, "haul": {"total": 11250}, "fee": 0, "keeper": {"gained": 36, "level": 2,
		"levelled": 1}}), {})
	var path := "user://leases-keeper-test.json"
	DirAccess.remove_absolute(path)
	var stock := LeaseStock.new(path)
	stock.add("b1", {"token": "T1", "expiresAt": 1}, PackedByteArray([1]))
	stock.add("b2", {"token": "T2", "expiresAt": 2}, PackedByteArray([2]))
	stock.drop("T1")
	var kept := LeaseStock.new(path)
	check.call("a repeated answer carries no Keeper experience and announces no level; a lease played online leaves "
			+ "the offline stock, so it is never played twice (14.2, 24.12)",
		again["keeper"] == null and KeeperPresenter.earned(again["keeper"]) == "" and kept.count() == 1
			and kept.bundles() == ["b2"],
		"%s | %s" % [again, kept.bundles()])


## The bar on Home and the line on the result screen, as drawn.
func _on_screen() -> void:
	var services: Services = App.services
	var home: Home = await mount.call("home")
	var hidden := not home.keeper_plate.visible
	services.store.dispatch(&"keeper_loaded", {"view": {"level": 3, "xp": 12, "toNext": 270, "cap": 40}})
	var shown := home.keeper_plate.visible and home.keeper_label.text.contains("Keeper 3") \
		and home.keeper_label.text.contains("○○○○○○○○○○") and home.keeper_label.text.contains("12 of 270") \
		and home.keeper_label.accessibility_name == Strings.t("KEEPER_SPOKEN", [3, Strings.t("KEEPER_PROGRESS",
			["12", "270", 4])])
	services.store.dispatch(&"keeper_earned", {"keeper": {"gained": 300, "level": 4, "xp": 42, "toNext": 370}})
	var moved := home.keeper_label.text.contains("Keeper 4") and home.keeper_label.text.contains("42 of 370")
	home.queue_free()
	var result: ResultScreen = await mount.call("result_screen")
	result.show_verdict({"ok": true, "server": true, "grade": "Clean", "banked": 508, "haul": 11250, "fee": 0,
		"keeper": {"gained": 36, "level": 2, "levelled": 1}}, 900)
	var said := result.detail_label.text
	result.queue_free()
	check.call("Home's Keeper bar waits for the server, then shows the level, the pips and the numbers, said aloud "
			+ "in words, and moves with a heist's answer; the result screen says what the raid earned (14.2)",
		hidden and shown and moved and said.contains(Strings.t("RESULT_KEEPER", "36"))
			and said.contains(Strings.t("RESULT_KEEPER_UP", 2)),
		"%s %s %s | %s" % [hidden, shown, moved, said.replace("\n", " / ")])
