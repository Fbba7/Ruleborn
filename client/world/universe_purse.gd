class_name UniversePurse
extends HBoxContainer
## Home's full-width row of resources (§21.8's home layout): Starlight, Aether
## and Essence, each the UI kit's resource pill (`KitStatus.resource`) with its
## icon, the amount held, and a line along its foot that fills as that
## resource's producers fill (§9.3's twelve hours), marked Full in words once
## they are nearly full, so a player sees what is waiting to be collected. An
## amount the server has not given is a dash, never a guess.

const ORDER := ["starlight", "aether", "essence"]
## The share at which producers are said to be full.
const FULL := 0.9

## Per resource: {"amount": int or -1, "ready": int, "holds": int}.
var rows := {}
var pills := {}


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_theme_constant_override("separation", UI.px(6))
	for k: String in ORDER:
		var p := KitStatus.resource("resources/" + k, "–", 0.0, UniverseHud.RESOURCES[k])
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
		KitStatus.set_resource(pills[k], UniverseHud.grouped(amount) if amount >= 0 else "–", share)
		said.append(Strings.t("HOME_PURSE_SPOKEN", [Strings.t("HOME_RES_" + k.to_upper()),
			UniverseHud.grouped(amount) if amount >= 0 else Strings.t("HOME_UNKNOWN"),
			UniverseHud.grouped(int(r.get("ready", 0)))]))
	accessibility_name = Strings.t("HOME_PURSE")
	accessibility_description = "\n".join(said)
