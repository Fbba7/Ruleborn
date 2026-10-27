// Run the server locally:
//
//     node server/src/main.mjs [port] [--example]
//
// RULEBORN_DATA names the data directory (server/.data/ by default).
// RULEBORN_SECRET is the key session tokens are signed with and telemetry's
// pseudonyms are made under; unset, one is made on the first start and kept
// in the data directory, so a restart neither signs everyone out nor orphans
// a player's telemetry from their deletion. RULEBORN_TOKEN_KEYS, if set,
// is a comma-separated list of kid:key pairs (each key 32 characters or
// more) the session tokens are signed with instead: the first signs, every
// one is accepted, so a key is rotated by putting a new one first and
// removing the old one once its tokens have lapsed — 180 days for a refresh
// token (docs/security/auth.md). RULEBORN_DELETIONS names the
// deletion journal's object store (accounts.mjs; a bucket where the edge
// runs), which must live where a restore of the database does not reach:
// every deletion of the last 31 days in it is made again at start (F50).
// --example publishes the simulation's example Heart, undefended, from an
// account of its own — seeded, as §13.1's designed islands are, so no
// new-player protection holds it back — and a client has an island to lease
// on a fresh database.
//
// The edge function (`http.mjs`) behind a plain node:http listener, with the
// database and the object store on disk under server/.data/ and the one
// simulation build this checkout compiles.
//
// Google's (stores.mjs): RULEBORN_GOOGLE_CLIENT_IDS, comma-separated, are the
// server's OAuth client ids a "Sign in with Google" ID token must name;
// RULEBORN_PLAY_PACKAGE and RULEBORN_PLAY_LICENCE_KEY (the Play Console's
// base64 key) check Play Billing purchases, RULEBORN_PLAY_SERVICE_ACCOUNT
// names the service account's JSON key the server looks each one up and
// settles it with, and RULEBORN_PLAY_TEST=1 lets a licence tester's free
// purchases pay too, as a test deployment may.
//
// Apple's proofs (stores.mjs) are checked against pinned certificates (PEM or
// DER files, comma-separated), each proof its own: RULEBORN_GAMECENTER_ROOTS
// names the CA that issues Game Center's key, RULEBORN_STOREKIT_ROOTS Apple
// Root CA G3, and RULEBORN_BUNDLE_ID the app. With the first a Game Center
// identity signs in; with the second an App Store transaction pays — from
// Production only, unless RULEBORN_APPLE_SANDBOX=1 lets Sandbox's free test
// purchases pay too, as a test deployment may. With neither Game Center's
// roots nor Google's client ids, sign-in is stubbed — a credential is taken
// as the identity it names — and a store not configured refuses every
// receipt; do not expose that to a network.

import { createServer } from "node:http";
import { X509Certificate, createPublicKey, randomBytes } from "node:crypto";
import { existsSync, linkSync, mkdirSync, readFileSync, unlinkSync, writeFileSync } from "node:fs";
import { fileURLToPath } from "node:url";
import { dirname, join } from "node:path";

import { Journal, reapplyDeletions } from "./accounts.mjs";
import { CloudflarePurge, purgeEdge } from "./edge.mjs";
import { PlayPurchases, ServiceAccount } from "./googleapi.mjs";
import { Fcm } from "./push.mjs";
import { open } from "./db.mjs";
import { handler, routeOf } from "./http.mjs";
import { Service, TARGET_LISTS_MS } from "./service.mjs";
import { Builds } from "./sim.mjs";
import { Store } from "./store.mjs";
import { raiseTo } from "./universe.mjs";
import { GOOGLE_KEYS_URL, GameCenter, GoogleSignIn, appStoreNotification, receipts } from "./stores.mjs";
import { platformProofs } from "./auth_proofs.mjs";

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

// Google's: "Sign in with Google" ID tokens for the server's OAuth client
// ids, checked against the keys Google publishes; Play Billing purchases for
// the package, signed with its licence key (the Play Console's base64 key).
const googleClients = (process.env.RULEBORN_GOOGLE_CLIENT_IDS ?? "").split(",").filter(Boolean);
const google = googleClients.length > 0 ? new GoogleSignIn({
  clientIds: googleClients,
  fetchKeys: async () => {
    const response = await fetch(GOOGLE_KEYS_URL, { redirect: "error", signal: AbortSignal.timeout(FETCH_TIMEOUT_MS) });
    if (!response.ok) throw new Error(`${GOOGLE_KEYS_URL}: ${response.status}`);
    const age = /max-age=(\d+)/.exec(response.headers.get("cache-control") ?? "");
    return { keys: (await response.json()).keys, maxAgeMs: age ? Number(age[1]) * 1000 : undefined };
  },
}) : null;
const playPackage = process.env.RULEBORN_PLAY_PACKAGE ?? null;
const playKey = process.env.RULEBORN_PLAY_LICENCE_KEY;
const play = playPackage && playKey ? {
  packageName: playPackage,
  licenceKey: createPublicKey({ key: Buffer.from(playKey, "base64"), format: "der", type: "spki" }),
} : null;
if (Boolean(playPackage) !== Boolean(playKey)) {
  throw new Error("set RULEBORN_PLAY_PACKAGE and RULEBORN_PLAY_LICENCE_KEY together, or neither");
}
// A Play purchase nobody acknowledges is refunded after three days, and whether
// it was a licence tester's is known only to Google: so the server asks, as
// a service account, before granting one (googleapi.mjs). Without the
// account, Play receipts are refused.
const playAccount = play && process.env.RULEBORN_PLAY_SERVICE_ACCOUNT
  ? new ServiceAccount({ serviceAccount: JSON.parse(readFileSync(process.env.RULEBORN_PLAY_SERVICE_ACCOUNT, "utf8")), fetch })
  : null;
if (play && !playAccount) {
  throw new Error("RULEBORN_PLAY_PACKAGE needs RULEBORN_PLAY_SERVICE_ACCOUNT: a Play purchase is acknowledged by the server");
}
const playPurchases = playAccount
  ? new PlayPurchases({ account: playAccount, packageName: playPackage, test: process.env.RULEBORN_PLAY_TEST === "1" })
  : null;

// A server that takes money must not take any credential as an identity:
// paid accounts would be anyone's for the naming. Stubbed sign-in beside real
// purchases only when the operator says so, for a test deployment.
// Each proof single-use: a Game Center salt once, a Google token's nonce once
// (auth_proofs.mjs).
const platforms = platformProofs({ gameCenter, google });
if ((storeKit || play) && platforms.stubbed && process.env.RULEBORN_STUB_SIGNIN !== "1") {
  throw new Error("a store's receipts would pay out with sign-in stubbed: set RULEBORN_GAMECENTER_ROOTS "
                  + "or RULEBORN_GOOGLE_CLIENT_IDS, or RULEBORN_STUB_SIGNIN=1 for a test deployment");
}

// D70: the edge's cache of an under-13 player's bundles, purged on their
// deletion (edge.mjs). RULEBORN_CF_ZONE is the zone the bundles are served
// from, RULEBORN_CF_PURGE_TOKEN an API token that may purge it, and
// RULEBORN_PUBLIC_ORIGIN the https://host they are served under. Unset, the
// server is behind no edge and the purges wait in the database.
const edgeVars = ["RULEBORN_CF_ZONE", "RULEBORN_CF_PURGE_TOKEN", "RULEBORN_PUBLIC_ORIGIN"].map((k) => process.env[k]);
if (edgeVars.some(Boolean) && !edgeVars.every(Boolean)) {
  throw new Error("set RULEBORN_CF_ZONE, RULEBORN_CF_PURGE_TOKEN and RULEBORN_PUBLIC_ORIGIN together, or none");
}
const edge = edgeVars.every(Boolean)
  ? new CloudflarePurge({ zone: edgeVars[0], token: edgeVars[1], origin: edgeVars[2] }) : null;

mkdirSync(data, { recursive: true });
// A key shorter than this signs nothing: an empty one, from a file a crash
// left before it was written, would let anyone make any session token.
const SECRET_MIN = 32;
function secret() {
  let key = process.env.RULEBORN_SECRET;
  if (!key) {
    const path = join(data, "secret");
    if (!existsSync(path)) {
      // Written whole beside, then linked into place: a crash leaves no
      // half-written key, and a second process starting at once keeps the
      // first one's.
      const part = `${path}.${process.pid}.part`;
      writeFileSync(part, randomBytes(32).toString("hex"), { mode: 0o600 });
      try {
        linkSync(part, path);
      } catch (err) {
        if (err.code !== "EEXIST") throw err;
      } finally {
        unlinkSync(part);
      }
    }
    key = readFileSync(path, "utf8").trim();
  }
  if (key.length < SECRET_MIN) throw new Error(`the server's secret is shorter than ${SECRET_MIN} characters`);
  return key;
}

const service = new Service({
  db: open(join(data, "ruleborn.sqlite")),
  store: new Store(join(data, "bundles")),
  builds: Builds.load([join(root, "sim/target/wasm32-unknown-unknown/release/ruleborn_sim.wasm")]),
  secret: secret(),
  tokenKeys: process.env.RULEBORN_TOKEN_KEYS ?? "",
  verifyPlatform: platforms.verify,
  preparePlatform: platforms.prepare,
  verifyReceipt: receipts({ appStore: storeKit ? { roots: storeKitRoots, bundleId, sandbox } : null, play }),
  settleReceipt: async (store, proof) => (store === "google-play" ? playPurchases.settle(proof) : { ok: true }),
  // §18.1's seasons run back to back from the first. RULEBORN_SEASON_START is
  // that moment, in ISO form; without it a fixed Monday, so a local server's
  // seasons do not move between restarts.
  seasonStart: Date.parse(process.env.RULEBORN_SEASON_START ?? "2026-01-05T00:00:00Z"),
  // §24.3's replays, private: not in the store anyone may fetch by hash.
  replays: new Store(join(data, "replays")),
  deletions: new Journal(new Store(process.env.RULEBORN_DELETIONS ?? join(data, "deletions"))),
  edge,
});
// G39's web page for deletion without the app signs in with Google under
// RULEBORN_GOOGLE_WEB_CLIENT_ID, a web OAuth client id that must also be one
// of RULEBORN_GOOGLE_CLIENT_IDS; unset, the page is not served.
const webClientId = process.env.RULEBORN_GOOGLE_WEB_CLIENT_ID ?? null;
if (webClientId && !googleClients.includes(webClientId)) {
  throw new Error("RULEBORN_GOOGLE_WEB_CLIENT_ID must be one of RULEBORN_GOOGLE_CLIENT_IDS");
}
// G32: Apple's App Store Server Notifications (v2) come to
// /v1/stores/apple/notifications, the URL the operator sets in App Store
// Connect, and are checked against the same pinned root as a transaction.
const appleNotifications = storeKit
  ? (signedPayload) => appStoreNotification(signedPayload, { roots: storeKitRoots, bundleId, sandbox, now: Date.now() })
  : null;
// §20.11's "published contact details": the operator's name and address on
// /support, as RULEBORN_CONTACT="Name <address>"; unset, the page is not
// served, and the stores' support link has nowhere to go.
const contactSetting = process.env.RULEBORN_CONTACT ?? "";
const contactMatch = /^\s*(.+?)\s*<([^<>\s]+@[^<>\s]+)>\s*$/.exec(contactSetting);
if (contactSetting && !contactMatch) throw new Error('RULEBORN_CONTACT must read "Name <address>"');
const contact = contactMatch ? { name: contactMatch[1], email: contactMatch[2] } : null;
// G44: a sign-in is always limited by the account it proves. Failed sign-ins
// are limited by address only where the proxy in front of this listener (it
// binds 127.0.0.1) names the caller's one address in a header it sets
// itself, RULEBORN_PEER_HEADER (Cloudflare's cf-connecting-ip, or x-real-ip;
// never x-forwarded-for, whose first address the caller writes). Unset,
// failures are not limited at all, and the log says so.
const peerHeader = (process.env.RULEBORN_PEER_HEADER ?? "").trim().toLowerCase();
if (!peerHeader) console.warn("RULEBORN_PEER_HEADER unset: failed sign-ins are not limited by address (G44)");
const peerOf = peerHeader ? (request) => request.headers.get(peerHeader) : null;
const handle = handler(service, { webClientId, appleNotifications, contact, peerOf });

// §20.12's "backups included": a database restored from before a deletion
// has it made again before anyone can sign in.
const remade = reapplyDeletions(service);
if (remade) console.log(`${remade} deletion(s) made again from the journal`);
// Target lists no band names any more, which name players (§20.5).
service.sweepLists();

// §24.8's lists are "generated periodically"; how often is not said. The
// owner decided once an hour (G21), and once at start.
// Today's generated islands (§12.22) before each list, so a new day's are
// on the next list made.
service.generator.stock();
service.targetLists();
setInterval(() => {
  service.generator.stock();
  service.targetLists();
}, TARGET_LISTS_MS).unref();

// §18.1: a season that has ended is closed — results, rewards, the pull back
// — and the next opened, checked every fifteen minutes; closing twice is a
// no-op, so a missed check costs nothing but a little lateness.
const ROLLOVER_MS = 15 * 60 * 1000;
service.seasons.rollover();
setInterval(() => service.seasons.rollover(), ROLLOVER_MS).unref();

if (process.argv.includes("--example")) {
  const { account } = service.session("example:defender");
  service.db.prepare("UPDATE accounts SET seeded = 1 WHERE id = ?").run(account);
  const { bundle } = service.publish(account, service.builds.current.exampleIsland(true));
  // And a universe to raid across (§5.4, crossings.mjs): another seeded
  // account's Heart and one outer realm, each laid by the generator — so
  // generated, never the lists' first authored target — joined by the
  // Stone bridge the outer realm opens with.
  const across = service.session("example:universe").account;
  service.db.prepare("UPDATE accounts SET seeded = 1 WHERE id = ?").run(across);
  const heart = service.builds.current.generate(7, 3);
  raiseTo(service.db, across, "heart", heart[4], heart[5]);
  service.publish(across, heart, "heart", { origin: "generated" });
  const outer = service.builds.current.generate(8, 1);
  raiseTo(service.db, across, "outer-1", outer[4], outer[5]);
  service.publish(across, outer, "outer-1", { origin: "generated" });
  service.links.ensure(across, service.now());
  service.targetLists();
  console.log(`example island ${bundle.slice(0, 12)} published, and a universe of two realms`);
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
    console.error(`${req.method} /${routeOf(req.url)}:`, err);
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
// What names a player and is no use once closed: sent notifications, used
// or lapsed invites and challenge links, and lapsed purchase intents and
// unplayed leases (§20.5, G38).
const tidy = () => {
  service.notifications.expire();
  service.friends.expire();
  service.expireLapsed();
  // Sessions ended or lapsed a week ago, and proofs past their five minutes.
  service.auth.expire();
  // §18.9: each ended quarter's Island Fund divided, once.
  service.fund.closeEnded();
  // G32: what Google refunded or revoked, taken back, once a day.
  if (playPurchases) service.shop.voided(playPurchases).catch((err) => console.error("voided purchases:", err));
};
tidy();
setInterval(tidy, DAY_MS).unref();
// §13.3's hold measurements, a few of the reference crew's raids at a time,
// so the queue never holds up a request for long (holds.mjs): a raid is
// some 30 to 50 ms, so two every quarter second, the eight a second forty
// every five seconds once played in one two-second block (SR-17).
setInterval(() => service.holds.work(2), 250).unref();

// §14.6's notifications, sent once a minute through Firebase Cloud Messaging
// (§24.1, push.mjs) as the project's service account: RULEBORN_FCM_SERVICE_ACCOUNT
// names its JSON key, whose project_id is the FCM project unless
// RULEBORN_FCM_PROJECT says otherwise. Without it a due notification is
// written to the log instead. The log names the kind and a count, never the
// token or a heist (§20.5).
const fcmKey = process.env.RULEBORN_FCM_SERVICE_ACCOUNT;
const fcm = fcmKey ? (() => {
  const serviceAccount = JSON.parse(readFileSync(fcmKey, "utf8"));
  return new Fcm({ account: new ServiceAccount({ serviceAccount, fetch }),
                   projectId: process.env.RULEBORN_FCM_PROJECT ?? serviceAccount.project_id });
})() : null;
const said = (message) => `${message.kind}${message.heists ? ` ×${message.heists.length}` : ""}`;
const push = fcm
  ? (token, message, options) => fcm.send(token, message, options)
  : (token, message) => console.log(`push ${said(message)}`);
// A tick's retries, give-ups and refusals, by reason: a key without the
// right to send, or the wrong project, shows here rather than as silence.
const tally = (map) => Object.entries(map).map(([why, n]) => `${n} ${why}`).join(", ");
// A purge the edge did not take waits and is asked again, never given up;
// why it waits is logged every time (edge.mjs).
setInterval(() => {
  purgeEdge(service).then(({ waiting, reasons }) => {
    if (Object.keys(reasons).length) console.error(`edge purge to retry: ${tally(reasons)}`);
    else if (waiting && !edge) console.error(`edge purge: ${waiting} waiting, and no edge is configured`);
  }).catch((err) => console.error("edge purge:", err));
}, 60 * 1000).unref();
setInterval(() => {
  service.notifications.deliver(push).then(() => {
    const t = service.notifications.tick;
    if (!t) return;
    for (const [label, map] of [["to retry", t.retried], ["given up", t.gaveUp], ["refused", t.dropped]]) {
      if (Object.keys(map).length) console.error(`push ${label}: ${tally(map)}`);
    }
  }).catch((err) => console.error("notifications:", err));
}, 60 * 1000).unref();
