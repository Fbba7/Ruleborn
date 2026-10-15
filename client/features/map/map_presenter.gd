class_name MapPresenter
extends RefCounted
## The Universe map in words (§23.2: "Home. See every realm and link at once.
## Realms with their laws, links, strain band, faults, alerts, resources,
## heist button"): each realm with the laws woven in it and the crown's, the
## universe's strain and band and its open faults, the resources held and
## what each producer has ready, the alerts the player can act on, and the
## way to a heist. Every number is the server's. The links and the diorama
## are the world's (TD.19).


static func screen(weaving: Dictionary, home: Dictionary, wallet: Dictionary, defences: Dictionary) -> Dictionary:
	var w: Dictionary = weaving.get("view", {})
	var h: Dictionary = home.get("view", {})
	var out := {"ready": not w.is_empty() and not h.is_empty()}
	if not out["ready"]:
		return out
	var st: Dictionary = w.get("stability", {})
	var band := int(st.get("band", 0))
	out["strain"] = Strings.t("MAP_STRAIN", [str(roundi(float(st.get("strain", 0.0)) * 100.0)) + "%",
		WeavingPresenter.band_name(band), int(st.get("faults", 0))])
	var crowned := PackedStringArray()
	var realms: Array[Dictionary] = []
	for r: Dictionary in w.get("realms", []):
		var laws := PackedStringArray()
		for s: Dictionary in r.get("slots", []):
			if s.get("law") is String:
				laws.append(Strings.term("LAW", str(s["law"])))
		if str(r["realm"]) == "crown":
			crowned = laws
			continue
		var title := WeavingPresenter.realm_title(r)
		realms.append({"realm": r["realm"], "title": title,
			"laws": Strings.t("MAP_LAWS", ", ".join(laws)) if not laws.is_empty() else Strings.t("MAP_NO_LAWS"),
			"open": {"key": "realm:" + str(r["realm"]), "item": "realm:" + str(r["realm"]),
				"action": Strings.t("MAP_OPEN_REALM"), "spoken": Strings.t("MAP_OPEN_REALM_SPOKEN", title),
				"can": true, "why": ""}})
	out["realms"] = realms
	out["crown"] = Strings.t("MAP_CROWN", ", ".join(crowned)) if not crowned.is_empty() else ""
	var balance: Dictionary = wallet if wallet.get("known", false) else {}
	out["resources"] = Strings.t("MAP_RESOURCES", [ShopPresenter.grouped(int(balance.get("starlight", 0))),
		ShopPresenter.grouped(int(h.get("essence", balance.get("essence", 0)))),
		ShopPresenter.grouped(int(w.get("aether", 0)))])
	var ready: Array[String] = []
	var alerts: Array[String] = []
	var unseen := int(defences.get("unseen", 0))
	if unseen > 0:
		alerts.append(Strings.t("MAP_RAIDS", unseen))
	for p: Dictionary in h.get("producers", []):
		var name := Strings.t("MAP_PRODUCER", [UniversePresenter.building_name(str(p["kind"])),
			RosterPresenter.realm_label(str(p["realm"]), h)])
		ready.append(Strings.t("MAP_READY", [name, ShopPresenter.grouped(int(p.get("stored", 0))),
			ShopPresenter.grouped(int(p.get("holds", 0)))]))
		if int(p.get("stored", 0)) >= int(p.get("holds", 1)):
			alerts.append(Strings.t("MAP_FULL", name))
	out["ready_lines"] = ready
	if alerts.is_empty():
		alerts.append(Strings.t("MAP_NO_ALERTS"))
	out["alerts"] = alerts
	out["heist"] = {"key": "heist", "item": "heist", "action": Strings.t("HOME_OBSERVATORY"),
		"spoken": Strings.t("HOME_OBSERVATORY"), "can": true, "why": ""}
	return out
