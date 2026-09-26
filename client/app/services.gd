class_name Services
extends RefCounted
## Everything a screen or presenter may use, built in one place at start (the
## composition root). A test builds its own with a `FakeTransport` and its own
## files, so nothing a test does reaches the network or a player's data, and
## nothing in the app reaches for a global it was not given.

var store: Store
var router: Router
var api: Api
var outbox: Outbox
var account: AccountRepository
var heists: HeistRepository


## `transport` null means the real network. `server` "" means none: the
## client plays offline on the fixture realm.
static func build(parent: Node, server: String, transport: Transport = null,
		outbox_path := Outbox.FILE) -> Services:
	var s := Services.new()
	s.store = Store.new()
	AppState.register(s.store)
	var t := transport if transport != null else HttpTransport.new()
	if t.get_parent() == null:
		parent.add_child(t)
	s.api = Api.new(t, server, s.store.log)
	s.outbox = Outbox.new(outbox_path)
	s.account = AccountRepository.new(s.api)
	s.heists = HeistRepository.new(s.api, s.outbox)
	s.router = Router.new(s.store)
	return s


## Where server/ is. The environment wins, so a test can point a run at a
## server it started; unset, the project setting; a server named over plain
## HTTP anywhere but this machine is refused, and the client plays offline.
static func server_url() -> String:
	var url := OS.get_environment("RULEBORN_SERVER")
	if url == "":
		url = str(ProjectSettings.get_setting("ruleborn/server_url", ""))
	if not Api.secure(url):
		push_error("refusing a server reached in the clear: %s" % url)
		return ""
	return url


## The platform credential. §24.8's sign-in needs Game Center or Play Games,
## which a desktop build does not have; the local server accepts any string.
static func credential() -> String:
	var from_env := OS.get_environment("RULEBORN_CREDENTIAL")
	return from_env if from_env != "" else "desktop:player"
