// Security review SR-01 (docs/security/review.md): §20.1's age band only
// tightens after the first answer. Before the fix any signed-in player could
// send PUT /v1/age {"band": "18+"} at any time and shed every §20.2 and §20.7
// protection: the €25 cap, the quiet night, curated Workshop lists.

import assert from "node:assert/strict";
import { test } from "node:test";

import { server } from "./setup.mjs";

const call = (t, method, path, { token, json } = {}) => t.handle(new Request(`https://edge.example${path}`, {
  method,
  headers: { ...(token ? { authorization: `Bearer ${token}` } : {}), "content-type": "application/json" },
  body: json ? JSON.stringify(json) : undefined,
}));

const band = (t, account) => t.service.db.prepare("SELECT age_band FROM accounts WHERE id = ?").get(account).age_band;

test("SR-01: after the first answer a looser age band is refused, a tighter one taken", async () => {
  const t = server({ firstBand: "13-15" });
  const minor = t.service.session("gc:minor");
  // The first answer sets the band, whatever it is.
  assert.equal((await call(t, "PUT", "/v1/age", { token: minor.token, json: { band: "13-15" } })).status, 200);
  for (const looser of ["16-17", "18+"]) {
    const res = await call(t, "PUT", "/v1/age", { token: minor.token, json: { band: looser } });
    assert.equal(res.status, 403, `13-15 to ${looser} is a loosening`);
    assert.deepEqual(await res.json(), { error: "age_band_only_tightens", ageBand: "13-15" });
  }
  assert.equal(band(t, minor.account), "13-15");
  // The same answer again is no loosening.
  assert.equal((await call(t, "PUT", "/v1/age", { token: minor.token, json: { band: "13-15" } })).status, 200);
  // And the protections it sheds stay: the Workshop's open lists.
  const browse = await call(t, "GET", "/v1/workshop?list=new", { token: minor.token });
  assert.equal(browse.status, 403);

  const adult = t.service.session("gc:adult");
  assert.equal((await call(t, "PUT", "/v1/age", { token: adult.token, json: { band: "18+" } })).status, 200);
  assert.equal((await call(t, "PUT", "/v1/age", { token: adult.token, json: { band: "16-17" } })).status, 200,
               "a tighter band is always taken");
  assert.equal((await call(t, "PUT", "/v1/age", { token: adult.token, json: { band: "18+" } })).status, 403);
  assert.equal(band(t, adult.account), "16-17");
});
