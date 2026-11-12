// The Island Workshop (§18.6, §18.7, §20.4, §20.7, §20.12), end to end,
// against the real simulation build.

import assert from "node:assert/strict";
import { test } from "node:test";

import { Refused, clockTicks } from "../src/service.mjs";
import { BUILDER_SLOTS, SLOTS, SPIKE_MIN, WORDS, Workshop } from "../src/workshop.mjs";
import { T0, counting, established, openPlan, server } from "./setup.mjs";

const refusal = (fn, reason) => assert.throws(fn, (e) => e instanceof Refused && e.reason === reason);
const HOUR = 60 * 60 * 1000;

/** A server with a Workshop and the open example Heart to publish. */
function workshop() {
  const t = server();
  const w = new Workshop(t.service);
  const island = t.build.exampleIsland(true);
  // The creator's clear: the planned heist on the open Heart, Clean.
  const cleared = t.build.record(island, { seed: 7n, ticks: clockTicks(0), crew: 3, commands: openPlan() });
  const name = { adjective: 1, noun: 9 };
  return { ...t, w, island, cleared, name };
}

/** Play an item as the device would: the planned clear, on the play's seed. */
function clear(t, player, id) {
  const p = t.w.play(player, id);
  const replay = t.build.record(t.service.bundle(p.bundle),
    { seed: BigInt(p.seed), ticks: p.ticks, crew: 3, commands: openPlan() });
  return t.w.submitPlay(player, p.token, replay);
}

const moderator = (t, account) =>
  t.service.db.prepare("UPDATE accounts SET moderator = 1 WHERE id = ?").run(account);

test("an island reaches the Workshop only once its creator has cleared it (18.6)", () => {
  const t = workshop();
  const me = t.service.session("gc:creator").account;
  const idle = t.build.recordDrawn(t.island, { seed: 7n, ticks: clockTicks(0), crew: 3 });
  assert.throws(() => t.w.publish(me, t.island, idle, t.name),
    (e) => e.reason === "not_cleared", "a heist that banks nothing clears nothing");
  const other = t.build.record(t.build.exampleIsland(false),
    { seed: 7n, ticks: clockTicks(0), crew: 3, commands: openPlan() });
  assert.throws(() => t.w.publish(me, t.island, other, t.name),
    (e) => e.reason === "not_cleared" && e.detail.why === "wrong_island");
  refusal(() => t.w.publish(me, t.island, t.cleared, { adjective: 99, noun: 0 }),
          "name_not_from_the_word_lists");
  const item = t.w.publish(me, t.island, t.cleared, t.name);
  assert.deepEqual(item.name, { en: "Hidden Isle", en_US: "Hidden Isle", pt_BR: "Ilha Oculta",
                                pt_PT: "Ilha Oculta", de: "Verborgene Insel", fr: "Île Cachée" },
                   "a name from the word lists, in each of the game's languages, agreeing in gender");
  const harbour = Workshop.name(1, WORDS.nouns.findIndex((n) => n.en === "Harbour"));
  assert.equal(harbour.en_US, "Hidden Harbor", "US spelling");
  assert.equal(harbour.de, "Verborgener Hafen", "a masculine noun takes the masculine ending");
  assert.equal(item.creator, me);
  assert.deepEqual(t.service.bundle(item.bundle), t.island);
});

test("a creator holds five islands, eight once a Builder, and a withdrawn one frees its slot (20.12, 18.7)", () => {
  const t = workshop();
  const me = t.service.session("gc:creator").account;
  const items = [];
  for (let i = 0; i < SLOTS; i++) items.push(t.w.publish(me, t.island, t.cleared, t.name));
  refusal(() => t.w.publish(me, t.island, t.cleared, t.name), "no_free_slot");
  t.w.withdraw(me, items[0].id);
  t.w.publish(me, t.island, t.cleared, t.name);
  assert.equal(t.w.mine(me).length, SLOTS + 1, "withdrawn, never deleted");
  // "Publishing an island anyone completes" makes a Builder: three more.
  // The completion is from a player who counts (SEC-26).
  const player = t.service.session("gc:player").account;
  counting(t, player);
  clear(t, player, items[1].id);
  assert.equal(t.w.ladder(me).level, "builder");
  for (let i = 0; i < BUILDER_SLOTS; i++) t.w.publish(me, t.island, t.cleared, t.name);
  refusal(() => t.w.publish(me, t.island, t.cleared, t.name), "no_free_slot");
});

test("a completion counts once a player, never the creator's own, and climbs the ladder (18.7)", () => {
  const t = workshop();
  const me = t.service.session("gc:creator").account;
  const { id } = t.w.publish(me, t.island, t.cleared, t.name);
  const player = t.service.session("gc:player").account;
  counting(t, player);                  // SEC-26: a player whose completion counts
  const first = clear(t, player, id);
  assert.equal(first.validated, true);
  assert.equal(first.cleared, true);
  assert.equal(first.counted, true);
  assert.equal(clear(t, player, id).counted, false, "the same player counts once");
  assert.equal(clear(t, me, id).counted, undefined, "the creator's own clear is not a completion");
  assert.equal(t.w.view(t.w.row(id)).completions, 1);
  assert.deepEqual(t.w.ladder(me), { level: "builder", completions: 1, featured: 0 });
  // A play is keyed by its token, like a heist: a retry is answered, not re-counted.
  const p = t.w.play(player, id);
  const replay = t.build.record(t.service.bundle(p.bundle),
    { seed: BigInt(p.seed), ticks: p.ticks, crew: 3, commands: openPlan() });
  t.w.submitPlay(player, p.token, replay);
  assert.equal(t.w.submitPlay(player, p.token, replay).repeated, true);
  const wrong = t.w.play(player, id);
  assert.equal(t.w.submitPlay(player, wrong.token, replay).reason, "wrong_seed");
});

test("a player aged 13 to 15 browses the curated list only (20.7)", () => {
  const t = workshop();
  const me = t.service.session("gc:creator").account;
  const { id } = t.w.publish(me, t.island, t.cleared, t.name);
  const young = t.service.session("gc:young").account;
  t.w.setAgeBand(young, "13-15");
  refusal(() => t.w.browse(young, "top"), "curated_lists_only");
  assert.deepEqual(t.w.browse(young, "featured"), []);
  const person = t.service.session("gc:moderator").account;
  moderator(t, person);
  t.w.feature(person, id);
  assert.deepEqual(t.w.browse(young, "featured").map((i) => i.id), [id]);
  assert.equal(t.w.ladder(me).level, "architect", "one island featured in the spotlight");
  assert.deepEqual(t.w.browse(me, "top").map((i) => i.id), [id], "older players see every list");
});

test("islands are rated for fun, cleverness and fairness by those who played them (18.6)", () => {
  const t = workshop();
  const me = t.service.session("gc:creator").account;
  const { id } = t.w.publish(me, t.island, t.cleared, t.name);
  const player = t.service.session("gc:player").account;
  counting(t, player);                  // SEC-26: a player whose rating counts
  const score = { fun: 5, cleverness: 4, fairness: 3 };
  refusal(() => t.w.rate(player, id, score), "not_played");
  clear(t, player, id);
  refusal(() => t.w.rate(player, id, { fun: 6, cleverness: 4, fairness: 3 }), "ratings_are_one_to_five");
  assert.deepEqual(t.w.rate(player, id, score), { count: 1, ...score });
  refusal(() => t.w.rate(me, id, score), "own_island");
});

test("reports wait for a person, a removal gives its reason, and a ban takes everything out (20.4, 20.12)", () => {
  const t = workshop();
  const me = t.service.session("gc:creator").account;
  established(t, me);
  const { bundle: realm } = t.service.publish(me, t.build.exampleIsland(false));
  const a = t.w.publish(me, t.island, t.cleared, t.name);
  const b = t.w.publish(me, t.island, t.cleared, { adjective: 2, noun: 3 });
  const player = t.service.session("gc:player").account;
  const person = t.service.session("gc:moderator").account;
  refusal(() => t.w.report(player, a.id, "boring"), "no_such_reason");
  const { report } = t.w.report(player, a.id, "unfair");
  assert.equal(t.w.report(player, a.id, "unfair").repeated, true, "one open report a player");
  refusal(() => t.w.queue(player), "not_a_moderator");
  moderator(t, person);
  t.clock.now = T0 + 25 * HOUR;
  assert.deepEqual(t.w.queue(person).map((r) => [r.item, r.overdue]), [[a.id, true]],
                   "past 24 hours, marked overdue");
  refusal(() => t.w.resolve(person, report, "remove"), "a_reason_is_owed");
  t.w.resolve(person, report, "remove", "unfair");
  assert.deepEqual(t.w.browse(player, "top").map((i) => i.id), [b.id]);
  assert.deepEqual(t.w.mine(me).find((i) => i.id === a.id).removed.reason, "unfair",
                   "the creator is told why");
  assert.deepEqual(t.w.queue(person), []);
  // A ban: the account's islands leave the Workshop and matchmaking at once.
  assert.ok(Object.keys(t.service.targetLists()).length > 0);
  const second = t.w.report(player, b.id, "offensive").report;
  t.w.resolve(person, second, "ban", "offensive");
  assert.deepEqual(t.w.browse(player, "top"), []);
  assert.deepEqual(t.service.targetLists(), {}, "no longer a target");
  refusal(() => t.service.lease(player, realm), "superseded");
  refusal(() => t.service.session("gc:creator"), "banned");
});

test("remixing hands over the island, and publishing the remix names the original (25.1)", () => {
  const t = workshop();
  const me = t.service.session("gc:creator").account;
  const original = t.w.publish(me, t.island, t.cleared, t.name);
  const player = t.service.session("gc:player").account;
  const draft = t.w.remix(player, original.id);
  assert.deepEqual(draft, t.island, "the island itself, to open in a builder");
  assert.throws(() => t.w.publish(player, draft, t.cleared, { adjective: 4, noun: 0, remixOf: original.id }),
                (e) => e.status === 409 && e.reason === "remix_unchanged", "a remix that changes nothing (SEC-41)");
  const changed = Uint8Array.from(draft);
  changed[6] = (changed[6] + 1) & 0xff;                  // the loot exposed
  const remix = t.w.publish(player, changed,
    t.build.record(changed, { seed: 7n, ticks: clockTicks(0), crew: 3, commands: openPlan() }),
    { adjective: 4, noun: 0, remixOf: original.id });
  assert.equal(remix.remixOf, original.id);
  assert.equal(remix.creator, player, "a remix is its remixer's own island, cleared by them");
  assert.equal(t.w.view(t.w.row(original.id)).remixes, 1);
});

test("a Workshop island is never edited or deleted (18.6)", () => {
  const t = workshop();
  const me = t.service.session("gc:creator").account;
  const { id } = t.w.publish(me, t.island, t.cleared, t.name);
  assert.throws(() => t.service.db.prepare("UPDATE workshop_items SET bundle = 'x' WHERE id = ?").run(id),
                /never edited/);
  assert.throws(() => t.service.db.prepare("DELETE FROM workshop_items WHERE id = ?").run(id),
                /never deleted/);
});

test("a sudden spike in completions is flagged for a person to review (18.7)", () => {
  const t = workshop();
  const me = t.service.session("gc:creator").account;
  const { id } = t.w.publish(me, t.island, t.cleared, t.name);
  const person = t.service.session("gc:moderator").account;
  moderator(t, person);
  for (let i = 0; i < SPIKE_MIN; i++) {
    const player = t.service.session(`gc:player${i}`).account;
    assert.equal(clear(t, player, id).counted, true);
  }
  assert.equal(t.w.row(id).review, 1);
  const queue = t.w.queue(person);
  assert.deepEqual(queue.map((r) => [r.item, r.reason, r.server]), [[id, "completion_spike", true]]);
  t.w.resolve(person, queue[0].report, "dismiss");
  assert.equal(t.w.row(id).review, 0, "a person looked and let it stand");
});

test("a Workshop play is a lease of one day: expireLapsed deletes the unsubmitted ones, never a submitted one (B7)", () => {
  const t = workshop();
  const db = t.service.db;
  const me = t.service.session("gc:creator").account;
  db.prepare(`INSERT INTO workshop_items (id, creator, bundle, realm_level, name_adjective, name_noun, cleared_by,
                                          bytes, published_at) VALUES ('i', ?, 'b', 3, 0, 0, 'r', 1, ?)`)
    .run(me, t.clock.now);
  const issued = t.clock.now;
  const add = (token, submitted) => db.prepare(
    `INSERT INTO workshop_plays (token, player, item, seed, ticks, issued_at, submitted_at, outcome)
     VALUES (?, ?, 'i', '1', 1, ?, ?, ?)`).run(token, me, issued, submitted ? issued : null, submitted ? "{}" : null);
  add("open", false);
  add("done", true);
  const left = () => db.prepare("SELECT token FROM workshop_plays ORDER BY token").all().map((r) => r.token);
  t.clock.now = issued + 24 * HOUR;
  assert.deepEqual(t.service.expireLapsed(), { intents: 0, leases: 0, plays: 0 }, "inside its day, kept");
  t.clock.now += 1;
  assert.equal(t.service.expireLapsed().plays, 1);
  assert.deepEqual(left(), ["done"], "the submitted play is a record");
  assert.equal(t.service.expireLapsed().plays, 0, "once");
});
