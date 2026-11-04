extends SceneTree
## The character icons' renders (art/ui/icons/README.md): each kind drawn
## in T7's portrait studio (client/world/portrait_studio.gd, used read only),
## in the hero stage's toon light, at icon size rather than the roster's
## 256, and cut as a bust. The 2D finish (art/ui/icons/studio/finish.html)
## then outlines and lights it like every other icon.
##
##   bash tools/render/shoot.sh client/tests/shots/icon_portraits.gd /tmp/x.png 640 640
##
## writes art/ui/icons/renders/<name>.png for every entry of KINDS (or only
## ONLY=<name>), and the last one to SHOT for a look.

## Icon name to [kind, look]: the crew badges batch by batch.
const KINDS := {
	"pip": ["skyskipper", ""],
}
## The render's side in pixels: the finish works at 640 (studio.html's R).
const SIDE := 640
## The studio draws at this, then the bust is cut and scaled to SIDE.
const DRAW := 1600
## How much wider than the studio's bust a badge is cut.
const WIDEN := 1.3
const OUT_DIR := "res://../art/ui/icons/renders/"


func _initialize() -> void:
	_go()


func _go() -> void:
	DisplayServer.window_set_size(Vector2i(SIDE, SIDE))
	root.size = Vector2i(SIDE, SIDE)
	var studio := PortraitStudio.new()
	studio.size = Vector2i(DRAW, DRAW)
	root.add_child(studio)
	await process_frame
	var only := OS.get_environment("ONLY")
	var last: Image = null
	for name: String in KINDS.keys():
		if only != "" and name != only:
			continue
		var kind: String = KINDS[name][0]
		var look: String = KINDS[name][1]
		var figure := StageHero.make_figure(kind, look)
		figure.rotation.y = -0.35
		studio.world.add_child(figure)
		studio._frame(kind, figure)
		var image: Image = null
		for _attempt in 3:
			studio.render_target_update_mode = SubViewport.UPDATE_ONCE
			await RenderingServer.frame_post_draw
			image = studio.get_texture().get_image()
			if image != null and not image.is_empty() and image.get_used_rect().size.x > 0:
				break
		figure.queue_free()
		await process_frame
		if image == null or image.is_empty():
			push_error("icon_portraits: %s drew nothing" % name)
			continue
		image.convert(Image.FORMAT_RGBA8)
		var bust := _bust(image)
		var path := ProjectSettings.globalize_path(OUT_DIR + name + ".png")
		DirAccess.make_dir_recursive_absolute(path.get_base_dir())
		bust.save_png(path)
		print("icon_portraits: wrote ", path)
		last = bust
	var shot := OS.get_environment("SHOT")
	if shot != "" and last != null:
		last.save_png(shot)
	quit()


## The studio's own bust cut (PortraitStudio.crop_bust, rule for rule), kept
## at SIDE (crop_bust scales its square to the roster's 256) and widened by
## WIDEN: a badge at 48 points reads by the whole head, ears and all, and
## the shoulders under it, where the heist's round frame fills with the face.
func _bust(image: Image) -> Image:
	var used := PortraitStudio._body(image)
	var top := mini(used.position.y, image.get_used_rect().position.y)
	var tall := used.end.y - top
	var side := int(clampf(minf(tall * 0.95, maxf(used.size.x * 0.9, tall * 0.62)) * WIDEN, 8.0,
		float(mini(image.get_width(), image.get_height()))))
	var sum := 0.0
	var count := 0.0
	for y in range(top, top + maxi(1, int(tall * 0.25)), 4):
		for x in range(used.position.x, used.end.x, 4):
			if image.get_pixel(x, y).a > 0.4:
				sum += x
				count += 1.0
	var mid := sum / count if count > 0.0 else used.position.x + used.size.x / 2.0
	var x0 := clampi(int(mid - side / 2.0), 0, image.get_width() - side)
	var y0 := clampi(top - int(side * 0.02), 0, image.get_height() - side)
	var out := image.get_region(Rect2i(x0, y0, side, side))
	out.resize(SIDE, SIDE, Image.INTERPOLATE_LANCZOS)
	return out
