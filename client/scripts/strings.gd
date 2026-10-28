class_name Strings
## Every word the client shows, from i18n/strings.csv: one row a key, one
## column a language. §20.6 ships English and Brazilian Portuguese at launch;
## the owner added English's US form, European Portuguese, German and French
## (D99). A language is a column, so adding one touches no other script.
## `en` is English as the document writes it, British; `en_US` is written
## from it by tools/english_us.py.
##
## Screens never hold text of their own. They call `Strings.t(key)`, and a
## pseudo-locale in the tests wraps every catalogue string, so a word typed
## into a script shows up unwrapped and fails.

## The client's own words, the content's names (law, note, resonance,
## chord, ward, ground), which tools/client_strings.py writes from content/,
## and the countries' names, which tools/auth_countries.py writes.
const CATALOGUES := ["res://i18n/strings.csv", "res://i18n/content.csv", "res://i18n/countries.csv"]
const LOCALES := ["en", "en_US", "pt_BR", "pt_PT", "de", "fr"]

static var _loaded := false
static var _rows := {}


## The catalogue as {key: {locale: text}}, read once.
static func rows() -> Dictionary:
	if not _loaded:
		_load()
	return _rows


static func _load() -> void:
	_loaded = true
	var translations := {}
	for path: String in CATALOGUES:
		var file := FileAccess.open(path, FileAccess.READ)
		if file == null:
			push_error("no string catalogue at %s" % path)
			continue
		var header := file.get_csv_line()
		for locale in header.slice(1):
			if not translations.has(locale):
				var translation := Translation.new()
				translation.locale = locale
				translations[locale] = translation
		while not file.eof_reached():
			var line := file.get_csv_line()
			if line.size() < header.size() or line[0] == "":
				continue
			if _rows.has(line[0]):
				push_error("%s is in two catalogues" % line[0])
			_rows[line[0]] = {}
			for i in range(1, header.size()):
				_rows[line[0]][header[i]] = line[i]
				translations[header[i]].add_message(line[0], line[i])
	for translation: Translation in translations.values():
		TranslationServer.add_translation(translation)


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


## The locale a new player starts in, from the phone's: Brazilian Portuguese
## in Brazil and European Portuguese anywhere else Portuguese is spoken;
## English's US form in the United States and British English anywhere else;
## German and French wherever they are spoken; British English otherwise.
static func default_locale() -> String:
	return locale_for(OS.get_locale())


static func locale_for(phone: String) -> String:
	var language := phone.get_slice("_", 0)
	var region := phone.get_slice("_", 1) if phone.contains("_") else ""
	match language:
		"pt":
			return "pt_BR" if region == "BR" else "pt_PT"
		"en":
			return "en_US" if region == "US" else "en"
		"de", "fr":
			return language
	return "en"
