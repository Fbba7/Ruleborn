class_name AgeTests
extends RefCounted
## §20.1's age check: asked once at first launch, kept on the phone, no
## account below 13, and the answer given to the server once an account
## exists.

var tree: SceneTree
var check: Callable
var server_url := ""


func _init(t: SceneTree, c: Callable, url: String) -> void:
	tree = t
	check = c
	server_url = url


func run() -> void:
	_kept()
	await _no_account_under_13()
	await _sent_once()
	await _against_server()


func _fresh(name: String) -> AgeCheck:
	var path := "user://age-%s-test.json" % name
	DirAccess.remove_absolute(path)
	return AgeCheck.new(path)


func _kept() -> void:
	var a := _fresh("kept")
	var before := a.band()
	a.answer("16-17")
	var again := AgeCheck.new(a.path)
	var young := _fresh("young")
	young.answer("under-13")
	young.answer("18+")
	var told := _fresh("told")
	told.platform = func() -> String: return "13-15"
	check.call("the age check answers once and is kept on the phone; a player under 13 keeps that answer; the "
			+ "platform's answer, when it has one, is taken instead of asking (§20.1)",
		before == "" and not AgeCheck.new(_fresh("none").path).allows_account() and again.band() == "16-17"
			and again.allows_account() and not again.sent() and young.band() == "under-13"
			and not young.allows_account() and told.band() == "13-15" and AgeCheck.new(told.path).band() == "13-15",
		"%s %s %s %s" % [before, again.band(), young.band(), told.band()])


func _fake(age: AgeCheck) -> Array:
	var transport := FakeTransport.new()
	var s := Services.build(tree.root, "https://edge.example", transport, "user://outbox-age-test.json")
	s.router.change = func(_path: String) -> void: pass
	s.age = age
	transport.on("POST /v1/session", {"account": "acc1", "token": "tok"})
	transport.on("PUT /v1/age", {"ageBand": "16-17"})
	return [s, transport]


## §20.1: "Players under 13 are told the game is for 13 and up, and no account
## is created" — nor before the check has answered; a call that needs a
## session is refused on the phone.
func _no_account_under_13() -> void:
	var unasked: Array = _fake(_fresh("unasked"))
	var young_check := _fresh("under")
	young_check.answer("under-13")
	var young: Array = _fake(young_check)
	var s1: Services = unasked[0]
	var s2: Services = young[0]
	var ok1 := await s1.sign_in()
	var ok2 := await s2.sign_in()
	var r := await s2.shop.catalogue()
	var calls: Array = (unasked[1] as FakeTransport).calls + (young[1] as FakeTransport).calls
	check.call("no account is made before the age check answers, nor ever under 13: no sign-in reaches the server "
			+ "(§20.1, §20.11)",
		not ok1 and not ok2 and not r.ok and calls.all(func(c: Dictionary) -> bool:
			return c["route"] != "POST /v1/session"),
		"%s %s %s %s" % [ok1, ok2, r.code, calls.map(func(c: Dictionary) -> String: return c["route"])])
	s1.close()
	s2.close()


func _sent_once() -> void:
	var age := _fresh("sent")
	age.answer("16-17")
	var f: Array = _fake(age)
	var s: Services = f[0]
	var transport: FakeTransport = f[1]
	var first := await s.sign_in()
	var second := await s.sign_in()
	var sent := transport.calls.filter(func(c: Dictionary) -> bool: return c["route"] == "PUT /v1/age")
	var body: Dictionary = JSON.parse_string((sent[0]["body"] as PackedByteArray).get_string_from_utf8()) \
		if sent.size() > 0 else {}
	check.call("the age band goes to the server with the first sign-in, and once",
		first and second and sent.size() == 1 and body == {"band": "16-17"} and age.sent(),
		"%s %s %s" % [first, second, sent.size()])
	s.close()


func _against_server() -> void:
	var name := "against the server: an adult's answer reaches the account, and the Workshop's every list opens "
	name += "to them; before it, a new account sees the featured list only (§20.1, §20.7)"
	if server_url == "":
		check.call(name, false, "no server: run through client/status.py, which starts one")
		return
	var s := Services.build(tree.root, server_url, null, "user://outbox-age-server-test.json")
	s.router.change = func(_path: String) -> void: pass
	var unasked := _fresh("server")
	s.age = unasked
	var refused := await s.sign_in()
	# A new account, before its age check has reached the server.
	var fresh := await s.account.sign_in("test:age-unanswered")
	var before := await s.workshop.browse("top")
	unasked.answer("18+")
	var signed := await s.sign_in()
	var after := await s.workshop.browse("top")
	check.call(name,
		not refused and fresh.ok and not before.ok and before.code == "curated_lists_only" and signed and after.ok
			and unasked.sent(),
		"%s %s %s %s" % [refused, before.code, signed, after.code])
	s.close()
