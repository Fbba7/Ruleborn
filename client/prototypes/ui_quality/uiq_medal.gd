class_name UiqMedal
extends Control
## T14's proof: one crew member's portrait in UiqHud, on authored art. The
## character's rendered bust on a lit disc of its school's colour, under a
## baked gold ring (brighter and glowing when chosen); its ability's pips as
## two gems on an ink tag; its health as a glossy bar in a sunk track; its
## name in the HUD's outlined type. A prototype: no screen of the game uses it.

const SIDE := 168.0

var _picture: Texture2D
var _kind := ""
var _role := ""


## `bare`: the ring and portrait alone (the Sage's disc).
func _init(member: FxPortrait, m: Dictionary, bare := false) -> void:
	_picture = member.picture
	_kind = member.kind
	_role = member.role
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	size = Vector2(SIDE, SIDE + 92.0)
	# The ground, the portrait and the ring each a child of their own (in one
	# canvas item a texture rect and the portrait's textured polygon drew
	# wrongly here). The disc and portrait (a texture each) stay at the
	# world's level; the ring and the rest go up with the HUD's other art,
	# so that still batches. Not below 0: the 3D world is drawn there.
	var c := Vector2(SIDE, SIDE) / 2.0
	var r := SIDE / 2.0 - 26.0
	var ground: Color = Palette.SCHOOL.get(StageHeroFigure.school(_kind), Palette.ROLE.get(_role, Palette.STONE))
	var disc := UiqArt.sprite("disc", c, Vector2(r, r) * 2.1)
	disc.self_modulate = ground
	add_child(disc)
	var face := Control.new()
	face.mouse_filter = Control.MOUSE_FILTER_IGNORE
	face.size = Vector2(SIDE, SIDE)
	face.draw.connect(func() -> void:
		if _picture != null:
			Portrait.draw_disc(face, _picture, c, r + 2.0))
	add_child(face)
	var ring := UiqArt.sprite("ring_chosen" if member.chosen else "ring", Vector2(SIDE, SIDE) / 2.0, Vector2(SIDE, SIDE))
	ring.z_index = 1
	add_child(ring)
	if member.uses >= 0:
		var tag := UiqArt.nine("frame_chip")
		tag.position = Vector2(SIDE - 96.0, -14.0)
		tag.size = Vector2(104, 60)
		tag.patch_margin_left = 22
		tag.patch_margin_right = 22
		tag.patch_margin_top = 20
		tag.patch_margin_bottom = 26
		add_child(tag)
		for k in 2:
			tag.add_child(UiqArt.sprite("pip" if k < member.uses else "pip_spent", Vector2(34.0 + 34.0 * k, 25.0),
				Vector2(38, 38)))
	if bare:
		return
	var track := UiqArt.nine("bar_track")
	track.position = Vector2(16, SIDE + 2.0)
	track.size = Vector2(SIDE - 32.0, 30)
	add_child(track)
	var health := clampf(member.health, 0.0, 1.0)
	if health > 0.0:
		var fill := UiqArt.nine("bar_green" if health > 0.35 else "bar_red")
		fill.patch_margin_left = 14
		fill.patch_margin_right = 14
		fill.position = Vector2(19, SIDE + 5.0)
		fill.size = Vector2(maxf(28.0, (SIDE - 38.0) * health), 24)
		add_child(fill)
	for k in get_children():
		if k != disc and k != face:
			(k as CanvasItem).z_index = 1
	var name := UiqArt.words(member.letters, 40.0, Color("#FFE3A0") if member.chosen else Color.WHITE)
	name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name.position = Vector2(-20, SIDE + 26.0)
	name.size = Vector2(SIDE + 40.0, 56)
	add_child(name)
	accessibility_name = "%s %s" % [member.letters, str(m.get("standing", ""))]
