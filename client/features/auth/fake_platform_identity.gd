class_name FakePlatformIdentity
extends PlatformIdentity
## A platform for tests: answers the credential set, or the failure set, and
## keeps each nonce it was asked to carry.

var answer: Variant = "gc:test-player"
var failure := ""
var nonce := false
var asked: Array[String] = []


func needs_nonce() -> bool:
	return nonce


func credential(n: String) -> Result:
	asked.append(n)
	await (Engine.get_main_loop() as SceneTree).process_frame
	if failure != "":
		return Result.failure(failure)
	return Result.success(answer)
