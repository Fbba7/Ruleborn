class_name KitSkin
extends RefCounted
## The kit's materials put on controls other tracks' skins built (the heist's
## `FxSkin`, the realm's `OverlaySheet`, the hero stage's `StageHeroSkin`):
## each skin keeps its own API and padding, and its surfaces are drawn by the
## kit's one box (`RbBox`), so every screen shares one look. A skin calls
## these instead of filling a StyleBoxFlat of its own.

## A skin's surface names, as the kit's materials.
const SURFACES := {
	"glass": "glass",
	"card": "card",
	"parchment": "parchment",
	"leather": "leather",
	"gold": "gold",
	"alarm": "red",
	"red": "red",
	"night": "card",
	"ability": "ability",
	"hero": "card_gold",
}


## The material for a skin's surface `kind` (the kit's card for an unknown).
static func material(kind: String) -> String:
	return str(SURFACES.get(kind, kind if Tokens.materials().has(kind) else "card"))


## `box`'s content margins on a box that draws nothing, so the kit's box
## behind the control shows and the control keeps its padding.
static func clear(box: StyleBox) -> StyleBoxFlat:
	var out := UI.clear_box(0, 0)
	if box != null:
		for side: int in [SIDE_LEFT, SIDE_TOP, SIDE_RIGHT, SIDE_BOTTOM]:
			out.set_content_margin(side, box.get_content_margin(side))
	return out


## Panel `p` drawn in the kit's material for `kind`, with `radius_points`
## corners (the material's own when negative); its padding kept.
static func panel(p: PanelContainer, kind: String, radius_points := -1.0) -> RbBox:
	p.add_theme_stylebox_override("panel", clear(p.get_theme_stylebox("panel")))
	var box := RbBox.dress(p, material(kind), radius_points)
	p.set_meta("surface", kind)
	return box


## Button `b` drawn in the kit's material for `kind`, its words in the
## material's ink and §21.8's press; its padding kept.
static func button(b: Button, kind: String, radius_points := -1.0) -> RbBox:
	for state: String in ["normal", "hover", "pressed", "focus", "disabled"]:
		b.add_theme_stylebox_override(state, clear(b.get_theme_stylebox(state)))
	UI.set_look(b, material(kind))
	var box := RbBox.of(b)
	box.radius_points = radius_points
	box.set_look(box.look)
	if not b.has_meta("kit_press"):
		b.set_meta("kit_press", true)
		b.button_down.connect(Motion.press.bind(b, true))
		b.button_up.connect(Motion.press.bind(b, false))
	b.set_meta("surface", kind)
	return box
