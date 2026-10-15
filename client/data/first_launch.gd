class_name FirstLaunch
extends RefCounted
## §23.2's first launch, kept on the phone: which beat the player is at — the
## title, the age check, the protections the band sets, the Keeper's name —
## so a killed app resumes at the same beat; and the name picked from the
## word lists, which stays here until an account exists (G58, §25.2) and is
## then sent once.

const FILE := "user://first-launch.json"
const BEATS := ["title", "age", "protections", "name", "done"]

var path := FILE
var _beat := "title"
var _name := {}
var _sent := false


func _init(p := FILE) -> void:
	path = p
	_read()


func beat() -> String:
	return _beat


func done() -> bool:
	return _beat == "done"


## On to the beat after this one.
func advance() -> void:
	var i := BEATS.find(_beat)
	_beat = BEATS[mini(i + 1, BEATS.size() - 1)]
	_write()


## The first launch finished at once: a test's player, or one before it.
func finish() -> void:
	_beat = "done"
	_write()


## The Keeper's name, as word-list indexes, or {} before it is picked.
func name() -> Dictionary:
	return _name.duplicate()


func set_name(adjective: int, noun: int) -> void:
	_name = {"adjective": adjective, "noun": noun}
	_sent = false
	_write()


func sent() -> bool:
	return _sent


func mark_sent() -> void:
	_sent = true
	_write()


func _read() -> void:
	if not FileAccess.file_exists(path):
		return
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not (parsed is Dictionary):
		return
	var d: Dictionary = parsed
	_beat = str(d.get("beat", "title")) if str(d.get("beat", "")) in BEATS else "title"
	var n: Variant = d.get("name", {})
	_name = {"adjective": int(n["adjective"]), "noun": int(n["noun"])} \
		if n is Dictionary and (n as Dictionary).has("adjective") else {}
	_sent = bool(d.get("sent", false))


func _write() -> void:
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f == null:
		push_error("could not keep the first launch in %s" % path)
		return
	f.store_string(JSON.stringify({"beat": _beat, "name": _name, "sent": _sent}))
