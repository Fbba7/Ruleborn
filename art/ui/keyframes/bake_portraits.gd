extends SceneTree
## The key frames' portraits, baked from the game's own models in its toon
## light (Portrait.bust, §21.3): the heist's crew of five as the design names
## them, its Sage and the Keeper. Run by bake.sh; OUT is the folder.

const KINDS := ["skyskipper", "tidewalker", "mossbear", "echoplate", "emberling", "archivist", "featherkin"]


func _initialize() -> void:
	_go()


func _go() -> void:
	var textures := {}
	for k: String in KINDS:
		textures[k] = Portrait.bust(k)
	for i in 240:
		await process_frame
		if Portrait.settled() and i > 4:
			break
	for i in 3:
		await process_frame
	await RenderingServer.frame_post_draw
	for k: String in KINDS:
		var image: Image = (textures[k] as Texture2D).get_image()
		image.save_png(OS.get_environment("OUT").path_join(k + ".png"))
		print("baked ", k, " ", image.get_size())
	quit()
