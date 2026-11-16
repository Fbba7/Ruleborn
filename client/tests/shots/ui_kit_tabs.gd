extends RefCounted
## The kit tests' checks of the tab bar's height and of KitLayout.tap's card
## (tests/ui_kit_tests.gd; S2-R24, S2-R26; §21.1, §21.8). A helper, not a
## shot: each check is said through the kit tests' `check`.


## KitLayout.tap's card presses in place of its clear button, connected once
## (S2-R26): Godot refuses a second connection to Motion.press whatever is
## bound to it, so a card whose button kept its own press never pressed.
static func tap_once(tree: SceneTree, check: Callable) -> void:
	var bad := []
	var screen := Control.new()
	screen.size = Vector2(1080, 2340)
	tree.root.add_child(screen)
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(UI.px(200), UI.px(80))
	screen.add_child(card)
	var none := func() -> void: pass
	var taps: Array[Button] = [KitLayout.tap(card, none, "first"), KitLayout.tap(card, none, "second")]
	await tree.process_frame
	for b: Button in taps:
		for sig: Signal in [b.button_down, b.button_up]:
			var presses := 0
			for c: Dictionary in sig.get_connections():
				if (c["callable"] as Callable).get_method() == "press":
					presses += 1
			if presses != 1:
				bad.append("%s %s: %d connections to Motion.press" % [b.accessibility_name, sig.get_name(), presses])
		if card.has_meta("motion_press"):
			card.remove_meta("motion_press")
		b.button_down.emit()
		if not card.has_meta("motion_press"):
			bad.append("%s: the card did not press" % b.accessibility_name)
		if b.has_meta("motion_press"):
			bad.append("%s: the clear button pressed itself" % b.accessibility_name)
		b.button_up.emit()
	screen.queue_free()
	await tree.process_frame
	check.call("a card made one control by KitLayout.tap presses as a button does, once: each tap's button has one "
			+ "connection to Motion.press per signal, a second tap() on the card adds no second one, and the press "
			+ "moves the card, not its clear button (S2-R26; §21.8)", bad.is_empty(), "; ".join(bad))


## Says what `found` (each case's lines from heads()) found wrong, as one check.
static func say(check: Callable, found: Array) -> void:
	check.call("the chosen tab's picture, at the top of its bob, stands inside its tab and the bar's rect, so the bar "
			+ "takes the height it draws, at 100%, 150% and 200% text in English, German and Portuguese; the bar's "
			+ "gold edge stays at the plain tabs' top, and at 100% the chosen tile still rises RISE above it; a tab "
			+ "a screen raises (home's Heist) stays raised, the gold edge where it was, until a tab is chosen "
			+ "(S2-R24)", found.is_empty(), "; ".join(found))


## Where tab bar `tabs` draws its chosen tab's picture against its rects
## (S2-R24), named `said`; at 100% text (`full`) the chosen tile's rise too,
## and a Heist raised by the screen, as home raises it, kept raised.
static func heads(tabs: KitTabs, said: String, full: bool) -> Array:
	var bad := []
	var b: Button = tabs.buttons[tabs.active]
	var tile: Control = tabs._tiles[tabs.active]
	var icon: TextureRect = tabs._icons[tabs.active]
	var r := b.get_global_rect()
	# Where it rests, wherever its bob has it now, then its bob's top.
	var top := tile.global_position.y + tile.size.y - KitTabs.rest(true) - maxf(icon.size.y,
		icon.custom_minimum_size.y) - UI.PX_PER_POINT * KitTabs.BOB
	var bar := tabs.get_global_rect()
	if top < r.position.y - 0.5 or top < bar.position.y - 0.5:
		bad.append("%s: the picture's top %.0f above its tab's %.0f or the bar's %.0f" % [said, top, r.position.y,
			bar.position.y])
	var plain: Button = tabs.buttons["islands" if tabs.active != "islands" else "laws"]
	var edge := (tabs._bar.get_parent() as Control).global_position.y + tabs._bar.inset_top
	if absf(edge - plain.global_position.y) > 0.5:
		bad.append("%s: the gold edge at %.0f, the plain tabs' top at %.0f" % [said, edge, plain.global_position.y])
	if full and absf(plain.global_position.y - tile.global_position.y - UI.px(KitTabs.RISE)) > 0.5:
		bad.append("%s: the chosen tile's top %.0f, not RISE over the plain tabs' %.0f" % [said,
			tile.global_position.y, plain.global_position.y])
	if full and tabs.buttons.has("heist") and tabs.active != "heist":
		var heist: Button = tabs.buttons["heist"]
		var was := tabs._bar.inset_top
		var raised := heist.custom_minimum_size.y + UI.px(KitTabs.RISE * 0.75)
		heist.custom_minimum_size.y = raised
		tabs._stand()
		tabs._stand()
		if absf(heist.custom_minimum_size.y - raised) > 0.5 or absf(tabs._bar.inset_top - was) > 0.5:
			bad.append("%s: the Heist raised to %.0f stands %.0f, the gold edge's inset %.0f, was %.0f" % [said,
				raised, heist.custom_minimum_size.y, tabs._bar.inset_top, was])
		tabs.choose(tabs.active, false)
		if heist.custom_minimum_size.y > raised - 0.5:
			bad.append("%s: the Heist still raised once a tab was chosen" % said)
	if tabs.buttons.has("heist") and tabs.active != "heist":
		# Home's own case: raised to its height while its name showed (the
		# tab stood taller then), its name hidden after.
		var heist: Button = tabs.buttons["heist"]
		var label: Label = tabs._labels["heist"]
		var shown := label.visible
		var was := tabs._bar.inset_top
		label.visible = true
		tabs._stand()
		var home := float(UI.px(Tokens.number("size", "tab_height") + KitTabs.RISE * 0.75))
		heist.custom_minimum_size.y = home
		label.visible = false
		tabs._stand()
		tabs._stand()
		if absf(heist.custom_minimum_size.y - home) > 0.5 or absf(tabs._bar.inset_top - was) > 0.5:
			bad.append("%s: the Heist raised as home raises it to %.0f stands %.0f, the gold edge's inset %.0f, was %.0f"
				% [said, home, heist.custom_minimum_size.y, tabs._bar.inset_top, was])
		label.visible = shown
		tabs.choose(tabs.active, false)
	return bad
