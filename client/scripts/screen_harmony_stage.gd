class_name ScreenHarmonyStage
extends LawFxPreview
## Harmony's preview, lighter than the law card's (§21.3: fewer than 150
## draw calls on the screen): the realm's pylons and the threads, clashes
## and chords between them as LawFxPreview draws them, without the props a
## signature dresses, the sun's shadow pass or the figure walking its loop,
## which say nothing about how laws combine.


func show_laws(which: Array, type := "heart") -> void:
	var fresh := view == null or which != laws or type != realm_type
	super(which, type)
	if not fresh or view == null:
		return
	view.sun.shadow_enabled = false
	if walker != null:
		walker.visible = false


## The realm bare but for the laws woven on it: Harmony shows how laws
## combine, not what each dresses, so the props the law card's preview
## sets out for its signatures stay away (and their draw calls with them).
static func island(which: Array) -> PackedByteArray:
	var i := RulebornIsland.new()
	i.reset(1)
	for k in mini(which.size(), SPOTS.size()):
		i.weave(str(which[k]), SPOTS[k].x, SPOTS[k].y)
	return i.bytes()
