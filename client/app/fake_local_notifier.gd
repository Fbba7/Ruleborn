class_name FakeLocalNotifier
extends LocalNotifier
## A phone for tests: the permission answers what the test set once asked, and
## every timer set is kept by its id.

var grants := true
var asked := 0
var token := "device-token"
var zone := "America/Sao_Paulo"
var timers: Dictionary = {}


func ask_permission() -> void:
	asked += 1


func permitted() -> bool:
	return asked > 0 and grants


func time_zone() -> String:
	return zone


func push_token() -> String:
	return token if permitted() else ""


func schedule(id: String, at: int, title: String, body: String) -> void:
	timers[id] = {"at": at, "title": title, "body": body}


func cancel(id: String) -> void:
	timers.erase(id)
