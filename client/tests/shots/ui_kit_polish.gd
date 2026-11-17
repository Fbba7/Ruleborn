extends RefCounted
## The kit tests' checks of the third wave's polish (tests/ui_kit_tests.gd;
## S3-R32, S2-R35): a panel scrolled far above its list still draws its face,
## and the baked numbers are drawn from mipmapped pages. A helper, not a shot:
## each check is said through the kit tests' `check`.


static func run(tree: SceneTree, check: Callable) -> void:
	await _scrolled(tree, check)
	_mipmapped(check)


## A parchment panel taller than its list, scrolled until its top is far
## above the list (S3-R32): its face from the atlas still draws, culled by
## the rect it drew, which covers the panel's part still in the list. Before,
## the renderer culled the face by a rect worked out from its scaled 9-slice,
## and a long panel scrolled to its end lost its whole face.
static func _scrolled(tree: SceneTree, check: Callable) -> void:
	var screen := Control.new()
	screen.size = Vector2(540, 600)
	tree.root.add_child(screen)
	var list := ScrollContainer.new()
	list.size = Vector2(540, 600)
	list.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	screen.add_child(list)
	var column := VBoxContainer.new()
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_child(column)
	var parchment := UI.panel("parchment")
	var tall := Control.new()
	tall.custom_minimum_size = Vector2(400, 1800)
	parchment.add_child(tall)
	column.add_child(parchment)
	await tree.process_frame
	await tree.process_frame
	list.scroll_vertical = 1500
	for i in 3:
		await tree.process_frame
	var box := RbBox.of(parchment)
	var said := "no box"
	var ok := false
	if box != null:
		var shown := parchment.get_global_rect().intersection(list.get_global_rect())
		var face := box._face
		var culled := Rect2()
		if face != null:
			culled = face.get_global_transform() * box._drawn
		var top := list.get_global_rect().position.y - parchment.get_global_rect().position.y
		var above := top > 0.5 * parchment.size.y
		ok = face != null and not box.piece().is_empty() and above and culled.encloses(shown)
		said = "face %s, piece %s, top above by half %s, culled by %s, shown %s" % [face != null,
			not box.piece().is_empty(), above, culled, shown]
	screen.queue_free()
	await tree.process_frame
	check.call("a panel scrolled more than half above its list still draws its face from the atlas: the face is "
			+ "culled by the rect it drew, which covers the part still in the list (S3-R32)", ok, said)


## Drawn a tenth of their baked height, the glyphs are averaged from their
## pages' mipmaps, so their stroke, drop and gradient survive (S2-R35): a row
## of numbers filters with mipmaps, and every page a glyph sits on, in both
## twins, is imported with them.
static func _mipmapped(check: Callable) -> void:
	var bad := []
	var shipped: Dictionary = (JSON.parse_string(FileAccess.get_file_as_string(KitSkin.MANIFEST)) as Dictionary)["pieces"]
	var pages := {}
	for finish: String in KitNumerals.FINISHES:
		for glyph: String in KitNumerals.GLYPHS.values():
			var key := "%s_%s" % [finish, glyph]
			if shipped.has(key):
				pages[int((shipped[key] as Dictionary).get("page", 1))] = true
	var row := KitNumerals.Row.new()
	if row.texture_filter != CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS:
		bad.append("a row of numbers filters with %d, not with mipmaps" % row.texture_filter)
	row.free()
	if pages.is_empty():
		bad.append("no numeral sits on a page of the atlas")
	for page: int in pages:
		for twin: String in ["", "_hc"]:
			var file := "%s/kit%s%s.webp.import" % [KitSkin.MANIFEST.get_base_dir(),
				"" if page == 1 else "_%d" % page, twin]
			if not "\nmipmaps/generate=true\n" in FileAccess.get_file_as_string(file):
				bad.append("%s, a page of the numerals, is imported without mipmaps" % file)
	check.call("the baked numbers are drawn with mipmaps from pages imported with them, so a number drawn small "
			+ "keeps its stroke and drop (S2-R35; kit-spec.md section 6.1)", bad.is_empty(), "; ".join(bad))
