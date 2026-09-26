class_name AccountRepository
extends RefCounted
## Signing in and what the account holds (§24.8): the platform credential
## exchanged for a session, the balance, and the account's deletion.

var api: Api


func _init(a: Api) -> void:
	api = a


## §24.8: "Platform identity is exchanged for a short-lived signed token."
func sign_in(credential: String) -> Result:
	var r := await api.post_json("/v1/session", {"credential": credential})
	if r.ok:
		api.token = str(r.value.get("token", ""))
	return r


func balance() -> Result:
	return await api.get_json("/v1/balance")


## §20.5: deletion from inside the game, and F43's "withdraw my islands too".
func delete_account(withdraw_islands: bool) -> Result:
	return await api.json(HTTPClient.METHOD_DELETE, "/v1/account", {"withdrawIslands": withdraw_islands})


## §20.1's age check, answered: "13-15", "16-17" or "18+". Until it is, the
## server holds the account to the most protective band (§20.2).
func set_age_band(band: String) -> Result:
	return await api.json(HTTPClient.METHOD_PUT, "/v1/age", {"band": band})
