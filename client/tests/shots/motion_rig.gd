extends RefCounted
## The motion shots' shared rig (P2-AIA-motion-2; report.md step 8 and 3.5):
## a stage of its own size on the ink ground, the form from FORM ("full" or
## "reduced") and high contrast from HC, then every frame of a motion saved
## to FRAMES as f000.png, f001.png... with what was measured in it, written
## to FRAMES/log.json for art/ui/motion/check_frames.py. Run under Godot's
## --fixed-fps 60 (art/ui/motion/strips.sh), so frame k is k/60 s after the
## motion starts whatever the machine's speed. Frame 0 is the rest before the
## motion starts. Preloaded by the motion_*.gd shots; not a shot itself.

const FPS := 60.0

var tree: SceneTree
var stage: SubViewport
var dir := ""
var rows: Array = []
var frame := 0


## A stage `size` pixels big on the ink ground, in `form` and contrast as the
## environment says.
func _init(on: SceneTree, size: Vector2i) -> void:
	tree = on
	ShotKit.prepare()
	Settings.reduced_motion = form() == "reduced"
	Tokens.high_contrast = OS.get_environment("HC") != ""
	dir = OS.get_environment("FRAMES")
	DirAccess.make_dir_recursive_absolute(dir)
	stage = SubViewport.new()
	stage.size = size
	stage.transparent_bg = false
	stage.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	tree.root.add_child(stage)
	var ground := ColorRect.new()
	ground.color = Tokens.color("ink")
	ground.size = Vector2(size)
	stage.add_child(ground)


static func form() -> String:
	return "reduced" if OS.get_environment("FORM") == "reduced" else "full"


## A few frames for the stage to lay out and draw once.
func settle() -> void:
	for i in 8:
		await tree.process_frame
	await RenderingServer.frame_post_draw


## This frame saved and `probe`'s measures logged under its time.
func shoot(probe: Callable) -> void:
	stage.get_texture().get_image().save_png("%s/f%03d.png" % [dir, frame])
	var row: Dictionary = probe.call()
	row["frame"] = frame
	row["t_ms"] = frame * 1000.0 / FPS
	rows.append(row)
	frame += 1


## One more frame of the motion: the tree steps 1/60 s, draws, and the frame
## is shot.
func step(probe: Callable) -> void:
	await tree.process_frame
	await RenderingServer.frame_post_draw
	shoot(probe)


## `seconds` of frames, one each 1/60 s; `at` maps a frame number to a
## callable run before that frame steps (a release, a second screen...).
func run(seconds: float, probe: Callable, at := {}) -> void:
	var last := int(round(seconds * FPS))
	while frame <= last:
		if at.has(frame):
			(at[frame] as Callable).call()
		await step(probe)


## The log beside the frames, and the end of the shot.
func finish(motion: String, extra := {}) -> void:
	var info := {"motion": motion, "form": form(), "high_contrast": Tokens.high_contrast, "fps": FPS,
		"size": [stage.size.x, stage.size.y], "px_per_point": UI.PX_PER_POINT, "frames": rows}
	info.merge(extra)
	var f := FileAccess.open(dir + "/log.json", FileAccess.WRITE)
	f.store_string(JSON.stringify(info, " "))
	f.close()
	print("wrote %d frames of %s (%s) to %s" % [rows.size(), motion, form(), dir])
	tree.quit()
