class_name Session
## What one screen hands the next, for as long as the app runs: the heist just
## played, so the result screen can show it and the replay screen can play it.
## Nothing here is saved; saving is §24.4's platform save, not built yet.

static var replay := PackedByteArray()
static var verdict := {}
## The island the replay was played on; empty for the fixture realm.
static var island := PackedByteArray()


## Where server/ is. Unset, the client plays offline on the fixture realm and
## checks its own replay; set, it leases, plays the leased island and submits.
## The environment wins, so a test can point a run at a server it started.
static func server_url() -> String:
	var from_env := OS.get_environment("RULEBORN_SERVER")
	if from_env != "":
		return from_env
	return str(ProjectSettings.get_setting("ruleborn/server_url", ""))


## The platform credential. §24.8's sign-in needs Game Center or Play Games,
## which a desktop build does not have; the local server accepts any string.
static func credential() -> String:
	var from_env := OS.get_environment("RULEBORN_CREDENTIAL")
	return from_env if from_env != "" else "desktop:player"
