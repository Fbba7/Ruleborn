class_name FixTests
extends RefCounted
## The November bug report's client fixes (docs/security/bug-report-2026-11.md),
## each group in its own file: one line in run.gd, which is at gdlint's
## length limit.

var tree: SceneTree
var check: Callable


func _init(t: SceneTree, c: Callable) -> void:
	tree = t
	check = c


func run() -> void:
	await FixTransportTests.new(tree, check).run()
	await FixTraceEventsTests.new(tree, check).run()
