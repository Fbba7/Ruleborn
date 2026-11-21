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
## The session's tokens, kept on the phone (features/auth/).
var auth: AuthSession
var heists: HeistRepository
var track: TrackRepository
var shop: ShopRepository
var social: SocialRepository
var friends: FriendsRepository
var workshop: WorkshopRepository
var universe: UniverseRepository
var home: HomeRepository
var weaving: WeavingRepository
var codex: CodexRepository
var observatory: ObservatoryRepository
var lab: LabRepository
var curation: CurationRepository
var defences: DefencesRepository
var profile: ProfileRepository
var device: DeviceRepository
## The platform's store (StoreKit, Play Billing); a test's fake in tests.
var purchases: StorePurchases
## §20.1's answer, kept on the phone: no account is made until it allows one.
var age: AgeCheck
## The first launch's beat and the Keeper's name, kept on the phone (TD.26).
var first: FirstLaunch
var first_repo: FirstRepository
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
var roster_flow: RosterController
var sage_flow: SageController
var forms_flow: FormsController
var weaving_flow: WeavingController
var codex_flow: CodexController
var harmony_flow: HarmonyController
var observatory_flow: ObservatoryController
var lab_flow: LabController
var curation_flow: CurationController
var defences_flow: DefencesController
var profile_flow: ProfileController
var planner_flow: PlannerController
var map_flow: MapController
var realm_flow: RealmController
var share_flow: ShareController
var first_flow: FirstController
var auth_flow: AuthController


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
	RosterState.register(s.store)
	SageState.register(s.store)
	FormsState.register(s.store)
	WeavingState.register(s.store)
	CodexState.register(s.store)
	HarmonyState.register(s.store)
	ObservatoryState.register(s.store)
	LabState.register(s.store)
	CurationState.register(s.store)
	DefencesState.register(s.store)
	ProfileState.register(s.store)
	PlannerState.register(s.store)
	RealmState.register(s.store)
	ShareState.register(s.store)
	FirstState.register(s.store)
	AuthState.register(s.store)
	var t := with_transport if with_transport != null else HttpTransport.new()
	if t.get_parent() == null:
		# A cold start builds the services from the main scene's _ready, while
		# root is still readying its children: Godot refuses a child added
		# then, so it joins once root is done (RB-27). Send waits for it.
		if parent.is_node_ready():
			parent.add_child(t)
		else:
			(func() -> void:
				if is_instance_valid(t) and is_instance_valid(parent) and t.get_parent() == null:
					parent.add_child(t)).call_deferred()
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
	s.first = FirstLaunch.new(FirstLaunch.FILE if outbox_path == Outbox.FILE
		else outbox_path.get_basename() + "-first.json")
	s.first_repo = FirstRepository.new(s.api)
	s.track = TrackRepository.new(s.api)
	s.shop = ShopRepository.new(s.api, s.outbox)
	s.social = SocialRepository.new(s.api)
	s.friends = FriendsRepository.new(s.api)
	s.workshop = WorkshopRepository.new(s.api, s.outbox)
	s.universe = UniverseRepository.new(s.api)
	s.purchases = StorePurchases.new()
	s.home = HomeRepository.new(s.api)
	s.weaving = WeavingRepository.new(s.api)
	s.codex = CodexRepository.new(s.api)
	s.observatory = ObservatoryRepository.new(s.api)
	s.lab = LabRepository.new(s.api)
	s.curation = CurationRepository.new(s.api)
	s.defences = DefencesRepository.new(s.api)
	s.profile = ProfileRepository.new(s.api)
	s.device = DeviceRepository.new(s.api)
	s.notifier = LocalNotifier.new()
	s.notices = DeviceNotices.new(DeviceNotices.FILE if outbox_path == Outbox.FILE
		else outbox_path.get_basename() + "-notices.json")
	s.auth = AuthSession.new(s.api, SecureStore.new(), PlatformIdentity.new(),
		AuthSession.FILE if outbox_path == Outbox.FILE else outbox_path.get_basename() + "-auth.json")
	s.api.reauth = s.session.bind(true)
	s.api.stale = s.auth.stale
	s.shop_flow = ShopController.new(s)
	s.social_flow = SocialController.new(s)
	s.workshop_flow = WorkshopController.new(s)
	s.keeper_flow = KeeperController.new(s)
	s.universe_flow = UniverseController.new(s)
	s.roster_flow = RosterController.new(s)
	s.sage_flow = SageController.new(s)
	s.forms_flow = FormsController.new(s)
	s.weaving_flow = WeavingController.new(s)
	s.codex_flow = CodexController.new(s)
	s.harmony_flow = HarmonyController.new(s)
	s.observatory_flow = ObservatoryController.new(s)
	s.lab_flow = LabController.new(s)
	s.curation_flow = CurationController.new(s)
	s.defences_flow = DefencesController.new(s)
	s.profile_flow = ProfileController.new(s)
	s.planner_flow = PlannerController.new(s)
	s.map_flow = MapController.new(s)
	s.realm_flow = RealmController.new(s)
	s.share_flow = ShareController.new(s)
	s.first_flow = FirstController.new(s)
	s.auth_flow = AuthController.new(s)
	# What the phone built, wove or assigned offline is answered when the
	# outbox sends it (§24).
	s.outbox.settled.connect(s.universe_flow.offline_settled)
	s.outbox.settled.connect(s.roster_flow.offline_settled)
	s.outbox.settled.connect(s.weaving_flow.offline_settled)
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
	if fresh or held == "" or not auth.fresh():
		r = await auth.ensure(fresh)
	if not r.ok:
		return r
	store.dispatch(&"signed_in", {"account": r.value["account"]})
	if not age.sent():
		var told := await account.set_age_band(age.band())
		if told.ok:
			age.mark_sent()
	# G58: the Keeper's name the first launch picked, kept on the phone until
	# the account was made, sent once.
	if not first.name().is_empty() and not first.sent():
		var named := await first_repo.send_name(first.name())
		if named.ok:
			first.mark_sent()
	return r


## The app came to the foreground (TD.74): the session counted and its start
## kept to send, the push permission asked at the third, and — with an
## account — the time zone and push token told to the server (G34), the
## session events sent, and its own timers set from the home (§14.6).
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
## timers moved out of the night.
func sync_device() -> void:
	var zone := notifier.time_zone()
	if zone != "":
		await device.report(zone, notifier.push_token())
	await send_events()
	await set_timers()


## §14.6's timers the device keeps itself, set from the home the server
## answers: storage full, a character rested, an experiment finished.
func set_timers() -> void:
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
	roster_flow = null
	sage_flow = null
	forms_flow = null
	weaving_flow = null
	codex_flow = null
	harmony_flow = null
	observatory_flow = null
	lab_flow = null
	curation_flow = null
	defences_flow = null
	profile_flow = null
	planner_flow = null
	map_flow = null
	realm_flow = null
	share_flow = null
	first_flow = null
	auth_flow = null
	if api != null:
		api.reauth = Callable()
		api.stale = Callable()
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
