extends RefCounted
## The kit tests' check that a sprite face (a piece with no 9-slice: the
## skin disc's, the gold round) is drawn only on a round host
## (tests/ui_kit_tests.gd, kit-spec.md section 8.2): a helper, not a shot.

## The looks of the skin disc, and the gold round of the primary button.
const LOOKS := ["disc", "icon_disc", "level_disc", "gem", "round_sky", "round_violet", "gold_round"]
## How far from square a round host may be, as a share of its shorter side.
const SLACK := 0.15


## Returns what is wrong, one line each: a sprite drawn on a host that is
## not round (a resource pill's storage bar, a product card's price button
## in each state, a pill, a wide and a tall panel in each look), and a round
## host that lost its sprite.
static func run(tree: SceneTree) -> Array:
	var bad := []
	KitSkin.reset()
	var screen := VBoxContainer.new()
	screen.size = Vector2(1080, 2340)
	tree.root.add_child(screen)
	# The hosts the fault was seen on (catalogue pages 27, 44 and 45; the
	# observatory's echo ribbon).
	var resource := KitStatus.resource("gold", "61.0k", 0.6, Tokens.color("gold_top"))
	resource.custom_minimum_size.x = UI.px(120)
	resource.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	screen.add_child(resource)
	var cards := HBoxContainer.new()
	screen.add_child(cards)
	var buys: Array[Button] = []
	for i: int in 3:
		var card := KitCards.product(null, "", "Product", "4.99", func() -> void: pass)
		cards.add_child(card)
		for b: Node in card.find_children("*", "Button", true, false):
			buys.append(b as Button)
	var pill := OverlayHud.pill("", "ECHO", "", "round_violet")
	pill.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	screen.add_child(pill)
	# Each look on a wide pill, on a tall one and on a round host.
	var round_hosts := {}
	for look: String in LOOKS:
		var row := HBoxContainer.new()
		screen.add_child(row)
		for shape: Array in [[160.0, 40.0, 999.0, "Wide"], [48.0, 160.0, 999.0, "Tall"],
				[44.0, 44.0, 999.0, "Round"]]:
			var host := PanelContainer.new()
			host.name = "%s %s" % [shape[3], look]
			host.add_theme_stylebox_override("panel", UI.clear_box(2, 2))
			host.custom_minimum_size = Vector2(UI.px(shape[0]), UI.px(shape[1]))
			host.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
			host.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
			UI.dress(host, look, shape[2])
			row.add_child(host)
			if shape[3] == "Round":
				round_hosts[look] = host
	for i: int in 3:
		await tree.process_frame
	if buys.size() != 3:
		bad.append("a product card does not have one price button (%d on three cards)" % buys.size())
	else:
		buys[1].disabled = true
		var held := RbBox.of(buys[2])
		if held != null:
			held.press = 1.0
	for i: int in 2:
		await tree.process_frame
	var sprites := 0
	for n: Node in screen.find_children("*", "Control", true, false):
		var host := n as Control
		var box := RbBox.of(host)
		if box == null:
			continue
		var p := box.piece()
		if p.is_empty() or p.get("slice") is Dictionary:
			continue
		sprites += 1
		if absf(host.size.x - host.size.y) > SLACK * minf(host.size.x, host.size.y):
			bad.append("%s draws the sprite of %s on a host %d by %d" % [_path(screen, host), box.look,
				int(host.size.x), int(host.size.y)])
	for look: String in LOOKS:
		var p := RbBox.of(round_hosts[look] as Control).piece()
		if p.is_empty() or p.get("slice") is Dictionary:
			bad.append("a round host in %s does not draw its sprite" % look)
	if sprites == 0:
		bad.append("no host draws a sprite")
	if not KitSkin.missing.is_empty():
		bad.append("a baked shape is logged missing: %s" % ", ".join(KitSkin.missing))
	screen.queue_free()
	KitSkin.reset()
	await tree.process_frame
	return bad


static func _path(from: Node, to: Node) -> String:
	return str(from.get_path_to(to))
