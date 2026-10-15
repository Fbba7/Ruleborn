class_name FirstController
extends RefCounted
## The first launch with no screen (§23.2, TD.26): it walks the phone's
## FirstLaunch through its beats, asks the server for what it shows before
## any account exists — §20.2's protections and the name word lists — and
## keeps the Keeper's name on the phone.

var services: Services


func _init(s: Services) -> void:
	services = s


func _first() -> FirstLaunch:
	return services.first


## Where the first launch stands: the age beat passes once §20.1's check
## allows an account, and an age not yet answered is the age screen's.
func resume() -> void:
	if _first().done():
		services.router.go(&"home")
		return
	if _first().beat() == "age":
		if services.age.allows_account():
			_first().advance()
		elif services.age.band() == "":
			services.router.go(&"age")
			return
	services.store.dispatch(&"first_moved", {"beat": _first().beat()})
	if _first().beat() in ["protections", "name"] and not services.store.get_slice(FirstState.FIRST)["asked"]:
		await load_words()


func load_words() -> void:
	services.store.dispatch(&"first_asked")
	var p := await services.first_repo.protections()
	var w := await services.first_repo.words()
	if p.ok and w.ok:
		services.store.dispatch(&"first_loaded", {"protections": p.value, "words": w.value})
	else:
		services.store.dispatch(&"first_failed", {"code": (p if not p.ok else w).code})


## The beat done: on to the next, and home once the first launch ends.
func next() -> void:
	_first().advance()
	if _first().done():
		services.router.go(&"home")
		return
	await resume()


## A word of the name moved along its list: `part` "adjective" or "noun".
func cycle(part: String, step := 1) -> void:
	var slice: Dictionary = services.store.get_slice(FirstState.FIRST)
	var words: Dictionary = slice["words"]
	var list: Array = words.get("adjectives" if part == "adjective" else "nouns", [])
	if list.is_empty():
		return
	var name: Dictionary = slice["name"].duplicate()
	name[part] = posmod(int(name.get(part, 0)) + step, list.size())
	services.store.dispatch(&"first_named", {"name": name})


## The name kept on the phone until the account is made (G58), and the beat
## done.
func keep_name() -> void:
	var name: Dictionary = services.store.get_slice(FirstState.FIRST)["name"]
	_first().set_name(int(name.get("adjective", 0)), int(name.get("noun", 0)))
	await next()
