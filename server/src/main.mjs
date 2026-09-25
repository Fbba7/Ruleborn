// Run the server locally:
//
//     node server/src/main.mjs [port] [--example]
//
// RULEBORN_DATA names the data directory (server/.data/ by default).
// RULEBORN_SECRET is the key session tokens are signed with and telemetry's
// pseudonyms are made under; unset, one is made on the first start and kept
// in the data directory, so a restart neither signs everyone out nor orphans
// a player's telemetry from their deletion. RULEBORN_DELETIONS names the
// deletion journal (accounts.mjs), which must live where a restore of the
// database does not reach: every deletion in it is made again at start.
// --example publishes the simulation's example Heart, undefended, from an
// account of its own — seeded, as §13.1's designed islands are, so no
// new-player protection holds it back — and a client has an island to lease
// on a fresh database.
//
// The edge function (`http.mjs`) behind a plain node:http listener, with the
// database and the object store on disk under server/.data/ and the one
// simulation build this checkout compiles.
//
// Apple's proofs (stores.mjs) are checked against pinned certificates (PEM or
// DER files, comma-separated), each proof its own: RULEBORN_GAMECENTER_ROOTS
// names the CA that issues Game Center's key, RULEBORN_STOREKIT_ROOTS Apple
// Root CA G3, and RULEBORN_BUNDLE_ID the app. With the first a Game Center
// identity signs in; with the second an App Store transaction pays — from
// Production only, unless RULEBORN_APPLE_SANDBOX=1 lets Sandbox's free test
// purchases pay too, as a test deployment may. Without Game Center's roots
// sign-in is stubbed — a credential is taken as the identity it names — and
// without StoreKit's every receipt is refused; do not expose that to a
// network.

import { createServer } from "node:http";
import { X509Certificate, randomBytes } from "node:crypto";
import { existsSync, mkdirSync, readFileSync, writeFileSync } from "node:fs";
import { fileURLToPath } from "node:url";
import { dirname, join } from "node:path";

import { Journal, reapplyDeletions } from "./accounts.mjs";
import { open } from "./db.mjs";
import { handler } from "./http.mjs";
import { Service } from "./service.mjs";
import { Builds } from "./sim.mjs";
import { Store } from "./store.mjs";
import { GameCenter, appStoreTransaction } from "./stores.mjs";

const here = dirname(fileURLToPath(import.meta.url));
const root = join(here, "..", "..");
const data = process.env.RULEBORN_DATA ?? join(here, "..", ".data");

const pinned = (paths) => (paths ?? "").split(",").filter(Boolean)
  .map((path) => new X509Certificate(readFileSync(path)));
const bundleId = process.env.RULEBORN_BUNDLE_ID ?? null;
// The one list both proofs once shared would now be ignored, and sign-in stubbed.
if (process.env.RULEBORN_APPLE_ROOTS) {
  throw new Error("RULEBORN_APPLE_ROOTS is split: set RULEBORN_GAMECENTER_ROOTS and RULEBORN_STOREKIT_ROOTS");
}
const gameCenterRoots = pinned(process.env.RULEBORN_GAMECENTER_ROOTS);
const storeKitRoots = pinned(process.env.RULEBORN_STOREKIT_ROOTS);
const sandbox = process.env.RULEBORN_APPLE_SANDBOX === "1";
// Game Center's key comes from apple.com, and nowhere a redirect leads.
const FETCH_TIMEOUT_MS = 5000;
const gameCenter = gameCenterRoots.length > 0 && bundleId ? new GameCenter({
  roots: gameCenterRoots, bundleId,
  fetchCertificate: async (url) => {
    const response = await fetch(url, { redirect: "error", signal: AbortSignal.timeout(FETCH_TIMEOUT_MS) });
    if (!response.ok) throw new Error(`${url}: ${response.status}`);
    return Buffer.from(await response.arrayBuffer());
  },
}) : null;
const storeKit = storeKitRoots.length > 0 && bundleId;
// A server that takes money must not take any credential as an identity:
// paid accounts would be anyone's for the naming. Stubbed sign-in beside real
// purchases only when the operator says so, for a test deployment.
if (storeKit && !gameCenter && process.env.RULEBORN_STUB_SIGNIN !== "1") {
  throw new Error("RULEBORN_STOREKIT_ROOTS without RULEBORN_GAMECENTER_ROOTS would pay out with sign-in stubbed; "
                  + "set both, or RULEBORN_STUB_SIGNIN=1 for a test deployment");
}

mkdirSync(data, { recursive: true });
function secret() {
  if (process.env.RULEBORN_SECRET) return process.env.RULEBORN_SECRET;
  const path = join(data, "secret");
  if (!existsSync(path)) writeFileSync(path, randomBytes(32).toString("hex"), { mode: 0o600, flag: "wx" });
  return readFileSync(path, "utf8").trim();
}

const service = new Service({
  db: open(join(data, "ruleborn.sqlite")),
  store: new Store(join(data, "bundles")),
  builds: Builds.load([join(root, "sim/target/wasm32-unknown-unknown/release/ruleborn_sim.wasm")]),
  secret: secret(),
  verifyPlatform: gameCenter
    ? (credential) => gameCenter.verify(credential)
    : (credential) => (typeof credential === "string" && credential ? credential : null),
  preparePlatform: gameCenter ? (credential) => gameCenter.prepare(credential) : async () => {},
  // Google Play's proofs need Google's API, and are not wired (D67).
  verifyReceipt: storeKit
    ? (store, receipt) => (store === "app-store"
      ? appStoreTransaction(receipt, { roots: storeKitRoots, bundleId, now: Date.now(), sandbox }) : null)
    : () => null,
  // §18.1's seasons run back to back from the first. RULEBORN_SEASON_START is
  // that moment, in ISO form; without it a fixed Monday, so a local server's
  // seasons do not move between restarts.
  seasonStart: Date.parse(process.env.RULEBORN_SEASON_START ?? "2026-01-05T00:00:00Z"),
  // §24.3's replays, private: not in the store anyone may fetch by hash.
  replays: new Store(join(data, "replays")),
  deletions: new Journal(process.env.RULEBORN_DELETIONS ?? join(data, "deletions.jsonl")),
});
const handle = handler(service);

// §20.12's "backups included": a database restored from before a deletion
// has it made again before anyone can sign in.
const remade = reapplyDeletions(service);
if (remade) console.log(`${remade} deletion(s) made again from the journal`);

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
// The edge refuses a body past its own limit; the listener stops reading one
// long before it could hold much memory, and nothing a request does takes the
// process down (C26).
const MAX_READ = 64 * 1024;
createServer(async (req, res) => {
  try {
    const chunks = [];
    let size = 0;
    for await (const chunk of req) {
      size += chunk.length;
      if (size > MAX_READ) {
        res.writeHead(413, { "content-type": "application/json" });
        res.end(JSON.stringify({ error: "too_large" }));
        req.destroy();
        return;
      }
      chunks.push(chunk);
    }
    const body = chunks.length ? Buffer.concat(chunks) : undefined;
    const request = new Request(`http://localhost${req.url}`, {
      method: req.method, headers: req.headers,
      body: req.method === "GET" || req.method === "HEAD" ? undefined : body,
    });
    const response = await handle(request);
    res.writeHead(response.status, Object.fromEntries(response.headers));
    res.end(Buffer.from(await response.arrayBuffer()));
  } catch (err) {
    // The route alone, as the edge logs it: a path can carry an account id
    // or a token, and a log is not where those are kept (§20.5).
    const route = (req.url ?? "").split("?")[0].split("/").filter(Boolean).slice(0, 2).join("/");
    console.error(`${req.method} /${route}:`, err);
    if (!res.headersSent) res.writeHead(500, { "content-type": "application/json" });
    res.end(JSON.stringify({ error: "internal" }));
  }
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
// What names a player and is no use once closed: sent notifications, and
// used or lapsed invites and challenge links (§20.5).
const tidy = () => {
  service.notifications.expire();
  service.friends.expire();
};
tidy();
setInterval(tidy, DAY_MS).unref();

// §14.6's notifications, sent once a minute. Push is Firebase Cloud
// Messaging (§24.1), which needs the operator's credentials; without them a
// due notification is written to the log instead (D68).
const push = (token, message) => console.log(`push ${token.slice(0, 8)}… ${JSON.stringify(message)}`);
setInterval(() => service.notifications.deliver(push), 60 * 1000).unref();
