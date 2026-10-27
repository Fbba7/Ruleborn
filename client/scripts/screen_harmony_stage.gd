class_name ScreenHarmonyStage
extends LawFxPreview
## Harmony's preview, lighter than the law card's (§21.3: fewer than 150
## draw calls on the screen): the realm's pylons and the threads, clashes
## and chords between them as LawFxPreview draws them, without the sun's
## shadow pass or the figure walking its loop, which say nothing about how
## laws combine. Weaving keeps the figure (`walking`), whose gait shows the
## law about to be woven, and drops only the shadow pass.

var walking := false


func show_laws(which: Array, type := "heart") -> void:
	var fresh := view == null or which != laws or type != realm_type
	super(which, type)
	if not fresh or view == null:
		return
	view.sun.shadow_enabled = false
	if walker != null:
		walker.visible = walking
