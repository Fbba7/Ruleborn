class_name SocialPresenter
extends RefCounted
## What the league and friends screens show, from the store's slices: plain
## data, no nodes. A player is named by the device's platform names (§17.6:
## "Names are the device's"); until the platforms' friend lists are wired, a
## Keeper is named by the first letters of their account, which is theirs
## alone and names no one outside the game.


## A name the server gives in each language ({"en": …, "pt_BR": …}), in
## the player's; a plain string as it is.
static func named(v: Variant) -> String:
	if v is Dictionary:
		var d: Dictionary = v
		return str(d.get(TranslationServer.get_locale(), d.get("en", "")))
	return str(v)


## A name made from the word lists, as the server makes it (workshop.mjs's
## Workshop.name): "Quiet Harbour"; in Portuguese the noun first and the
## adjective agreeing with it, "Porto Silencioso".
static func word_name(words: Dictionary, adjective: int, noun: int) -> String:
	var adjectives: Array = words.get("adjectives", [])
	var nouns: Array = words.get("nouns", [])
	if adjectives.is_empty() or nouns.is_empty():
		return ""
	var a: Dictionary = adjectives[adjective % adjectives.size()]
	var n: Dictionary = nouns[noun % nouns.size()]
	if TranslationServer.get_locale() == "pt_BR":
		return "%s %s" % [str(n.get("pt_BR", "")), str((a.get("pt_BR", {}) as Dictionary).get(n.get("gender", "m"), ""))]
	return "%s %s" % [str(a.get("en", "")), str(n.get("en", ""))]


## A player as the screens name them: "you", or "Keeper 3F2A".
static func who(account: String, me: String) -> String:
	if account == me and me != "":
		return Strings.t("SOCIAL_YOU")
	return Strings.t("SOCIAL_KEEPER", account.left(4).to_upper())


## §18.1: the league and division, Renown, and how far to the next league.
static func league(l: Dictionary) -> Dictionary:
	var v: Dictionary = l.get("view", {})
	if v.is_empty():
		return {"ready": false, "error": str(l.get("error", ""))}
	var name := Strings.term("LEAGUE", str(v["league"]))
	var division: Variant = v.get("division")
	var placed := Strings.t("LEAGUE_PLACE", [name, _roman(int(division))]) if division != null \
		else Strings.t("LEAGUE_PLACE_TOP", name)
	var next: Variant = v.get("next")
	return {
		"ready": true, "error": str(l.get("error", "")),
		"place": placed,
		"renown": Strings.t("LEAGUE_RENOWN", [ShopPresenter.grouped(int(v["renown"])), int(v["season"])]),
		"next": Strings.t("LEAGUE_TO_NEXT", ShopPresenter.grouped(int(next) - int(v["renown"])))
			if next != null else Strings.t("LEAGUE_TOP"),
	}


static func _roman(n: int) -> String:
	return ["", "I", "II", "III"][clampi(n, 0, 3)]


## §17.1 and §17.7: the player's constellation and crew, or what joining
## takes, with the roles and the crew's invite.
static func groups(g: Dictionary, me: String) -> Dictionary:
	var c: Dictionary = g.get("constellation", {})
	var crew: Dictionary = g.get("crew", {})
	var members: Array[String] = []
	var founder := false
	for m: Dictionary in c.get("members", []):
		members.append(Strings.t("SOCIAL_MEMBER", [who(str(m["account"]), me), Strings.term("RANK", str(m["role"]))]))
		founder = founder or (str(m["account"]) == me and str(m["role"]) == "founder")
	var crew_members: Array[String] = []
	for m: Dictionary in crew.get("members", []):
		crew_members.append(who(str(m["account"]), me))
	return {
		"known": bool(g.get("known", false)), "error": str(g.get("error", "")),
		"in_constellation": not c.is_empty(),
		"constellation": Strings.t("SOCIAL_CONSTELLATION", [named(c.get("name", "")), members.size()])
			if not c.is_empty() else Strings.t("SOCIAL_NO_CONSTELLATION"),
		"members": members, "founder": founder,
		"in_crew": not crew.is_empty(),
		"crew": (Strings.t("SOCIAL_CREW_FORMED" if crew.get("formed", false) else "SOCIAL_CREW_FORMING",
				crew_members.size()) if not crew.is_empty() else Strings.t("SOCIAL_NO_CREW")),
		"crew_members": crew_members,
		"crew_invite": str(crew.get("invite", "")),
	}


## §17.6: friends, and the week's feed, newest first.
static func friends(f: Dictionary, me: String) -> Dictionary:
	var list: Array[Dictionary] = []
	for x: Dictionary in f.get("friends", []):
		list.append({"account": str(x["account"]), "name": who(str(x["account"]), me)})
	var feed: Array[String] = []
	for e: Dictionary in f.get("feed", []):
		var grade: Variant = e.get("grade")
		feed.append(Strings.t("FEED_" + str(e.get("mode", "raid")).to_upper() if Strings.rows().has(
				"FEED_" + str(e.get("mode", "raid")).to_upper()) else "FEED_RAID",
			[who(str(e["raider"]), me), who(str(e["defender"]), me),
				Strings.term("GRADE", str(grade)) if grade != null else "—"]))
	var invite: Dictionary = f.get("invite", {})
	var challenge: Dictionary = f.get("challenge", {})
	return {
		"error": str(f.get("error", "")), "busy": bool(f.get("busy", false)),
		"friends": list, "none": list.is_empty(),
		"feed": feed,
		"invite": Strings.t("FRIENDS_INVITE_CODE", str(invite["invite"])) if invite.has("invite") else "",
		"challenge": Strings.t("FRIENDS_CHALLENGE_CODE", str(challenge["challenge"]))
			if challenge.has("challenge") else "",
		"accepted": Strings.t("FRIENDS_ACCEPTED", who(str(f["accepted"]), me)) if str(f.get("accepted", "")) != ""
			else "",
		"last": str(f.get("last", "")),
	}
