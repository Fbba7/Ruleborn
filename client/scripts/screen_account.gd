class_name ScreenAccount
extends RefCounted
## Settings' Account tab, the design's fourth, under T11's AuthPanel (which
## builds itself from ScreenParts): the Profile and stats row and the
## no-tracking note.


## The design's "Profile and stats" row under the account: the whole row
## the one control, on the parchment the Access tab's switch rows stand on,
## so it sits value steps off the night as they do (board 5b's objection L).
## The tap target covers the whole plate, edge to edge, as a switch row's
## button does: a target inside the plate's margins would leave its edge a
## dead ring, and a reader would see a plate whose rim does nothing.
static func profile_row() -> PanelContainer:
	var go := ScreenKit.text("›", 22.0, "words", "parchment", true)
	var plate := ScreenParts.item("screens", "character", Strings.t("PROFILE_TITLE"), "", go, "parchment")
	var row := PanelContainer.new()
	row.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	row.add_child(plate)
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
