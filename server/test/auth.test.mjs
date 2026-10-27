// Sessions and their tokens (docs/security/auth.md): every rule the threat
// model names, refused the way it says — forged, expired, revoked, reused,
// lapsed, rotated keys — and every refusal the same answer.

import assert from "node:assert/strict";
import { test } from "node:test";

import { ABSOLUTE_MS, ENDED_KEEP_MS, IDLE_MS } from "../src/auth.mjs";
import { deleteAccount } from "../src/accounts.mjs";
import { NONCE_MS, SESSION_MS, issueAccess, keyring, readAccess } from "../src/tokens.mjs";
import { Workshop } from "../src/workshop.mjs";
import { server } from "./setup.mjs";

const DAY = 24 * 60 * 60 * 1000;

function refusal(fn, reason = "session_refused") {
  assert.throws(fn, (e) => e.reason === reason, `refused as ${reason}`);
}

test("a sign-in makes a session the server names, an hour's access token and a refresh token (24.8)", () => {
  const t = server();
  const s = t.service.session("gc:alice");
  assert.deepEqual(Object.keys(s).sort(), ["account", "expiresIn", "refreshToken", "token"]);
  assert.equal(s.expiresIn, SESSION_MS / 1000);
  assert.match(s.token, /^a1\.k0\.[0-9a-f]+\.\d+\.\d+\.[A-Za-z0-9_-]{43}$/);
  assert.match(s.refreshToken, /^r1\.k0\.\d+\.0\.[A-Za-z0-9_-]{43}$/);
  assert.equal(t.service.account(s.token), s.account);
  // No fixation: every sign-in is a new session, whatever the device held.
  const again = t.service.session("gc:alice");
  assert.equal(again.account, s.account);
  assert.notEqual(again.token.split(".")[3], s.token.split(".")[3]);
  assert.equal(t.service.auth.live(s.account), 2, "two devices");
});

test("a forged, altered, foreign or malformed access token is refused, all alike", () => {
  const t = server();
  const s = t.service.session("gc:alice");
  const bob = t.service.session("gc:bob");
  const [v, kid, account, session, expiry, mac] = s.token.split(".");
  const flip = (c) => (c === "A" ? "B" : "A");
  const forged = {
    "a changed MAC": `${v}.${kid}.${account}.${session}.${expiry}.${mac.slice(0, -1)}${flip(mac.at(-1))}`,
    "another account": `${v}.${kid}.${bob.account}.${session}.${expiry}.${mac}`,
    "a later expiry": `${v}.${kid}.${account}.${session}.${Number(expiry) + 1}.${mac}`,
    "another session": `${v}.${kid}.${account}.${bob.token.split(".")[3]}.${expiry}.${mac}`,
    "an unknown key": `${v}.k9.${account}.${session}.${expiry}.${mac}`,
    "another version": `a0.${kid}.${account}.${session}.${expiry}.${mac}`,
    "a refresh token": s.refreshToken,
    "no MAC": `${v}.${kid}.${account}.${session}.${expiry}`,
    "the old format": `${account}.${expiry}.${mac}`,
    "empty": "",
    "a number": 5,
    "too long": `${s.token}${"x".repeat(600)}`,
    "a prototype key id": `${v}.constructor.${account}.${session}.${expiry}.${mac}`,
  };
  for (const [why, token] of Object.entries(forged)) {
    assert.throws(() => t.service.account(token), (e) => e.reason === "session_refused" && e.status === 401, why);
  }
  // Signed with another server's key: the right shape, the wrong MAC.
  const stranger = issueAccess(keyring("another server's secret"), { account: s.account, session: Number(session) },
                               t.clock.now);
  refusal(() => t.service.account(stranger.token));
  // A session id that is real but another account's, signed: the row says whose.
  const theirs = issueAccess(t.service.auth.keys, { account: s.account, session: Number(bob.token.split(".")[3]) }, t.clock.now);
  refusal(() => t.service.account(theirs.token));
});

test("an access token lasts its hour on the server's clock, not the device's", () => {
  const t = server();
  const s = t.service.session("gc:alice");
  t.clock.now += SESSION_MS - 1;
  assert.equal(t.service.account(s.token), s.account);
  t.clock.now += 1;
  refusal(() => t.service.account(s.token));
});

test("signing out ends the session at once, and only that one; again is harmless", () => {
  const t = server();
  const phone = t.service.session("gc:alice");
  const tablet = t.service.session("gc:alice");
  assert.equal(t.service.auth.signOut(phone.token), 1);
  refusal(() => t.service.account(phone.token));
  refusal(() => t.service.auth.refresh(phone.refreshToken));
  assert.equal(t.service.account(tablet.token), tablet.account, "the other device stays signed in");
  refusal(() => t.service.auth.signOut(phone.token + "x"));
  assert.equal(t.service.auth.signOutWith(phone.refreshToken), 0, "already ended: nothing more to end");
  assert.equal(t.service.db.prepare("SELECT ended FROM sessions WHERE id = ?").get(phone.token.split(".")[3]).ended,
               "signed_out");
});

test("signing out everywhere ends every session of the account, and no one else's", () => {
  const t = server();
  const a = [t.service.session("gc:alice"), t.service.session("gc:alice"), t.service.session("gc:alice")];
  const bob = t.service.session("gc:bob");
  assert.equal(t.service.auth.signOut(a[1].token, { everywhere: true }), 3);
  for (const s of a) {
    refusal(() => t.service.account(s.token));
    refusal(() => t.service.auth.refresh(s.refreshToken));
  }
  assert.equal(t.service.auth.live(a[0].account), 0);
  assert.equal(t.service.account(bob.token), bob.account);
  // With only a refresh token, past the access token's hour.
  const late = t.service.session("gc:alice");
  t.clock.now += SESSION_MS * 2;
  assert.equal(t.service.auth.signOutWith(late.refreshToken, { everywhere: true }), 1);
  refusal(() => t.service.auth.refresh(late.refreshToken));
});

test("a refresh token is rotated on every use, and one used twice ends its whole family", () => {
  const t = server();
  const s0 = t.service.session("gc:alice");
  t.clock.now += 1000;
  const s1 = t.service.auth.refresh(s0.refreshToken);
  assert.equal(s1.account, s0.account);
  assert.notEqual(s1.refreshToken, s0.refreshToken);
  assert.match(s1.refreshToken, /^r1\.k0\.\d+\.1\./);
  assert.equal(s1.token.split(".")[3], s0.token.split(".")[3], "the same session, a new generation");
  const s2 = t.service.auth.refresh(s1.refreshToken);
  assert.equal(t.service.account(s2.token), s0.account);
  // A thief replays the first token: two holders, so the family ends.
  refusal(() => t.service.auth.refresh(s0.refreshToken));
  refusal(() => t.service.auth.refresh(s2.refreshToken), "session_refused");
  refusal(() => t.service.account(s2.token));
  refusal(() => t.service.account(s1.token));
  assert.equal(t.service.db.prepare("SELECT ended FROM sessions").get().ended, "reused");
  // And the player signs in again with the platform, a new family.
  const fresh = t.service.session("gc:alice");
  assert.equal(t.service.account(fresh.token), s0.account);
});

test("a refresh token not this server's, or altered, is refused and ends nothing: a guess cannot sign anyone out", () => {
  const t = server();
  const s = t.service.session("gc:alice");
  const [v, kid, session, gen, mac] = s.refreshToken.split(".");
  const tries = [
    `${v}.${kid}.${session}.${gen}.${"A".repeat(43)}`,
    `${v}.${kid}.${session}.${Number(gen) + 1}.${mac}`,
    `${v}.${kid}.${session}.-1.${mac}`,
    `${v}.${kid}.999999.${gen}.${mac}`,
    `${v}.${kid}.${session}x.${gen}.${mac}`,
    `${v}.k7.${session}.${gen}.${mac}`,
    s.token,
    "",
    null,
  ];
  for (const r of tries) refusal(() => t.service.auth.refresh(r));
  assert.equal(t.service.account(s.token), s.account, "still signed in");
  assert.ok(t.service.auth.refresh(s.refreshToken).token);
});

test("a session lapses 30 days unused and 180 days after it was made, refreshed or not", () => {
  const t = server();
  const s = t.service.session("gc:alice");
  t.clock.now += IDLE_MS + 1;
  refusal(() => t.service.auth.refresh(s.refreshToken));
  const u = { ...t.service.session("gc:alice"), created: t.clock.now };
  let r = u;
  for (let used = 0; used + 20 * DAY < ABSOLUTE_MS; used += 20 * DAY) {
    t.clock.now += 20 * DAY;
    r = t.service.auth.refresh(r.refreshToken);
  }
  t.clock.now = u.created + ABSOLUTE_MS + 1;
  refusal(() => t.service.auth.refresh(r.refreshToken));
});

test("deletion, a ban and a change of platform identity end every session (20.5, 20.12)", () => {
  const t = server();
  const gone = t.service.session("gc:gone");
  deleteAccount(t.service, gone.account);
  refusal(() => t.service.account(gone.token), "account_deleted");
  refusal(() => t.service.auth.refresh(gone.refreshToken));
  assert.equal(t.service.db.prepare("SELECT COUNT(*) AS n FROM sessions WHERE account = ?").get(gone.account).n, 0,
               "erased, as privacy.json says");

  const cheat = [t.service.session("gc:cheat"), t.service.session("gc:cheat")];
  new Workshop(t.service).ban(cheat[0].account, "offensive");
  for (const s of cheat) {
    refusal(() => t.service.account(s.token), "banned");
    refusal(() => t.service.auth.refresh(s.refreshToken));
  }
  assert.deepEqual(t.service.db.prepare("SELECT DISTINCT ended FROM sessions WHERE account = ?")
    .all(cheat[0].account).map((r) => r.ended), ["banned"]);
  refusal(() => t.service.session("gc:cheat"), "banned");

  const moved = t.service.session("gc:moved");
  assert.equal(t.service.auth.identityChanged(moved.account), 1);
  refusal(() => t.service.account(moved.token));
});

test("a token signed with a retired key is refused; one signed with an older key in the ring is not (key rotation)", () => {
  const old = "an old token key of thirty-two chars or more";
  const neu = "a new token key and also thirty-two characters";
  const t = server({ tokenKeys: `k1:${old}` });
  const before = t.service.session("gc:alice");
  assert.match(before.token, /^a1\.k1\./);
  // Rotated: the new key signs, the old one is still accepted.
  t.service.auth.keys = keyring("unused", `k2:${neu},k1:${old}`);
  assert.equal(t.service.account(before.token), before.account, "nobody signed out by a rotation");
  const after = t.service.auth.refresh(before.refreshToken);
  assert.match(after.token, /^a1\.k2\./);
  assert.match(after.refreshToken, /^r1\.k2\./);
  // Retired.
  const late = t.service.session("gc:alice");
  t.service.auth.keys = keyring("unused", `k2:${neu}`);
  assert.equal(t.service.account(after.token), after.account);
  t.service.auth.keys = keyring("unused", `k3:${old}`);
  refusal(() => t.service.account(late.token), "session_refused");
});

test("a key ring refuses short keys, bad ids and repeats; without one, its key is not telemetry's", () => {
  assert.throws(() => keyring("s", "k1:short"), /shorter than 32/);
  assert.throws(() => keyring("s", "k.1:" + "x".repeat(32)), /letters and digits/);
  assert.throws(() => keyring("s", ":" + "x".repeat(32)), /letters and digits/);
  assert.throws(() => keyring("s", `k1:${"x".repeat(32)},k1:${"y".repeat(32)}`), /twice/);
  assert.throws(() => keyring(""), /secret/);
  const ring = keyring("test secret");
  assert.deepEqual(Object.keys(ring.keys), ["k0"]);
  assert.notDeepEqual(ring.keys.k0, Buffer.from("test secret"), "derived, apart from the pseudonyms' use");
  const t = server();
  const s = t.service.session("gc:alice");
  assert.equal(readAccess(ring, s.token, t.clock.now).account, s.account, "the test server's tokens are k0's");
});

test("a nonce is the server's, lasts five minutes and is spent once (24.8)", () => {
  const t = server();
  const { nonce, expiresIn } = t.service.auth.nonce();
  assert.equal(expiresIn, NONCE_MS / 1000);
  assert.match(nonce, /^n1\.k0\.[0-9a-f]{32}\.\d+\./);
  assert.equal(t.service.db.prepare("SELECT COUNT(*) AS n FROM auth_spent").get().n, 0, "asking writes nothing");
  assert.equal(t.service.auth.spendNonce(nonce), true);
  assert.equal(t.service.auth.spendNonce(nonce), false, "once");
  const stale = t.service.auth.nonce().nonce;
  t.clock.now += NONCE_MS;
  assert.equal(t.service.auth.spendNonce(stale), false, "five minutes");
  const fresh = t.service.auth.nonce().nonce;
  assert.equal(t.service.auth.spendNonce(fresh.replace(/.$/, (c) => (c === "A" ? "B" : "A"))), false, "forged");
  assert.equal(t.service.auth.spendNonce("n1.k0.00.9999999999999.x"), false);
  assert.equal(t.service.auth.spendNonce(undefined), false);
});

test("what ended or lapsed is deleted seven days after, and spent proofs once past their life (20.5)", () => {
  const t = server();
  const ended = t.service.session("gc:alice");
  const live = t.service.session("gc:alice");
  const idle = t.service.session("gc:bob");
  t.service.auth.signOut(ended.token);
  t.service.auth.spend("gc|x|salt|1", t.clock.now + 60_000);
  const count = () => t.service.db.prepare("SELECT COUNT(*) AS n FROM sessions").get().n;
  assert.deepEqual(t.service.auth.expire(), { sessions: 0, spent: 0 });
  t.clock.now += ENDED_KEEP_MS + 1;
  live.refreshToken = t.service.auth.refresh(live.refreshToken).refreshToken;
  assert.deepEqual(t.service.auth.expire(), { sessions: 1, spent: 1 }, "the one signed out");
  t.clock.now += IDLE_MS;
  t.service.auth.refresh(live.refreshToken);
  assert.deepEqual(t.service.auth.expire(), { sessions: 1, spent: 0 }, "bob's, lapsed a week ago");
  assert.equal(count(), 1);
  refusal(() => t.service.auth.refresh(idle.refreshToken));
  assert.deepEqual(t.service.auth.expire(), { sessions: 0, spent: 0 }, "idempotent");
});

test("a key spent is refused until its life is over, then may be spent again", () => {
  const t = server();
  const until = t.clock.now + 1000;
  assert.equal(t.service.auth.spend("k", until), true);
  assert.equal(t.service.auth.spend("k", until), false);
  t.clock.now = until + 1;
  assert.equal(t.service.auth.spend("k", until + 5000), true, "a lapsed row is no reason to refuse");
  assert.equal(t.service.auth.spend("k", until + 5000), false);
  const rows = t.service.db.prepare("SELECT key FROM auth_spent").all();
  assert.equal(rows.length, 1);
  assert.notEqual(rows[0].key, "k", "kept by a hash");
});
