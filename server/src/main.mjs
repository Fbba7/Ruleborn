// Run the server locally:
//
//     node server/src/main.mjs [port] [--example]
//
// RULEBORN_DATA names the data directory (server/.data/ by default).
// --example publishes the simulation's example Heart, undefended, from an
// account of its own — seeded, as §13.1's designed islands are, so no
// new-player protection holds it back — and a client has an island to lease
// on a fresh database.
//
// The edge function (`http.mjs`) behind a plain node:http listener, with the
// database and the object store on disk under server/.data/ and the one
// simulation build this checkout compiles.
//
// Apple's proofs (stores.mjs) are checked once RULEBORN_APPLE_ROOTS names the
// pinned root certificates (PEM or DER files, comma-separated; Apple Root CA
// G3 and the CA that issues Game Center's key) and RULEBORN_BUNDLE_ID the
// app: then a Game Center identity signs in and an App Store transaction
// pays. Without them sign-in is stubbed — a credential is taken as the
// identity it names — and every receipt is refused; do not expose that to a
// network.

import { createServer } from "node:http";
import { X509Certificate, randomBytes } from "node:crypto";
import { readFileSync } from "node:fs";
import { fileURLToPath } from "node:url";
import { dirname, join } from "node:path";

import { open } from "./db.mjs";
import { handler } from "./http.mjs";
import { Service } from "./service.mjs";
import { Builds } from "./sim.mjs";
import { Store } from "./store.mjs";
import { GameCenter, appStoreTransaction } from "./stores.mjs";

const here = dirname(fileURLToPath(import.meta.url));
const root = join(here, "..", "..");
const data = process.env.RULEBORN_DATA ?? join(here, "..", ".data");

const roots = (process.env.RULEBORN_APPLE_ROOTS ?? "").split(",").filter(Boolean)
  .map((path) => new X509Certificate(readFileSync(path)));
const bundleId = process.env.RULEBORN_BUNDLE_ID ?? null;
const apple = roots.length > 0 && bundleId;
const gameCenter = apple ? new GameCenter({
  roots, bundleId,
  fetchCertificate: async (url) => Buffer.from(await (await fetch(url)).arrayBuffer()),
}) : null;

const service = new Service({
  db: open(join(data, "ruleborn.sqlite")),
  store: new Store(join(data, "bundles")),
  builds: Builds.load([join(root, "sim/target/wasm32-unknown-unknown/release/ruleborn_sim.wasm")]),
  secret: process.env.RULEBORN_SECRET ?? randomBytes(32).toString("hex"),
  verifyPlatform: apple
    ? (credential) => gameCenter.verify(credential)
    : (credential) => (typeof credential === "string" && credential ? credential : null),
  preparePlatform: apple ? (credential) => gameCenter.prepare(credential) : async () => {},
  // Google Play's proofs need Google's API, and are not wired (D67).
  verifyReceipt: apple
    ? (store, receipt) => (store === "app-store"
      ? appStoreTransaction(receipt, { roots, bundleId, now: Date.now() }) : null)
    : () => null,
  // §18.1's seasons run back to back from the first. RULEBORN_SEASON_START is
  // that moment, in ISO form; without it a fixed Monday, so a local server's
  // seasons do not move between restarts.
  seasonStart: Date.parse(process.env.RULEBORN_SEASON_START ?? "2026-01-05T00:00:00Z"),
  // §24.3's replays, private: not in the store anyone may fetch by hash.
  replays: new Store(join(data, "replays")),
});
const handle = handler(service);

// §24.8's lists are "generated periodically"; how often is not said. Every
// fifteen minutes here, and once at start.
const TARGET_LISTS_MS = 15 * 60 * 1000;
service.targetLists();
setInterval(() => service.targetLists(), TARGET_LISTS_MS).unref();

// §18.1: a season that has ended is closed — results, rewards, the pull back
// — and the next opened. Checked with the target lists; closing twice is a
// no-op, so a missed check costs nothing but a little lateness.
service.seasons.rollover();
setInterval(() => service.seasons.rollover(), TARGET_LISTS_MS).unref();

if (process.argv.includes("--example")) {
  const { account } = service.session("example:defender");
  service.db.prepare("UPDATE accounts SET seeded = 1 WHERE id = ?").run(account);
  const { bundle } = service.publish(account, service.builds.current.exampleIsland(true));
  service.targetLists();
  console.log(`example island ${bundle.slice(0, 12)} published`);
}

const port = Number(process.argv.slice(2).find((a) => /^\d+$/.test(a)) ?? 8787);
createServer(async (req, res) => {
  const chunks = [];
  for await (const chunk of req) chunks.push(chunk);
  const body = chunks.length ? Buffer.concat(chunks) : undefined;
  const request = new Request(`http://localhost${req.url}`, {
    method: req.method, headers: req.headers,
    body: req.method === "GET" || req.method === "HEAD" ? undefined : body,
  });
  const response = await handle(request);
  res.writeHead(response.status, Object.fromEntries(response.headers));
  res.end(Buffer.from(await response.arrayBuffer()));
}).listen(port, "127.0.0.1", () => {
  console.log(`ruleborn server on http://127.0.0.1:${port} (rules ${service.builds.current.rulesVersion.slice(0, 12)})`);
});

// §24.3: raw events older than 90 days are "aggregated and discarded", once a
// day; compacting twice is a no-op.
const DAY_MS = 24 * 60 * 60 * 1000;
service.telemetry.compact();
setInterval(() => service.telemetry.compact(), DAY_MS).unref();
service.expireReplays();
setInterval(() => service.expireReplays(), DAY_MS).unref();

// §14.6's notifications, sent once a minute. Push is Firebase Cloud
// Messaging (§24.1), which needs the operator's credentials; without them a
// due notification is written to the log instead (D68).
const push = (token, message) => console.log(`push ${token.slice(0, 8)}… ${JSON.stringify(message)}`);
setInterval(() => service.notifications.deliver(push), 60 * 1000).unref();
