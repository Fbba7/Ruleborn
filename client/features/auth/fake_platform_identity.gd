class_name FakePlatformIdentity
extends PlatformIdentity
## A platform for tests: answers the credential set for each platform, or
## the failure set, and keeps each nonce it was asked to carry.

var answer: Variant = "gc:test-player"
## What each other platform answers (`{"gp": "gp:…"}`); a platform not here
## and not the first of `available` is one this device cannot prove.
var answers := {}
var available: Array[String] = ["gc"]
var failure := ""
var nonce := false
var asked: Array[String] = []


func platforms() -> Array[String]:
	return available


func needs_nonce() -> bool:
	return nonce


func needs_nonce_for(platform: String) -> bool:
	return nonce if platform == primary() else platform == "gp"


func credential_for(platform: String, n: String) -> Result:
	asked.append(n)
	await (Engine.get_main_loop() as SceneTree).process_frame
	if failure != "":
		return Result.failure(failure)
	if platform == primary():
		return Result.success(answer)
	if answers.has(platform) and platform in available:
		return Result.success(answers[platform])
	return Result.failure("no_platform")
