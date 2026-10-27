class_name ScreenAccount
extends RefCounted
## Settings' Account tab, the design's fourth: T11's AuthPanel, its words,
## actions and confirm untouched, dressed in these screens' look each time
## it builds (AuthPanel.built). The account's mark and heading head a lit
## card, the status sits on parchment as every screen's status does, signing
## in is the gold action and either sign-out leather (its confirm says what it
## costs).


## The panel on its card, dressed after each build.
static func card(panel: AuthPanel) -> PanelContainer:
	panel.built.connect(dress.bind(panel))
	return ScreenKit.panel("card_lit", panel, 20.0, 14.0)


static func dress(panel: AuthPanel) -> void:
	panel.add_theme_constant_override("separation", UI.px(10))
	for c: Node in panel.get_children():
		if c is Label and c != panel.detail_label:
			_heading(panel, c as Label)
		elif c is PanelContainer and c.is_ancestor_of(panel.status_label):
			ScreenKit.restyle(c as Control, "parchment", 14.0)
			c.set_meta("material", "parchment")
			ScreenParts.show_status(panel.status_label)
			panel.status_label.add_theme_font_override("font", ScreenKit.font("words"))
			panel.status_label.set_meta("bold", true)
		elif c is Container and not (c is PanelContainer):
			_actions(c as Container)
		elif not (c is Label):
			(c as CanvasItem).visible = false
	var d := panel.detail_label
	d.add_theme_font_override("font", ScreenKit.font("body"))
	d.add_theme_color_override("font_color", ScreenKit.ink("card_lit"))
	d.set_meta("own_ink", true)
	d.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	panel.status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT


## The heading beside the account's mark, in the names' face.
static func _heading(panel: AuthPanel, heading: Label) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", UI.px(12))
	var mark := ScreenKit.panel("well", ScreenKit.icon("settingsandwellbeing", "account", 34.0), -1.0, 6.0)
	mark.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(mark)
	var at := heading.get_index()
	panel.remove_child(heading)
	heading.add_theme_font_override("font", ScreenKit.font("name"))
	heading.add_theme_font_size_override("font_size", UI.text_px(22))
	heading.set_meta("points", 22.0)
	heading.add_theme_color_override("font_color", ScreenKit.ink("card_lit"))
	heading.set_meta("own_ink", true)
	heading.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	heading.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	row.add_child(heading)
	panel.add_child(row)
	panel.move_child(row, at)


## Sign in or try again in gold, the sign-outs in leather, each taking its
## share of the width.
static func _actions(row: Container) -> void:
	for b: Button in row.find_children("*", "Button", false, false):
		var what := str(b.get_meta("auth", ""))
		ScreenKit.dress(b, "gold" if what in ["sign_in", "retry"] else "leather")
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL


## The design's "Profile and stats" row under the account: the whole row
## the one control.
static func profile_row() -> PanelContainer:
	var go := ScreenKit.text("›", 22.0, "words", "card", true)
	var row := ScreenParts.item("screens", "character", Strings.t("PROFILE_TITLE"), "", go)
	ScreenParts.tap(row, func() -> void: App.services.router.go(&"profile"), Strings.t("PROFILE_TITLE"))
	return row


## The design's note in green words: no ads and no tracking (§20.5).
static func privacy_note() -> PanelContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", UI.px(10))
	var mark := ScreenKit.icon("settingsandwellbeing", "privacy", 24.0)
	mark.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(mark)
	var words := ScreenKit.text(Strings.t("FIRST_NO_ADS"), 14.0, "words", "well", false, true)
	words.add_theme_color_override("font_color", Tokens.color("success_text_on_night"))
	words.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(words)
	return ScreenKit.panel("well", row, 14.0, 10.0)
