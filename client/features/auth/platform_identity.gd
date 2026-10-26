class_name PlatformIdentity
extends RefCounted
## The player's platform proof, §24.8's "Game Center on iPhone, the player's
## Google account on Android": Game Center's identity-verification signature
## (`{playerId, bundleId, publicKeyUrl, signature, salt, timestamp}`), or a
## Google ID token (`{idToken}`) that carries the nonce the server gave, so
## the server takes it once. Each comes from the platform's plugin, the
## engine singleton GAME_CENTER or GOOGLE: `request(nonce)`, answered by its
## `credential(answer: Dictionary)` signal — the proof, or `{"error": code}`.
##
## Without either — desktop, headless — the credential is the local server's
## stub, a string it takes as the identity it names (Services.credential).
## A test puts a FakePlatformIdentity here.

const GAME_CENTER := "RulebornGameCenter"
const GOOGLE := "RulebornGoogleSignIn"


## Whether the proof needs the server's nonce first: Google's does.
func needs_nonce() -> bool:
	return not Engine.has_singleton(GAME_CENTER) and Engine.has_singleton(GOOGLE)


## The proof, as a Result: a failure the platform names — "platform_cancelled"
## when the player closed its sheet, "no_platform_account" when the phone is
## signed in to no Game Center or Google account.
func credential(nonce: String) -> Result:
	for name: String in [GAME_CENTER, GOOGLE]:
		if Engine.has_singleton(name):
			var plugin := Engine.get_singleton(name)
			plugin.call("request", nonce)
			var got: Array = await Signal(plugin, "credential")
			var answer: Dictionary = got[0] if not got.is_empty() and got[0] is Dictionary else {}
			if answer.is_empty() or answer.has("error"):
				return Result.failure(str(answer.get("error", "platform_cancelled")))
			return Result.success(answer)
	return Result.success(Services.credential())
