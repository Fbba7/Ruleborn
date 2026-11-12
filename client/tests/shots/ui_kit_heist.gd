extends RefCounted
## The kit tests' check of the heist's calls (tests/ui_kit_tests.gd,
## P1-K1-heist-kit, S1-R1 to S1-R6): the clock, the alarm and the loot panel
## changed in place; the alarm and the loot panel for a narrow column at any
## text size; the wrapping law chip; the tip; words on the world; the
## crew's ink; and the fly into a counter. A helper, not a shot.

## Long words of the kind pt_BR gives the loot panel.
const LONG := [["Sala", "1.840"], ["Restam", "~2.600"]]


## Returns what is wrong, one line each.
static func run(tree: SceneTree) -> Array:
	var bad := []
	var scale := Settings.text_scale
	var still := Settings.reduced_motion
	KitSkin.reset()
	var screen := VBoxContainer.new()
	screen.size = Vector2(1080, 2340)
	tree.root.add_child(screen)
	await _clocks(tree, screen, bad)
	await _alarms(tree, screen, bad)
	for at: int in [100, 200]:
		Settings.text_scale = at
		await _loot(tree, screen, bad, at)
		await _chip(tree, screen, bad, at)
	Settings.text_scale = scale
	await _words(tree, screen, bad)
	await _fly(tree, screen, bad)
	Settings.text_scale = scale
	Settings.reduced_motion = still
	screen.queue_free()
	KitSkin.reset()
	return bad


## Whether an outline of `c` counts all round for words `points` tall, as
## the contrast check reads one (tests/a11y_tests.gd).
static func _counts(c: Control, points: float) -> bool:
	return c.get_theme_constant("outline_size") / UI.PX_PER_POINT >= maxf(1.5, 0.12 * points)


static func _clocks(tree: SceneTree, screen: Control, bad: Array) -> void:
	var big := KitHud.clock_large("03:42")
	var small := KitHud.clock("03:42")
	for p: Control in [big, small]:
		p.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		screen.add_child(p)
	await tree.process_frame
	var time := big.get_node("Time") as Label
	if time.get_theme_font_size("font_size") != UI.text_px(26):
		bad.append("the large clock's figures are not 26 points")
	if not _counts(time, 26):
		bad.append("the large clock's outline does not count all round")
	if time.get_theme_constant("shadow_offset_y") <= 0:
		bad.append("the large clock's figures have no drop")
	if str(big.get_meta("rb_material", "")) != "parchment":
		bad.append("the large clock is not on parchment")
	if big.size.y <= small.size.y:
		bad.append("the large clock is not taller than the clock")
	KitHud.set_clock(big, "00:30", true)
	KitHud.set_clock(small, "00:30", true)
	if time.text != "00:30" or (small.get_node("Time") as Label).text != "00:30":
		bad.append("set_clock does not write the new time")
	for p: Control in [big, small]:
		if str(p.get_meta("rb_material", "")) != "red":
			bad.append("set_clock(alarmed) leaves %s off the alarm's red" % p.name)
	var words := small.get_node("Time") as Label
	if not words.has_theme_color_override("font_color") or words.get_theme_constant("outline_size") != UI.px(3):
		bad.append("set_clock(alarmed) does not give the clock its alarm words, as clock(warning) does")
	if time.get_theme_color("font_color") != Tokens.color("on_alarm"):
		bad.append("set_clock(alarmed) leaves the large clock's figures cream")
	KitHud.set_clock(small, "00:29", false)
	KitHud.set_clock(big, "00:29", false)
	if str(small.get_meta("rb_material", "")) != "parchment" or words.has_theme_color_override("font_color") \
			or words.has_theme_constant_override("outline_size"):
		bad.append("set_clock(not alarmed) does not give the clock back its parchment and words")
	if time.get_theme_color("font_color") != Tokens.color("cream"):
		bad.append("set_clock(not alarmed) leaves the large clock's figures in the alarm's colour")
	big.queue_free()
	small.queue_free()


static func _alarms(tree: SceneTree, screen: Control, bad: Array) -> void:
	var p := KitHud.alarm(2, 6, "Alarm")
	screen.add_child(p)
	KitHud.set_alarm(p, 4)
	await tree.process_frame
	var count := p.find_child("Count", true, false) as Label
	var bells := p.find_child("Bells", true, false)
	var lit := 0
	for b: Node in bells.get_children():
		if b.has_meta("lit"):
			lit += 1
	if count.text != "4 / 6" or bells.get_child_count() != 6 or lit != 4:
		bad.append("set_alarm(4) shows %s with %d of %d bells lit, not 4 / 6 with 4 of 6"
				% [count.text, lit, bells.get_child_count()])
	if count.has_theme_color_override("font_color"):
		bad.append("set_alarm colours the plain alarm's count, which alarm() never does")
	p.queue_free()
	for at: int in [100, 200]:
		Settings.text_scale = at
		var fit := KitHud.alarm_fit(3, 6, "Alarm")
		fit.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		screen.add_child(fit)
		await tree.process_frame
		var n := fit.find_child("Count", true, false) as Label
		var under := n.get_parent() is VBoxContainer
		if under != (at > 130):
			bad.append("alarm_fit at %d%% text puts the count %s the word" % [at, "under" if under else "beside"])
		if n.has_theme_color_override("font_color"):
			bad.append("alarm_fit(3 of 6) writes the count in the alarm's red before past half the bells")
		KitHud.set_alarm(fit, 4)
		if n.get_theme_color("font_color") != Tokens.color("alarm_text_on_night"):
			bad.append("alarm_fit at 4 of 6 (%d%% text) does not write the count in the alarm's red" % at)
		if fit.accessibility_name != Strings.t("HUD_ALARM", "4 / 6"):
			bad.append("alarm_fit is named \"%s\" for a screen reader, not \"%s\""
					% [fit.accessibility_name, Strings.t("HUD_ALARM", "4 / 6")])
		fit.queue_free()


static func _loot(tree: SceneTree, screen: Control, bad: Array, at: int) -> void:
	var room := UI.px(90) * (2.3 if at > 130 else 1.0)
	var p := KitHud.loot_fit(LONG, 0.4, -1.0, "Carregar até 100% antes de sair", ["Cofre", "40%", 0.4])
	p.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	screen.add_child(p)
	for i: int in 2:
		await tree.process_frame
	var v := p.get_child(0) as Control
	if v.size.x > room + 1.0:
		bad.append("loot_fit at %d%% text is %d pixels wide inside, past its column's %d" % [at, v.size.x, room])
	var bar := p.find_child("Load", true, false) as KitBar
	if (bar.get_node("Aim") as Control).visible:
		bad.append("loot_fit with no aim (-1) still draws the aim's tick")
	if bar.size.y < UI.px(10) - 0.5:
		bad.append("loot_fit's load bar is thinner than 10 points")
	var caption := p.find_child("Caption", true, false) as Label
	if caption.autowrap_mode == TextServer.AUTOWRAP_OFF or caption.get_line_count() < 2:
		bad.append("loot_fit's long caption at %d%% text does not wrap" % at)
	var cracked := p.find_child("Cracked", true, false)
	var rows := (p.get_meta("words", []) as Array).size()
	if at > 130 and (cracked == null or rows != 2):
		bad.append("loot_fit with large text does not show the vault as a bar beside its icon")
	if at <= 130 and (cracked != null or rows != 3):
		bad.append("loot_fit does not show the vault as a third row (%d rows)" % rows)
	if not p.accessibility_name.contains("Cofre 40%") or not p.accessibility_name.contains("Carregar"):
		bad.append("loot_fit is named \"%s\" for a screen reader, without the vault and the caption"
				% p.accessibility_name)
	Settings.reduced_motion = true
	KitHud.set_loot(p, [["Sala", "2.100"], ["Restam", "~900"]], 0.7, 0.8, "Carregar até 80%", ["Cofre", "60%", 0.6])
	Settings.reduced_motion = false
	var said: Array = p.get_meta("numbers", [])
	if (said[0] as Label).text != "2.100" or (said[1] as Label).text != "~900":
		bad.append("set_loot does not write the new numbers")
	if not is_equal_approx(bar.value, 0.7) or caption.text != "Carregar até 80%":
		bad.append("set_loot does not move the load to 0.7 and write its caption")
	var tick := bar.get_node("Aim") as Control
	if not tick.visible or not is_equal_approx(tick.anchor_left, 0.8):
		bad.append("set_loot with an aim does not draw the aim's tick there")
	if at > 130 and not is_equal_approx((cracked as KitBar).value, 0.6):
		bad.append("set_loot does not move the vault's bar")
	if at <= 130 and (said[2] as Label).text != "60%":
		bad.append("set_loot does not write the vault's row")
	if not p.accessibility_name.contains("Cofre 60%") or not p.accessibility_name.contains("~900"):
		bad.append("set_loot does not rename the panel for a screen reader (\"%s\")" % p.accessibility_name)
	p.queue_free()


static func _chip(tree: SceneTree, screen: Control, bad: Array, at: int) -> void:
	var cap := UI.px(100) * maxf(1.0, at / 100.0)
	var dark := KitCards.law_chip_fit("laws/glowingdark", "Glowing dark beneath the old vault")
	var light := KitCards.law_chip_fit("laws/halfgravity", "Half gravity")
	for p: Control in [dark, light]:
		p.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		screen.add_child(p)
	await tree.process_frame
	var words := dark.find_child("Words", true, false) as Label
	if words.autowrap_mode == TextServer.AUTOWRAP_OFF or words.get_line_count() < 2:
		bad.append("law_chip_fit's long name does not wrap at %d%% text" % at)
	if words.size.x > cap + 1.0:
		bad.append("law_chip_fit's name is %d pixels wide at %d%% text, past %d" % [words.size.x, at, cap])
	if dark.find_child("Disc", true, false) == null or light.find_child("Disc", true, false) != null:
		bad.append("law_chip_fit puts the disc behind the wrong icon (it is for a dark icon only)")
	if not KitCards.dark_icon("laws/glowingdark") or KitCards.dark_icon("laws/halfgravity"):
		bad.append("dark_icon does not tell Glowing dark's icon (dark) from Half gravity's (light)")
	dark.queue_free()
	light.queue_free()


static func _words(tree: SceneTree, screen: Control, bad: Array) -> void:
	var said := UI.world_words("Laws here", 16)
	var tip := KitHud.tip("Tap crew, then ground")
	var plain := KitHud.crew(null, "Pip", 0.6, 2, func() -> void: pass)
	var inked := KitHud.crew(null, "Pip", 0.6, 2, func() -> void: pass, "", true)
	for c: Control in [said, tip, plain, inked]:
		c.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		screen.add_child(c)
	await tree.process_frame
	if not _counts(said, 16) or not said.has_meta("bold") \
			or said.get_theme_color("font_color") != Tokens.color("gold_top"):
		bad.append("world_words is not bold gold with an outline that counts all round")
	var w := tip.get_node("Words") as Label
	if str(tip.get_meta("rb_material", "")) != "leather" or w.autowrap_mode == TextServer.AUTOWRAP_OFF \
			or not _counts(w, 15):
		bad.append("the tip is not wrapping words on leather with an outline that counts")
	var names: Array[Label] = []
	var bars: Array[KitBar] = []
	for c: Control in [plain, inked]:
		for l: Node in c.find_children("*", "Label", true, false):
			if (l as Label).text == "Pip":
				names.append(l as Label)
		bars.append(c.find_children("*", "KitBar", true, false)[0] as KitBar)
	if names.size() != 2 or not _counts(names[1], 14) or names[0].get_theme_constant("outline_size") != UI.px(2):
		bad.append("crew(inked) does not give the name an outline that counts, or crew() changed its own")
	if bars[1].custom_minimum_size.y <= bars[0].custom_minimum_size.y \
			or bars[0].custom_minimum_size.y != UI.px(8):
		bad.append("crew(inked) does not draw a thicker health bar, or crew() changed its own")
	for c: Control in [said, tip, plain, inked]:
		c.queue_free()


static func _fly(tree: SceneTree, screen: Control, bad: Array) -> void:
	var counter := KitHud.loot(LONG, 0.4, 0.8, "")
	counter.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	screen.add_child(counter)
	await tree.process_frame
	Settings.reduced_motion = true
	var still := Icons.view("heiststatus/lootbag", 14.0)
	screen.add_child(still)
	if Motion.fly(still, Vector2(500, 1500), counter) != null or not still.is_queued_for_deletion():
		bad.append("Motion.fly under reduced motion moves the coin rather than freeing it at once")
	Settings.reduced_motion = false
	var coin := Icons.view("heiststatus/lootbag", 14.0)
	screen.add_child(coin)
	var t := Motion.fly(coin, Vector2(500, 1500), counter)
	if t == null or not coin.top_level:
		bad.append("Motion.fly does not fly the coin")
	else:
		await tree.create_timer(0.3).timeout
		await tree.process_frame
		if is_instance_valid(coin) and not coin.is_queued_for_deletion():
			bad.append("Motion.fly leaves the coin after 300 ms, past §21.8's 250 ms")
	counter.queue_free()
