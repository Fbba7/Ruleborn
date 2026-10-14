class_name CodexRepository
extends RefCounted
## The Codex (§7.6, §18.5; server/src/codex.mjs): the laws met, their pages
## and tiers, each school's album and mastery track, and the steps that
## restore a law, raise its tier, or mark it as the one worked on.

var api: Api


func _init(a: Api) -> void:
	api = a


func view() -> Result:
	return await api.get_json("/v1/codex")


## §7.6: `law` restored at tier I for its rank's pages. Answers {codex, keeper}.
func restore(law: String) -> Result:
	return await api.post_json("/v1/codex/restore", {"law": law})


## §7.6: `law` raised to tier `to`, II or III. Answers {codex}.
func tier(law: String, to: int) -> Result:
	return await api.post_json("/v1/codex/tier", {"law": law, "to": to})


## §7.6: the law the eighth heist's page and the Lab's go to, or none.
## Answers the Codex itself.
func work_on(law: Variant) -> Result:
	return await api.post_json("/v1/codex/working", {"law": law})
