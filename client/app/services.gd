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
var workshop: WorkshopRepository
var universe: UniverseRepository
var home: HomeRepository
var device: DeviceRepository
## The platform's store (StoreKit, Play Billing); a test's fake in tests.
var purchases: StorePurchases
## §20.1's answer, kept on the phone: no account is made until it allows one.
var age: AgeCheck
## The phone's own notifications and their permission; a test's fake in tests.
var notifier: LocalNotifier
## Sessions, the permission's asking, and events not yet sent, kept on the phone.
var notices: DeviceNotices
## The network, as this build reaches it; `close` releases it.
var transport: Transport
## The flows that outlive a screen: a purchase or a join in flight goes on
## when the player leaves the screen that started it.
var shop_flow: ShopController
var social_flow: SocialController
var workshop_flow: WorkshopController
var keeper_flow: KeeperController
var universe_flow: UniverseController


## `transport` null means the real network. `server` "" means none: the
## client plays offline on the fixture realm.
static func build(parent: Node, server: String, with_transport: Transport = null,
		outbox_path := Outbox.FILE) -> Services:
	var s := Services.new()
	s.store = Store.new()
	AppState.register(s.store)
	ShopState.register(s.store)
	SocialState.register(s.store)
	WorkshopState.register(s.store)
	KeeperState.register(s.store)
	UniverseState.register(s.store)
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
	s.age = AgeCheck.new(AgeCheck.FILE if outbox_path == Outbox.FILE else outbox_path.get_basename() + "-age.json")
	s.track = TrackRepository.new(s.api)
	s.shop = ShopRepository.new(s.api, s.outbox)
	s.social = SocialRepository.new(s.api)
	s.friends = FriendsRepository.new(s.api)
	s.workshop = WorkshopRepository.new(s.api, s.outbox)
	s.universe = UniverseRepository.new(s.api)
	s.purchases = StorePurchases.new()
	s.home = HomeRepository.new(s.api)
	s.device = DeviceRepository.new(s.api)
	s.notifier = LocalNotifier.new()
	s.notices = DeviceNotices.new(DeviceNotices.FILE if outbox_path == Outbox.FILE
		else outbox_path.get_basename() + "-notices.json")
	s.api.reauth = s.session.bind(true)
	s.shop_flow = ShopController.new(s)
	s.social_flow = SocialController.new(s)
	s.workshop_flow = WorkshopController.new(s)
	s.keeper_flow = KeeperController.new(s)
	s.universe_flow = UniverseController.new(s)
	s.router = Router.new(s.store)
	return s


## Sign in with the platform's credential, and say who is signed in. Every
## call without a session, or with an expired one, comes here (Api.reauth).
func sign_in() -> bool:
	return (await session(true)).ok


## The session, as a Result: refused on the phone until §20.1's age check
## allows an account; once signed in, the check's answer goes to the server
## if it has not yet. The session held is kept for the hour it lasts unless
## `fresh` asks for a new one — a call refused for an expired one gets one
## (Api.reauth) — so the phone does not sign in again for every heist, which
## the server limits (G44).
func session(fresh := false) -> Result:
	if not age.allows_account():
		return Result.failure("age_check_first")
	var held := str(store.get_slice(AppState.SESSION).get("account", ""))
	var r := Result.success({"account": held})
	if fresh or held == "" or api.token == "":
		r = await account.sign_in(Services.credential())
	if not r.ok:
		return r
	store.dispatch(&"signed_in", {"account": r.value["account"]})
	if not age.sent():
		var told := await account.set_age_band(age.band())
		if told.ok:
			age.mark_sent()
	return r


## The app came to the foreground (TD.74): the session counted and its start
## kept to send, the push permission asked at the third, and — with an
## account — the time zone and push token told to the server (G34), the
## session events sent, and the storage-full timer set from the home (§14.6).
## Offline, the events wait for the next time.
func foreground(now := 0) -> void:
	var at := now if now > 0 else int(Time.get_unix_time_from_system() * 1000)
	notices.start(at)
	if notices.should_ask():
		notifier.ask_permission()
		notices.mark_asked()
	if api.online() and age.allows_account() and (await session()).ok:
		await sync_device()


## The app went to the background: the session's end kept, and sent if it can be.
func background(now := 0) -> void:
	notices.stop(now if now > 0 else int(Time.get_unix_time_from_system() * 1000))
	if api.online() and api.token != "":
		await send_events()


## The device told to the server: its zone and token, its events, and its
## storage-full timer moved out of the night.
func sync_device() -> void:
	var zone := notifier.time_zone()
	if zone != "":
		await device.report(zone, notifier.push_token())
	await send_events()
	var h := await home.view()
	if h.ok:
		DeviceNotices.apply(notifier, h.value, int(Time.get_time_zone_from_system().get("bias", 0)))


func send_events() -> void:
	var batch := notices.pending()
	if batch.is_empty():
		return
	var r := await device.events(batch)
	if r.ok:
		notices.sent(batch.size())


## Everything released: the transport node taken out of the tree and freed,
## and the flows, which hold these services, let go.
func close() -> void:
	shop_flow = null
	social_flow = null
	workshop_flow = null
	keeper_flow = null
	universe_flow = null
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
