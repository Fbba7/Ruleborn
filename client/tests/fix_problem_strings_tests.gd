class_name FixProblemStringsTests
extends RefCounted
## The two publish problems FX3-2-island added to island::Problem (FX4-5,
## FX3-R1): EntranceBlocked (RB-40) and DuplicateLaw (the report's candidate
## 7). The builder and curation show a problem as Strings.t("PROBLEM_" + its
## name in capitals), so each needs its row, or the screen shows the raw key.

var tree: SceneTree
var check: Callable


func _init(t: SceneTree, c: Callable) -> void:
	tree = t
	check = c


func run() -> void:
	_new_problems_have_words()
	_blocked_entrance_is_named()


## Both new problems, by the key the builder and curation build from the
## name RulebornIsland.problems() gives.
func _new_problems_have_words() -> void:
	for p: String in ["EntranceBlocked", "DuplicateLaw"]:
		var key := "PROBLEM_" + p.to_upper()
		var text := Strings.t(key)
		check.call("FX4-5: the publish problem %s is shown in words, not as its key" % p,
			text != key and not text.is_empty(), "Strings.t(\"%s\") gave \"%s\"" % [key, text])


## A real island whose entrance (the south-east corner of a blank realm) is
## under a rock pillar: every problem it names has its words.
func _blocked_entrance_is_named() -> void:
	var island := RulebornIsland.new()
	island.reset(1)
	var corner := island.side() - 1
	island.set_ground(corner, corner, "rock_pillar")
	var problems := island.problems()
	var raw := Array(problems).filter(func(p: Variant) -> bool:
		var key := "PROBLEM_" + str(p).to_upper()
		return Strings.t(key) == key)
	check.call("FX4-5: an island with its entrance under a pillar names EntranceBlocked, in words",
		problems.has("EntranceBlocked") and raw.is_empty(),
		"problems %s, shown as their key %s" % [problems, raw])
