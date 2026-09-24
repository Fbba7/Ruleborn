// A server for a test: in-memory database and store, the build this checkout
// compiled, a clock the test moves, and a random source that counts, so every
// seed and token is the same on every run.

import { existsSync } from "node:fs";
import { fileURLToPath } from "node:url";

import { open } from "../src/db.mjs";
import { handler } from "../src/http.mjs";
import { Service } from "../src/service.mjs";
import { Build, Builds } from "../src/sim.mjs";
import { Store } from "../src/store.mjs";

export const WASM = fileURLToPath(new URL(
  "../../sim/target/wasm32-unknown-unknown/release/ruleborn_sim.wasm", import.meta.url));

let build = null;
export function simulation() {
  if (!build) {
    if (!existsSync(WASM)) {
      throw new Error(`${WASM} is not built: bash sim/run_spike.sh builds it`);
    }
    build = Build.load(WASM);
  }
  return build;
}

export const T0 = Date.UTC(2026, 8, 23, 9, 0, 0);

export function server() {
  const clock = { now: T0 };
  let counter = 0;
  const random = (n) => {
    const out = Buffer.alloc(n);
    // One count a draw, and its high bits mixed in, so a test that makes
    // hundreds of accounts and plays never wraps onto an id it already used.
    counter++;
    for (let i = 0; i < n; i++) out[i] = (counter * 37 + i * 11 + (counter >> 8) * (i + 1) * 53) & 255;
    return out;
  };
  const service = new Service({
    db: open(),
    store: new Store(),
    builds: new Builds([simulation()]),
    secret: "test secret",
    verifyPlatform: (c) => (typeof c === "string" && c.startsWith("gc:") ? c : null),
    now: () => clock.now,
    random,
    seasonStart: T0,
  });
  return { service, clock, handle: handler(service), build: simulation() };
}

/** A tile's centre, as a command aims at it: 1/256 of a tile. */
export const at = (tile) => tile * 256 + 128;

/**
 * A heist planned on `Island::example_open()`: three crew walk through the
 * wall's gap to the Vault, crack it together, load full, call the skiff to the
 * south edge and leave on it. Clean, and every bag full.
 */
export function openPlan() {
  const s = (seconds) => seconds * 30;
  return [
    { tick: s(0), member: 0, kind: "MoveTo", x: at(6), y: at(8) },
    { tick: s(0), member: 1, kind: "MoveTo", x: at(7), y: at(9) },
    { tick: s(0), member: 2, kind: "MoveTo", x: at(5), y: at(9) },
    { tick: s(15), member: 0, kind: "Crack", x: 0, y: 0 },
    { tick: s(15), member: 1, kind: "Crack", x: 0, y: 0 },
    { tick: s(15), member: 2, kind: "Crack", x: 0, y: 0 },
    { tick: s(50), member: 0, kind: "Load", x: 100, y: 0 },
    { tick: s(50), member: 0, kind: "Skiff", x: at(6), y: at(11) },
    { tick: s(50), member: 1, kind: "Load", x: 100, y: 0 },
    { tick: s(50), member: 2, kind: "Load", x: 100, y: 0 },
    { tick: s(62), member: 0, kind: "MoveTo", x: at(6), y: at(11) },
    { tick: s(62), member: 1, kind: "MoveTo", x: at(6), y: at(11) },
    { tick: s(62), member: 2, kind: "MoveTo", x: at(6), y: at(11) },
  ];
}

/** A player past §12.3's first 72 hours, so their island can be raided:
 *  the tests that are not about that protection start from here. */
export function established(t, account) {
  t.service.db.prepare("UPDATE accounts SET created_at = ? WHERE id = ?")
    .run(t.clock.now - 72 * 60 * 60 * 1000, account);
}

/** Two players, a defender with a published island and a raider. */
export function twoPlayers(open = true) {
  const t = server();
  const defender = t.service.session("gc:defender");
  established(t, defender.account);
  const raider = t.service.session("gc:raider");
  const island = t.build.exampleIsland(open);
  const { bundle } = t.service.publish(defender.account, island);
  return { ...t, defender, raider, island, bundle };
}

/** Play a lease as the device would, with `plan` or the drawn test player. */
export function play(t, lease, { plan = null, crew = 3 } = {}) {
  const island = t.service.bundle(lease.bundle);
  const spec = { seed: BigInt(lease.seed), ticks: lease.ticks, crew };
  return plan ? t.build.record(island, { ...spec, commands: plan })
              : t.build.recordDrawn(island, spec);
}
