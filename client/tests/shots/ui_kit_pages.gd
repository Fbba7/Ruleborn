class_name UiKitPages
extends RefCounted
## The pages of the kit's component sheet (ui_kit_sheet.gd).


static func page(column: VBoxContainer, n: int) -> void:
	match n:
		1:
			_materials(column)
		2:
			_controls(column)
		_:
			_status(column)


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
	column.add_child(KitNav.header("Settings", "Wellbeing"))
	column.add_child(KitNav.segmented(["Roster", "Sages", "Forms"], 0, func(_i: int) -> void: pass))
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
		"No swoops, fewer particles", "On", true, func() -> void: pass))
	column.add_child(KitControls.toggle_row("settingsandwellbeing/accessibility", "High contrast",
		"Opaque cards, heavier outlines", "Off", false, func() -> void: pass))
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
	pills.add_child(KitStatus.pill("82% · Humming", "hud/strain"))
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
