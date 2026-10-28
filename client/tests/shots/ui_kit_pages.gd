class_name UiKitPages
extends RefCounted
## The pages of the kit's component sheet (ui_kit_sheet.gd).


static func page(column: VBoxContainer, n: int) -> void:
	match n:
		1:
			_materials(column)
		2:
			_controls(column)
		3:
			_status(column)
		4:
			_home(column)
		5:
			_cards(column)
		6:
			_settings(column)
		7:
			_roster(column)
		8:
			_result(column)
		9:
			_heist(column)
		10:
			_character(column)
		12:
			_friends(column)
		13:
			_log(column)
		14:
			_stats(column)
		15:
			_tray(column)
		_:
			_season(column)


static func _materials(column: VBoxContainer) -> void:
	column.add_child(UI.title("Materials"))
	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", UI.px(12))
	grid.add_theme_constant_override("v_separation", UI.px(14))
	for m: String in Tokens.materials():
		if m == "night":
			continue
		var p := UI.panel(m)
		p.custom_minimum_size = Vector2(UI.px(100), UI.px(64))
		var l := UI.label(m, 13)
		l.theme_type_variation = "Kicker"
		p.add_child(l)
		grid.add_child(p)
	var c := CenterContainer.new()
	c.add_child(grid)
	column.add_child(c)
	var types := UI.panel("card")
	var list := VBoxContainer.new()
	for role: String in Tokens.type_roles():
		var l := UI.label("%s 1234 Aa" % role, float(Tokens.type_role(role)["points"]))
		l.theme_type_variation = RbTheme.variation(role)
		list.add_child(l)
	types.add_child(list)
	column.add_child(types)


static func _controls(column: VBoxContainer) -> void:
	column.add_child(KitNav.top_bar("Settings", func() -> void: pass, "Age 18+"))
	column.add_child(KitNav.segmented([["Wellbeing", "settingsandwellbeing/playtimereminder"],
		["Game", "settingsandwellbeing/sound"], ["Access", "settingsandwellbeing/accessibility"],
		["Account", "settingsandwellbeing/account"]], 0, func(_i: int) -> void: pass))
	column.add_child(KitNav.segmented(["Off", "45 min", "60 min", "90 min"], 0, func(_i: int) -> void: pass))
	var chips := UI.row(6)
	for c: Array in [["All", true], ["Motion", false], ["Time", false]]:
		chips.add_child(KitControls.chip(c[0], c[1], func() -> void: pass))
	column.add_child(chips)
	var buttons := UI.row(8)
	for look: String in ["gold", "leather", "red", "green", "ghost"]:
		buttons.add_child(UI.action(look.capitalize(), func() -> void: pass, look))
	column.add_child(buttons)
	var rounds := UI.row(18)
	rounds.add_child(KitControls.round_action("realmactions/weave", "Weave", func() -> void: pass, false, 60,
		"1 free", "violet"))
	rounds.add_child(KitControls.round_action("realmactions/build", "Build", func() -> void: pass, true, 76))
	rounds.add_child(KitControls.round_action("screens/universe", "Map", func() -> void: pass, false, 68, "",
		"sky"))
	rounds.add_child(KitNav.back(func() -> void: pass))
	column.add_child(rounds)
	column.add_child(KitControls.toggle_row("settingsandwellbeing/reducedmotion", "Reduced motion",
		"No swoops, fewer particles", true, func(_on: bool) -> void: pass))
	column.add_child(KitControls.toggle_row("settingsandwellbeing/accessibility", "High contrast",
		"Opaque cards, heavier outlines", false, func(_on: bool) -> void: pass))
	var sw := UI.row(10)
	var slider := HSlider.new()
	slider.custom_minimum_size = Vector2(UI.px(140), UI.px(48))
	slider.value = 60
	sw.add_child(slider)
	column.add_child(sw)
	column.add_child(KitPanels.locked("settingsandwellbeing/playtimereminder", "Play reminder", "Every 60 min",
		"Set for ages 13 to 15"))
	column.add_child(UI.field("Keeper name"))
	column.add_child(UI.grow())
	column.add_child(KitNav.tabs("heist", {"islands": 3, "laws": 1, "crew": 2}))


static func _status(column: VBoxContainer) -> void:
	column.add_child(KitNav.header("Status", "Pieces"))
	# A flow, so at large text the pills take a second line, not the phone's edge.
	var res := KitLayout.flow(6)
	for r: Array in [["resources/starlight", "12,480", 0.62, Tokens.color("starlight")],
			["resources/aether", "3,105", 0.95, Tokens.color("aether")],
			["resources/essence", "840", 0.2, Tokens.color("essence")]]:
		var pill := KitStatus.resource(r[0], r[1], r[2], r[3])
		pill.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		res.add_child(pill)
	column.add_child(res)
	var pills := UI.row(8)
	pills.add_child(KitStatus.strain("82% · Humming", "humming"))
	pills.add_child(KitStatus.badge("4"))
	pills.add_child(KitStatus.plate("LV 5"))
	pills.add_child(KitStatus.island_label("realms/verdant", "Verdant", 3))
	column.add_child(pills)
	column.add_child(KitStatus.progress(3, 5, "3 / 5", Tokens.color("motion")))
	column.add_child(KitStatus.progress(7, 12, "7 / 12", Tokens.color("time")))
	column.add_child(KitPanels.section("Reminders"))
	column.add_child(KitPanels.row("alerts/buildingready", "Star Well is ready", "Collect 1,200 Starlight",
		KitStatus.badge("2"), func() -> void: pass))
	column.add_child(KitPanels.row("alerts/raided", "Raided by Marta", "Held · 2 of 3 pylons stood",
		KitStatus.plate("12m")))
	var banners := VBoxContainer.new()
	banners.add_child(KitPanels.notice("alarm", "alerts/raided", "Marta raided Verdant", "Your defence kept 1,240 Essence",
		"Trace", func() -> void: pass))
	banners.add_child(UI.banner("success", "Woven: Haste into the Heart"))
	banners.add_child(UI.banner("alarm", "Not enough Essence to level Pip"))
	column.add_child(banners)
	var sheet := KitPanels.sheet("Build")
	(sheet.get_meta("body") as VBoxContainer).add_child(UI.label("Choose a building for the Heart.", 16, true))
	column.add_child(sheet)


## The home arrangement §21.8 names, from the kit's pieces: Keeper and
## Renown top left, strain top right, resources with storage beneath, side
## buttons down both edges, the nearest goal above five tabs; and the heist's
## clock, alarm meter and ability pips.
static func _home(column: VBoxContainer) -> void:
	var top := HBoxContainer.new()
	top.add_child(KitHud.keeper(Icons.texture("crewroles/scout"), "Ines", 7, 0.64, "410"))
	top.add_child(UI.grow())
	(top.get_child(1) as Control).size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var strain := KitStatus.strain("82% · Humming", "humming")
	strain.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	top.add_child(strain)
	column.add_child(top)
	# A flow, so at large text the pills take a second line, not the phone's edge.
	var res := KitLayout.flow(6)
	for r: Array in [["resources/starlight", "12,480", 0.62, Tokens.color("starlight")],
			["resources/aether", "3,105", 0.95, Tokens.color("aether")],
			["resources/essence", "840", 0.2, Tokens.color("essence")]]:
		var pill := KitStatus.resource(r[0], r[1], r[2], r[3])
		pill.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		res.add_child(pill)
	column.add_child(res)
	var hud := HBoxContainer.new()
	hud.alignment = BoxContainer.ALIGNMENT_CENTER
	hud.add_theme_constant_override("separation", UI.px(12))
	hud.add_child(KitHud.pips(1, 2))
	hud.add_child(KitHud.clock("2:26"))
	hud.add_child(KitHud.meter(4, 6, "Alarm 4 / 6"))
	hud.add_child(KitHud.clock("0:24", true))
	column.add_child(hud)
	var sides := HBoxContainer.new()
	sides.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var left := VBoxContainer.new()
	left.alignment = BoxContainer.ALIGNMENT_CENTER
	# The designs' 36-point balls over §21.1's 48-point hit areas.
	left.add_child(KitControls.round_action("hud/crew", "Crew", func() -> void: pass, false, 48, "", "leather", 36))
	left.add_child(KitControls.round_action("alerts/newtargets", "Raid", func() -> void: pass, false, 48, "4",
		"leather", 36))
	sides.add_child(left)
	sides.add_child(UI.grow())
	(sides.get_child(1) as Control).size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var right := VBoxContainer.new()
	right.alignment = BoxContainer.ALIGNMENT_CENTER
	right.add_child(KitControls.round_action("screens/shop", "Shop", func() -> void: pass, false, 48, "", "leather", 36))
	right.add_child(KitControls.round_action("screens/season", "Season", func() -> void: pass, false, 48, "",
		"leather", 36))
	sides.add_child(right)
	column.add_child(sides)
	var collect := UI.row()
	collect.add_child(UI.action("Collect 3.4k", func() -> void: pass, "gold"))
	column.add_child(collect)
	column.add_child(KitHud.goal("realmactions/upgrade", "Raise the Star Well to level 3", 2, 3, "2 / 3"))
	column.add_child(KitNav.tabs("islands", {"islands": 3, "heist": 4, "friends": 1}))


## Law cards in the four rarity frames, and the six school chips.
static func _cards(column: VBoxContainer) -> void:
	column.add_child(KitNav.segmented([["All laws", "screens/lawcodex"], ["Harmony", "screens/harmonyview"],
		["Lab", "screens/resonancelab"]], 0, func(_i: int) -> void: pass))
	# One row that scrolls sideways, as the design's, rather than two.
	var filters := KitLayout.strip(4)
	var row := filters.get_node("Row") as HBoxContainer
	row.add_child(KitControls.chip("All 18 / 24", true, func() -> void: pass))
	for school: String in Tokens.schools():
		row.add_child(KitControls.school_button(school, school == "time", func() -> void: pass))
	column.add_child(filters)
	column.add_child(KitControls.search("Search laws"))
	var grid := GridContainer.new()
	grid.columns = KitLayout.grid_columns(3)
	grid.add_theme_constant_override("h_separation", UI.px(8))
	grid.add_theme_constant_override("v_separation", UI.px(8))
	for c: Array in [["laws/bounce", "Bounce", "motion", "common", ""],
			["laws/halfgravity", "Half gravity", "motion", "uncommon", "II"],
			["laws/frictionless", "Frictionless", "motion", "rare", ""]]:
		var icon: String = c[0] if Icons.has(c[0]) else "laws/bounce"
		grid.add_child(KitCards.law_card(icon, c[1], c[2], c[3], c[4], 102, str(12 + grid.get_child_count() * 4)))
	var centre := CenterContainer.new()
	centre.add_child(grid)
	column.add_child(KitPanels.album("motion", "Motion", "Chapter I", "3 of 4 restored", centre))
	# A column fewer as large text widens the cards (KitLayout.grid_columns).
	var more := GridContainer.new()
	more.columns = KitLayout.grid_columns(3)
	more.add_theme_constant_override("h_separation", UI.px(8))
	more.add_theme_constant_override("v_separation", UI.px(8))
	more.add_child(KitCards.album_card("laws/bounce", "Brittle stone", "matter", "common", "In Skyfield", "10"))
	more.add_child(KitCards.album_card("laws/frictionless", "Glass", "matter", "rare", "In Emberreach", "12", "I"))
	more.add_child(KitCards.album_card("laws/halfgravity", "Inward pull", "matter", "deep", "", "22"))
	column.add_child(KitPanels.album("matter", "Matter", "Chapter II", "1 of 4 restored", more))


## The design's Settings and wellbeing screen (19-settings-and-wellbeing.png)
## built from the kit alone, as the reference for the screen's owner.
static func _settings(column: VBoxContainer) -> void:
	column.add_child(KitNav.top_bar("Settings", func() -> void: pass, "Age 18+"))
	column.add_child(KitNav.segmented([["Wellbeing", "settingsandwellbeing/playtimereminder"],
		["Game", "settingsandwellbeing/sound"], ["Access", "settingsandwellbeing/accessibility"],
		["Account", "settingsandwellbeing/account"]], 0, func(_i: int) -> void: pass))
	var body := UI.scroll(column)
	var play := UI.panel("card_gold")
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", UI.px(12))
	var dial := KitHud.dial("38", "min today", 1.0)
	dial.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var words := VBoxContainer.new()
	words.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	words.alignment = BoxContainer.ALIGNMENT_CENTER
	var t := UI.label("Play-time reminder is off", 16, true)
	t.theme_type_variation = "BodyBold"
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	t.set_meta("bold", true)
	words.add_child(t)
	var s := UI.label("Turn it on below for a gentle pause card.", 13, true)
	s.theme_type_variation = "Secondary"
	s.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	words.add_child(s)
	# Side by side, stacked at large text (KitLayout.columns).
	var top := KitLayout.columns([dial, words], 12)
	dial.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	v.add_child(top)
	var week := PanelContainer.new()
	week.add_theme_stylebox_override("panel", UI.clear_box(10, 8))
	UI.dress(week, "well")
	var wv := VBoxContainer.new()
	# A flow: at large text the total takes a line of its own.
	var head := KitLayout.flow(8)
	var k := UI.label("This week", 13)
	k.theme_type_variation = "Kicker"
	k.uppercase = true
	k.set_meta("bold", true)
	k.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	k.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	head.add_child(k)
	var total := UI.label("4 h this week", 13)
	total.theme_type_variation = "Number"
	total.add_theme_color_override("font_color", Tokens.color("gold_top"))
	total.set_meta("bold", true)
	head.add_child(total)
	wv.add_child(head)
	wv.add_child(KitHud.week([60, 40, 55, 15, 38, 20, 48], ["M", "T", "W", "T", "F", "S", "S"], 6))
	week.add_child(wv)
	v.add_child(week)
	play.add_child(v)
	body.add_child(play)
	body.add_child(KitPanels.section("Reminders"))
	for r: Array in [["settingsandwellbeing/playtimereminder", "Play-time reminder", "A pause card after long play",
			["Off", "45 min", "60 min", "90 min"]],
			["settingsandwellbeing/notifications", "Quiet hours", "No notifications 22:00 - 08:00", ["On", "Off"]]]:
		var card := UI.panel("card")
		var cv := VBoxContainer.new()
		cv.add_theme_constant_override("separation", UI.px(8))
		cv.add_child(KitPanels.row(r[0], r[1], r[2], null, Callable(), "seg"))
		cv.add_child(KitNav.segmented(r[3], 0, func(_i: int) -> void: pass))
		card.add_child(cv)
		body.add_child(card)
	body.add_child(KitControls.toggle_row("settingsandwellbeing/reducedmotion", "Reduced motion",
		"No swoops, fewer particles", false, func(_on: bool) -> void: pass))


## The design's Roster pieces (10-roster.png): the hub strip, the actions,
## the filters with their dots and counts, and portrait cards.
static func _roster(column: VBoxContainer) -> void:
	column.add_child(KitNav.segmented([["Roster", "screens/roster"], ["Sages", "screens/sagehall"],
		["Forms", "screens/formsalbum"]], 0, func(_i: int) -> void: pass))
	var acts := HBoxContainer.new()
	acts.add_theme_constant_override("separation", UI.px(8))
	var assign := UI.action("Assign", func() -> void: pass, "gold")
	assign.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	acts.add_child(assign)
	var up := KitControls.action2("Level up", "866 Essence", func() -> void: pass, "green_muted")
	up.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	acts.add_child(up)
	acts.add_child(KitControls.icon_button("generalui/info", "About Pip", func() -> void: pass))
	column.add_child(acts)
	var filters := UI.row(6)
	filters.add_child(KitControls.chip("All", true, func() -> void: pass, "12"))
	filters.add_child(KitControls.chip("Idle", false, func() -> void: pass, "3", Tokens.color("success")))
	filters.add_child(KitControls.chip("Working", false, func() -> void: pass, "4", Tokens.color("motion")))
	column.add_child(filters)
	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", UI.px(8))
	grid.add_theme_constant_override("v_separation", UI.px(8))
	# The characters' own portraits, as the design's cards show them.
	for c: Array in [["mossbear", "Bramble", 6, "life"], ["skyskipper", "Pip", 5, "motion"],
			["glass_golem", "Facet", 5, "matter"], ["tidewalker", "Mo", 4, "time"],
			["emberling", "Ash", 4, "energy"], ["lantern_wisp", "Volt", 4, "spirit"]]:
		grid.add_child(KitCards.portrait(Portrait.of(str(c[0])), c[1], c[2], c[3], Tokens.color("success"),
			"crewroles/carrier", func() -> void: pass, c[1] == "Pip"))
	column.add_child(grid)
	column.add_child(UI.grow())
	var tabs := KitNav.tabs("crew", {"islands": 3, "laws": 1, "heist": 4, "friends": 3})
	# Pip's face on the chosen tab, as 10-roster.png draws it.
	tabs.face("crew", Portrait.of("skyskipper"))
	column.add_child(tabs)


## The design's result and shop pieces (07-heist-result.png, 18-shop.png).
static func _result(column: VBoxContainer) -> void:
	KitNav.celebrate(column.get_parent().get_parent() as Control)
	column.add_child(KitNav.hero("Heist complete", "Loud", "Alarm raised · everyone out", "Haul ×0.7 · Renown ×0.8"))
	var rewards := HBoxContainer.new()
	rewards.add_theme_constant_override("separation", UI.px(8))
	rewards.add_child(KitCards.reward("resources/starlight", "+2,310", "Starlight", "gold"))
	rewards.add_child(KitCards.reward("resources/essence", "+805", "Essence", "green"))
	rewards.add_child(KitCards.reward("resources/renown", "+15", "Renown", "pink"))
	column.add_child(rewards)
	var tags := UI.row(8)
	tags.add_child(KitStatus.tag("Featured set"))
	tags.add_child(KitStatus.tag("Emote", true))
	column.add_child(tags)
	var prices := UI.row(8)
	prices.add_child(KitControls.action2("120", "≈ €1.20", func() -> void: pass, "gem", "currencies/starglass"))
	prices.add_child(KitControls.action2("€8.99", "899 ✦", func() -> void: pass, "gold"))
	column.add_child(prices)
	column.add_child(UI.grow())
	var end := HBoxContainer.new()
	end.add_theme_constant_override("separation", UI.px(8))
	end.add_child(UI.action("Home", func() -> void: pass, "leather"))
	var again := KitControls.action2("Raid again", "Idle crew of 5 ready", func() -> void: pass, "gold")
	again.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	end.add_child(again)
	column.add_child(end)


## The design's heist HUD pieces (02-heist.png), over a stand-in for the
## world.
static func _heist(column: VBoxContainer) -> void:
	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", UI.px(8))
	var laws := VBoxContainer.new()
	laws.add_child(KitCards.law_chip("laws/sleepwalk", "Sleepwalk"))
	laws.add_child(KitCards.law_chip("laws/glass", "Glass"))
	top.add_child(laws)
	var mid := VBoxContainer.new()
	mid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mid.add_child(KitHud.clock("2:38"))
	mid.add_child(KitHud.alarm(2, 6, "Alarm"))
	top.add_child(mid)
	top.add_child(KitHud.loot([["Room", "1,840"], ["Left", "2,600"]], 0.62, 0.8, "Load to 80%"))
	column.add_child(top)
	column.add_child(UI.grow())
	column.add_child(KitStatus.hint("Tap crew, then ground · hold ground to sneak or run"))
	var foot := HBoxContainer.new()
	foot.add_theme_constant_override("separation", UI.px(4))
	var crew := HBoxContainer.new()
	crew.add_theme_constant_override("separation", UI.px(2))
	crew.size_flags_vertical = Control.SIZE_SHRINK_END
	for c: Array in [["skyskipper", "Pip", 1.0, 2, "motion"], ["tidewalker", "Mo", 0.7, 1, "time"],
			["mossbear", "Bramble", 0.4, 0, "life"], ["emberling", "Ash", 0.9, 2, "energy"]]:
		crew.add_child(KitHud.crew(Portrait.of(str(c[0])), c[1], c[2], c[3], func() -> void: pass, c[4]))
	foot.add_child(crew)
	foot.add_child(UI.grow())
	(foot.get_child(foot.get_child_count() - 1) as Control).size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var right := VBoxContainer.new()
	right.add_theme_constant_override("separation", UI.px(8))
	right.add_child(KitHud.sage(Portrait.of("archivist"), "The Archivist", "Cast", func() -> void: pass))
	right.add_child(KitControls.big_action("heistcontrols/getout", "Get out", func() -> void: pass))
	foot.add_child(right)
	column.add_child(foot)


## The design's Character pieces (11-character.png).
static func _character(column: VBoxContainer) -> void:
	column.add_child(UI.grow())
	var stats := HBoxContainer.new()
	stats.add_theme_constant_override("separation", UI.px(8))
	stats.add_child(KitHex.make("LV", "5"))
	var xp := KitStatus.xp(588, 600, "588 / 600 XP")
	xp.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	stats.add_child(xp)
	stats.add_child(KitStatus.pill("200", "hud/star", "leather"))
	column.add_child(stats)
	column.add_child(KitNav.segmented([["Heist", "screens/heist"], ["Stats", "realmactions/upgrade"],
		["Compare", "generalui/sort"]], 0, func(_i: int) -> void: pass))
	var facts := GridContainer.new()
	facts.columns = 2
	facts.add_theme_constant_override("h_separation", UI.px(8))
	facts.add_theme_constant_override("v_separation", UI.px(8))
	facts.add_child(KitCards.fact("crewroles/carrier", "Carrier", "Carries the loot", "motion"))
	facts.add_child(KitCards.fact("hud/shield", "Resists", "No-jump zones", "life"))
	facts.add_child(KitCards.fact("traits/hoarder", "Traits", "Swift · Lucky", "matter"))
	facts.add_child(KitCards.fact("buildings/starwell" if Icons.has("buildings/starwell") else "hud/home",
		"At home", "Star Well · +12%", "time"))
	var paper := UI.panel("parchment")
	var inside := VBoxContainer.new()
	inside.add_theme_constant_override("separation", UI.px(10))
	inside.add_child(KitCards.ability("crewroles/carrier", "motion", "Ability", "Once a heist", "Stuff the satchel",
		"Loads loot at 60 a second instead of 30 for 5 s."))
	inside.add_child(facts)
	paper.add_child(inside)
	column.add_child(paper)
	var end := HBoxContainer.new()
	end.add_theme_constant_override("separation", UI.px(8))
	end.add_child(KitControls.round_action("screens/heist", "Heist", func() -> void: pass, false, 52))
	var up := KitControls.upgrade("Upgrade", "Lv 5 → 6 · +539 power", "resources/essence", "866", func() -> void: pass)
	up.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	up.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	end.add_child(up)
	column.add_child(end)


## The design's first-launch logo and season pieces (20, 17).
static func _season(column: VBoxContainer) -> void:
	column.add_child(KitNav.logo("Ruleborn"))
	var line := UI.label("Your islands. Your rules. Their treasure.", 18, true)
	column.add_child(line)
	column.add_child(KitNav.top_bar("Held Breath", func() -> void: pass, "18 days"))
	# A sideways strip, as the design's reward track (17-season.png).
	var rewards := KitLayout.strip(8)
	var row := rewards.get_node("Row") as HBoxContainer
	row.add_child(KitCards.season_reward("Common", "currencies/starglass", "600", func() -> void: pass, false, "Claim"))
	row.add_child(KitCards.season_reward("Common", "currencies/pages", "×2", func() -> void: pass, false, "Claim"))
	row.add_child(KitCards.season_reward("Rare", "currencies/starglass", "1,200", Callable(), true))
	column.add_child(KitRail.make(11, 3, 12, 0.68, "Tier 12, 340 of 500 to the next"))
	column.add_child(rewards)


## The design's Friends pieces (27-friends.png) and a chip strip that
## scrolls sideways (18-shop.png).
static func _friends(column: VBoxContainer) -> void:
	var chips := KitLayout.strip(6)
	var chip_row := chips.get_node("Row") as HBoxContainer
	chip_row.add_child(KitControls.chip("All", true, func() -> void: pass))
	for c: String in ["Realm skins", "Outfits", "Sage robes", "Emotes"]:
		chip_row.add_child(KitControls.chip(c, false, func() -> void: pass))
	column.add_child(chips)
	var picks := KitLayout.strip(8)
	var pick_row := picks.get_node("Row") as HBoxContainer
	for p: Array in [["archivist", "Emote", "Tip of the Hat", "120"], ["tidewalker", "Outfit", "Tide Raincoat", "160"],
			["lantern_wisp", "Bridge style", "Living Vines", "240"]]:
		var card := KitCards.product(Portrait.of(str(p[0])), p[1], p[2], p[3], func() -> void: pass, "round_violet",
			128.0, "resources/renown")
		if pick_row.get_child_count() == 0:
			card.add_child(KitStatus.sash("Trace · 24 h"))
		pick_row.add_child(card)
	column.add_child(picks)
	var people := KitLayout.strip(10)
	var people_row := people.get_node("Row") as HBoxContainer
	for f: Array in [["mossbear", "Kofi", "Raiding", "alarm"], ["lantern_wisp", "Lea", "Workshop", "spirit"],
			["glass_golem", "Tomas", "Home", "life"], ["tidewalker", "Aiko", "3 h ago", ""], ["", "Ines", "Yesterday", ""]]:
		var picture: Texture2D = Portrait.of(str(f[0])) if f[0] != "" else null
		people_row.add_child(KitSocial.avatar(picture, str(f[1]).left(2).to_upper(), f[1], f[2], f[3],
			func() -> void: pass))
	column.add_child(people)
	column.add_child(KitSocial.feed_row(Portrait.of("mossbear"), "KO", "Kofi", "Escaped", "success", "12 min",
		"Kofi's crew slipped through Ines's Glowing dark with 2,300 Starlight.", Icons.texture("screens/heist"),
		"Watch", func() -> void: pass))
	column.add_child(KitSocial.feed_row(null, "LE", "Lea", "Challenge", "gold", "40 min",
		"Sent you her Lantern Vale to beat: Stillness and Echoes, 2:30 on the clock.", null, "Play",
		func() -> void: pass))
	column.add_child(KitSocial.feed_row(Portrait.of("tidewalker"), "AI", "Aiko", "Hatched", "", "3 h",
		"Hatched a Spark Emberling. It was born swift, a body trait."))


## The design's Defence log (16-rehearsal-and-defence-log-defence-log.png).
static func _log(column: VBoxContainer) -> void:
	column.add_child(KitNav.segmented(["Rehearse", "Defence log"], 1, func(_i: int) -> void: pass))
	column.add_child(KitLayout.columns([KitStatus.stat("5", "Raids this week"), KitStatus.stat("4", "Held"),
		KitStatus.stat("2", "Trace ready")], 6))
	column.add_child(KitLayout.columns([KitControls.tile("Easy", "Slow rivers", "life", func() -> void: pass),
		KitControls.tile("Medium", "Glass", "motion", func() -> void: pass),
		KitControls.tile("Hard", "Haste", "energy", func() -> void: pass)], 6))
	column.add_child(KitPanels.notice("alarm", "", "A crew is in Tidehold now",
		"The raider's name shows when the raid ends", "", func() -> void: pass))
	column.add_child(KitSocial.log_row(Portrait.of("lantern_wisp"), "MA", "Marta", "Held", "success",
		"2 h ago · held them 2:31", "Denied 3,300", "success", "Report", func() -> void: pass))
	column.add_child(KitSocial.log_row(null, "KO", "Kofi", "Got out", "warn", "Yesterday · out via Lantern Vale",
		"You lost nothing", "info", "Report", func() -> void: pass))
	column.add_child(KitSocial.log_row(null, "TO", "Tomas", "Friendly", "violet", "2 days ago · caught twice",
		"+2 pages", "success", "Report", func() -> void: pass))


## The design's Player stats chart (19b-player-stats.png).
static func _stats(column: VBoxContainer) -> void:
	column.add_child(KitPanels.section("Renown"))
	var renown := UI.panel("card")
	var rv := VBoxContainer.new()
	var head := KitLayout.flow(8)
	var big := UI.label("1,460", 30)
	big.theme_type_variation = "Display"
	head.add_child(big)
	head.add_child(UI.status("success", "+11", false))
	rv.add_child(head)
	rv.add_child(KitChart.make([1260, 1270, 1262, 1290, 1300, 1295, 1330, 1350, 1345, 1372, 1390, 1380, 1405, 1420, 1410,
		1430, 1445, 1460], [[1450, "1,450"], [1350, "1,350"], [1250, "1,250"]], "Sep 28", "Today",
		"Renown 1,460 today, up 201 in 30 days"))
	renown.add_child(rv)
	column.add_child(renown)


## The design's build tray (04-realm-view-build-tray.png): a parchment sheet
## with the light segments and chips and the building cards.
static func _tray(column: VBoxContainer) -> void:
	column.add_child(UI.grow())
	var sheet := KitPanels.sheet("", "sheet_parchment")
	var body: VBoxContainer = sheet.get_meta("body")
	# Side by side, the close button over the segments at large text.
	var head: BoxContainer = HBoxContainer.new()
	if Settings.text_scale > KitLayout.SIDE_BY_SIDE_UP_TO:
		head = VBoxContainer.new()
		head.alignment = BoxContainer.ALIGNMENT_END
	head.add_theme_constant_override("separation", UI.px(8))
	var segs := KitNav.segmented(["Build", "Terrain", "Defence"], 0, func(_i: int) -> void: pass, true)
	segs.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var close := KitControls.icon_button("generalui/close", "Close", func() -> void: pass, "parchment")
	close.size_flags_horizontal = Control.SIZE_SHRINK_END
	if head is VBoxContainer:
		head.add_child(close)
		head.add_child(segs)
	else:
		head.add_child(segs)
		head.add_child(close)
	body.add_child(head)
	var chips := KitLayout.strip(6)
	var row := chips.get_node("Row") as HBoxContainer
	for c: Array in [["Economy", true], ["Homes", false], ["Arcane", false]]:
		row.add_child(KitControls.chip(c[0], c[1], func() -> void: pass, "", Color(0, 0, 0, 0), true))
	body.add_child(chips)
	var cards := KitLayout.strip(8)
	var card_row := cards.get_node("Row") as HBoxContainer
	for b: Array in [["resources/starlight", "Star Well", "Makes Starlight.", "1,200", "3 / 4"],
			["resources/aether", "Aether Loom", "Spins Aether for weaving.", "900", "2 / 3"],
			["resources/essence", "Essence Garden", "Grows Essence for births.", "800", "2 / 4"]]:
		var icon: String = b[0] if Icons.has(b[0]) else "realmactions/build"
		card_row.add_child(KitCards.build_card(icon, b[1], b[2], "resources/starlight", b[3], b[4],
			func() -> void: pass))
	body.add_child(cards)
	column.add_child(sheet)

