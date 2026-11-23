// FX2-6's audit, sign-in and deletion (docs/security/audit-2026-11/server-b.md).

import assert from "node:assert/strict";
import { test } from "node:test";

import { DELETE_COOKIE } from "../src/auth_http.mjs";
import { rotateHoursOf } from "../src/auth.mjs";
import { handler } from "../src/http.mjs";
import { GAME_CENTER_FRESH_MS } from "../src/stores.mjs";
import { keyring } from "../src/tokens.mjs";
import { NOW, WEB, gc, real } from "./auth_fixtures.mjs";
import { stillOpen } from "./fix_fx2_open.mjs";

async function page(handle) {
  const res = await handle(new Request("https://edge.example/account/delete"));
  const html = await res.text();
  const nonce = /data-nonce="([^"]+)"/.exec(html)[1];
  const set = res.headers.get("set-cookie");
  return { nonce, cookie: `${DELETE_COOKIE}=${/=([^;]+)/.exec(set)[1]}` };
}
const remove = (handle, { idToken, cookie }) =>
  handle(new Request("https://edge.example/v1/account/delete", {
    method: "POST",
    headers: { "content-type": "application/json", origin: "https://edge.example", "sec-fetch-site": "same-origin",
               ...(cookie ? { cookie } : {}) },
    body: JSON.stringify({ idToken, withdrawIslands: false }) }));

// AUD-B-05: open. The page's nonce is fixed (web/delete.html's data-nonce),
// and the first try spends it, so the right account's retry is refused.
test("AUD-B-05: after a wrong Google account (404), the right one on the same page can still delete", async () => {
  await stillOpen("AUD-B-05", async () => {
    const r = real();
    const handle = handler(r.t.service, { webClientId: WEB });
    const me = await r.signIn({ idToken: r.idToken({ nonce: r.t.service.auth.nonce().nonce }) });
    const p = await page(handle);
    const wrong = await remove(handle, { idToken: r.idToken({ aud: WEB, nonce: p.nonce, sub: "999999999999" }),
                                         cookie: p.cookie });
    assert.equal(wrong.status, 404, "the wrong account has no Ruleborn account");
    const right = await remove(handle, { idToken: r.idToken({ aud: WEB, nonce: p.nonce }), cookie: p.cookie });
    assert.equal(right.status, 200, "the retry with the right account deletes it");
    assert.throws(() => r.t.service.account(me.token));
  });
});

// AUD-B-08: with no web client id, the audience check is skipped
// (auth_proofs.mjs), so the route must not run at all.
test("AUD-B-08: with no web client configured, POST /v1/account/delete deletes nothing", async () => {
  const r = real();
  const handle = handler(r.t.service, {});
  assert.equal((await handle(new Request("https://edge.example/account/delete"))).status, 503);
  const me = await r.signIn({ idToken: r.idToken({ nonce: r.t.service.auth.nonce().nonce }) });
  // A nonce any client can ask for, and the game's own (Android client) token carrying it.
  const { nonce } = r.t.service.auth.nonce();
  const res = await remove(handle, { idToken: r.idToken({ nonce }), cookie: `${DELETE_COOKIE}=${nonce}` });
  assert.equal(res.status, 503, "the game's token reached the web deletion");
  assert.equal(r.t.service.account(me.token), me.account);
});

// AUD-B-09: stores.mjs takes a proof while |now - timestamp| <= 5 min, and the
// spent key must hold through that last millisecond.
test("AUD-B-09: a Game Center proof replayed at the last millisecond of its window is refused", async () => {
  const r = real();
  const credential = gc({ timestamp: NOW });
  r.clock.now = NOW + GAME_CENTER_FRESH_MS - 1000;
  await r.signIn(credential);
  r.clock.now = NOW + GAME_CENTER_FRESH_MS - 1;
  await assert.rejects(r.signIn(credential), "control: a millisecond earlier the replay is refused");
  r.clock.now = NOW + GAME_CENTER_FRESH_MS;
  await assert.rejects(r.signIn(credential), "the replay at the window's last millisecond signed in");
});

// AUD-B-10: open. tokens.mjs reads `keys[kid]` on a plain object, so a kid
// that names an Object.prototype member is taken for a key already given.
test("AUD-B-10: a token key may be named constructor (letters and digits, the kid's own rule)", async () => {
  await stillOpen("AUD-B-10", () => {
    let ring = null;
    try {
      ring = keyring("x", `constructor:${"a".repeat(32)}`);
    } catch (e) {
      assert.fail(`the key is refused: ${e.message}`);
    }
    assert.equal(ring.current, "constructor");
  });
});

// AUD-B-11: an empty variable is an unset one, not zero hours.
test("AUD-B-11: an empty RULEBORN_REFRESH_ROTATE_HOURS is unset (24 hours), never 0", () => {
  assert.equal(rotateHoursOf({ RULEBORN_REFRESH_ROTATE_HOURS: "" }), 24);
  assert.equal(rotateHoursOf({ RULEBORN_REFRESH_ROTATE_HOURS: "" }, { example: true }), 0);
  assert.equal(rotateHoursOf({ RULEBORN_REFRESH_ROTATE_HOURS: "0" }), 0);
});
