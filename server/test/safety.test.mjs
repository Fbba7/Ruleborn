// What the stores require of player-made content (§20.11): blocking as §17.8
// says it works, a terms-of-use gate before the Workshop, and the pages the
// stores link to.

import assert from "node:assert/strict";
import { test } from "node:test";

import { privacyPage, supportPage, termsPage } from "../src/pages.mjs";
import { TERMS_VERSION } from "../src/safety.mjs";
import { Refused, clockTicks } from "../src/service.mjs";
import { Social } from "../src/social.mjs";
import { Workshop } from "../src/workshop.mjs";
import { established, openPlan, play, server } from "./setup.mjs";

const refusal = (fn, reason) => assert.throws(fn, (e) => e instanceof Refused && e.reason === reason);

/** A creator with an island in the Workshop, and two other players. */
function three(options = {}) {
  const t = server(options);
  const w = new Workshop(t.service);
  const [creator, viewer, other] = ["gc:creator", "gc:viewer", "gc:other"].map((c) => t.service.session(c).account);
  for (const a of [creator, viewer, other]) established(t, a);
  const island = t.build.exampleIsland(true);
  const cleared = t.build.record(island, { seed: 7n, ticks: clockTicks(0), crew: 3, commands: openPlan() });
  return { ...t, w, creator, viewer, other, island, cleared };
}

test("the Workshop asks for the current terms of use before a player publishes, plays, rates or remixes, and never before a report (20.11)", () => {
  const t = three({ strictTerms: true });
  const safety = t.service.safety;
  assert.deepEqual(safety.terms(t.creator), { version: TERMS_VERSION, accepted: false, url: "/terms" });
  assert.throws(() => t.w.publish(t.creator, t.island, t.cleared, { adjective: 1, noun: 1 }),
    (e) => e.reason === "terms_first" && e.status === 403 && e.detail.version === TERMS_VERSION);
  refusal(() => safety.accept(t.creator, "an-older-version"), "not_the_current_terms");
  assert.equal(safety.accept(t.creator, TERMS_VERSION).accepted, true);
  const item = t.w.publish(t.creator, t.island, t.cleared, { adjective: 1, noun: 1 });
  refusal(() => t.w.play(t.viewer, item.id), "terms_first");
  refusal(() => t.w.remix(t.viewer, item.id), "terms_first");
  assert.ok(t.w.report(t.viewer, item.id, "other").report, "a report never waits for the terms");
  safety.accept(t.viewer, TERMS_VERSION);
  assert.ok(t.w.play(t.viewer, item.id).token);
});

test("a block hides each player from the other in the Workshop's lists, and not their islands from raids (17.8)", () => {
  const t = three();
  const item = t.w.publish(t.creator, t.island, t.cleared, { adjective: 2, noun: 3 });
  const listed = (who) => t.w.browse(who, "new").map((i) => i.id);
  assert.deepEqual(listed(t.viewer), [item.id]);
  assert.deepEqual(t.service.safety.block(t.viewer, t.creator), { blocked: t.creator, unfriended: false });
  assert.deepEqual(listed(t.viewer), [], "the blocked creator's islands leave the blocker's lists");
  assert.deepEqual(listed(t.other), [item.id], "and no one else's");
  // The blocker's own island: other bytes, since the creator's are listed (SEC-41).
  const own = Uint8Array.from(t.island);
  own[6] = (own[6] + 1) & 0xff;
  const mine = t.w.publish(t.viewer, own, t.build.record(own, { seed: 7n, ticks: clockTicks(0), crew: 3, commands: openPlan() }),
                           { adjective: 4, noun: 5 });
  assert.ok(!listed(t.creator).includes(mine.id), "and the blocker's leave the blocked player's (you disappear from theirs)");
  // "Their island can still appear as a target, and yours as theirs."
  const { bundle } = t.service.publish(t.creator, t.island);
  assert.ok(t.service.lease(t.viewer, bundle).token, "a blocked player's island is still a target");
  assert.deepEqual(t.service.safety.list(t.viewer).map((b) => b.account), [t.creator]);
  t.service.safety.unblock(t.viewer, t.creator);
  assert.deepEqual(listed(t.viewer).sort(), [item.id, mine.id].sort());
  refusal(() => t.service.safety.unblock(t.viewer, t.creator), "not_blocked");
  refusal(() => t.service.safety.block(t.viewer, t.viewer), "own_account");
  refusal(() => t.service.safety.block(t.viewer, "nobody"), "no_such_account");
});

test("a block ends a friendship, closes invites and challenge links both ways, and hides each from the other's feed (17.8)", () => {
  const t = three();
  const f = t.service.friends;
  f.accept(t.viewer, f.invite(t.creator).invite);
  const { bundle } = t.service.publish(t.creator, t.island);
  const { challenge } = f.challenge(t.creator);
  // A heist between the blocked player and a friend of the blocker's shows in
  // the blocker's feed until the block.
  f.accept(t.other, f.invite(t.viewer).invite);
  const lease = t.service.lease(t.other, bundle);
  assert.equal(t.service.submit(t.other, lease.token, play(t, lease, { plan: openPlan() })).validated, true);
  assert.equal(f.feed(t.viewer).length, 1);
  assert.deepEqual(t.service.safety.block(t.creator, t.viewer), { blocked: t.viewer, unfriended: true });
  assert.equal(f.areFriends(t.viewer, t.creator), false);
  assert.deepEqual(f.feed(t.viewer), [], "the blocked player's heist leaves the blocker's feed, and the other way round");
  refusal(() => f.accept(t.viewer, f.invite(t.creator).invite), "no_such_invite");
  refusal(() => f.accept(t.creator, f.invite(t.viewer).invite), "no_such_invite");
  refusal(() => t.service.challenge(t.viewer, challenge), "no_such_challenge");
  assert.ok(t.service.challenge(t.other, challenge), "the link still opens for anyone else");
});

test("the terms, the privacy policy and the support page are served for the stores to link to (20.10, 20.11)", async () => {
  const t = server();
  const get = async (h, path) => {
    const r = await h(new Request(`https://edge.example${path}`));
    return { status: r.status, type: r.headers.get("content-type"), text: await r.text() };
  };
  const terms = await get(t.handle, "/terms");
  assert.equal(terms.status, 200);
  assert.match(terms.type, /text\/html/);
  assert.ok(terms.text.includes(TERMS_VERSION) && terms.text.includes("aged 13 and over"));
  const privacy = await get(t.handle, "/privacy");
  assert.equal(privacy.status, 200);
  const words = privacy.text.replace(/<style>[^<]*<\/style>/, "").replace(/<[^>]+>/g, " ");
  assert.ok(words.includes("The push token") && words.includes("blocks"), "every data type the server keeps is named");
  assert.equal((words.match(/§|\b[CDFG]\d{2}\b/g) ?? []).length, 0, "and none of the design's references");
  assert.equal((await get(t.handle, "/support")).status, 503, "no contact set, no support page");
  const { handler } = await import("../src/http.mjs");
  const staffed = handler(t.service, { contact: { name: "The Operator", email: "help@example.org" } });
  const support = await get(staffed, "/support");
  assert.equal(support.status, 200);
  assert.ok(support.text.includes("mailto:help@example.org") && support.text.includes("within 24 hours"));
  assert.equal(supportPage(null), null);
  assert.ok(termsPage().startsWith("<!doctype html>") && privacyPage().startsWith("<!doctype html>"));
});

test("terms and blocks over HTTP (20.11)", async () => {
  const t = server({ strictTerms: true });
  const call = async (method, path, token, json) => {
    const r = await t.handle(new Request(`https://edge.example${path}`, {
      method, headers: { authorization: `Bearer ${token}`, ...(json ? { "content-type": "application/json" } : {}) },
      body: json ? JSON.stringify(json) : undefined }));
    return { status: r.status, body: await r.json() };
  };
  const a = t.service.session("gc:a");
  const b = t.service.session("gc:b");
  assert.equal((await call("GET", "/v1/terms", a.token)).body.accepted, false);
  const accepted = await call("PUT", "/v1/terms", a.token, { version: TERMS_VERSION });
  assert.equal(accepted.body.accepted, true);
  assert.equal((await call("PUT", "/v1/terms", a.token, { version: "old" })).status, 409);
  assert.equal((await call("POST", "/v1/blocks", a.token, { account: b.account })).status, 201);
  assert.deepEqual((await call("GET", "/v1/blocks", a.token)).body.map((x) => x.account), [b.account]);
  assert.equal((await call("DELETE", `/v1/blocks/${b.account}`, a.token)).status, 200);
  assert.equal((await call("POST", "/v1/blocks", a.token, { account: 7 })).status, 400);
});

test("a block keeps two players out of each other's crew and constellation, and out of each other's lists of one (17.8)", () => {
  const t = three();
  const social = new Social(t.service);
  t.service.db.prepare("UPDATE accounts SET keeper_level = 6").run();
  const c = social.found(t.creator, { adjective: 1, noun: 2 });
  social.join(t.other, c.id);
  const crew = social.startCrew(t.creator);
  t.service.safety.block(t.creator, t.viewer);
  // Joining where a member is across a block is answered as no such group,
  // so the block is not told.
  refusal(() => social.join(t.viewer, c.id), "no_such_constellation");
  refusal(() => social.joinCrew(t.viewer, crew.invite), "no_such_crew");
  // And asked for by id, the group answers the same, so the two routes
  // cannot be set against each other to tell the block.
  refusal(() => social.constellation(c.id, t.viewer), "no_such_constellation");
  refusal(() => social.crew(crew.id, t.viewer), "no_such_crew");
  // Two who shared a group before the block keep it, and do not see each other.
  t.service.safety.unblock(t.creator, t.viewer);
  social.join(t.viewer, c.id);
  social.joinCrew(t.viewer, crew.invite);
  t.service.safety.block(t.viewer, t.creator);
  const names = (x) => x.members.map((m) => m.account).sort();
  assert.deepEqual(names(social.constellation(c.id, t.viewer)), [t.other, t.viewer].sort());
  assert.deepEqual(names(social.constellation(c.id, t.creator)), [t.creator, t.other].sort());
  assert.equal(social.constellation(c.id).members.length, 3, "and the constellation still counts all three");
  assert.deepEqual(names(social.crew(crew.id, t.creator)), [t.creator]);
  assert.equal(social.crew(crew.id).members.length, 2);
  // Members of it, they still see it, and a founder's appointment answers
  // with the list as the founder sees it.
  assert.equal(social.constellation(c.id, t.viewer).id, c.id);
  assert.deepEqual(names(social.appoint(t.creator, t.other, "elder")), [t.creator, t.other].sort());
});

test("the pages answer HEAD, and are never kept by a cache, so new terms are never shown old (20.11)", async () => {
  const t = server();
  for (const path of ["/terms", "/privacy"]) {
    const head = await t.handle(new Request(`https://edge.example${path}`, { method: "HEAD" }));
    assert.equal(head.status, 200, path);
    assert.equal(await head.text(), "");
    assert.equal(head.headers.get("cache-control"), "no-cache");
  }
  const { handler } = await import("../src/http.mjs");
  const policy = async (h) => (await (await h(new Request("https://edge.example/privacy"))).text());
  assert.ok(!(await policy(t.handle)).includes("/account/delete"), "no web deletion offered where none is served");
  assert.ok((await policy(handler(t.service, { webClientId: "web-client" }))).includes("/account/delete"));
});
