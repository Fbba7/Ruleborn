// Security review findings in sign-in and session code, which the auth work
// (T11) owns: each test pins the behaviour as it stands, so it passes, and
// the fix turns its assertion round (docs/security/review.md, "Sent to T11").
// SR-11 is fixed on T11's branch (11a8e3c), with its test there
// (auth_http.test.mjs), so its pin here is gone.

import assert from "node:assert/strict";
import { X509Certificate, createPrivateKey, createSign } from "node:crypto";
import { readFileSync } from "node:fs";
import { test } from "node:test";

import { GAME_CENTER_CACHE, GameCenter } from "../src/stores.mjs";

// SR-20: Game Center's keys are fetched at most one new URL a second, the
// server's whole, into a cache of GAME_CENTER_CACHE. The names are Apple's
// own (gc-prod-N), so every one a caller names that Apple serves is kept and
// pushes out the key in use; the next real sign-in then waits for the one
// fetch a second the same caller keeps taking.
test("SR-20 (sent to T11): a caller cycling through Apple's key names pushes out the key in use, and holds the one fetch a second", async () => {
  const fixture = (name) => readFileSync(new URL(`./fixtures/apple/${name}`, import.meta.url));
  const cert = (name) => new X509Certificate(fixture(`${name}.pem`));
  const [ROOT, INTERMEDIATE, GAMECENTER] = [cert("root"), cert("intermediate"), cert("gamecenter")];
  const BUNDLE = "com.example.ruleborn";
  const URL_ = "https://static.gc.apple.com/public-key/gc-prod-6.cer";
  const clock = { now: Date.parse(ROOT.validFrom) + 24 * 60 * 60 * 1000 };
  // Apple serving a certificate at each of its names, as it does for the keys it has used.
  const gc = new GameCenter({ roots: [INTERMEDIATE, ROOT], bundleId: BUNDLE, now: () => clock.now,
                              fetchCertificate: async () => GAMECENTER.raw });
  const identity = () => {
    const salt = Buffer.from("0123456789abcdef");
    const stamp = Buffer.alloc(8);
    stamp.writeBigUInt64BE(BigInt(clock.now));
    const signer = createSign("RSA-SHA256");
    signer.update(Buffer.concat([Buffer.from("T:_player1"), Buffer.from(BUNDLE), stamp, salt]));
    return { playerId: "T:_player1", bundleId: BUNDLE, timestamp: clock.now, publicKeyUrl: URL_,
             salt: salt.toString("base64"), signature: signer.sign(createPrivateKey(fixture("gamecenter.key"))).toString("base64") };
  };
  await gc.prepare(identity());
  assert.equal(gc.verify(identity()), "gc:T:_player1");
  for (let i = 1; i <= GAME_CENTER_CACHE; i++) {
    clock.now += 1000;
    await gc.prepare({ publicKeyUrl: `https://static.gc.apple.com/public-key/gc-prod-${10 + i}.cer` });
  }
  clock.now += 1000;
  await gc.prepare({ publicKeyUrl: "https://static.gc.apple.com/public-key/gc-prod-99.cer" });
  await gc.prepare(identity());
  assert.equal(gc.verify(identity()), null, "the player's sign-in fails while the caller keeps it up");
});
