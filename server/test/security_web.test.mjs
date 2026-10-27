// Security review findings on the server's web pages and what every answer
// carries (docs/security/review.md).

import assert from "node:assert/strict";
import { createHash } from "node:crypto";
import { readFileSync } from "node:fs";
import { test } from "node:test";

import { handler } from "../src/http.mjs";
import { server } from "./setup.mjs";

const DELETE_PAGE = readFileSync(new URL("../web/delete.html", import.meta.url), "utf8");
const hash = (s) => `'sha256-${createHash("sha256").update(s).digest("base64")}'`;
const directive = (csp, name) => (csp ?? "").split(";").map((d) => d.trim()).find((d) => d.startsWith(`${name} `));

// SR-04: the pages the stores link to and G39's deletion page were served
// with no Content-Security-Policy, nosniff or referrer policy, and the API's
// answers without nosniff.
test("SR-04: every page carries a CSP that runs nothing but its own, and no answer is sniffed", async () => {
  const t = server();
  const h = handler(t.service, { webClientId: "web.apps.googleusercontent.com",
                                 contact: { name: "Operator", email: "op@example.com" } });
  for (const path of ["/terms", "/privacy", "/support"]) {
    const r = await h(new Request(`https://edge.example${path}`));
    assert.equal(r.status, 200, path);
    const csp = r.headers.get("content-security-policy");
    assert.equal(directive(csp, "default-src"), "default-src 'none'", path);
    assert.equal(directive(csp, "frame-ancestors"), "frame-ancestors 'none'", path);
    assert.match(directive(csp, "style-src"), /^style-src 'sha256-[^']+'$/, `${path}: its own style, by hash`);
    assert.equal(directive(csp, "script-src"), undefined, `${path} runs no script`);
    assert.equal(r.headers.get("x-content-type-options"), "nosniff");
    assert.equal(r.headers.get("referrer-policy"), "no-referrer");
  }

  const del = await h(new Request("https://edge.example/account/delete"));
  assert.equal(del.status, 200);
  const csp = del.headers.get("content-security-policy");
  const inline = /<script>([\s\S]*?)<\/script>/.exec(DELETE_PAGE)[1];
  assert.equal(directive(csp, "script-src"),
               `script-src ${hash(inline)} https://accounts.google.com/gsi/client`,
               "the page's own script by its hash, and Google's sign-in, nothing else");
  assert.equal(directive(csp, "frame-ancestors"), "frame-ancestors 'none'");
  assert.equal(directive(csp, "connect-src"), "connect-src 'self' https://accounts.google.com/gsi/");
  assert.equal(del.headers.get("x-frame-options"), "DENY");

  const api = await h(new Request("https://edge.example/v1/words"));
  assert.equal(api.headers.get("x-content-type-options"), "nosniff");
  const missing = await h(new Request("https://edge.example/v1/bundles/00"));
  assert.equal(missing.headers.get("x-content-type-options"), "nosniff");
});

// SR-05: §17.8's block — "you disappear from theirs" — held everywhere but
// the profile: a blocked player still read the blocker's open profile.
test("SR-05: a profile is no account at all across a block, either way", async () => {
  const t = server();
  const a = t.service.session("gc:a");
  const b = t.service.session("gc:b");
  t.service.profile.share(a.account, true);
  t.service.profile.share(b.account, true);
  const show = async (viewer, account) => (await t.handle(new Request(`https://edge.example/v1/profile/${account}`,
    { headers: { authorization: `Bearer ${viewer.token}` } }))).status;
  assert.equal(await show(b, a.account), 200, "open, before any block");
  t.service.safety.block(a.account, b.account);
  assert.equal(await show(b, a.account), 404, "the blocked player no longer finds the blocker");
  assert.equal(await show(a, b.account), 404, "nor the blocker the blocked");
  t.service.safety.unblock(a.account, b.account);
  assert.equal(await show(b, a.account), 200);
});
