class_name LeaseStock
extends RefCounted
## The owner's answer to G41: online is the rule, offline the exception. While
## online the phone keeps a few leases in stock — each §24.12's "target
## snapshot, a seed, a single-use token and an expiry a day away", with the
## island's bytes — so a heist can still start underground. Kept in one file,
## so a restart loses none; a lease the server has since expired still earns
## its one grace submission (§24.12), so an old one is played rather than
## thrown away, newest first.

const FILE := "user://leases.json"
## How many are kept: enough for a journey, few enough that each is fresh.
const SIZE := 3

var path := FILE
var _items: Array[Dictionary] = []


func _init(p := FILE) -> void:
	path = p
	_read()


func count() -> int:
	return _items.size()


## The bundle hashes held, so a refill leases others.
func bundles() -> Array[String]:
	var out: Array[String] = []
	for i: Dictionary in _items:
		out.append(str(i.get("key", "")))
	return out


## A lease on the island stored under `key`, and the island's bytes.
func add(key: String, lease: Dictionary, bundle: PackedByteArray) -> void:
	_items.append({"key": key, "lease": lease, "island": Marshalls.raw_to_base64(bundle)})
	_write()


## A lease settled some other way — played online on the same token — leaves
## the stock, so it is never played again from it.
func drop(token: String) -> void:
	var before := _items.size()
	_items.assign(_items.filter(func(i: Dictionary) -> bool: return str(i["lease"].get("token", "")) != token))
	if _items.size() != before:
		_write()


## The newest lease and its island, taken out of the stock, or {} for none.
func take() -> Dictionary:
	if _items.is_empty():
		return {}
	_items.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return int(a["lease"].get("expiresAt", 0)) < int(b["lease"].get("expiresAt", 0)))
	var item: Dictionary = _items.pop_back()
	_write()
	return {"lease": item["lease"], "island": Marshalls.base64_to_raw(str(item["island"]))}


func _read() -> void:
	_items.clear()
	if not FileAccess.file_exists(path):
		return
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if parsed is Array:
		for item: Variant in parsed:
			if item is Dictionary and (item as Dictionary).has("lease") and (item as Dictionary).has("island"):
				_items.append(item)


func _write() -> void:
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f == null:
		push_error("could not keep the lease stock in %s" % path)
		return
	f.store_string(JSON.stringify(_items))
