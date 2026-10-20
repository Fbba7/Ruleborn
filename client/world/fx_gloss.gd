class_name FxGloss
extends Control
## The designs' volume on a HUD surface (§21.8: "a three-stop gradient, a
## gloss and a soft drop shadow"): a light band across the top and a shade
## along the bottom, drawn over the fill. It never takes a tap.

var radius := 24.0


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)


func _draw() -> void:
	if Settings.high_contrast:
		return
	var w := size.x
	var h := size.y
	if w < 4.0 or h < 4.0:
		return
	var inset := maxf(3.0, radius * 0.18)
	var r := minf(radius, h * 0.5) - inset
	# The gloss: a soft rounded band over the top 40%.
	var top := Rect2(Vector2(inset * 1.6, inset), Vector2(w - inset * 3.2, h * 0.38))
	var band := StyleBoxFlat.new()
	band.bg_color = Color(1, 1, 1, 0.16)
	band.set_corner_radius_all(int(maxf(2.0, r)))
	band.corner_radius_bottom_left = int(maxf(2.0, r * 0.4))
	band.corner_radius_bottom_right = int(maxf(2.0, r * 0.4))
	draw_style_box(band, top)
	# The shade: the lowest quarter, darker, so the face reads as a dome.
	var low := Rect2(Vector2(inset, h * 0.7), Vector2(w - inset * 2.0, h * 0.3 - inset))
	var shade := StyleBoxFlat.new()
	shade.bg_color = Color(0.1, 0.02, 0.12, 0.14)
	shade.set_corner_radius_all(int(maxf(2.0, r)))
	shade.corner_radius_top_left = 2
	shade.corner_radius_top_right = 2
	draw_style_box(shade, low)
