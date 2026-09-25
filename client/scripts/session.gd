class_name Session
## What one screen hands the next, for as long as the app runs: the heist just
## played, so the result screen can show it and the replay screen can play it.
## Nothing here is saved; saving is §24.4's platform save, not built yet.

static var replay := PackedByteArray()
static var verdict := {}
## The island the replay was played on; empty for the fixture realm.
static var island := PackedByteArray()
## Raiding the player's own island from the builder: the heist plays
## `island` offline, and the result screen offers the way back.
static var testing := false


## Where server/ is. Unset, the client plays offline on the fixture realm and
## checks its own replay; set, it leases, plays the leased island and submits.
## The environment wins, so a test can point a run at a server it started.
## A server named over plain HTTP anywhere but this machine is refused, and the
## client plays offline: the stores are told everything is encrypted in transit
## (server/declarations.md), and a session token is not sent in the clear.
static func server_url() -> String:
	var url := OS.get_environment("RULEBORN_SERVER")
	if url == "":
		url = str(ProjectSettings.get_setting("ruleborn/server_url", ""))
	if not secure(url):
		push_error("refusing a server reached in the clear: %s" % url)
		return ""
	return url


## HTTPS, or HTTP to this machine's own loopback for the tests.
static func secure(url: String) -> bool:
	if url == "" or url.begins_with("https://"):
		return true
	if not url.begins_with("http://"):
		return false
	var host := url.trim_prefix("http://").get_slice("/", 0).get_slice(":", 0)
	return host == "127.0.0.1" or host == "localhost"


## The platform credential. §24.8's sign-in needs Game Center or Play Games,
## which a desktop build does not have; the local server accepts any string.
static func credential() -> String:
	var from_env := OS.get_environment("RULEBORN_CREDENTIAL")
	return from_env if from_env != "" else "desktop:player"
