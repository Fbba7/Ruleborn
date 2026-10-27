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
## A device may have both (Google's sign-in also runs on iPhone): the first
## is the one it signs in with; the other is offered to link to the account,
## so the same account opens on the other platform (docs/security/auth.md).
##
## Without either — desktop, headless — the credential is the local server's
## stub, a string it takes as the identity it names (Services.credential).
## A test puts a FakePlatformIdentity here.

const GAME_CENTER := "RulebornGameCenter"
const GOOGLE := "RulebornGoogleSignIn"
## The server's names for the platforms (auth.mjs PLATFORMS), and the plugin
## each needs.
const PLUGINS := {"gc": GAME_CENTER, "gp": GOOGLE}


## The platforms this device can prove, the one it signs in with first.
## Without a plugin, the stub's Game Center.
func platforms() -> Array[String]:
	var out: Array[String] = []
	for p: String in PLUGINS:
		if Engine.has_singleton(PLUGINS[p]):
			out.append(p)
	if out.is_empty():
		out.append("gc")
	return out


## The platform this device signs in with.
func primary() -> String:
	return platforms()[0]


## Whether the proof needs the server's nonce first: Google's does.
func needs_nonce() -> bool:
	return needs_nonce_for(primary())


func needs_nonce_for(platform: String) -> bool:
	return platform == "gp" and Engine.has_singleton(GOOGLE)


## The proof this device signs in with (credential_for its primary).
func credential(nonce: String) -> Result:
	return await credential_for(primary(), nonce)


## A proof of `platform`, as a Result: a failure the platform names —
## "platform_cancelled" when the player closed its sheet,
## "no_platform_account" when the phone is signed in to no such account,
## "no_platform" when this device has no way to prove it.
func credential_for(platform: String, nonce: String) -> Result:
	var name: String = PLUGINS.get(platform, "")
	if name != "" and Engine.has_singleton(name):
		var plugin := Engine.get_singleton(name)
		plugin.call("request", nonce)
		var got: Array = await Signal(plugin, "credential")
		var answer: Dictionary = got[0] if not got.is_empty() and got[0] is Dictionary else {}
		if answer.is_empty() or answer.has("error"):
			return Result.failure(str(answer.get("error", "platform_cancelled")))
		return Result.success(answer)
	if platform == "gc" and not Engine.has_singleton(GOOGLE):
		return Result.success(Services.credential())
	return Result.failure("no_platform")
