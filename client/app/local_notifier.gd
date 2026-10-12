class_name LocalNotifier
extends RefCounted
## The phone's own notifications (§14.6): the permission to show them, the
## push token the server sends to, and the timers the device keeps itself —
## storage full, a character rested, an experiment finished. A notification
## names keys from the app's own string tables (client/platform/, written by
## tools/native_strings.py), so the phone draws it in its own language.
##
## They are reached through each platform's notification plugin, which a
## desktop or headless build does not have: this one does nothing and says it
## may not, and a test puts a FakeLocalNotifier in its place.


## Ask the phone for permission to notify. The answer comes back from the
## platform later; `permitted` says what it was.
func ask_permission() -> void:
	pass


func permitted() -> bool:
	return false


## The phone's IANA time zone ("America/Sao_Paulo"), which §20.2's night is
## worked out in (G34); "" when the platform cannot say, and nothing is sent.
func time_zone() -> String:
	return ""


## The token the server sends pushes to, or "" before the platform gives one.
func push_token() -> String:
	return ""


## A notification under `id` at `at` (unix milliseconds), with the string
## table's `title` and `body` keys. One already set under `id` is replaced.
func schedule(_id: String, _at: int, _title: String, _body: String) -> void:
	pass


func cancel(_id: String) -> void:
	pass
