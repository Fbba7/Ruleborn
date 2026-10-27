class_name FakeSecureStore
extends SecureStore
## The platform's secret storage for tests: kept as the platform would keep
## it, across a "launch" (a second AuthSession given the same store), and
## every write counted.

var kept: Dictionary = {}
var writes := 0


func persistent() -> bool:
	return true


func read(key: String) -> String:
	return str(kept.get(key, ""))


func write(key: String, value: String) -> bool:
	writes += 1
	kept[key] = value
	return true


func erase(key: String) -> void:
	kept.erase(key)
