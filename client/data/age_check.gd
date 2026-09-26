class_name AgeCheck
extends RefCounted
## §20.1's age check: "at first launch the game asks the platform for the
## player's age band (under 13, 13 to 15, 16 to 17, or 18 and over) instead
## of a birthdate. Players under 13 are told the game is for 13 and up, and no
## account is created." The platforms' age-range services are not in this
## build (`platform` answers ""), so the player is asked, neutrally, once.
## The answer is kept on the phone, and sent to the server once an account
## exists (PUT /v1/age); until it is, the server holds the account to the most
## protective band (§20.2).

const FILE := "user://age.json"
const BANDS := ["under-13", "13-15", "16-17", "18+"]

var path := FILE
## The platform's answer: a band from BANDS, or "" when it cannot say.
var platform: Callable = func() -> String: return ""
var _band := ""
var _sent := false


func _init(p := FILE) -> void:
	path = p
	_read()


## The band answered, or "" before the check.
func band() -> String:
	if _band == "":
		var said := str(platform.call())
		if said in BANDS:
			answer(said)
	return _band


## Whether the game may make an account: only once the check has answered,
## and never under 13.
func allows_account() -> bool:
	var b := band()
	return b != "" and b != "under-13"


## The check's answer, kept. A player under 13 keeps that answer: the gate is
## not asked again (§20.11's "the gate is not decorative").
func answer(b: String) -> void:
	if not (b in BANDS) or _band == "under-13":
		return
	_band = b
	_sent = false
	_write()


## Whether the server has the answer yet.
func sent() -> bool:
	return _sent


func mark_sent() -> void:
	_sent = true
	_write()


func _read() -> void:
	if not FileAccess.file_exists(path):
		return
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if parsed is Dictionary and str((parsed as Dictionary).get("band", "")) in BANDS:
		_band = str(parsed["band"])
		_sent = bool((parsed as Dictionary).get("sent", false))


func _write() -> void:
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f == null:
		push_error("could not keep the age check's answer in %s" % path)
		return
	f.store_string(JSON.stringify({"band": _band, "sent": _sent}))
