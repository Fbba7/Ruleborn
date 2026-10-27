// Security review, second pass: the sign-in and session code T11 built this
// wave (auth.mjs, auth_http.mjs; docs/security/review.md, SR-24 onwards).

import assert from "node:assert/strict";
import { test } from "node:test";

import { gc, real } from "./auth_fixtures.mjs";
import { server } from "./setup.mjs";

const call = (t, path, { token, body } = {}) => t.handle(new Request(`https://edge.example${path}`, {
  method: "POST",
  headers: { "content-type": "application/json", ...(token ? { authorization: `Bearer ${token}` } : {}) },
  body: JSON.stringify(body ?? {}) }));
const signIn = async (t, who) => (await call(t, "/v1/session", { body: { credential: who } })).json();
const refresh = async (t, refreshToken) => (await call(t, "/v1/session/refresh", { body: { refreshToken } })).json();
const live = (t, account) => t.service.auth.live(account);

// SR-24: "sign out everywhere" took any token the server ever signed for the
// account: an access token of a session already ended, or a refresh token
// rotated away long ago. A thief holding either — the very tokens rotation
// and sign-out are meant to make worthless — could sign the player out of
// every device, again each time they signed back in, for as long as the old
// session's row is kept. Now only a live session's current token ends them
// all; a dead token ends at most its own, already dead, session.
test("SR-24: only a live session's current token signs out everywhere", async () => {
  const t = server();
  const phone = await signIn(t, "gc:victim");
  const tablet = await signIn(t, "gc:victim");
  // The thief copies the phone's tokens; the phone then refreshes, so the
  // copied refresh token is a generation behind, and signs out, so the
  // copied access token's session is over.
  const stolen = { token: phone.token, refreshToken: phone.refreshToken };
  const rotated = await refresh(t, phone.refreshToken);
  assert.ok(rotated.token, "the phone refreshed");
  assert.equal(live(t, phone.account), 2);

  const old = await call(t, "/v1/session/end", { body: { everywhere: true, refreshToken: stolen.refreshToken } });
  assert.equal(old.status, 401, "a rotated refresh token ends nothing everywhere");
  assert.equal(live(t, phone.account), 2, "the tablet is still signed in");

  await call(t, "/v1/session/end", { token: rotated.token });
  assert.equal(live(t, phone.account), 1, "the phone signed out");
  const dead = await call(t, "/v1/session/end", { token: stolen.token, body: { everywhere: true } });
  assert.equal(dead.status, 401, "an ended session's access token ends nothing everywhere");
  assert.equal(live(t, phone.account), 1, "the tablet is still signed in");

  // A device's own sign-out is still harmless to retry, and everywhere
  // still works from a live session.
  assert.equal((await call(t, "/v1/session/end", { token: rotated.token })).status, 200);
  assert.equal((await call(t, "/v1/session/end", { token: tablet.token, body: { everywhere: true } })).status, 200);
  assert.equal(live(t, phone.account), 0);
});

// SR-25: a Game Center proof is single-use by its player, salt and
// timestamp — but the salt was spent as the string the caller sent, while
// the signature is over its decoded bytes, and Node's base64 decoder skips
// padding, spaces and characters outside the alphabet. One captured proof
// therefore signed in again and again for its five minutes, its salt
// respelled each time ("AAEC", "AAEC=", "AA EC", "AAEC!"): the replay T3 of
// docs/security/auth.md says is stopped. Now the salt is spent by its bytes.
test("SR-25: a Game Center proof respelled is the same proof, and is refused the second time", async () => {
  const r = real();
  const proof = gc({ salt: "salt-0025" });
  const first = await r.signIn(proof);
  assert.ok(first.token);
  for (const salt of [`${proof.salt}=`, ` ${proof.salt}`, `${proof.salt}!`, proof.salt.replace(/=+$/, "")]) {
    if (salt === proof.salt) continue;
    await assert.rejects(r.signIn({ ...proof, salt }), (err) => err.reason === "platform_identity_refused",
                         `the salt respelled ${JSON.stringify(salt)} is a replay`);
  }
});

// SR-28: a refresh was held to the bucket of the session its token names
// (§24.1's sign-ins, ten at once then one every ten seconds) before the
// token was checked, and session ids are sequential. Anyone could send
// made-up refresh tokens naming every session id in turn, about one a
// session every ten seconds, and keep every player's refresh "held back";
// the device keeps its token and waits on a 429 rather than proving itself
// again, so a player stays signed out of the server while it lasts — and
// with no RULEBORN_PEER_HEADER, the default, no address limit stops it.
// Now a token is admitted to its session's bucket only once it is proven.
test("SR-28: made-up refresh tokens naming a session cannot hold its real refresh back", async () => {
  const t = server();
  const player = await signIn(t, "gc:held");
  const session = player.refreshToken.split(".")[2];
  for (let i = 0; i < 30; i++) {
    const forged = await call(t, "/v1/session/refresh", { body: { refreshToken: `r1.k0.${session}.0.${"A".repeat(43)}` } });
    assert.equal(forged.status, 401, "a made-up token is refused");
  }
  const real = await call(t, "/v1/session/refresh", { body: { refreshToken: player.refreshToken } });
  assert.equal(real.status, 200, "the player's own refresh is not held back");
  // The bucket still holds a real token's holder: ten at once, then held.
  let token = (await real.json()).refreshToken;
  let held = null;
  for (let i = 0; i < 12 && !held; i++) {
    const r = await call(t, "/v1/session/refresh", { body: { refreshToken: token } });
    if (r.status === 429) held = i;
    else token = (await r.json()).refreshToken;
  }
  assert.equal(held, 9, "a proven session's refreshes are still limited");
});
