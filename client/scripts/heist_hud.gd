class_name HeistHud
extends HFlowContainer
## §21.8's heist layout, top row: "Clock and alarm meter at the top centre;
## loot at the top right as two numbers, what the bags can still take and what
## is left to load (12.19), beside the Vault's progress". With §20.8's large
## text the two panels stack rather than outgrow the phone.

var clock_label: Label
var alarm_label: Label
var loot_label: Label


func _init() -> void:
	alignment = FlowContainer.ALIGNMENT_END
	var gap := UI.px(Tokens.number("size", "gap_points"))
	add_theme_constant_override("h_separation", gap)
	add_theme_constant_override("v_separation", gap)
	var centre := UI.panel()
	var centre_box := VBoxContainer.new()
	centre.add_child(centre_box)
	clock_label = UI.label()
	alarm_label = UI.label()
	centre_box.add_child(clock_label)
	centre_box.add_child(alarm_label)
	add_child(centre)
	var right := UI.panel()
	loot_label = UI.label()
	loot_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	right.add_child(loot_label)
	add_child(right)


func show_state(r: RulebornReplay) -> void:
	var tps := RulebornReplay.ticks_per_second()
	var now := r.tick() / tps
	var total := r.ticks() / tps
	clock_label.text = "%d:%02d / %d:%02d" % [now / 60, now % 60, total / 60, total % 60]
	var alarm := r.alarm()
	var meter := Strings.t("HUD_ALARM", "●".repeat(alarm) + "○".repeat(6 - alarm))
	# The meter's filled pips say how loud it is; the colour only repeats it.
	if alarm > 0:
		UI.set_status(alarm_label, "alarm", meter)
	else:
		alarm_label.text = meter
		alarm_label.add_theme_color_override("font_color", Palette.INK)
	var carried := 0
	var carry := 0
	for m in r.crew():
		carried += int(m["carried"])
		carry += int(m["carry"])
	loot_label.text = Strings.t("HUD_LOOT", [carry - carried, int(r.vault().get("exposed", 0))])
