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
	column.add_child(UI.title("Controls"))


static func _status(column: VBoxContainer) -> void:
	column.add_child(UI.title("Status"))
