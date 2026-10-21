class_name LookBackdrop
extends ColorRect
## The backdrop a menu stands on (§21.2: "Menus stand on a night backdrop
## (#171046 to #2C3AA8)"), painted as the realms' own sky so the world and
## the interface read as one picture: the gradient, a glow, stars, far
## islets, a cloud sea at the foot and the vignette as a tint
## (look_backdrop.gdshader, one quad). `for_world` gives a screen standing
## over a realm the same sky as that realm at the player's hour.
##
## Use it in place of a plain gradient behind a screen's controls:
##
##     screen.add_child(LookBackdrop.new())     # first child, under the rest
##
## or `LookBackdrop.dress(screen)` to swap the "Sky" UI.frame adds.

static var _shader: Shader = load("res://world/look_backdrop.gdshader")


func _init() -> void:
	name = "Sky"
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var m := ShaderMaterial.new()
	m.shader = _shader
	material = m
	resized.connect(_on_resized)
	# Reduced motion holds the clouds, islets and stars still (§21.8).
	m.set_shader_parameter("motion", 0.0 if Settings.reduced_motion else 1.0)
	night()


## The night backdrop of §21.2, unchanged: its two colours from the palette.
func night() -> void:
	set_colours(Color("#171046"), Color("#2C3AA8"))


## The sky of `realm` at `hour` (RealmPalette.realm_sky_at), for a sheet or
## hub drawn over that realm, so its edges meet the world's sky.
func for_world(hour: int, realm: String) -> void:
	var sky := RealmPalette.realm_sky_at(hour, realm)
	set_colours(sky[0], sky[2].lerp(sky[1], 0.5))
	var m := material as ShaderMaterial
	m.set_shader_parameter("stars", 1.0 if sky[0].get_luminance() < 0.2 else 0.0)


## The gradient from `upper` to `lower`; the glow, the clouds, the islets
## and the vignette are drawn from them.
func set_colours(upper: Color, lower: Color) -> void:
	var m := material as ShaderMaterial
	m.set_shader_parameter("top", upper)
	m.set_shader_parameter("bottom", lower)
	m.set_shader_parameter("glow", lower.lerp(Color("#C8A0FF"), 0.5))
	m.set_shader_parameter("cloud_body", lower.lerp(upper, 0.15).lerp(Color("#8C6CF0"), 0.2))
	m.set_shader_parameter("cloud_top", lower.lerp(Color("#F3EEFF"), 0.45))
	m.set_shader_parameter("islet", upper.lerp(lower, 0.55).darkened(0.18))
	m.set_shader_parameter("islet_lit", lower.lerp(Color("#9C8CE8"), 0.5))
	m.set_shader_parameter("edge", upper.darkened(0.6))
	m.set_shader_parameter("nebula", lower.lerp(Color("#C050B0"), 0.55))


## Swap the plain gradient UI.frame puts behind `screen` (its "Sky") for
## the backdrop, or put the backdrop under everything if it has none.
static func dress(screen: Control) -> LookBackdrop:
	var b := LookBackdrop.new()
	var old := screen.get_node_or_null("Sky")
	var at := 0
	if old != null:
		at = old.get_index()
		old.queue_free()
		screen.remove_child(old)
	screen.add_child(b)
	screen.move_child(b, at)
	return b


func _on_resized() -> void:
	(material as ShaderMaterial).set_shader_parameter("aspect", size.x / maxf(1.0, size.y))
