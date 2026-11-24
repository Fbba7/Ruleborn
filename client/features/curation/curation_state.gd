class_name CurationState
extends RefCounted
## Curation as the store holds it (§13.3, §23.2): which realm and page, the
## server's curation view, the published island's bytes and the draft that
## curation's verbs change, the post picked, the swap previewed, the name
## being picked, the slots still weaving a swap with when each is ready,
## what is on its way, what was said and the last failure.

const CURATION := &"curation"
const NO_POST := Vector2i(-1, -1)


static func register(store: Store) -> void:
	store.register(CURATION, fresh("heart"), {
		&"curation_opened": opened,
		&"curation_asked": asked,
		&"curation_loaded": loaded,
		&"curation_island": island,
		&"curation_drafted": drafted,
		&"curation_picked": picked,
		&"curation_words": words,
		&"curation_naming": naming,
		&"curation_failed": failed,
		&"curation_weaving": weaving,
	})


static func fresh(realm: String) -> Dictionary:
	return {"realm": realm, "page": 0, "view": {}, "base": PackedByteArray(), "draft": PackedByteArray(),
		"post": NO_POST, "swap": {}, "words": {}, "pick": {"adjective": 0, "noun": 0}, "busy": "", "said": "",
		"error": "", "weaving": {}}


static func opened(_s: Dictionary, p: Dictionary) -> Dictionary:
	return fresh(str(p["realm"]))


static func asked(s: Dictionary, p: Dictionary) -> Dictionary:
	var next := s.duplicate()
	next["busy"] = str(p["what"])
	next["said"] = ""
	next["error"] = ""
	return next


static func loaded(s: Dictionary, p: Dictionary) -> Dictionary:
	var next := s.duplicate()
	next["view"] = p["view"]
	next["page"] = int((p["view"] as Dictionary).get("page", s["page"]))
	# The island the view names is fetched next, unless it is the one held.
	next["busy"] = "island" if p.get("fetch", true) else ""
	next["said"] = str(p.get("said", ""))
	next["swap"] = {}
	return next


## The published island, which the draft starts from.
static func island(s: Dictionary, p: Dictionary) -> Dictionary:
	var next := s.duplicate()
	next["base"] = p["island"]
	next["draft"] = p["island"]
	next["post"] = NO_POST
	next["busy"] = ""
	return next


## The draft after a verb: a post moved or turned, a swap previewed or
## taken back.
static func drafted(s: Dictionary, p: Dictionary) -> Dictionary:
	var next := s.duplicate()
	next["draft"] = p["draft"]
	next["post"] = p.get("post", s["post"])
	next["swap"] = p.get("swap", s["swap"])
	next["said"] = ""
	next["error"] = ""
	return next


static func picked(s: Dictionary, p: Dictionary) -> Dictionary:
	var next := s.duplicate()
	next["post"] = p["post"]
	next["error"] = ""
	return next


static func words(s: Dictionary, p: Dictionary) -> Dictionary:
	var next := s.duplicate()
	next["words"] = p["words"]
	return next


static func naming(s: Dictionary, p: Dictionary) -> Dictionary:
	var next := s.duplicate()
	next["pick"] = p["pick"]
	return next


static func failed(s: Dictionary, p: Dictionary) -> Dictionary:
	var next := s.duplicate()
	next["busy"] = ""
	next["said"] = ""
	next["error"] = str(p["code"])
	return next


## The slots weaving a swap, by slot, with when each is ready (CLI-1).
static func weaving(s: Dictionary, p: Dictionary) -> Dictionary:
	var next := s.duplicate()
	next["weaving"] = p["weaving"]
	return next
