class_name Settings
## The player's settings, kept on the phone in one file and put back on the
## next launch: the language, separate volumes for music, effects and alerts
## (§20.6), and §20.8's accessibility set — text size to 200%, high contrast,
## reduced motion, haptics, controls mirrored for left-handed play, a slower
## pace for rehearsals, and banners that stay until dismissed. High contrast
## and reduced motion start as the phone's own settings say.
##
## §20.8's adjustable hold times are one setting, for every held control: a
## held Weave is the first (§23.5), with a tap path beside it. §20.8 also asks
## for a way to switch screen shake off: nothing in the client shakes, so it
## is not offered until something does.

const FILE := "user://settings.cfg"
## Volumes are steps of a tenth, so a stepper reaches every value in ten taps.
const VOLUME_STEPS := 10
const VOLUMES := ["music", "effects", "alerts"]
## Alerts start loudest: an alarm is information, music is not (§21.8).
const DEFAULT_VOLUME := {"music": 7, "effects": 8, "alerts": 10}

## Where the file is; a test points this elsewhere so it never touches a
## player's own settings.
static var path := FILE
static var locale := ""
static var volume := DEFAULT_VOLUME.duplicate()
static var reduced_motion := false
static var haptics := true
## §20.8: "text size adjustable to 200%", in ui/tokens.json's steps.
static var text_scale := 100
static var high_contrast := false
## §20.8: "hold times adjustable", in milliseconds, in ui/tokens.json's steps.
static var hold_ms: int = int(Tokens.number("hold", "default"))
## §20.8: "controls can be mirrored for left-handed play".
static var left_handed := false
## §20.8: "a slower mode for ruins that runs the simulation at 75% speed".
static var slow_rehearsals := false
## §20.8: banners "stay until dismissed if the player chooses".
static var banners_stay := false
## §21.1: "a Settings switch shows rotate and zoom buttons, so no action needs
## two fingers".
static var camera_buttons := false
## How the phone is asked; a test puts its own answer here.
static var phone: Callable = func(what: String) -> bool:
	match what:
		"increase_contrast":
			return DisplayServer.accessibility_should_increase_contrast() == 1
		"reduce_animation":
			return DisplayServer.accessibility_should_reduce_animation() == 1
	return false
static var _restored := false


## Read the file once per run and apply it. A first launch has no file and
## starts in the phone's language, contrast and motion.
static func restore() -> void:
	if _restored:
		return
	_restored = true
	read_file()


## Not `reload`: that is Script.reload(), which recompiles this class and
## resets every static here.
static func read_file() -> void:
	var cfg := ConfigFile.new()
	var found := cfg.load(path) == OK
	locale = str(cfg.get_value("general", "locale", Strings.default_locale()))
	if locale not in Strings.LOCALES:
		locale = Strings.default_locale()
	for bus: String in VOLUMES:
		volume[bus] = clampi(int(cfg.get_value("volume", bus, DEFAULT_VOLUME[bus])), 0, VOLUME_STEPS)
	reduced_motion = bool(cfg.get_value("motion", "reduced", phone_says("reduce_animation")))
	haptics = bool(cfg.get_value("motion", "haptics", true))
	var scale := int(cfg.get_value("access", "text_scale", 100))
	text_scale = scale if scale in text_steps() else 100
	high_contrast = bool(cfg.get_value("access", "high_contrast", phone_says("increase_contrast")))
	var hold := int(cfg.get_value("access", "hold_ms", hold_default()))
	hold_ms = hold if hold in hold_steps() else hold_default()
	left_handed = bool(cfg.get_value("access", "left_handed", false))
	slow_rehearsals = bool(cfg.get_value("access", "slow_rehearsals", false))
	banners_stay = bool(cfg.get_value("access", "banners_stay", false))
	camera_buttons = bool(cfg.get_value("access", "camera_buttons", false))
	apply()
	if not found:
		save()


## Whether the phone's own accessibility settings ask for this: "increase_contrast"
## or "reduce_animation". Unknown (a desktop, a headless run) is no.
static func phone_says(what: String) -> bool:
	return bool(phone.call(what))



static func flag(name: String) -> bool:
	match name:
		"high_contrast":
			return high_contrast
		"reduced_motion":
			return reduced_motion
		"haptics":
			return haptics
		"left_handed":
			return left_handed
		"slow_rehearsals":
			return slow_rehearsals
		"banners_stay":
			return banners_stay
		"camera_buttons":
			return camera_buttons
	assert(false, "no setting %s" % name)
	return false


static func set_flag(name: String, on: bool) -> void:
	match name:
		"high_contrast":
			high_contrast = on
		"reduced_motion":
			reduced_motion = on
		"haptics":
			haptics = on
		"left_handed":
			left_handed = on
		"slow_rehearsals":
			slow_rehearsals = on
		"banners_stay":
			banners_stay = on
		"camera_buttons":
			camera_buttons = on
		_:
			assert(false, "no setting %s" % name)


static func text_steps() -> Array[int]:
	var out: Array[int] = []
	for s: Variant in Tokens.list("text_scale", "steps"):
		out.append(int(s))
	return out


static func hold_steps() -> Array[int]:
	var out: Array[int] = []
	for s: Variant in Tokens.list("hold", "steps"):
		out.append(int(s))
	return out


static func hold_default() -> int:
	return int(Tokens.number("hold", "default"))


static func save() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("general", "locale", locale)
	for bus: String in VOLUMES:
		cfg.set_value("volume", bus, volume[bus])
	cfg.set_value("motion", "reduced", reduced_motion)
	cfg.set_value("motion", "haptics", haptics)
	cfg.set_value("access", "text_scale", text_scale)
	cfg.set_value("access", "high_contrast", high_contrast)
	cfg.set_value("access", "hold_ms", hold_ms)
	cfg.set_value("access", "left_handed", left_handed)
	cfg.set_value("access", "slow_rehearsals", slow_rehearsals)
	cfg.set_value("access", "banners_stay", banners_stay)
	cfg.set_value("access", "camera_buttons", camera_buttons)
	if cfg.save(path) != OK:
		push_error("could not save settings to %s" % path)


## Put the settings into effect: the language, the colours, and one audio bus
## a volume, so music can be silenced without silencing an alarm.
static func apply() -> void:
	Strings.set_locale(locale)
	if Tokens.high_contrast != high_contrast:
		Tokens.high_contrast = high_contrast
		Palette.reload()
	for bus: String in VOLUMES:
		var index := bus_index(bus)
		AudioServer.set_bus_volume_db(index, linear_to_db(volume[bus] / float(VOLUME_STEPS)))
		AudioServer.set_bus_mute(index, volume[bus] == 0)


static func bus_index(bus: String) -> int:
	var name := bus.capitalize()
	var index := AudioServer.get_bus_index(name)
	if index == -1:
		index = AudioServer.bus_count
		AudioServer.add_bus(index)
		AudioServer.set_bus_name(index, name)
	return index


## One change from the settings screen: applied and saved at once, so leaving
## the app mid-screen loses nothing.
static func change(what: Callable) -> void:
	what.call()
	apply()
	save()
