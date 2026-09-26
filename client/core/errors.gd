class_name Errors
## A failure's code, in words the player reads. Every code the server can
## refuse with, and every code the client makes, has an ERR_ key in the
## catalogue (tools/client_contract.py fails the build otherwise), so what the
## player sees names the code, and the code is found in both halves by one
## search. A code with no key still shows, as itself, and is logged.

## The catalogue key for `code`.
static func key(code: String) -> String:
	return "ERR_" + code.to_upper()


## `code` in the current language.
static func text(code: String) -> String:
	var k := key(code)
	if Strings.rows().has(k):
		return Strings.t(k)
	push_warning("no words for the failure %s" % code)
	return Strings.t("ERR_UNKNOWN", code)


## A screen's message with the failure's words in it: Strings.t(`message_key`,
## text(`code`)).
static func message(message_key: String, code: String) -> String:
	return Strings.t(message_key, text(code))
