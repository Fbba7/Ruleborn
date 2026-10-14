class_name CodexTests
extends RefCounted
## The Codex (§7.6, §18.5, §23.2): its words headless, its changes through a
## FakeTransport, the screen as drawn, and the Codex against the server when
## one is named.

var tree: SceneTree
var check: Callable
var mount: Callable
var server_url := ""


func _init(t: SceneTree, c: Callable, m: Callable, url: String) -> void:
	tree = t
	check = c
	mount = m
	server_url = url


func run() -> void:
	_words()
	await _flows()
	await _on_screen()
	await _online()


## A Codex as GET /v1/codex answers at Keeper level 1 and Spire level 1:
## the three starting laws, Glass met with enough pages to restore, Kinship
## met with too few, Haste met from chapter 2, and Bloom worked on.
static func sample() -> Dictionary:
	var known := func(law: String, school: String, rank: String, chapter: int, pages: int, tier: int,
			open: bool) -> Dictionary:
		var next: Variant = {"pages": 10} if tier == 0 else {"pages": 20, "aether": 2000, "spire": 4}
		return {"known": true, "law": law, "school": school, "rank": rank, "chapter": chapter, "open": open,
			"pages": pages, "tier": tier, "next": next}
	var unknown := func(chapter: int) -> Dictionary:
		return {"known": false, "chapter": chapter, "open": chapter == 1}
	var album := func(school: String, laws: Array, restored: int) -> Dictionary:
		return {"school": school, "laws": laws, "restored": restored,
			"milestones": [{"at": 2, "reached": restored >= 2}, {"at": 4, "reached": restored >= 4},
				{"at": 8, "reached": false}]}
	var albums := [
		album.call("Motion", [known.call("half_gravity", "Motion", "Common", 1, 3, 1, true), unknown.call(1),
			unknown.call(2), unknown.call(2)], 1),
		album.call("Matter", [unknown.call(1), known.call("glass", "Matter", "Common", 1, 12, 0, true),
			unknown.call(2), unknown.call(2)], 0),
		album.call("Time", [known.call("slow_rivers", "Time", "Common", 1, 0, 1, true), unknown.call(1),
			known.call("haste", "Time", "Uncommon", 2, 5, 0, false), unknown.call(2)], 1),
		album.call("Energy", [unknown.call(1), unknown.call(1), unknown.call(2), unknown.call(2)], 0),
		album.call("Life", [known.call("bloom", "Life", "Common", 1, 0, 1, true),
			known.call("kinship", "Life", "Common", 1, 4, 0, true), unknown.call(2), unknown.call(2)], 1),
		album.call("Spirit", [unknown.call(1), unknown.call(1), unknown.call(2), unknown.call(2)], 0)]
	var mastery := []
	for school: String in ["Motion", "Matter", "Time", "Energy", "Life", "Spirit"]:
		mastery.append({"school": school, "steps": 1 if school == "Motion" else 0, "total": 12,
			"marks": {"title": 4, "style": 8, "last_title": 12}})
	return {"laws": [], "albums": albums, "mastery": mastery, "working_on": "bloom", "keeper_level": 1, "spire": 1,
		"aether": 1250, "next_chapter_at": 6}


static func _law(c: Dictionary, school: String, law: String) -> Dictionary:
	for a: Dictionary in c["albums"]:
		if a["school"] == school:
			for l: Dictionary in a["laws"]:
				if l.get("law", "") == law:
					return l
	return {}


func _words() -> void:
	var c := CodexPresenter.screen({"view": sample(), "busy": "", "error": "", "last": {}})
	var motion: Dictionary = c["albums"][0]
	var lines: Array = (motion["laws"] as Array).map(func(l: Dictionary) -> String: return l["text"])
	check.call("the Codex shows each school's album by its shape and name, its laws in chapter order, a law not met "
			+ "a ? that names nothing, and when a closed chapter opens (7.6, 21.2, D79)",
		(c["albums"] as Array).size() == 6 and motion["title"] == UI.school_mark("Motion")
			and lines == ["Half gravity · Common · tier I · 3 pages",
				"? · not met yet: a heist through a realm running it meets it",
				"? · chapter 2, from Keeper level 6", "? · chapter 2, from Keeper level 6"]
			and c["chapter"] == "Chapter 2 opens at Keeper level 6"
			and c["header"] == "1,250 Aether · Keeper 1 · Spire 1",
		"%s | %s" % [lines, c.get("chapter")])
	check.call("the Codex shows each album's restored count and its three milestones, and each school's mastery "
			+ "track with its marks: a title at a third, the style at two thirds, a title at all (7.6, 18.5)",
		motion["count"] == "1 of 4 restored"
			and motion["milestones"] == ["○ a Codex stamp at 2 restored", "○ a skiff pennant at 4",
				"○ the school's crest on your islands at 8"]
			and motion["mastery"] == "Mastery: 1 of 12 steps"
			and motion["marks"] == "A title at 4, the school's new style at 8, a title at 12",
		"%s" % [motion])
	var glass := _law(c, "Matter", "glass")
	var kinship := _law(c, "Life", "kinship")
	var haste := _law(c, "Time", "haste")
	var hg := _law(c, "Motion", "half_gravity")
	check.call("each law met says its next step with its price on the button, and why it waits: too few pages, a "
			+ "closed chapter, or the Spire a tier needs (7.6)",
		glass["text"] == "Glass · Common · 12 of 10 pages to restore" and glass["act"]["can"]
			and glass["act"]["action"] == "Restore: 10 pages"
			and not kinship["act"]["can"] and kinship["act"]["why"] == "4 of 10 pages"
			and not haste["act"]["can"] and haste["act"]["why"] == "chapter 2 opens at Keeper level 6"
			and not hg["act"]["can"] and hg["act"]["why"] == "Needs the Spire at level 4"
			and hg["act"]["action"] == "Tier II: 20 pages, 2,000 Aether",
		"%s | %s | %s | %s" % [glass["act"], kinship["act"], haste["act"], hg["act"]])
	var bloom := _law(c, "Life", "bloom")
	check.call("the Codex names the law worked on, which every eighth heist pages, and any law met can be marked "
			+ "worked on in one tap (7.6)",
		c["working"] == "Working on Bloom: every eighth heist brings a page of it" and bloom["worked"]
			and (bloom["work"] as Dictionary).is_empty() and glass["work"]["action"] == "Work on it"
			and glass["work"]["spoken"] == "Work on Glass",
		"%s | %s" % [c["working"], glass["work"]])


func _flows() -> void:
	var transport := FakeTransport.new()
	var s := Fixtures.answered(Services.build(tree.root, "https://edge.example", transport,
		"user://outbox-codex-test.json"))
	s.api.token = "t"
	transport.on("GET /v1/codex", sample())
	await s.codex_flow.load_codex()
	transport.on("POST /v1/codex/restore", {"codex": sample(), "keeper": {"gained": 70, "level": 1, "xp": 70,
		"toNext": 30}})
	await s.codex_flow.restore("glass")
	var sent: Dictionary = JSON.parse_string((transport.calls[-1]["body"] as PackedByteArray).get_string_from_utf8())
	var said: String = CodexPresenter.screen(s.store.get_slice(CodexState.CODEX))["said"]
	var xp := int(s.store.get_slice(KeeperState.KEEPER)["view"].get("xp", 0))
	transport.on("POST /v1/codex/tier", {"error": "needs_spire_level", "needs": 4}, 409)
	await s.codex_flow.tier("half_gravity", 2)
	var refused: Dictionary = s.store.get_slice(CodexState.CODEX)
	var tier_sent: Dictionary = JSON.parse_string(
		(transport.calls[-1]["body"] as PackedByteArray).get_string_from_utf8())
	var worked := sample()
	worked["working_on"] = "glass"
	transport.on("POST /v1/codex/working", worked)
	await s.codex_flow.work_on("glass")
	var after: Dictionary = s.store.get_slice(CodexState.CODEX)
	check.call("restoring sends the law and shows the Codex and the Keeper's experience the server answers; a "
			+ "refused tier keeps the Codex on show and says why; marking a law worked on shows it (7.6, 14.2)",
		sent.get("law") == "glass" and said == "Glass restored" and xp == 70
			and refused["error"] == "needs_spire_level" and not (refused["view"] as Dictionary).is_empty()
			and tier_sent.get("law") == "half_gravity" and int(tier_sent.get("to", 0)) == 2
			and after["view"]["working_on"] == "glass"
			and CodexPresenter.screen(after)["said"] == "Working on Glass",
		"%s | %s | %s | %s" % [sent, said, xp, refused["error"]])
	s.close()


func _on_screen() -> void:
	var services: Services = App.services
	var screen: CodexScreen = await mount.call("codex")
	await tree.process_frame
	services.store.dispatch(&"codex_loaded", {"view": sample()})
	var find := func(key: String) -> Button:
		for b: Button in screen.find_children("*", "Button", true, false):
			if b.get_meta("key", "") == key:
				return b
		return null
	var schools := screen.body.find_children("*", "Label", true, false).filter(
		func(l: Label) -> bool: return l.has_meta("school"))
	var restore: Button = find.call("restore:glass")
	var waits: Button = find.call("restore:kinship")
	var tier: Button = find.call("tier:half_gravity:2")
	var drawn: bool = schools.size() == 6 and restore != null and restore.text == "Restore: 10 pages" \
		and not restore.disabled and waits != null and waits.disabled and tier != null and tier.disabled
	restore.pressed.emit()
	await tree.process_frame
	var asked: Button = find.call("restore:glass")
	var confirming: bool = asked != null and asked.text == "Tap again to spend 10 pages" \
		and services.store.get_slice(CodexState.CODEX)["busy"] == ""
	screen.queue_free()
	await tree.process_frame
	check.call("the Codex screen draws the six albums by their marks, each law's step with its price, a step that "
			+ "waits disabled with why, and spends pages on a second tap (7.6, 23.2)",
		drawn and confirming, "%s %s" % [drawn, confirming])


func _online() -> void:
	var name := "against the server: a new Keeper's Codex holds six albums of four launch laws, the starting "
	name += "three restored and the rest a ?, mastery tracks of twelve steps, and a law marked worked on (7.6, 18.5)"
	if server_url == "":
		check.call(name, false, "no server: run through client/status.py, which starts one")
		return
	var s := Fixtures.answered(Services.build(tree.root, server_url, null, "user://outbox-test-codex.json"))
	s.router.change = func(_path: String) -> void: pass
	var me := await s.account.sign_in("test:codex")
	if not me.ok:
		check.call(name, false, "sign-in refused: %s" % me.code)
		s.close()
		return
	await s.codex_flow.load_codex()
	var v: Dictionary = s.store.get_slice(CodexState.CODEX)["view"]
	var albums: Array = v.get("albums", [])
	var known := 0
	var unknown := 0
	for a: Dictionary in albums:
		for l: Dictionary in a["laws"]:
			if l["known"]:
				known += 1
			else:
				unknown += 1
	var tracks: Array = v.get("mastery", [])
	await s.codex_flow.work_on("slow_rivers")
	var after: Dictionary = s.store.get_slice(CodexState.CODEX)
	check.call(name,
		albums.size() == 6 and albums.all(func(a: Dictionary) -> bool: return (a["laws"] as Array).size() == 4)
			and known == 3 and unknown == 21 and tracks.size() == 6
			and tracks.all(func(m: Dictionary) -> bool: return int(m["total"]) == 12)
			and after["error"] == "" and after["view"].get("working_on") == "slow_rivers",
		"%s albums, %s known, %s unknown, %s" % [albums.size(), known, unknown, after["error"]])
	s.close()
