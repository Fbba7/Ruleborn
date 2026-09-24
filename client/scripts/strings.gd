class_name Strings
## Every word the client shows, from i18n/strings.csv: one row a key, one
## column a language. §20.6 ships English and Brazilian Portuguese at launch;
## a language is a column, so adding one touches no script.
##
## Screens never hold text of their own. They call `Strings.t(key)`, and a
## pseudo-locale in the tests wraps every catalogue string, so a word typed
## into a script shows up unwrapped and fails.

const CATALOGUE := "res://i18n/strings.csv"
const LOCALES := ["en", "pt_BR"]

static var _loaded := false
static var _rows := {}


## The catalogue as {key: {locale: text}}, read once.
static func rows() -> Dictionary:
	if not _loaded:
		_load()
	return _rows


static func _load() -> void:
	_loaded = true
	var file := FileAccess.open(CATALOGUE, FileAccess.READ)
	if file == null:
		push_error("no string catalogue at %s" % CATALOGUE)
		return
	var header := file.get_csv_line()
	var translations := {}
	for locale in header.slice(1):
		var t := Translation.new()
		t.locale = locale
		translations[locale] = t
	while not file.eof_reached():
		var line := file.get_csv_line()
		if line.size() < header.size() or line[0] == "":
			continue
		_rows[line[0]] = {}
		for i in range(1, header.size()):
			_rows[line[0]][header[i]] = line[i]
			translations[header[i]].add_message(line[0], line[i])
	for t in translations.values():
		TranslationServer.add_translation(t)


## The text for `key` in the current locale, formatted with `args`.
static func t(key: String, args: Variant = null) -> String:
	rows()
	var text := TranslationServer.translate(key)
	if args == null:
		return text
	return text % args


## A game term the simulation names in English (a role, a grade, a gait), in
## the current locale: "Scout" is ROLE_SCOUT.
static func term(prefix: String, name: String) -> String:
	var key := "%s_%s" % [prefix, name.to_upper()]
	return t(key) if rows().has(key) else name


static func set_locale(locale: String) -> void:
	rows()
	TranslationServer.set_locale(locale)


## The locale a new player starts in: Portuguese on a phone set to any
## Portuguese, English otherwise.
static func default_locale() -> String:
	return "pt_BR" if OS.get_locale_language() == "pt" else "en"
