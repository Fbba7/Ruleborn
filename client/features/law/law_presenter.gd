class_name LawPresenter
extends RefCounted
## The law card in words (§21.7: "the school shape and colour at the top, the
## law's name, a looping four-second preview of its movement signature, a
## one-line rule, notes as symbols, rank and tier pips"; §23.2: "Icon with
## school shape, one-line rule, looping preview, rank, pages"; §23.5: §7.7's
## one weakness, notes as symbols, rank and tier pips, pages). The rule and
## the weakness are the law's own content; the tier and pages are the
## Codex's, from the server.

const PIP_ON := "●"
const PIP_OFF := "○"


## The card for a law the Codex holds, `l` as GET /v1/codex sends it.
static func card(l: Dictionary) -> Dictionary:
	var law := str(l.get("law", ""))
	var key := law.to_upper()
	var name := Strings.term("LAW", law)
	var tier := int(l.get("tier", 0))
	var next: Variant = l.get("next")
	var pages := int(l.get("pages", 0))
	var notes: Array = l.get("notes", [])
	var symbols := ", ".join(notes.map(func(n: String) -> String:
		return Strings.t("LAW_CARD_NOTE", [Strings.t("NOTE_SYMBOL_" + n.to_upper()), Strings.term("NOTE", n)])))
	var pips := ""
	for i in 3:
		pips += PIP_ON if i < tier else PIP_OFF
	var page_line := Strings.t("LAW_CARD_PAGES_TO", [pages, int((next as Dictionary)["pages"])]) \
		if next is Dictionary else Strings.t("LAW_CARD_PAGES", pages)
	return {
		"law": law, "school": str(l.get("school", "")).to_lower(),
		"mark": UI.school_mark(str(l.get("school", "")).to_lower()),
		"name": name,
		"rule": Strings.t("LAW_RULE_" + key),
		"notes": Strings.t("LAW_CARD_NOTES", symbols),
		"rank": Strings.t("LAW_CARD_RANK", Strings.t("LAW_RANK_" + str(l.get("rank", "common")).to_upper())),
		"tier": Strings.t("LAW_CARD_TIER", [pips, CodexPresenter.ROMAN[tier]]) if tier > 0
			else Strings.t("LAW_CARD_UNRESTORED", pips),
		"tier_spoken": Strings.t("LAW_CARD_TIER_SPOKEN", tier),
		"pages": page_line,
		"weakness": Strings.t("LAW_CARD_WEAKNESS", Strings.t("LAW_WEAKNESS_" + key)),
	}


## The card for `law` from the Codex the store holds — its laws, or a met law
## of an album — or {} if it is not met.
static func from_codex(codex: Dictionary, law: String) -> Dictionary:
	var v: Dictionary = codex.get("view", {})
	var met: Array = (v.get("laws", []) as Array).duplicate()
	for a: Dictionary in v.get("albums", []):
		met.append_array((a.get("laws", []) as Array).filter(func(l: Dictionary) -> bool: return l.get("known", false)))
	for l: Dictionary in met:
		if str(l.get("law", "")) == law:
			return card(l)
	return {}
