class_name ActionLog
extends RefCounted
## The last things that happened, oldest first: every action the store
## applied and every failure a call returned, each with the time since start.
## A defect report carries it, and the debug overlay shows it, so a bug comes
## with the steps that caused it. It holds kinds and codes, never a token, a
## replay's bytes or anything that names a player (§20.5).

const CAPACITY := 64

var _entries: Array[Dictionary] = []


func add(kind: String, what: String, fields := {}) -> void:
	var safe := {}
	for key: String in fields:
		var v: Variant = fields[key]
		if v is int or v is float or v is bool or (v is String and (v as String).length() <= 64):
			safe[key] = v
	_entries.append({"ms": Time.get_ticks_msec(), "kind": kind, "what": what, "fields": safe})
	if _entries.size() > CAPACITY:
		_entries.pop_front()


func entries() -> Array[Dictionary]:
	return _entries.duplicate()


func clear() -> void:
	_entries.clear()


## One line an entry, for a log file or a report.
func dump() -> String:
	var lines: PackedStringArray = []
	for e: Dictionary in _entries:
		lines.append("%8d %-7s %s %s" % [e["ms"], e["kind"], e["what"], JSON.stringify(e["fields"])])
	return "\n".join(lines)
