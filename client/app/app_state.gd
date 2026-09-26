class_name AppState
extends RefCounted
## The app's slices and the reducers that own them, registered on a store.
## Each reducer is a static function of (slice, payload) that returns the new
## slice and touches nothing else, so tests call them directly.

## §24.8: who is signed in, once the server has said so.
const SESSION := &"session"
## The heist just played, so the result screen can show it and the replay
## screen can play it: its replay, the check's verdict, the island it was
## played on (empty for the fixture realm), and whether it was the player's
## own island raided from the builder.
const HEIST := &"heist"
## The screen on show and what it was opened with.
const ROUTE := &"route"


static func register(store: Store) -> void:
	store.register(SESSION, {"account": ""}, {
		&"signed_in": signed_in,
		&"signed_out": signed_out,
	})
	store.register(HEIST, {"replay": PackedByteArray(), "verdict": {}, "island": PackedByteArray(),
			"testing": false}, {
		&"heist_started": heist_started,
		&"heist_finished": heist_finished,
		&"heist_verdict": heist_verdict,
	})
	store.register(ROUTE, {"name": &"", "params": {}}, {
		&"navigated": navigated,
	})


static func signed_in(_s: Dictionary, p: Dictionary) -> Dictionary:
	return {"account": str(p["account"])}


static func signed_out(_s: Dictionary, _p: Dictionary) -> Dictionary:
	return {"account": ""}


## A heist begins on `island` (empty: the fixture realm); `testing` when it is
## the player's own island from the builder.
static func heist_started(s: Dictionary, p: Dictionary) -> Dictionary:
	var next := s.duplicate()
	next["island"] = p.get("island", PackedByteArray())
	next["testing"] = bool(p.get("testing", false))
	next["replay"] = PackedByteArray()
	next["verdict"] = {}
	return next


static func heist_finished(s: Dictionary, p: Dictionary) -> Dictionary:
	var next := s.duplicate()
	next["replay"] = p["replay"]
	next["verdict"] = p["verdict"]
	return next


## What the server decided once it answered, merged over the device's own
## verdict (§24.12: shown at once, confirmed after).
static func heist_verdict(s: Dictionary, p: Dictionary) -> Dictionary:
	var next := s.duplicate()
	var merged: Dictionary = (s["verdict"] as Dictionary).duplicate()
	merged.merge(p, true)
	next["verdict"] = merged
	return next


static func navigated(_s: Dictionary, p: Dictionary) -> Dictionary:
	return {"name": p["name"], "params": p.get("params", {})}
