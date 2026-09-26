// Account and data deletion (§20.5, §20.11), against the real simulation
// build.

import assert from "node:assert/strict";
import { test } from "node:test";

import { deleteAccount } from "../src/accounts.mjs";
import { handler } from "../src/http.mjs";
import { Refused, clockTicks } from "../src/service.mjs";
import { Social } from "../src/social.mjs";
import { Workshop } from "../src/workshop.mjs";
import { openPlan, play, twoPlayers } from "./setup.mjs";

const refusal = (fn, reason) => assert.throws(fn, (e) => e instanceof Refused && e.reason === reason);

const call = (t, method, path, { token, json } = {}) => t.handle(new Request(`https://edge.example${path}`, {
  method,
  headers: { ...(token ? { authorization: `Bearer ${token}` } : {}),
             ...(json ? { "content-type": "application/json" } : {}) },
  body: json ? JSON.stringify(json) : undefined,
}));

test("deleting an account takes the person out of everything, and keeps the records nobody edits (20.5)", () => {
  const t = twoPlayers(true);
  const gone = t.defender.account;
  const other = t.raider.account;
  // A raid, so there is a ledger and Renown to keep.
  const lease = t.service.lease(other, t.bundle);
  t.service.submit(other, lease.token, play(t, lease, { plan: openPlan() }));
  // A Workshop island, a constellation it founded and a crew.
  const w = new Workshop(t.service);
  const cleared = t.build.record(t.island, { seed: 7n, ticks: clockTicks(0), crew: 3, commands: openPlan() });
  const { id: item } = w.publish(gone, t.island, cleared, { adjective: 0, noun: 0 });
  t.service.db.prepare("UPDATE accounts SET keeper_level = 6").run();
  const social = new Social(t.service);
  const c = social.found(gone, { adjective: 1, noun: 1 });
  social.join(other, c.id);
  social.startCrew(gone);
  t.service.friends.accept(other, t.service.friends.invite(gone).invite);
  const ledger = t.service.db.prepare("SELECT COUNT(*) AS n FROM ledger").get().n;

  const out = deleteAccount(t.service, gone, "requested", { withdraw: true });
  assert.deepEqual([out.deleted, out.islands, out.withdrawn, out.left.length], [true, 1, 1, 2]);
  refusal(() => t.service.account(t.defender.token), "account_deleted");
  assert.notEqual(t.service.session("gc:defender").account, gone, "signing in again starts afresh");
  assert.deepEqual(t.service.targetLists(), {}, "its island left the target lists");
  refusal(() => t.service.lease(other, t.bundle), "superseded");
  assert.equal(w.view(w.row(item)).withdrawn, true, "withdrawn, not deleted: a remix still names it");
  assert.equal(social.constellation(c.id).members[0].account, other, "the constellation was handed on");
  assert.deepEqual(t.service.friends.list(other), [], "and friendships end");
  const who = t.service.telemetry.pseudonym(gone);
  assert.equal(t.service.db.prepare("SELECT COUNT(*) AS n FROM events WHERE who = ?").get(who).n, 0);
  assert.equal(t.service.db.prepare("SELECT COUNT(*) AS n FROM ledger").get().n, ledger,
               "the ledger is append-only, and names only an id that leads nowhere");
  assert.deepEqual(deleteAccount(t.service, gone).islands, 0, "asking again finishes, and changes nothing");
});

test("a deleted player's Workshop islands stay listed with no creator, unless they asked to withdraw them (F43)", async () => {
  for (const withdrawIslands of [false, true]) {
    const t = twoPlayers(true);
    const w = new Workshop(t.service);
    const cleared = t.build.record(t.island, { seed: 7n, ticks: clockTicks(0), crew: 3, commands: openPlan() });
    const { id } = w.publish(t.defender.account, t.island, cleared, { adjective: 0, noun: 0 });
    const res = await call(t, "DELETE", "/v1/account", { token: t.defender.token, json: { withdrawIslands } });
    assert.equal(res.status, 200);
    const view = w.view(w.row(id));
    assert.equal(view.withdrawn, withdrawIslands);
    assert.deepEqual([view.creator, view.creatorLevel], [null, null], "no creator shown");
    const listed = w.browse(t.raider.account, "new").map((i) => i.id);
    assert.deepEqual(listed, withdrawIslands ? [] : [id]);
    const entry = t.service.deletions.entries().at(-1);
    assert.equal(entry.withdraw, withdrawIslands, "the journal records the choice (F50)");
  }
  const t = twoPlayers(true);
  const bad = await call(t, "DELETE", "/v1/account", { token: t.defender.token, json: { withdrawIslands: "yes" } });
  assert.deepEqual([bad.status, (await bad.json()).error], [400, "bad_withdraw"]);
});

test("a banned player's deletion never puts their islands back in the Workshop, whatever they ask (F43, 20.12)", async () => {
  for (const how of ["app", "web"]) {
    const t = twoPlayers(true);
    const w = new Workshop(t.service);
    const cleared = t.build.record(t.island, { seed: 7n, ticks: clockTicks(0), crew: 3, commands: openPlan() });
    const { id } = w.publish(t.defender.account, t.island, cleared, { adjective: 0, noun: 0 });
    w.ban(t.defender.account, "offensive");
    assert.deepEqual(w.browse(t.raider.account, "new"), [], "a ban takes them out of play");
    if (how === "app") {
      deleteAccount(t.service, t.defender.account, "requested", { withdraw: false });
    } else {
      t.service.db.prepare("UPDATE accounts SET platform_identity = 'gp:banned' WHERE id = ?").run(t.defender.account);
      t.service.verifyPlatform = (c) => (c?.idToken === "banned-token" ? "gp:banned" : typeof c === "string" ? c : null);
      const web = handler(t.service, { webClientId: "web-client.apps.googleusercontent.com" });
      const res = await web(new Request("https://edge.example/v1/account/delete", {
        method: "POST", headers: { "content-type": "application/json" },
        body: JSON.stringify({ idToken: "banned-token", withdrawIslands: false }) }));
      assert.equal(res.status, 200);
    }
    assert.deepEqual(w.browse(t.raider.account, "new"), [], how);
    assert.equal(w.view(w.row(id)).withdrawn, true, how);
    assert.equal(t.service.deletions.entries().at(-1).withdraw, true, "and a restore makes it again so");
  }
});

test("an edge that cannot make the journal's deletions again answers nothing until it can (F50)", async () => {
  const t = twoPlayers(true);
  const journal = t.service.deletions;
  let failing = true;
  t.service.deletions = { entries: () => { if (failing) throw new Error("bucket unreachable"); return journal.entries(); },
                          append: (e) => journal.append(e) };
  journal.append({ account: t.defender.account, reason: "requested", withdraw: false, at: t.clock.now });
  const edge = handler(t.service);
  const logged = console.error;
  console.error = () => {};
  try {
    const first = await edge(new Request("https://edge.example/v1/era"));
    assert.deepEqual([first.status, first.headers.get("retry-after")], [503, "1"]);
  } finally {
    console.error = logged;
  }
  assert.equal(t.service.db.prepare("SELECT deleted_at FROM accounts WHERE id = ?").get(t.defender.account).deleted_at,
               null);
  failing = false;
  assert.notEqual((await edge(new Request("https://edge.example/v1/era"))).status, 503, "answered");
  assert.ok(t.service.db.prepare("SELECT deleted_at FROM accounts WHERE id = ?").get(t.defender.account).deleted_at,
            "the next request made it");
});

test("a player deletes from the web by signing in with the Google account they play with (G39)", async () => {
  const t = twoPlayers(true);
  const { account } = t.service.session("gc:web");
  t.service.db.prepare("UPDATE accounts SET platform_identity = 'gp:1234' WHERE id = ?").run(account);
  // Google's check, as stores.mjs makes it: an ID token names gp:<sub>.
  t.service.verifyPlatform = (c) => (c?.idToken === "good-token" ? "gp:1234"
    : c?.idToken === "other-token" ? "gp:9999" : typeof c === "string" ? c : null);
  const web = handler(t.service, { webClientId: "web-client.apps.googleusercontent.com" });
  const page = await web(new Request("https://edge.example/account/delete"));
  assert.equal(page.status, 200);
  const html = await page.text();
  assert.match(html, /data-client_id="web-client\.apps\.googleusercontent\.com"/);
  assert.match(html, /Withdraw my Workshop islands too/);
  assert.equal(page.headers.get("x-frame-options"), "DENY");
  assert.equal((await t.handle(new Request("https://edge.example/account/delete"))).status, 503,
               "no web client id, no page");
  const post = (json) => web(new Request("https://edge.example/v1/account/delete", {
    method: "POST", headers: { "content-type": "application/json" }, body: JSON.stringify(json) }));
  const bad = await post({ idToken: "forged" });
  assert.deepEqual([bad.status, (await bad.json()).error], [401, "google_identity_refused"]);
  const nobody = await post({ idToken: "other-token" });
  assert.deepEqual([nobody.status, (await nobody.json()).error], [404, "no_such_account"]);
  const gc = await post({ idToken: 7 });
  assert.equal(gc.status, 400, "only a token");
  const ok = await post({ idToken: "good-token", withdrawIslands: true });
  assert.deepEqual(await ok.json(), { deleted: true, reason: "requested" });
  assert.ok(t.service.db.prepare("SELECT deleted_at FROM accounts WHERE id = ?").get(account).deleted_at);
  assert.equal(t.service.deletions.entries().at(-1).withdraw, true);
});

test("a deletion is all or nothing: one stopped in its group places can be asked for again (20.5)", async () => {
  const t = twoPlayers(true);
  const gone = t.defender.account;
  t.service.db.prepare("UPDATE accounts SET keeper_level = 6").run();
  const social = new Social(t.service);
  const c = social.found(gone, { adjective: 1, noun: 1 });
  social.join(t.raider.account, c.id);
  social.startCrew(gone);
  // The last write fails, as a full disk would.
  t.service.db.exec(`CREATE TRIGGER fail BEFORE UPDATE ON crew_members
                       BEGIN SELECT RAISE(ABORT, 'disk full'); END`);
  // The edge answers an unexpected failure 500 and keeps serving (C26).
  assert.equal((await call(t, "DELETE", "/v1/account", { token: t.defender.token })).status, 500);
  assert.equal(t.service.account(t.defender.token), gone, "nothing was done, so the token still works");
  assert.equal(social.membership(gone).role, "founder");
  t.service.db.exec("DROP TRIGGER fail");
  assert.equal((await call(t, "DELETE", "/v1/account", { token: t.defender.token })).status, 200);
  assert.deepEqual(social.constellation(c.id).members.map((m) => [m.account, m.role]),
                   [[t.raider.account, "founder"]], "handed on, in the same transaction");
  assert.equal(social.crewOf(gone), null);
});

test("a banned player's deletion keeps the ban on their identity (20.12)", () => {
  const t = twoPlayers(true);
  new Workshop(t.service).ban(t.raider.account, "cheating");
  refusal(() => t.service.session("gc:raider"), "banned");
  assert.equal(deleteAccount(t.service, t.raider.account).deleted, true);
  refusal(() => t.service.session("gc:raider"), "banned");
  assert.equal(t.service.db.prepare("SELECT COUNT(*) AS n FROM accounts").get().n, 2, "no fresh account");
});

test("a player who turns out to be under 13 is deleted at once (20.11)", async () => {
  const t = twoPlayers(true);
  const res = await call(t, "PUT", "/v1/age", { token: t.defender.token, json: { band: "under-13" } });
  assert.deepEqual(await res.json(), { deleted: true, reason: "under-13" });
  assert.equal((await call(t, "GET", "/v1/balance", { token: t.defender.token })).status, 401);
  assert.deepEqual(t.service.targetLists(), {});
});

test("account deletion from inside the game, over HTTP (20.5)", async () => {
  const t = twoPlayers(true);
  const res = await call(t, "DELETE", "/v1/account", { token: t.raider.token });
  assert.equal(res.status, 200);
  assert.equal((await res.json()).reason, "requested");
  const after = await call(t, "GET", "/v1/league", { token: t.raider.token });
  assert.deepEqual([after.status, (await after.json()).error], [401, "account_deleted"]);
});
