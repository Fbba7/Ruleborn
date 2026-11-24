class_name Draft
extends RefCounted
## The island the player is building, kept on the phone between runs, and —
## when it began as a remix (§18.6) — the Workshop island it was built on,
## so publishing it names the original even after a restart. A remix never
## overwrites the player's own island (§18.6: player creations are never
## deleted or overwritten): the island it replaces is kept, to restore.

## Where the island is kept; a test points this elsewhere. Its original's id
## is kept beside it.
static var path := "user://island.rbi"


static func island() -> PackedByteArray:
	return FileAccess.get_file_as_bytes(path) if FileAccess.file_exists(path) else PackedByteArray()


static func keep(bytes: PackedByteArray) -> bool:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		push_error("could not keep the island in %s" % path)
		return false
	file.store_buffer(bytes)
	file.close()
	return true


## The Workshop island this one was remixed from, or "".
static func remix_of() -> String:
	var file := _origin()
	return FileAccess.get_file_as_string(file).strip_edges() if FileAccess.file_exists(file) else ""


## §18.6: a Workshop island becomes the draft, to build on; the island it
## replaces is kept, with its own original if it had one. A remix replacing
## a remix keeps the player's own island kept, not the first remix (CLI-4):
## the player's creation is the one never lost.
static func start_remix(bytes: PackedByteArray, id: String) -> bool:
	var before := island()
	var own_kept := has_kept() and remix_of() != "" and (not FileAccess.file_exists(_kept_origin())
		or FileAccess.get_file_as_string(_kept_origin()).strip_edges() == "")
	if not before.is_empty() and before != bytes and not own_kept:
		if not _write(_kept(), before) or not _write_text(_kept_origin(), remix_of()):
			return false
	return keep(bytes) and _write_text(_origin(), id)


## Whether an island a remix replaced is kept, to restore.
static func has_kept() -> bool:
	return FileAccess.file_exists(_kept())


## The island a remix replaced, back as the draft, with its own original;
## the remix in its place is kept in turn, so restoring loses nothing.
static func restore() -> bool:
	if not has_kept():
		return false
	var back := FileAccess.get_file_as_bytes(_kept())
	var back_origin := FileAccess.get_file_as_string(_kept_origin()).strip_edges() \
		if FileAccess.file_exists(_kept_origin()) else ""
	var now := island()
	var now_origin := remix_of()
	if not _write(_kept(), now) or not _write_text(_kept_origin(), now_origin):
		return false
	return keep(back) and _write_text(_origin(), back_origin)


## The draft is no longer the remix: it was published, or a blank realm
## replaced it, or its original is gone. What it grows into is its own.
static func forget_origin() -> void:
	if FileAccess.file_exists(_origin()):
		DirAccess.remove_absolute(_origin())


static func _origin() -> String:
	return path.get_basename() + "-remix.txt"


static func _kept() -> String:
	return path.get_basename() + "-kept.rbi"


static func _kept_origin() -> String:
	return path.get_basename() + "-kept-remix.txt"


static func _write(to: String, bytes: PackedByteArray) -> bool:
	var f := FileAccess.open(to, FileAccess.WRITE)
	if f == null:
		push_error("could not keep an island in %s" % to)
		return false
	f.store_buffer(bytes)
	f.close()
	return true


## `text` written to `to`; "" removes it.
static func _write_text(to: String, text: String) -> bool:
	if text == "":
		if FileAccess.file_exists(to):
			DirAccess.remove_absolute(to)
		return true
	var f := FileAccess.open(to, FileAccess.WRITE)
	if f == null:
		push_error("could not keep %s" % to)
		return false
	f.store_string(text)
	f.close()
	return true
