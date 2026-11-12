class_name UniverseBadge
extends PanelContainer
## Home's top left (§21.8's home layout), from the kit's Keeper part
## (`KitHud.keeper`): the Keeper's emblem in a ring whose gold arc is the way
## to the next Keeper level (§14.2), the level on a gold plate at the ring's
## foot, "Keeper 14" in the heading face, and Renown on a glass pill beneath,
## its gem before the number, so the number starts past the gem at every text
## size. The whole badge is one control (`KitLayout.tap`) that opens the menu
## of every screen, as the designs' portrait does. What it shows is said in
## words to a screen reader (§20.8).

signal pressed

var level := 0
## The share of the way to the next level, 0 to 1.
var share := 0.0
var title := ""
## Renown's number, or "" before the league has answered.
var renown := ""
## The kit's control over the whole badge.
var tap: Button
var _face: Texture2D = UniverseHud.icon("realm_heart")
var _row: Control
var _box := UI.clear_box(0, 0)


func _init() -> void:
	add_theme_stylebox_override("panel", _box)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	accessibility_name = Strings.t("HOME_MENU")
	tap = KitLayout.tap(self, func() -> void: pressed.emit(), accessibility_name)
	# The menu is a secondary place (§21.1 binds only the frequent controls to
	# the thumb zone), and the check reads that on the button itself.
	tap.set_meta("frequent", false)


## What the Keeper bar says (KeeperPresenter.bar), and Renown if known.
func show_keeper(bar: Dictionary, xp_share: float, renown_text: String) -> void:
	level = int(bar.get("level", 0))
	share = clampf(xp_share, 0.0, 1.0)
	title = str(bar.get("title", ""))
	renown = renown_text
	accessibility_name = str(bar.get("spoken", title))
	tap.accessibility_name = accessibility_name
	if _row != null:
		_row.queue_free()
	_row = KitHud.keeper(_face, title, level, share, renown)
	var ring := _row.find_child("Portrait", true, false) as KitRing
	# The emblem stands in the ring on the card's violet, as the design's
	# portrait does, not cut to its edge.
	ring.ground = Tokens.color("card_top")
	ring.zoom = 0.78
	# Before the league answers there is no Renown to show, not an empty pill.
	var pill := _row.find_child("Pill", true, false) as Control
	if pill != null:
		pill.visible = renown != ""
	for c: Node in _row.find_children("*", "Control", true, false):
		(c as Control).mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_row)
	move_child(_row, 0)
	# The level's plate hangs below the ring's foot; the badge keeps room for
	# it beneath, so the row under the badge never covers the level.
	var plate := ring.get_child(0) as Control
	plate.item_rect_changed.connect(_clear_plate.bind(plate), CONNECT_DEFERRED)
	_row.item_rect_changed.connect(_clear_plate.bind(plate), CONNECT_DEFERRED)


func _clear_plate(plate: Control) -> void:
	if not is_instance_valid(plate) or not is_instance_valid(_row) or not plate.is_inside_tree():
		return
	var below := maxf(0.0, ceilf(plate.get_global_rect().end.y - _row.get_global_rect().end.y))
	if not is_equal_approx(_box.content_margin_bottom, below):
		_box.content_margin_bottom = below
		update_minimum_size()
