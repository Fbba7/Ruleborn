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
var track: TrackRepository
var shop: ShopRepository
var social: SocialRepository
var friends: FriendsRepository
## The platform's store (StoreKit, Play Billing); a test's fake in tests.
var purchases: StorePurchases
## The network, as this build reaches it; `close` releases it.
var transport: Transport
## The flows that outlive a screen: a purchase or a join in flight goes on
## when the player leaves the screen that started it.
var shop_flow: ShopController
var social_flow: SocialController


## `transport` null means the real network. `server` "" means none: the
## client plays offline on the fixture realm.
static func build(parent: Node, server: String, with_transport: Transport = null,
		outbox_path := Outbox.FILE) -> Services:
	var s := Services.new()
	s.store = Store.new()
	AppState.register(s.store)
	ShopState.register(s.store)
	SocialState.register(s.store)
	var t := with_transport if with_transport != null else HttpTransport.new()
	if t.get_parent() == null:
		parent.add_child(t)
	s.transport = t
	s.api = Api.new(t, server, s.store.action_log)
	s.outbox = Outbox.new(outbox_path)
	s.account = AccountRepository.new(s.api)
	# A test's services keep their leases beside their outbox, never the
	# player's own.
	var stock_path := LeaseStock.FILE if outbox_path == Outbox.FILE \
		else outbox_path.get_basename() + "-leases.json"
	s.heists = HeistRepository.new(s.api, s.outbox, LeaseStock.new(stock_path))
	s.track = TrackRepository.new(s.api)
	s.shop = ShopRepository.new(s.api, s.outbox)
	s.social = SocialRepository.new(s.api)
	s.friends = FriendsRepository.new(s.api)
	s.purchases = StorePurchases.new()
	s.api.reauth = s.sign_in
	s.shop_flow = ShopController.new(s)
	s.social_flow = SocialController.new(s)
	s.router = Router.new(s.store)
	return s


## Sign in with the platform's credential, and say who is signed in. Every
## call without a session, or with an expired one, comes here (Api.reauth).
func sign_in() -> bool:
	var r := await account.sign_in(Services.credential())
	if r.ok:
		store.dispatch(&"signed_in", {"account": r.value["account"]})
	return r.ok


## Everything released: the transport node taken out of the tree and freed,
## and the flows, which hold these services, let go.
func close() -> void:
	shop_flow = null
	social_flow = null
	if api != null:
		api.reauth = Callable()
	if transport != null and is_instance_valid(transport):
		if transport.get_parent() != null:
			transport.get_parent().remove_child(transport)
		transport.queue_free()


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
