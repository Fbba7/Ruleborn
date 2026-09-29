class_name WorkshopState
extends RefCounted
## The Island Workshop as the store holds it (§18.6, §18.7, §20.7): the list
## on show and its items; whether the player may see only the curated list;
## the name word lists; the player's creator ladder; the island last played,
## to rate; and what the last action came to. A failed call keeps what was on
## show.

const WORKSHOP := &"workshop"

## §18.6's report reasons, as server/src/workshop.mjs takes them.
const REPORT_REASONS := ["unfair", "unplayable", "copied", "offensive", "other"]


static func register(store: Store) -> void:
	store.register(WORKSHOP, {"list": "top", "items": [], "loaded": false, "curated": false, "words": {},
			"ladder": {}, "played": {}, "busy": false, "error": "", "done": "", "last": {}, "terms": {}}, {
		&"workshop_asked": asked,
		&"workshop_listed": listed,
		&"workshop_curated": curated,
		&"workshop_words": words,
		&"workshop_ladder": ladder,
		&"workshop_playing": playing,
		&"workshop_done": done,
		&"workshop_failed": failed,
		&"workshop_terms": terms,
	})


static func asked(s: Dictionary, _p: Dictionary) -> Dictionary:
	var next := s.duplicate()
	next["busy"] = true
	next["error"] = ""
	next["done"] = ""
	return next


static func failed(s: Dictionary, p: Dictionary) -> Dictionary:
	var next := s.duplicate()
	next["busy"] = false
	next["error"] = str(p["code"])
	next["done"] = ""
	return next


## A list, as the server answered it: "top", "new", "featured" or "mine". The
## top or new list answered means the player is no longer held to the curated
## list (their age check has reached the server since).
static func listed(s: Dictionary, p: Dictionary) -> Dictionary:
	var next := s.duplicate()
	next["list"] = str(p["list"])
	if next["list"] in ["top", "new"]:
		next["curated"] = false
	next["items"] = p["items"]
	next["loaded"] = true
	next["busy"] = false
	next["error"] = ""
	return next


## §20.7: a player aged 13 to 15 browses "curated lists only".
static func curated(s: Dictionary, _p: Dictionary) -> Dictionary:
	var next := s.duplicate()
	next["curated"] = true
	return next


static func words(s: Dictionary, p: Dictionary) -> Dictionary:
	var next := s.duplicate()
	next["words"] = p["words"]
	return next


## §18.7's ladder for the player: their level, completions and islands
## featured.
static func ladder(s: Dictionary, p: Dictionary) -> Dictionary:
	var next := s.duplicate()
	next["ladder"] = p["ladder"]
	return next


## §20.11's terms of use as the server holds them for the player: the
## current version, and whether they have accepted it.
static func terms(s: Dictionary, p: Dictionary) -> Dictionary:
	var next := s.duplicate()
	var had: Dictionary = s["terms"]
	var got: Dictionary = p["terms"]
	# A slower answer from before the player accepted never reopens the gate
	# on the same version.
	if bool(had.get("accepted", false)) and not bool(got.get("accepted", false)) \
			and str(had.get("version", "")) == str(got.get("version", "")):
		return next
	next["terms"] = got
	return next


## The island a play was started on, so the result can offer to rate it.
static func playing(s: Dictionary, p: Dictionary) -> Dictionary:
	var next := s.duplicate()
	next["played"] = p["item"]
	next["busy"] = false
	return next


## An action the server took: "published", "played", "rated", "reported",
## "remixed", "withdrawn", "blocked" or "terms"; `last` is what it answered.
static func done(s: Dictionary, p: Dictionary) -> Dictionary:
	var next := s.duplicate()
	next["done"] = str(p["what"])
	next["last"] = p.get("answer", {})
	next["busy"] = false
	next["error"] = ""
	return next
