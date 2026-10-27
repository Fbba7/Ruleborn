class_name UniversePurse
extends HFlowContainer
## Home's full-width row of resources (§21.8's home layout): Starlight, Aether
## and Essence, each the UI kit's resource pill (`KitStatus.resource`) with its
## icon, the amount held (past 10,000 in thousands, as the designs show it,
## "142.0k"; said in full), and a line along its foot that fills as that
## resource's producers fill (§9.3's twelve hours), marked Full in words once
## they are nearly full, so a player sees what is waiting to be collected. An
## amount the server has not given is a dash, never a guess. Where the three
## will not sit on one line with Full in words (a long amount, large text), the
## word gives way first (the line still shows full, and it is still said);
## past that the row wraps rather than run off the screen.

const ORDER := ["starlight", "aether", "essence"]
## The share at which producers are said to be full.
const FULL := 0.9

## Per resource: {"amount": int or -1, "ready": int, "holds": int}.
var rows := {}
var pills := {}
## The resources whose producers are full, which say so in words when there is
## room.
var _full := {}


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_theme_constant_override("h_separation", UI.px(4))
	add_theme_constant_override("v_separation", UI.px(6))
	for k: String in ORDER:
		var p := KitStatus.resource("resources/" + k, "–", 0.0, UniverseHud.RESOURCES[k])
		# Tighter at the right than the kit's pill, so "FULL 61.0k" sits in a
		# third of the phone as the designs' row has it.
		var pad := p.get_theme_stylebox("panel").duplicate() as StyleBox
		pad.content_margin_right = UI.px(6)
		p.add_theme_stylebox_override("panel", pad)
		p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		p.mouse_filter = Control.MOUSE_FILTER_IGNORE
		pills[k] = p
		add_child(p)


## What the store holds (UniverseStore.purse).
func show_purse(purse: Dictionary) -> void:
	rows = purse
	var said := PackedStringArray()
	for k: String in ORDER:
		var r: Dictionary = rows.get(k, {})
		var amount := int(r.get("amount", -1))
		var holds := int(r.get("holds", 0))
		var share := clampf(float(r.get("ready", 0)) / holds, 0.0, 1.0) if holds > 0 else 0.0
		KitStatus.set_resource(pills[k], UniverseHud.compact(amount) if amount >= 0 else "–", share)
		_full[k] = share >= FULL
		said.append(Strings.t("HOME_PURSE_SPOKEN", [Strings.t("HOME_RES_" + k.to_upper()),
			UniverseHud.grouped(amount) if amount >= 0 else Strings.t("HOME_UNKNOWN"),
			UniverseHud.grouped(int(r.get("ready", 0)))]))
	accessibility_name = Strings.t("HOME_PURSE")
	accessibility_description = "\n".join(said)


func _notification(what: int) -> void:
	if what == NOTIFICATION_PRE_SORT_CHILDREN:
		_fit()


## Full in words only while all three pills still sit on one line with it.
func _fit() -> void:
	var need := float(get_theme_constant("h_separation")) * (ORDER.size() - 1)
	var words := 0.0
	for k: String in ORDER:
		var p: Control = pills[k]
		var full: Control = p.find_child("Full", true, false)
		var shown := full.visible
		full.visible = false
		need += p.get_combined_minimum_size().x
		full.visible = shown
		if _full.get(k, false):
			words += full.get_combined_minimum_size().x + UI.px(4)
	var room := need + words <= size.x
	for k: String in ORDER:
		var full: Control = (pills[k] as Control).find_child("Full", true, false)
		var want: bool = room and _full.get(k, false)
		if full.visible != want:
			full.visible = want
