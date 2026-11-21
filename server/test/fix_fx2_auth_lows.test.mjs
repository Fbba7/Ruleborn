// FX2-5-auth-lows: RB-23, RB-24, RB-25, RB-26 and RB-60 of
// docs/security/bug-report-2026-11.md, and the report's unproven
// candidate 23. Each test reproduces its entry's Input.

import assert from "node:assert/strict";
import { test } from "node:test";

import { SEASON_MS } from "../src/seasons.mjs";
import { Social } from "../src/social.mjs";
import { openPlan, play, server, twoPlayers } from "./setup.mjs";

const HOUR = 60 * 60 * 1000;
const DAY = 24 * HOUR;

const post = (t, path, { token, body } = {}) => t.handle(new Request(`https://edge.example${path}`, {
  method: "POST",
  headers: { "content-type": "application/json", ...(token ? { authorization: `Bearer ${token}` } : {}) },
  body: JSON.stringify(body ?? {}) }));

// RB-23: with RULEBORN_REFRESH_ROTATE_HOURS=720, the most the setting
// accepts, a refresh inside the span writes nothing, so a device refreshing
// every hour still looked unused since its sign-in, and at hour 720.5 the
// idle lapse ("30 days after its last use") signed it out.
test("RB-23: a device refreshing every hour stays signed in with a 720-hour rotation span", () => {
  const t = server({ refreshRotateMs: 720 * HOUR });
  const s = t.service.session("gc:rb23");
  let token = s.refreshToken;
  t.clock.now += HOUR / 2;
  for (let n = 1; n <= 722; n++) {
    let r = null;
    try { r = t.service.auth.refresh(token, t.clock.now, { place: "PT" }); } catch (err) { r = err.reason; }
    assert.ok(r?.refreshToken, `refresh #${n} at ${n - 0.5} h refused: ${r}`);
    token = r.refreshToken;
    t.clock.now += HOUR;
  }
  assert.equal(t.service.auth.live(s.account), 1, "the device is still listed");
});

// RB-24: "sign out everywhere" with a refresh token whose session lapsed
// (unused past the idle limit) ended every other device, though `refresh`
// refuses that same token.
test("RB-24: a lapsed session's refresh token does not sign out everywhere", async () => {
  const t = server();
  const a = await (await post(t, "/v1/session", { body: { credential: "gc:rb24" } })).json();
  let b = await (await post(t, "/v1/session", { body: { credential: "gc:rb24" } })).json();
  for (let day = 0; day < 35; day += 7) {
    t.clock.now += 7 * DAY;
    b = await (await post(t, "/v1/session/refresh", { body: { refreshToken: b.refreshToken } })).json();
    assert.ok(b.refreshToken, `session B refreshed on day ${day + 7}`);
  }
  const lapsed = await post(t, "/v1/session/refresh", { body: { refreshToken: a.refreshToken } });
  assert.equal(lapsed.status, 401, "refresh refuses A, unused 35 days");
  const r = await post(t, "/v1/session/end", { body: { everywhere: true, refreshToken: a.refreshToken } });
  assert.equal(r.status, 401, "the same answer refresh gives for A");
  const still = await post(t, "/v1/session/refresh", { body: { refreshToken: b.refreshToken } });
  assert.equal(still.status, 200, "session B is still signed in");
});

// RB-25: the replay manifest's form byte was not compared with the
// character's form, so a replay could show a form the raider never earned.
test("RB-25: a manifest member's form must be the character's", () => {
  const t = twoPlayers(true);
  const me = t.raider.account;
  const crew = t.service.home.show(me).characters.slice(0, 3);
  assert.ok(crew.every((c) => c.wire), "the roster carries each member as the manifest writes it");
  // Member 0 claims a form it does not have; the others are as they are.
  const manifest = { members: crew.map((c, i) => ({ ...c.wire, form: i ? c.wire.form : (c.wire.form === 2 ? 1 : 2) })),
                     sage: 0, casts: [] };
  const lease = t.service.lease(me, t.bundle);
  const replay = play(t, lease, { plan: openPlan(), manifest });
  assert.equal(t.service.submit(me, lease.token, replay, crew.map((c) => c.id)).reason, "crew_mismatch");
  // The crew's own forms still pass.
  const honest = { ...manifest, members: crew.map((c) => ({ ...c.wire })) };
  const fair = t.service.lease(me, t.bundle);
  const out = t.service.submit(me, fair.token, play(t, fair, { plan: openPlan(), manifest: honest }),
                               crew.map((c) => c.id));
  assert.equal(out.reason, undefined, "the crew's own forms are accepted");
  assert.ok(out.validated);
});

// RB-26: POST /v1/constellations/<id>/roles ignored the id and acted on the
// founder's own constellation.
test("RB-26: the roles route acts only on the constellation its URL names", async () => {
  const t = server();
  const social = new Social(t.service);
  const [founder, member, other] = ["gc:rb26-f", "gc:rb26-m", "gc:rb26-o"].map((c) => t.service.session(c));
  t.service.db.prepare("UPDATE accounts SET keeper_level = 6").run();
  const mine = social.found(founder.account, { adjective: 1, noun: 1 });
  const theirs = social.found(other.account, { adjective: 2, noun: 3 });
  social.join(member.account, mine.id);
  const role = () => social.membership(member.account).role;
  assert.equal(role(), "member");
  const r = await post(t, `/v1/constellations/${theirs.id}/roles`,
                       { token: founder.token, body: { account: member.account, role: "elder" } });
  assert.ok([403, 404].includes(r.status), `a wrong id answers ${r.status}`);
  assert.equal(role(), "member", "the founder's own constellation is unchanged");
  const ok = await post(t, `/v1/constellations/${mine.id}/roles`,
                        { token: founder.token, body: { account: member.account, role: "elder" } });
  assert.equal(ok.status, 200, "the right id still appoints");
  assert.equal(role(), "elder");
});

// RB-60: the public privacy policy showed references `plain` left behind.
test("RB-60: the privacy policy shows no leftover reference text", async () => {
  const t = server();
  const r = await t.handle(new Request("https://edge.example/privacy"));
  assert.equal(r.status, 200);
  const page = await r.text();
  for (const leftover of ["(to, )", "(SEC-18)", "(SEC-29)", "(to )", "( )", "()"]) {
    assert.ok(!page.includes(leftover), `the page shows ${JSON.stringify(leftover)}`);
  }
  assert.ok(!/\((?:to|and)[,\s]*\)/.test(page), "no reference join word left alone in parentheses");
  // The prose's own parentheses stay.
  for (const kept of ["(ISO 3166"]) assert.ok(page.includes(kept), `the page keeps ${JSON.stringify(kept)}`);
});

// Candidate 23: the season track's tier price is fixed the first time a
// player appears in a season, scaled to the time it has left (G28). Another
// player viewing their profile opened their standing, so it fixed the price
// early for them.
test("candidate 23: viewing another player's profile does not fix their tier price", () => {
  const price = (viewed) => {
    const t = server();
    const a = t.service.session("gc:c23-a").account;
    const b = t.service.session("gc:c23-b").account;
    t.service.db.prepare("UPDATE accounts SET profile_public = 1").run();
    const season = t.service.seasons.current().id;
    if (viewed) {
      t.service.profile.show(a, b);
      assert.equal(t.service.db.prepare("SELECT COUNT(*) AS n FROM standings WHERE account = ?").get(b).n, 0,
                   "the view wrote no standing for the viewed player");
    }
    t.clock.now += SEASON_MS / 2;
    t.service.profile.show(b, b);
    return t.service.track.tierStars(b, season);
  };
  assert.equal(price(true), price(false), "the price is the one the player's own first appearance sets");
});
