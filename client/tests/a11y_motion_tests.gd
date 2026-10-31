class_name A11yMotionTests
extends RefCounted
## Reduced motion never flashes the screen edge (§20.8): the heist's alarm
## edge keeps its steady tint but not its flash, and Harmony's flicker and
## unmaking previews draw no strobe or edge flicker.

var check: Callable


func _init(c: Callable) -> void:
	check = c


func run() -> void:
	_alarm_edge()


func _alarm_edge() -> void:
	var was := Settings.reduced_motion
	var anchors := FxAnchors.new()
	anchors.alarm_share = 0.5
	anchors.flash = 1.0
	var steady := 0.5 * 0.32
	Settings.reduced_motion = true
	var calm := anchors.edge_alpha(true)
	anchors.flash = 0.0
	var calm_after := anchors.edge_alpha(true)
	anchors.flash = 1.0
	var lively := anchors.edge_alpha(false)
	Settings.reduced_motion = was
	anchors.free()
	check.call("with reduced motion the alarm's screen edge keeps its steady tint and never flashes; without it "
			+ "a fresh alert flashes the edge (20.8)",
		is_equal_approx(calm, steady) and is_equal_approx(calm, calm_after) and lively > steady,
		"%s %s %s" % [calm, calm_after, lively])
