class_name FirstPresenter
extends RefCounted
## The first launch in words (§23.2: "The title, the age band check with no
## answer pre-selected, the protections summary, the Keeper's name from word
## lists and face, then each of section 16's moments on its own screen"):
## the title; the protections §20.2 sets for the band the age check
## answered, with its night and spending cap as the server holds them; and
## the Keeper's name from the word lists, which raiders will see (§12.4).


static func screen(slice: Dictionary, band: String) -> Dictionary:
	var beat := str(slice.get("beat", "title"))
	var code := str(slice.get("error", ""))
	var out := {"beat": beat, "error": Errors.message("FIRST_FAILED", code) if code != "" else ""}
	match beat:
		"title":
			out["lines"] = [Strings.t("APP_NAME"), Strings.t("HOME_TAGLINE")] as Array[String]
			out["next"] = Strings.t("FIRST_BEGIN")
		"protections":
			out["lines"] = protections(band, slice.get("protections", {}))
			out["next"] = Strings.t("FIRST_GO_ON")
		"name":
			var words: Dictionary = slice.get("words", {})
			var n: Dictionary = slice.get("name", {})
			out["name"] = SocialPresenter.word_name(words, int(n.get("adjective", 0)), int(n.get("noun", 0)))
			out["lines"] = [Strings.t("FIRST_NAME_WHY")] as Array[String]
			out["next"] = Strings.t("FIRST_KEEP_NAME")
		_:
			out["lines"] = [] as Array[String]
			out["next"] = ""
	return out


## §20.2's protections for `band`, in words, its night and cap the server's.
static func protections(band: String, by_band: Dictionary) -> Array[String]:
	var p: Dictionary = by_band.get(band, {})
	var night: Array = p.get("night", [22, 8])
	var lines: Array[String] = [Strings.t("FIRST_PROTECTIONS_" + band.replace("-", "_").replace("+", "_PLUS"))]
	match band:
		"13-15":
			lines.append_array([Strings.t("FIRST_CHAT_PRESET"), Strings.t("FIRST_PROFILE_PRIVATE"),
				Strings.t("FIRST_NIGHT_NEVER", [int(night[0]), int(night[1])]),
				Strings.t("FIRST_REMINDER_FIXED"), Strings.t("FIRST_CAP", int(p.get("cap", 0)))])
		"16-17":
			lines.append_array([Strings.t("FIRST_CHAT_CONFIRM"), Strings.t("FIRST_PROFILE_DEFAULT"),
				Strings.t("FIRST_NIGHT_NEVER", [int(night[0]), int(night[1])]),
				Strings.t("FIRST_REMINDER_NEVER_OFF"), Strings.t("FIRST_CAP", int(p.get("cap", 0)))])
		_:
			lines.append_array([Strings.t("FIRST_CHAT_FILTERED"), Strings.t("FIRST_PROFILE_CHOICE"),
				Strings.t("FIRST_NIGHT_DEFAULT", [int(night[0]), int(night[1])]),
				Strings.t("FIRST_REMINDER_CHOICE"), Strings.t("FIRST_SUMMARY")])
	lines.append(Strings.t("FIRST_NO_ADS"))
	return lines
