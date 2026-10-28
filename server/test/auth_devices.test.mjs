// The devices list, ending one device or every other, linking a second
// platform's identity, and the limits on every session path
// (auth.mjs, auth_http.mjs, docs/security/auth.md).

import assert from "node:assert/strict";
import { test } from "node:test";

import { ABSOLUTE_MS, deviceOf, placeOf } from "../src/auth.mjs";
import { handler } from "../src/http.mjs";
import { KINDS } from "../src/limits.mjs";
import { Refused } from "../src/refused.mjs";
import { SESSION_MS } from "../src/tokens.mjs";
import { Workshop } from "../src/workshop.mjs";
import { server } from "./setup.mjs";

const HOUR = 60 * 60 * 1000;
const DAY = 24 * HOUR;
const refusal = (fn, status, reason) =>
  assert.throws(fn, (e) => e instanceof Refused && e.status === status && e.reason === reason);

const request = (path, { method = "GET", token, peer, place, body } = {}) =>
  new Request(`https://edge.example${path}`, {
    method,
    headers: { ...(token ? { authorization: `Bearer ${token}` } : {}), ...(peer ? { "x-peer": peer } : {}),
               ...(place ? { "cf-ipcountry": place } : {}),
               ...(body !== undefined ? { "content-type": "application/json" } : {}) },
    body: body !== undefined ? JSON.stringify(body) : undefined });

const read = async (res) => ({ status: res.status, body: await res.json() });

/** A server whose fake platforms prove Google identities too, and an edge
 *  that names the caller's address and country. */
function both() {
  const t = server();
  t.service.verifyPlatform = (c) => (typeof c === "string" && /^g[cp]:/.test(c) ? c : null);
  const handle = handler(t.service, { peerOf: (r) => r.headers.get("x-peer"),
                                      placeOf: (r) => r.headers.get("cf-ipcountry") });
  return { t, handle };
}

test("what a device says it is is held to the list's words, and a place is a country or nothing", () => {
  assert.deepEqual(deviceOf({ kind: "iphone", model: "iPhone15,2" }), { device: "iphone", model: "iPhone15,2" });
  assert.deepEqual(deviceOf({ kind: "android_phone", model: "  Pixel   8 Pro " }),
                   { device: "android_phone", model: "Pixel 8 Pro" });
  assert.deepEqual(deviceOf({ kind: "toaster", model: "<script>alert(1)</script>" + "x".repeat(60) }).device, "other");
  assert.ok(deviceOf({ model: "x".repeat(60) }).model.length <= 32);
  assert.deepEqual(deviceOf(null), { device: "other", model: null });
  assert.deepEqual(deviceOf({ model: "Ünïcödé 😀" }), { device: "other", model: "ncd" });
  assert.equal(placeOf("pt"), "PT");
  for (const no of ["XX", "T1", "", null, "PRT", "203.0.113.7", "2001:db8::1"]) assert.equal(placeOf(no), null);
});

test("the devices list: each signed-in device's kind, model, platform, country and last use, never an address", async () => {
  const { t, handle } = both();
  const t0 = t.clock.now;
  const sign = async (credential, device, place, peer) => (await handle(request("/v1/session", {
    method: "POST", peer, place, body: { credential, device } }))).json();
  const phone = await sign("gc:alice", { kind: "iphone", model: "iPhone 15" }, "PT", "198.51.100.7");
  t.clock.now += 3 * HOUR + 17 * 60 * 1000;
  const tablet = await sign("gc:alice", { kind: "ipad", model: "iPad Air" }, "ES", "2001:db8:1:2::9");
  await sign("gc:bob", { kind: "android_phone", model: "Pixel 8" }, "FR", "203.0.113.4");
  t.clock.now += 2 * DAY;
  // The phone refreshes from another country: last seen there, then.
  const moved = await read(await handle(request("/v1/session/refresh", {
    method: "POST", place: "BR", body: { refreshToken: phone.refreshToken } })));
  assert.equal(moved.status, 200);
  t.clock.now += 10 * 60 * 1000;
  const list = await read(await handle(request("/v1/session/devices", { token: moved.body.token })));
  assert.equal(list.status, 200);
  const now = t.clock.now;
  const tabletAt = t0 + 3 * HOUR + 17 * 60 * 1000;
  assert.deepEqual(list.body.devices, [
    { id: list.body.devices[0].id, current: true, via: "gc", device: "iphone", model: "iPhone 15", place: "BR",
      signedInAt: t0 - (t0 % DAY), lastSeenAt: now - (now % HOUR), idleHours: 0 },
    { id: list.body.devices[1].id, current: false, via: "gc", device: "ipad", model: "iPad Air", place: "ES",
      signedInAt: tabletAt - (tabletAt % DAY), lastSeenAt: tabletAt - (tabletAt % HOUR),
      idleHours: Math.floor((now - tabletAt) / HOUR) },
  ], "this device first, then by last use; bob's is not here");
  assert.ok(tablet.token);
  assert.deepEqual(list.body.identities, [{ platform: "gc", primary: true, linkedAt: null }]);
  // No address is stored anywhere a session is.
  const rows = JSON.stringify(t.service.db.prepare("SELECT * FROM sessions").all());
  for (const address of ["198.51.100.7", "2001:db8", "203.0.113.4"]) assert.ok(!rows.includes(address), address);
  // A malformed device is refused before anything is read.
  assert.equal((await handle(request("/v1/session", { method: "POST", body: { credential: "gc:a", device: [1] } })))
    .status, 400);
});

test("a device ended from the list is signed out at once; another account's id ends nothing and answers alike", async () => {
  const { t, handle } = both();
  const a1 = t.service.session("gc:alice");
  const a2 = t.service.session("gc:alice");
  const a3 = t.service.session("gc:alice");
  const b = t.service.session("gc:bob");
  const ids = (await read(await handle(request("/v1/session/devices", { token: a1.token })))).body.devices
    .map((d) => d.id);
  const bobs = (await read(await handle(request("/v1/session/devices", { token: b.token })))).body.devices[0].id;
  const end = (token, body) => handle(request("/v1/session/end", { method: "POST", token, body }));
  assert.deepEqual(await read(await end(a1.token, { device: bobs })), { status: 200, body: { ended: 0 } });
  assert.equal((await handle(request("/v1/balance", { token: b.token }))).status, 200, "bob's is untouched");
  assert.deepEqual(await read(await end(a1.token, { device: ids[1] })), { status: 200, body: { ended: 1 } });
  assert.deepEqual(await read(await end(a1.token, { device: ids[1] })), { status: 200, body: { ended: 0 } },
                   "again is harmless");
  const ended = t.service.db.prepare("SELECT ended FROM sessions WHERE id = ?").get(ids[1]).ended;
  assert.equal(ended, "device");
  const alive = await Promise.all([a1, a2, a3].map(async (s) => (await handle(request("/v1/balance",
                                                                                     { token: s.token }))).status));
  assert.equal(alive.filter((s) => s === 401).length, 1);
  for (const bad of [{ device: "1" }, { device: -1 }, { device: 1.5 }, { others: "yes" }]) {
    assert.equal((await end(a1.token, bad)).status, 400, JSON.stringify(bad));
  }
  // Without a live access token, only this session or all can be ended.
  assert.equal((await end(undefined, { device: ids[0], refreshToken: a1.refreshToken })).status, 401);
});

test("sign out every other device keeps this one and ends the rest of the account's, and nobody else's", async () => {
  const { t, handle } = both();
  const mine = t.service.session("gc:alice");
  const others = [t.service.session("gc:alice"), t.service.session("gc:alice")];
  const bob = t.service.session("gc:bob");
  const out = await read(await handle(request("/v1/session/end", { method: "POST", token: mine.token,
                                                                    body: { others: true } })));
  assert.deepEqual(out, { status: 200, body: { ended: 2 } });
  assert.equal((await handle(request("/v1/balance", { token: mine.token }))).status, 200);
  assert.equal((await handle(request("/v1/balance", { token: bob.token }))).status, 200);
  for (const o of others) {
    assert.equal((await handle(request("/v1/balance", { token: o.token }))).status, 401);
    refusal(() => t.service.auth.refresh(o.refreshToken), 401, "session_refused");
  }
  assert.equal(t.service.auth.devices(mine.account, null).length, 1);
});

test("an access token never outlives its session's absolute life", () => {
  const t = server();
  const s = t.service.session("gc:alice");
  let r = s;
  for (let day = 0; day < 179; day++) {
    t.clock.now += DAY;
    r = t.service.auth.refresh(r.refreshToken);
  }
  t.clock.now += DAY - 20 * 60 * 1000;                   // 20 minutes of the 180 days left
  r = t.service.auth.refresh(r.refreshToken);
  assert.equal(r.expiresIn, 20 * 60);
  t.clock.now += 20 * 60 * 1000;
  refusal(() => t.service.account(r.token), 401, "session_refused");
  refusal(() => t.service.auth.refresh(r.refreshToken), 401, "session_refused");
  assert.ok(ABSOLUTE_MS > SESSION_MS);
});

test("a second platform's identity links only with fresh proofs of both, then signs in to the same account", async () => {
  const { t, handle } = both();
  const s = await (await handle(request("/v1/session", { method: "POST", body: { credential: "gc:alice" } }))).json();
  const link = (body, token = s.token) => handle(request("/v1/session/link", { method: "POST", token, body }));
  // A stolen access token alone links nothing: the account's own identity
  // must be proven too, and a proof of someone else's is no proof.
  assert.deepEqual(await read(await link({ credential: "gp:thief" })),
                   { status: 401, body: { error: "platform_identity_refused" } });
  assert.deepEqual(await read(await link({ current: "gc:bob", credential: "gp:thief" })),
                   { status: 401, body: { error: "platform_identity_refused" } });
  assert.equal((await link({ current: "gc:alice", credential: "gp:alice" }, "a1.forged")).status, 401);
  const done = await read(await link({ current: "gc:alice", credential: "gp:alice" }));
  assert.equal(done.status, 200);
  assert.deepEqual(done.body.identities.map((i) => [i.platform, i.primary]), [["gc", true], ["gp", false]]);
  // The Android phone signs in with Google and is the same account.
  const android = t.service.session("gp:alice", { device: { kind: "android_phone" } });
  assert.equal(android.account, s.account);
  const list = t.service.auth.devices(s.account, null);
  assert.deepEqual(list.map((d) => d.via).sort(), ["gc", "gp"]);
  // One identity a platform; none that has an account of its own.
  t.service.session("gp:carol");
  assert.deepEqual(await read(await link({ current: "gc:alice", credential: "gp:alice2" })),
                   { status: 409, body: { error: "platform_linked" } });
  assert.deepEqual(await read(await link({ current: "gc:alice", credential: "gc:alice-other" })),
                   { status: 409, body: { error: "platform_linked" } });
  const dave = t.service.session("gc:dave");
  assert.deepEqual(await read(await link({ current: "gc:dave", credential: "gp:carol" }, dave.token)),
                   { status: 409, body: { error: "identity_in_use" } }, "never merged");
  assert.deepEqual(await read(await link({ current: "gc:dave", credential: "gp:alice" }, dave.token)),
                   { status: 409, body: { error: "identity_in_use" } });
});

test("unlinking needs a fresh proof of the identity that stays, and ends the sessions the other signed in", async () => {
  const { t, handle } = both();
  const ios = t.service.session("gc:alice");
  t.service.auth.link(ios.account, "gc:alice", "gp:alice");
  const android = t.service.session("gp:alice");
  const ipad = t.service.session("gc:alice");
  const unlink = (body, token) => handle(request("/v1/session/unlink", { method: "POST", token, body }));
  assert.deepEqual(await read(await unlink({ current: "gp:alice", platform: "gp" }, android.token)),
                   { status: 409, body: { error: "not_linked" } }, "the identity going cannot vouch for itself");
  assert.equal((await unlink({ current: "gc:alice", platform: "pc" }, ios.token)).status, 400);
  const out = await read(await unlink({ current: "gc:alice", platform: "gp" }, ios.token));
  assert.deepEqual(out, { status: 200, body: { identities: [{ platform: "gc", primary: true, linkedAt: null }] } });
  assert.equal((await handle(request("/v1/balance", { token: android.token }))).status, 401);
  assert.equal((await handle(request("/v1/balance", { token: ios.token }))).status, 200);
  assert.equal((await handle(request("/v1/balance", { token: ipad.token }))).status, 200);
  // Google now makes an account of its own, as for anyone.
  assert.notEqual(t.service.session("gp:alice").account, ios.account);
  assert.deepEqual(await read(await unlink({ current: "gc:alice", platform: "gp" }, ios.token)),
                   { status: 409, body: { error: "not_linked" } });
});

test("a ban holds on a linked identity too, and outlives the account; a deletion erases the link (20.12)", async () => {
  const { t } = both();
  const s = t.service.session("gc:alice");
  t.service.auth.link(s.account, "gc:alice", "gp:alice");
  new Workshop(t.service).ban(s.account, "cheating", t.clock.now);
  refusal(() => t.service.session("gp:alice"), 403, "banned");
  const { deleteAccount } = await import("../src/accounts.mjs");
  deleteAccount(t.service, s.account, "requested");
  assert.equal(t.service.db.prepare("SELECT COUNT(*) AS n FROM linked_identities").get().n, 0);
  refusal(() => t.service.session("gp:alice"), 403, "banned");
  refusal(() => t.service.session("gc:alice"), 403, "banned");
  // A banned identity is never linked to another account.
  const bob = t.service.session("gc:bob");
  refusal(() => t.service.auth.link(bob.account, "gc:bob", "gp:alice"), 403, "banned");
  // An unbanned player's deletion frees both identities.
  const c = t.service.session("gc:carol");
  t.service.auth.link(c.account, "gc:carol", "gp:carol");
  deleteAccount(t.service, c.account, "requested");
  assert.notEqual(t.service.session("gp:carol").account, c.account);
});

test("every session path is limited: devices, ending one or others, linking, unlinking, a late sign-out (24.1)", async () => {
  const { t, handle } = both();
  const s = t.service.session("gc:alice");
  // The account's calls bucket holds the list and the endings.
  let status = 200;
  let asked = 0;
  while (status !== 429 && asked < KINDS.calls.burst + 2) {
    status = (await handle(request("/v1/session/devices", { token: s.token }))).status;
    asked++;
  }
  assert.equal(status, 429);
  assert.equal(asked, KINDS.calls.burst + 1);
  const held = await handle(request("/v1/session/end", { method: "POST", token: s.token, body: { others: true } }));
  assert.equal(held.status, 429);
  assert.ok(Number(held.headers.get("retry-after")) >= 1);
  for (const verb of ["link", "unlink"]) {
    assert.equal((await handle(request(`/v1/session/${verb}`, { method: "POST", token: s.token,
                                                                 body: { current: "gc:alice" } }))).status, 429);
  }
  // Each proof in a link is a sign-in by the identity it proves.
  const { t: t2, handle: h2 } = both();
  const a = t2.service.session("gc:amy");
  for (let i = 0; i < KINDS.signIns.burst; i++) t2.service.session("gc:amy", { admit: () => {} });
  const linkAs = (current, credential, peer) => h2(request("/v1/session/link", { method: "POST", token: a.token, peer,
                                                                                body: { current, credential } }));
  for (let i = 0; i < KINDS.signIns.burst; i++) {
    const r = await linkAs("gc:amy", `gp:nobody-${i}`, "198.51.100.1");
    assert.equal(r.status, i === 0 ? 200 : 409, `link ${i}`);
  }
  assert.equal((await linkAs("gc:amy", "gp:one-more", "198.51.100.1")).status, 429, "amy's proofs are held");
  // Failed proofs hold the address, a link's as a sign-in's.
  const b = t2.service.session("gc:ben");
  for (let i = 0; i < KINDS.failedSignIns.burst; i++) {
    const r = await h2(request("/v1/session/link", { method: "POST", token: b.token, peer: "203.0.113.5",
                                                     body: { current: "not a proof", credential: "gp:x" } }));
    assert.equal(r.status, 401);
  }
  assert.equal((await h2(request("/v1/session", { method: "POST", peer: "203.0.113.5",
                                                  body: { credential: "gc:ben" } }))).status, 429);
  // A late sign-out by refresh token is held to its session's sign-ins.
  const { t: t3, handle: h3 } = both();
  const late = t3.service.session("gc:cy");
  let r = late;
  for (let i = 0; i < KINDS.signIns.burst; i++) r = t3.service.auth.refresh(r.refreshToken);
  const bucket = handler(t3.service, { peerOf: (q) => q.headers.get("x-peer") });
  for (let i = 0; i < KINDS.signIns.burst; i++) {
    const x = await bucket(request("/v1/session/refresh", { method: "POST", body: { refreshToken: r.refreshToken } }));
    r = await x.json();
  }
  const out = await bucket(request("/v1/session/end", { method: "POST", body: { refreshToken: r.refreshToken } }));
  assert.equal(out.status, 429);
  t3.clock.now += KINDS.signIns.per;
  assert.deepEqual(await read(await bucket(request("/v1/session/end", { method: "POST",
                                                                        body: { refreshToken: r.refreshToken } }))),
                   { status: 200, body: { ended: 1 } });
  assert.ok(h3);
});

test("rotating the refresh token once a day writes once a day, and a copy is still caught at the next rotation", () => {
  const t = server({ refreshRotateMs: DAY });
  const s = t.service.session("gc:alice");
  const writes = () => t.service.db.prepare("SELECT generation, used_at FROM sessions WHERE id = 1").get();
  const before = writes();
  let r = s;
  for (let hour = 1; hour < 24; hour++) {
    t.clock.now += HOUR;
    r = t.service.auth.refresh(r.refreshToken, t.clock.now, { place: "PT" });
    assert.equal(r.refreshToken, s.refreshToken, `hour ${hour}: the same refresh token stands`);
    assert.equal(t.service.account(r.token), s.account, "with a new access token");
  }
  assert.deepEqual(writes(), before, "nothing written inside the day");
  t.clock.now += HOUR;
  const rotated = t.service.auth.refresh(r.refreshToken);
  assert.notEqual(rotated.refreshToken, s.refreshToken);
  assert.equal(writes().generation, 1);
  // The old token, used once more after the rotation, ends the family.
  refusal(() => t.service.auth.refresh(s.refreshToken), 401, "session_refused");
  refusal(() => t.service.auth.refresh(rotated.refreshToken), 401, "session_refused");
  // The default rotates on every refresh.
  const d = server();
  const a = d.service.session("gc:bob");
  d.clock.now += HOUR;
  assert.notEqual(d.service.auth.refresh(a.refreshToken).refreshToken, a.refreshToken);
});
