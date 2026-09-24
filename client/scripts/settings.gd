class_name Settings
## The player's settings, kept on the phone in one file and put back on the
## next launch. §20.6 names what is here: the language, separate volumes for
## music, effects and alerts, reduced motion and switchable haptics. The rest
## of §20.6's set (text size, left-handed controls, high contrast) belongs to
## the accessibility pass and is not offered until it does something.

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
static var _restored := false


## Read the file once per run and apply it. A first launch has no file and
## starts in the phone's language.
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
	for bus in VOLUMES:
		volume[bus] = clampi(int(cfg.get_value("volume", bus, DEFAULT_VOLUME[bus])), 0, VOLUME_STEPS)
	reduced_motion = bool(cfg.get_value("motion", "reduced", false))
	haptics = bool(cfg.get_value("motion", "haptics", true))
	apply()
	if not found:
		save()


static func save() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("general", "locale", locale)
	for bus in VOLUMES:
		cfg.set_value("volume", bus, volume[bus])
	cfg.set_value("motion", "reduced", reduced_motion)
	cfg.set_value("motion", "haptics", haptics)
	if cfg.save(path) != OK:
		push_error("could not save settings to %s" % path)


## Put the settings into effect: the language, and one audio bus a volume, so
## music can be silenced without silencing an alarm.
static func apply() -> void:
	Strings.set_locale(locale)
	for bus in VOLUMES:
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

