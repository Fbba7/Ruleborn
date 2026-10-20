class_name UniverseHeading
extends RefCounted
## A realm's heading in a screen's word list over the universe map (the map
## and the universe screens): the realm type's own icon from the design's set
## beside the words a screen reader reads, and a tap on it swoops the map to
## that realm, as a tap on the island does. The words stay the label they
## were, so what a screen says and what its tests read are unchanged.


## `title` (a Label) led by realm `id`'s icon, as drawn in `view`.
static func make(title: Label, id: String, view: UniverseView) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", UI.px(6))
	var icon := TextureRect.new()
	icon.texture = load("res://world/universe_icons/realm_%s.svg" % _key(id, view))
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.custom_minimum_size = Vector2.ONE * UI.text_px(UI.TEXT_POINTS) * 1.6
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(icon)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(title)
	row.mouse_filter = Control.MOUSE_FILTER_PASS
	var pressed_at := [Vector2.ZERO]
	row.gui_input.connect(func(e: InputEvent) -> void:
		var b := e as InputEventMouseButton
		if b == null or b.button_index != MOUSE_BUTTON_LEFT:
			return
		if b.pressed:
			pressed_at[0] = b.global_position
		elif b.global_position.distance_to(pressed_at[0]) < UniverseView.TAP_PX and view.islands.has(id):
			view.focus_realm(id, 1))
	return row


## The realm's type key, for its icon: the Heart, or the type the map drew.
static func _key(id: String, view: UniverseView) -> String:
	if view != null and view.islands.has(id):
		return (view.islands[id] as UniverseIsland).key
	return "heart"
