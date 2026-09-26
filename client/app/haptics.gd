class_name Haptics
## §21.8's haptics: "A light tap on buttons, a medium pulse on abilities and
## pylon breaks, a success pattern on escape, a warning pattern on alarm."
## §20.8: every alarm and cue has a haptic form as well as a visual one, and
## haptics can be switched off. The patterns are ui/tokens.json's.

const KINDS := ["tap", "pulse", "success", "warning"]

## What plays a pattern: the phone's vibrator; a test puts a recorder here.
static var player: Callable = _vibrate


## Play `kind`'s pattern, unless the player switched haptics off.
static func play(kind: String) -> void:
	assert(kind in KINDS, "no haptic pattern %s" % kind)
	if not Settings.haptics or kind not in KINDS:
		return
	player.call(kind, Tokens.list("haptics", kind))


## Each pulse in turn: [milliseconds, strength], a strength of 0 a pause.
static func _vibrate(_kind: String, pulses: Array) -> void:
	var tree := Engine.get_main_loop() as SceneTree
	for p: Array in pulses:
		var ms := int(p[0])
		if float(p[1]) > 0.0:
			Input.vibrate_handheld(ms, float(p[1]))
		if tree != null:
			await tree.create_timer(ms / 1000.0).timeout
