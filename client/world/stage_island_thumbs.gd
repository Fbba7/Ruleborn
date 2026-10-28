class_name StageIslandThumbs
extends StageThumbs
## Each landing card's island as a picture (the design's landing deck: every
## outer realm on its card, seen from above), from the one shared offscreen
## view `StageThumbs` keeps, so a deck of six cards costs one 3D viewport.
## A card is `{"bundle": a key, "island": the realm's island bytes}`; what is
## drawn is that island as the lease gave it, its Vault hidden as a scout's
## (§12.4).


func stage(card: Dictionary) -> void:
	var replay := StageRealm.replay_of(card.get("island", PackedByteArray()))
	if replay == null:
		return
	view.realm_type = StageRealm.realm_type(str(card.get("type", "Heart")))
	view.show_replay(replay)
	view.show_vault(false)
	for c: Node in view.layers.get_children():
		c.queue_free()
	view.fill = 0.9
	view.look_up = 0.0
