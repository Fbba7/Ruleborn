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
		_:
			_cards(column)


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
	rounds.add_child(KitControls.round_action("realmactions/weave", "Weave", func() -> void: pass, false, 60, "1"))
	rounds.add_child(KitControls.round_action("realmactions/build", "Build", func() -> void: pass, true, 72))
	rounds.add_child(KitControls.round_action("hud/compass", "Map", func() -> void: pass, false, 60))
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
	var res := HBoxContainer.new()
	res.add_theme_constant_override("separation", UI.px(6))
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
	pills.add_child(KitStatus.pill("Ready", "", "parchment"))
	column.add_child(pills)
	column.add_child(KitStatus.progress(3, 5, "3 / 5", Tokens.color("motion")))
	column.add_child(KitStatus.progress(7, 12, "7 / 12", Tokens.color("time")))
	column.add_child(KitPanels.section("Reminders"))
	column.add_child(KitPanels.row("alerts/buildingready", "Star Well is ready", "Collect 1,200 Starlight",
		KitStatus.badge("2"), func() -> void: pass))
	column.add_child(KitPanels.row("alerts/raided", "Raided by Marta", "Held · 2 of 3 pylons stood",
		KitStatus.plate("12m")))
	var banners := VBoxContainer.new()
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
	var res := HBoxContainer.new()
	res.add_theme_constant_override("separation", UI.px(6))
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
	left.add_child(KitControls.round_action("hud/crew", "Crew", func() -> void: pass, false, 52))
	left.add_child(KitControls.round_action("alerts/newtargets", "Raid", func() -> void: pass, false, 52, "4"))
	sides.add_child(left)
	sides.add_child(UI.grow())
	(sides.get_child(1) as Control).size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var right := VBoxContainer.new()
	right.alignment = BoxContainer.ALIGNMENT_CENTER
	right.add_child(KitControls.round_action("screens/shop", "Shop", func() -> void: pass, false, 52))
	right.add_child(KitControls.round_action("screens/season", "Season", func() -> void: pass, false, 52))
	sides.add_child(right)
	column.add_child(sides)
	var collect := UI.row()
	collect.add_child(UI.action("Collect 3.4k", func() -> void: pass, "gold"))
	column.add_child(collect)
	column.add_child(KitHud.goal("realmactions/upgrade", "Raise the Star Well to level 3", 2, 3, "2 / 3"))
	column.add_child(KitNav.tabs("islands", {"islands": 3, "heist": 4, "friends": 1}))


## Law cards in the four rarity frames, and the six school chips.
static func _cards(column: VBoxContainer) -> void:
	column.add_child(KitNav.header("Codex", "Law cards"))
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", UI.px(14))
	grid.add_theme_constant_override("v_separation", UI.px(14))
	for c: Array in [["laws/bounce", "Bounce", "motion", "common", ""],
			["laws/stillness", "Stillness", "time", "uncommon", "II"],
			["laws/brittlestone", "Brittle Stone", "matter", "rare", ""],
			["laws/soullanterns", "Soul Lanterns", "spirit", "deep", ""]]:
		var icon: String = c[0] if Icons.has(c[0]) else "laws/bounce"
		grid.add_child(KitCards.law_card(icon, c[1], c[2], c[3], c[4]))
	var centre := CenterContainer.new()
	centre.add_child(grid)
	column.add_child(centre)
	var schools := UI.row(6)
	for school: String in Tokens.schools():
		schools.add_child(KitCards.school_chip(school))
	column.add_child(schools)
