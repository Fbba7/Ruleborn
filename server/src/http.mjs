// The edge function: a web-standard Request in, a Response out (§24.1:
// "Edge functions against a managed serverless SQL database"). It routes and
// translates; every decision is the service's.
//
//   POST /v1/session             {"credential": …}          → {account, token, expiresIn, refreshToken}
//   POST /v1/session/nonce                                   → {nonce, expiresIn}: for a Google ID token (auth_http.mjs)
//   POST /v1/session/refresh     {"refreshToken"}           → a new pair; the one sent is spent
//   POST /v1/session/end         {"everywhere"?, "others"?, "device"?, "refreshToken"?} → {ended}
//   GET  /v1/session                                         → {account, devices}
//   GET  /v1/session/devices                                 → the devices list (auth_http.mjs)
//   POST /v1/session/link|unlink {"current", …}              → another platform's identity (auth_http.mjs)
//   PUT  /v1/islands/:realm      island bundle bytes         → {bundle}; heart or outer-1 … outer-6
//   GET  /v1/bundles/:hash       — immutable, cached a year  → bundle bytes
//   POST /v1/leases              {"bundle": hash, "owner"?, "trace"?, "mode"?, "challenge"?, "universe"?} → the lease
//   GET  /v1/offer?size=3                                    → §12.22's list for the caller, no rating
//   GET  /v1/observatory                                     → §12.3's targets as §12.4's cards, a Trace apart
//   GET  /v1/profile                                         → your record, badges, titles and battle log (23.2)
//   GET  /v1/profile/:account                                → another's record, if they opened it (20.2)
//   PUT  /v1/profile             {"public"}                  → your profile shown to others or hidden (20.2)
//   GET  /v1/defences                                        → the season's raids on you, each with its report (13.2)
//   GET  /v1/defences/badge                                  → {unseen}: raids since the log was last read
//   GET  /v1/curation/:realm?page=n                          → the realm's island, origin, name, layouts, swaps (13.3)
//   POST /v1/curation/:realm/layout {"seed"}                 → the generator's layout laid and published, generated
//   PUT  /v1/curation/:realm/name {"adjective", "noun"}      → the island named from the word lists
//   GET  /v1/fund                                            → the Island Fund: opted in, and each closed quarter's pay (18.9)
//   PUT  /v1/fund                {"optIn"}                   → opted in or out, at 18 or over
//   GET  /v1/lab                                             → the Lab's chambers, finds and hints (8.6)
//   POST /v1/lab                 {"chamber", "laws"}         → an experiment placed and paid (8.6, 9.5)
//   POST /v1/lab/sphere                                      → the third sphere names a chord, daily (8.5)
//   POST /v1/observatory/refresh                             → a new list, for 50 Aether doubling in the hour
//   GET  /v1/era                                             → §18.3's era of the week, and when it ends
//   GET  /v1/heists/:token/replay                            → the replay, to its raider or defender (§13)
//   PUT  /v1/notifications       {"timeZone", "reminder", "nightQuiet", "pushToken"} → the settings,
//                                                              and "reminderCleared" if the night took it
//   POST /v1/heists/:token       replay bytes                → what was settled; ?crew=ids names the roster's crew (11.6)
//   GET  /v1/balance                                         → {starlight, essence}
//   GET  /v1/keeper                                          → {level, xp, toNext, cap, plan, name} (§14.2)
//   PUT  /v1/keeper/name         {"adjective", "noun"}       → the Keeper's name from the word lists (G58)
//   GET  /v1/words                                           → the name word lists, before any account
//   GET  /v1/protections                                     → §20.2's night and spending cap by band
//   GET  /v1/sages                                           → each Sage, its unlock, the guardian (§11.7)
//   PUT  /v1/sages/guardian      {"sage": id | null}         → the Sage stationed at the Heart, or none
//   GET  /v1/terms                                           → {version, accepted, url} (§20.11)
//   PUT  /v1/terms               {"version"}                 → the current terms accepted
//   GET  /v1/blocks                                          → the caller's blocks (§17.8)
//   POST /v1/blocks              {"account"}                 → blocked; a friendship between them ends
//   DELETE /v1/blocks/:account                               → unblocked
//   GET  /terms, /privacy, /support                          → the pages the stores link to (pages.mjs)
//   GET  /v1/universe                                        → realms, buildings, and what each can buy
//   POST /v1/universe/realms     {"type"}                    → the next outer realm opened (§5.2)
//   POST /v1/universe/realms/:realm/level {"to"}             → an outer realm raised a level
//   POST /v1/universe/buildings  {"realm", "kind", "n", "to"} → a building built (to 1) or raised (§10.2)
//   PUT  /v1/universe/buildings/place {"realm", "kind", "n", "x", "y"} → a building moved, free (§10.1)
//   POST /v1/universe/links      {"a", "b", "kind"}          → a link built between two realms (§5.3)
//   PUT  /v1/universe/links/:n   {"kind", "from"?}           → a link rebuilt as another kind, a Chute's way
//   DELETE /v1/universe/links/:n                             → a link taken down, if every realm still reaches the Heart
//   POST /v1/offline {"actions": [{"do": "build"|"place"|"work"|"weave"|"unweave", …}]} → each confirmed or refused, in order (24)
//   GET  /v1/weaving                                        → each realm's law slots and the crown's, and prices (5.6)
//   POST /v1/weaving {"realm", "slot", "law", "swap"?}      → a restored law woven into a slot (5.6), or swapped in (G54)
//   DELETE /v1/weaving/:realm/:slot                         → a slot emptied; it rests an hour (5.6)
//   GET  /v1/weaving/harmony                                → how each realm's laws combine (8, 23.2)
//   GET  /v1/home                                            → the roster, its places, births and producers
//   POST /v1/home/births         {"realm", "n"}              → a birth at the realm's Nursery (§11.5)
//   POST /v1/home/characters/:id/work  {"realm", "kind", "n"} → set to work or to guard; no kind recalls (§5.8)
//   POST /v1/home/characters/:id/level {"to"}                → raised a level with Essence (§11.4)
//   POST /v1/home/characters/:id/home  {"home"}              → moved to another free place (§11.4)
//   POST /v1/home/characters/:id/wake                       → a resting character back early, in Essence (§11.6)
//   POST /v1/home/collect        {"realm", "kind"}           → what a producer holds, paid (§9.3)
//   POST /v1/home/characters/:id/name {"adjective", "noun"}  → named from the word lists (§19.20)
//   POST /v1/home/strays/:id/take                            → a heist's stray into the roster, at a birth's price (§11.5)
//   POST /v1/home/strays/:id/decline                         → it goes on its way
//   GET  /v1/forms                                           → §11.10's album: the 54 forms, owned, and the sets
//   GET  /v1/codex                                           → laws met, albums, mastery tracks (§7.6, §18.5)
//   POST /v1/codex/study         {"heist", "law"}            → a heist's one study (§7.6)
//   POST /v1/codex/working       {"law"}                     → the law worked on, for the floor's page
//   POST /v1/codex/restore       {"law"}                     → restored at tier I for its pages (§7.6, §14.2)
//   POST /v1/codex/tier          {"law", "to"}               → tier II or III for pages and Aether
//   GET  /v1/targets                                         → {band: list hash}
//   PUT  /v1/age                 {"band": "13-15"|"16-17"|"18+"} → {ageBand}
//                                {"band": "under-13"}         → the account deleted (§20.11)
//   DELETE /v1/account           {"withdrawIslands"?}        → the account deleted (§20.5, F43)
//   GET  /account/delete                                     → G39's deletion page, without the app
//   POST /v1/account/delete      {"idToken", "withdrawIslands"?} → the account deleted, proven with Google
//
// The Island Workshop (§18.6; workshop.mjs):
//
//   POST /v1/workshop            {"bundle", "replay" (base64), "adjective", "noun", "remixOf"?}
//                                                             → the item, published
//   GET  /v1/workshop?list=top|new|featured&limit=           → items
//   GET  /v1/workshop/mine                                   → the caller's own items
//   GET  /v1/workshop/words                                  → the name word lists
//   POST /v1/workshop/:id/play                               → {token, bundle, seed, ticks}
//   POST /v1/workshop/plays/:token   replay bytes            → the play's outcome
//   POST /v1/workshop/:id/rating {"fun", "cleverness", "fairness"} → the averages
//   POST /v1/workshop/:id/report {"reason"}                  → {report}
//   POST /v1/workshop/:id/remix                              → bundle bytes
//   POST /v1/workshop/:id/withdraw                           → the item
//   GET  /v1/creators/:account                               → §18.7's ladder
//   GET  /v1/moderation/reports                              → the queue (moderators)
//   POST /v1/moderation/reports/:id {"action", "reason"?}    → the item
//   POST /v1/moderation/featured/:id                         → the item
//
// Leagues and seasons (§12.9, §18.1; seasons.mjs), constellations and crews
// (§17; social.mjs):
//
//   GET  /v1/league                                          → {season, renown, league, division, …}
//   GET  /v1/seasons/:id/result                              → the caller's closed-season result
//   GET  /v1/seasons/:id/constellations                      → §17.5's constellation league
//   POST /v1/constellations      {"adjective", "noun"}       → founded
//   GET  /v1/constellations/mine                             → {constellation}, the caller's, or null
//   GET  /v1/constellations/:id                              → it, and its members
//   POST /v1/constellations/:id/join                         → joined
//   POST /v1/constellations/:id/roles {"account", "role"}    → an elder named, or unnamed
//   POST /v1/constellations/leave                            → left
//   POST /v1/crews                                           → a crew, and its invite
//   POST /v1/crews/join          {"invite"}                  → joined
//   POST /v1/crews/leave                                     → left
//   GET  /v1/crews/mine                                      → {crew}, the caller's, or null
//   GET  /v1/crews/:id                                       → it
//
// The season track (§18.2, §18.8; track.mjs), purchases and cosmetics
// (§20.2, §22.1, F41, G32; shop.mjs):
//
//   GET  /v1/track?season=N                                  → the track, this season's by default
//   POST /v1/track/claim         {"season"}                  → the next tier, claimed
//   POST /v1/shop/intents        {"product", "for"?}         → an intent, held under a minor's cap;
//                                                              "for" a friend, a gift ("gift.<product>")
//   POST /v1/shop/receipts       {"store", "receipt"}        → what was granted, and to whom
//   GET  /v1/shop/summary                                    → §20.2's monthly spending summary
//   POST /v1/stores/apple/notifications {"signedPayload"}    → Apple's refunds taken back, and reversed ones
//                                                              given back (no session)
//   GET  /v1/cosmetics                                       → the catalogue, owned and worn
//   POST /v1/cosmetics/equip     {"kind", "item", "target"?} → what is worn
//
// Telemetry (§24, §24.3; telemetry.mjs):
//
//   POST /v1/events              [{"kind", "data", "at"?}, …] → {recorded}, a batch from the device
//   GET  /v1/survey                                          → {due}, whether this month's survey is the player's (G29)
//   GET  /v1/metrics?from=&to=                               → the launch gates' figures (analysts)
//   GET  /v1/metrics/absence                                 → §25.3's recency of absence (analysts)
//
// Friends (§12.11, §17.6; friends.mjs):
//
//   GET    /v1/friends                                       → the caller's friends
//   POST   /v1/friends/invites                               → an invite to share
//   POST   /v1/friends/accept   {"invite"}                   → friends
//   DELETE /v1/friends/:account                              → no longer
//   GET    /v1/friends/feed                                  → §17.6's friends' feed
//   POST   /v1/challenges       {"realm"?}                   → a challenge link to the caller's island
//   GET    /v1/challenges/:code                              → the link's island, to lease with mode "challenge"
//
// A target list is fetched like a bundle, by its hash (§24.8: "a file, not a
// query"); the index naming the current ones is the only thing that changes.
//
// Everything but the session and a bundle needs `Authorization: Bearer …`.
//
// How fast each caller may ask is limits.mjs's (G44): past it, 429
// {"error": "too_many_requests", "retryAfter": seconds}, with Retry-After.

import { readFileSync } from "node:fs";

import { deleteAccount, reapplyDeletions } from "./accounts.mjs";
import { deleteByGoogle, deletePage, sessionRoute } from "./auth_http.mjs";
import { planning } from "./keeper.mjs";
import { offer } from "./matchmaking.mjs";
import { PAGE_HEADERS, privacyPage, supportPage, termsPage } from "./pages.mjs";
import { Limiter, peerKey } from "./limits.mjs";
import { Refused, TARGET_LISTS_MS } from "./service.mjs";
import { Social } from "./social.mjs";
import { confirm as confirmOffline } from "./offline.mjs";
import { WORDS, Workshop } from "./workshop.mjs";

const facts = JSON.parse(readFileSync(new URL("./facts.json", import.meta.url), "utf8"));

const json = (body, status = 200) => new Response(JSON.stringify(body), {
  status, headers: { "content-type": "application/json" },
});

/** §24.10: "Size of a heist — under 2 kilobytes"; an island is a few hundred bytes. */
const MAX_BODY = 16 * 1024;

async function bytes(request) {
  const body = new Uint8Array(await request.arrayBuffer());
  if (body.length > MAX_BODY) throw new Refused(413, "too_large");
  return body;
}

/** A JSON body, held to the same limit — base64 of an island and a replay
 *  is still a few kilobytes — and an object or a list, never a bare value
 *  a route would read fields off. */
async function body(request) {
  return parse(await bytes(request));
}

/** A JSON body that may be left out. */
async function optional(request) {
  const raw = await bytes(request);
  return raw.length ? parse(raw) : {};
}

function parse(raw) {
  const out = JSON.parse(new TextDecoder().decode(raw));
  if (out === null || typeof out !== "object") throw new Refused(400, "malformed_body");
  return out;
}

/** A body field a route passes on as a string: anything else a caller sends
 *  is refused here, not bound into SQL. `null` if left out and optional. */
function text(value, optional = false) {
  if (optional && value == null) return null;
  if (typeof value !== "string") throw new Refused(400, "malformed_body");
  return value;
}

const base64 = (s) => new Uint8Array(Buffer.from(String(s ?? ""), "base64"));

const octets = (b) => new Response(b, { headers: { "content-type": "application/octet-stream" } });

/** Leagues, seasons, constellations and crews. */
async function socialRoute(service, social, request, parts, who) {
  const [, area, a, b] = parts;
  const m = request.method;
  const me = who();
  if (area === "league" && m === "GET") return json(service.seasons.league(me));
  if (area === "seasons" && m === "GET" && a && b === "result") {
    return json(service.seasons.result(me, Number(a)));
  }
  if (area === "seasons" && m === "GET" && a && b === "constellations") {
    return json(service.seasons.constellationTable(Number(a)));
  }
  if (area === "constellations") {
    if (m === "POST" && !a) return json(social.found(me, await body(request)), 201);
    if (m === "POST" && a === "leave") return json(social.leave(me));
    // The player's own, so a device that knows nothing yet can find it.
    if (m === "GET" && a === "mine") {
      const own = social.membership(me);
      return json({ constellation: own ? social.constellation(own.constellation, me) : null });
    }
    if (m === "GET" && a) return json(social.constellation(a, me));
    if (m === "POST" && a && b === "join") return json(social.join(me, a));
    if (m === "POST" && a && b === "roles") {
      const { account, role } = await body(request);
      return json(social.appoint(me, account, role));
    }
  }
  if (area === "crews") {
    if (m === "POST" && !a) return json(social.startCrew(me), 201);
    if (m === "POST" && a === "join") return json(social.joinCrew(me, text((await body(request)).invite)));
    if (m === "POST" && a === "leave") return json(social.leaveCrew(me));
    if (m === "GET" && a === "mine") {
      const own = social.crewOf(me);
      return json({ crew: own ? social.crew(own, me) : null });
    }
    if (m === "GET" && a) return json(social.crew(a, me));
  }
  return null;
}

/** The season track, the shop and the wardrobe. */
async function shopRoute(service, request, url, parts, who) {
  const [, area, a, b] = parts;
  const m = request.method;
  const me = who();
  if (area === "track") {
    if (m === "GET" && !a) {
      const season = url.searchParams.get("season");
      return json(service.track.view(me, season === null ? undefined : Number(season)));
    }
    if (m === "POST" && a === "claim") return json(service.track.claim(me, (await body(request)).season));
  }
  if (area === "shop") {
    if (m === "POST" && a === "intents") {
      const q = await body(request);
      return json(service.shop.intent(me, q.product, { for: text(q.for, true) }), 201);
    }
    if (m === "POST" && a === "receipts") {
      const { store, receipt } = await body(request);
      return json(await service.shop.claim(me, store, receipt), 201);
    }
    if (m === "GET" && a === "summary") return json(service.shop.summary(me));
  }
  if (area === "cosmetics") {
    if (m === "GET" && !a) return json(service.shop.catalogue(me));
    if (m === "POST" && a === "equip") return json(service.shop.equip(me, await body(request)));
  }
  return null;
}

/** The Workshop's routes: /v1/workshop/…, /v1/creators/…, /v1/moderation/…. */
async function workshopRoute(workshop, request, url, parts, who) {
  const [, area, a, b] = parts;
  const m = request.method;
  if (area === "creators" && m === "GET" && a) {
    who();
    return json(workshop.ladder(a));
  }
  if (area === "moderation") {
    const me = who();
    if (m === "GET" && a === "reports") return json(workshop.queue(me));
    if (m === "POST" && a === "reports" && b) {
      const { action, reason = null } = await body(request);
      return json(workshop.resolve(me, Number(b), action, reason));
    }
    if (m === "POST" && a === "featured" && b) return json(workshop.feature(me, b));
    return null;
  }
  // /v1/workshop…
  const me = who();
  if (m === "POST" && !a) {
    const q = await body(request);
    return json(workshop.publish(me, base64(q.bundle), base64(q.replay),
      { adjective: q.adjective, noun: q.noun, remixOf: q.remixOf ?? null }), 201);
  }
  if (m === "GET" && !a) {
    return json(workshop.browse(me, url.searchParams.get("list") ?? "top",
                                Number.parseInt(url.searchParams.get("limit"), 10) || 20));
  }
  if (m === "GET" && a === "mine") return json(workshop.mine(me));
  if (m === "GET" && a === "words") return json(WORDS);
  if (m === "POST" && a === "plays" && b) return json(workshop.submitPlay(me, b, await bytes(request)));
  if (m === "POST" && a && b === "play") return json(workshop.play(me, a), 201);
  if (m === "POST" && a && b === "rating") return json(workshop.rate(me, a, await body(request)));
  if (m === "POST" && a && b === "report") {
    return json(workshop.report(me, a, (await body(request)).reason), 201);
  }
  if (m === "POST" && a && b === "remix") return octets(workshop.remix(me, a));
  if (m === "POST" && a && b === "withdraw") return json(workshop.withdraw(me, a));
  return null;
}

/** A request's route for a log line: the first two segments of its path,
 *  never an id or a token that follows them, nor its query (§20.5). */
export function routeOf(url) {
  return String(url ?? "").split("?")[0].split("/").filter(Boolean).slice(0, 2).join("/");
}

/**
 * The edge function. `webClientId` is the OAuth client id G39's web page
 * signs in with (it must be among the ids Google sign-in accepts); without
 * it the page is not served. `appleNotifications(signedPayload)` checks an
 * App Store Server Notification (stores.mjs appStoreNotification); without
 * it Apple's refunds are not taken (G32). `contact` is the operator's
 * {name, email} for the support page (§20.11); without it that page is not
 * served. `limiter` holds each caller to limits.mjs's buckets (G44). Failed
 * sign-ins are held by address only where `peerOf(request)` says what the
 * caller's address is — a header the deployment's own proxy sets, never one
 * a caller could choose. `placeOf(request)` is the country the edge says a
 * request came from, kept on a session for its devices list (auth.mjs).
 */
export function handler(service, { webClientId = null, appleNotifications = null, contact = null,
                                   limiter = new Limiter(), peerOf = null, placeOf = null } = {}) {
  const workshop = new Workshop(service);
  const social = new Social(service);
  // Every answer tells the device to reach this host over HTTPS only: the
  // platform's edge terminates TLS (§24.1), and the Data safety form asks
  // whether all of it is encrypted in transit (privacy.json).
  // F50: an edge isolate's start makes the journal's recent deletions again,
  // as the node server's does, before it answers anything. Until that has
  // succeeded nothing is answered, and each request tries it again: a
  // restored database never serves an account its player deleted.
  let started = false;
  return async function handle(request) {
    if (!started) {
      try {
        reapplyDeletions(service);
        started = true;
      } catch (err) {
        console.error("reapplying deletions:", err);
        const refused = json({ error: "starting" }, 503);
        refused.headers.set("strict-transport-security", "max-age=31536000");
        refused.headers.set("retry-after", "1");
        return refused;
      }
    }
    const response = await answer(request);
    response.headers.set("strict-transport-security", "max-age=31536000");
    // No answer is sniffed into another type: a bundle or a replay's bytes
    // are never run as a page (SR-04).
    response.headers.set("x-content-type-options", "nosniff");
    return response;
  };
  async function answer(request) {
    const url = new URL(request.url);
    const parts = url.pathname.split("/").filter(Boolean);
    const route = `${request.method} /${routeOf(url.pathname)}`;
    // What runs the simulation: a replay re-simulated, an island checked, a
    // Workshop entry and its clearing replay (G44's second bucket).
    const simulates = (request.method === "PUT" && parts[1] === "islands")
      || (request.method === "POST" && parts[1] === "heists")
      || (request.method === "POST" && parts[1] === "curation")
      || (request.method === "POST" && parts[1] === "workshop" && (parts.length === 2 || parts[2] === "plays"));
    const limit = (kind, key) => {
      const wait = limiter.take(kind, key, service.now());
      if (wait) throw new Refused(429, "too_many_requests", { retryAfter: Math.ceil(wait / 1000) });
    };
    // The caller, once a request: limited by the token's signature before
    // the account is read, so a refused request reads nothing (G44).
    let caller = null;
    const who = () => {
      if (caller) return caller;
      const header = request.headers.get("authorization") ?? "";
      const token = header.startsWith("Bearer ") ? header.slice(7) : "";
      const id = service.holder(token);
      limit("calls", id);
      if (simulates) limit("simulations", id);
      caller = service.account(token);
      return caller;
    };
    // A sign-in: refused while its address has failed too often, where the
    // deployment can tell the address; held to the account it proves once
    // proven, before anything is read; and a failure counted to its address.
    const signIn = async (proceed) => {
      const peer = peerOf ? peerKey(peerOf(request)) : null;
      if (peer) {
        const wait = limiter.peek("failedSignIns", peer, service.now());
        if (wait) throw new Refused(429, "too_many_requests", { retryAfter: Math.ceil(wait / 1000) });
      }
      try {
        return await proceed((identity) => limit("signIns", identity));
      } catch (err) {
        const failed = err instanceof SyntaxError || (err instanceof Refused && err.status >= 400
          && err.status < 500 && err.status !== 429 && err.status !== 403);
        if (peer && failed) limiter.take("failedSignIns", peer, service.now());
        throw err;
      }
    };
    try {
      if (parts[0] === "v1" && parts[1] === "session") {
        return await sessionRoute(service, request, parts,
                                  { signIn, limit, read: body, optional, place: placeOf?.(request) ?? null });
      }
      if (["league", "seasons", "constellations", "crews"].includes(parts[1])) {
        const out = await socialRoute(service, social, request, parts, who);
        return out ?? json({ error: "no_such_route" }, 404);
      }
      if (parts[1] === "friends" || parts[1] === "challenges") {
        const me = who();
        const f = service.friends;
        const [, area, a] = parts;
        const m = request.method;
        if (area === "friends") {
          if (m === "GET" && !a) return json(f.list(me));
          if (m === "GET" && a === "feed") return json(f.feed(me));
          if (m === "POST" && a === "invites") return json(f.invite(me), 201);
          if (m === "POST" && a === "accept") return json(f.accept(me, text((await body(request)).invite)));
          if (m === "DELETE" && a) return json(f.remove(me, a));
        } else {
          if (m === "POST" && !a) {
            return json(f.challenge(me, text((await optional(request)).realm, true) ?? "heart"), 201);
          }
          if (m === "GET" && a) {
            const c = service.challenge(me, a);
            return json({ challenge: c.code, bundle: c.bundle, from: c.account });
          }
        }
        return json({ error: "no_such_route" }, 404);
      }
      if (["terms", "privacy", "support"].includes(parts[0]) && parts.length === 1
          && (request.method === "GET" || request.method === "HEAD")) {
        const html = parts[0] === "terms" ? termsPage()
          : parts[0] === "privacy" ? privacyPage(undefined, { webDeletion: Boolean(webClientId) }) : supportPage(contact);
        if (!html) return json({ error: "not_configured" }, 503);
        // Asked for afresh each time: a player asked to accept new terms
        // must never be shown a cached copy of the old ones.
        return new Response(request.method === "HEAD" ? null : html, {
          headers: { "content-type": "text/html; charset=utf-8", "cache-control": "no-cache", ...PAGE_HEADERS } });
      }
      if (parts[1] === "terms" && parts.length === 2) {
        const me = who();
        if (request.method === "GET") return json(service.safety.terms(me));
        if (request.method === "PUT") return json(service.safety.accept(me, text((await body(request)).version)));
      }
      if (parts[1] === "blocks") {
        const me = who();
        const m = request.method;
        if (m === "GET" && !parts[2]) return json(service.safety.list(me));
        if (m === "POST" && !parts[2]) return json(service.safety.block(me, text((await body(request)).account)), 201);
        if (m === "DELETE" && parts[2]) return json(service.safety.unblock(me, parts[2]));
        return json({ error: "no_such_route" }, 404);
      }
      if (parts[1] === "offline" && !parts[2]) {
        // §24: what the device built, placed and assigned offline, made now
        // in order and answered one by one (offline.mjs).
        if (request.method !== "POST") return json({ error: "no_such_route" }, 404);
        return json(confirmOffline(service, who(), (await body(request)).actions));
      }
      if (parts[1] === "profile") {
        // §23.2's Profile and stats (profile.mjs): the player's own, its
        // switch, and another's only as §20.2 lets it be seen.
        const me = who();
        if (request.method === "GET" && parts.length === 2) return json(service.profile.view(me));
        if (request.method === "GET" && parts.length === 3) return json(service.profile.show(me, parts[2]));
        if (request.method === "PUT" && parts.length === 2) {
          return json(service.profile.share(me, (await body(request)).public));
        }
        return json({ error: "no_such_route" }, 404);
      }
      if (parts[1] === "defences" && request.method === "GET") {
        // §23.2's defence log (defences.mjs): reading it clears the raid
        // badge, which the badge route only counts.
        if (parts.length === 2) return json(service.defences.show(who()));
        if (parts[2] === "badge" && parts.length === 3) return json(service.defences.badge(who()));
        return json({ error: "no_such_route" }, 404);
      }
      if (parts[1] === "curation") {
        // §13.3's curation (curation.mjs): a layout names its seed, so a
        // retry lays the same island.
        const me = who();
        const [, , realm, verb] = parts;
        const m = request.method;
        if (m === "GET" && realm && !verb) {
          return json(service.curation.view(me, realm, Number(url.searchParams.get("page") ?? 0)));
        }
        if (m === "POST" && verb === "layout" && parts.length === 4) {
          return json(service.curation.layout(me, realm, (await body(request)).seed));
        }
        if (m === "PUT" && verb === "name" && parts.length === 4) {
          const q = await body(request);
          return json(service.curation.name(me, realm, { adjective: q.adjective, noun: q.noun }));
        }
        return json({ error: "no_such_route" }, 404);
      }
      if (parts[1] === "fund" && parts.length === 2) {
        // §18.9's Island Fund (fund.mjs): the settings page's opt-in and the
        // quarters already paid, never a live counter.
        if (request.method === "GET") return json(service.fund.view(who()));
        if (request.method === "PUT") return json(service.fund.optIn(who(), (await body(request)).optIn));
        return json({ error: "no_such_route" }, 404);
      }
      if (parts[1] === "lab") {
        // §8.6's Resonance Lab (lab.mjs): an experiment names its chamber,
        // so one already running there is refused, never charged twice.
        const me = who();
        if (request.method === "GET" && parts.length === 2) return json(service.lab.show(me));
        if (request.method === "POST" && parts.length === 2) {
          const b = await body(request);
          return json(service.lab.start(me, { chamber: b.chamber, laws: b.laws }));
        }
        if (request.method === "POST" && parts[2] === "sphere" && parts.length === 3) return json(service.lab.name(me));
        return json({ error: "no_such_route" }, 404);
      }
      if (parts[1] === "observatory" && parts[2] === "refresh" && parts.length === 3 && request.method === "POST") {
        // §12.3: a paid refresh, which buys a list without the targets shown.
        return json(service.observatory.refresh(who()));
      }
      if (parts[1] === "weaving") {
        // §5.1 and §5.6 (weaving.mjs): a weave names the slot and the law,
        // so a retry is answered as woven.
        const me = who();
        const w = service.weaving;
        const [, , a, b] = parts;
        const m = request.method;
        if (m === "GET" && !a) return json(w.show(me));
        if (m === "GET" && a === "harmony" && !b) return json(w.harmony(me));
        if (m === "POST" && !a) return json(w.weave(me, await body(request)));
        if (m === "DELETE" && a && b) return json(w.unweave(me, { realm: a, slot: Number(b) }));
        return json({ error: "no_such_route" }, 404);
      }
      if (parts[1] === "universe") {
        // §5.2 and §10.2 (universe.mjs): each purchase names the level it
        // leads to, so a retry is answered, never charged again.
        const me = who();
        const u = service.universe;
        const [, , a, b, c] = parts;
        const m = request.method;
        if (m === "GET" && !a) return json(u.show(me));
        // §5.3's links (links.mjs): a rebuild names the kind it leads to.
        if (m === "POST" && a === "links" && !b) return json(service.links.build(me, await body(request)));
        if (m === "PUT" && a === "links" && b && !c) {
          const q = await body(request);
          return json(service.links.rebuild(me, Number(b), { kind: q.kind, from: q.from ?? null }));
        }
        if (m === "DELETE" && a === "links" && b && !c) return json(service.links.remove(me, Number(b)));
        if (m === "POST" && a === "realms" && !b) return json(u.open(me, text((await body(request)).type)));
        if (m === "POST" && a === "realms" && b && c === "level") return json(u.raise(me, b, (await body(request)).to));
        if (m === "POST" && a === "buildings" && !b) return json(u.build(me, await body(request)));
        if (m === "PUT" && a === "buildings" && b === "place") return json(u.place(me, await body(request)));
        return json({ error: "no_such_route" }, 404);
      }
      if (parts[1] === "home") {
        // §5.8, §9.3, §11.4 to §11.6 (home.mjs): a birth names the roster
        // size it leads to and a level the level, so a retry is answered.
        const me = who();
        const h = service.home;
        const [, , a, b, c] = parts;
        const m = request.method;
        if (m === "GET" && !a) return json(h.show(me));
        if (m === "POST" && a === "births" && !b) return json(h.birth(me, await body(request)));
        if (m === "POST" && a === "collect" && !b) return json(h.collect(me, await body(request)));
        if (m === "POST" && a === "characters" && b && c === "work") return json(h.work(me, b, await body(request)));
        if (m === "POST" && a === "characters" && b && c === "level") return json(h.level(me, b, (await body(request)).to));
        if (m === "POST" && a === "characters" && b && c === "home") return json(h.move(me, b, text((await body(request)).home)));
        if (m === "POST" && a === "characters" && b && c === "wake") return json(h.wake(me, b));
        if (m === "POST" && a === "characters" && b && c === "name") return json(h.name(me, b, await body(request)));
        if (m === "POST" && a === "strays" && b && c === "take") return json(h.takeStray(me, b));
        if (m === "POST" && a === "strays" && b && c === "decline") return json(h.declineStray(me, b));
        return json({ error: "no_such_route" }, 404);
      }
      if (parts[1] === "codex") {
        // §7.6 (codex.mjs): a restoration or a tier names what it leads to,
        // and a heist allows one study, so a retry is answered as done.
        const me = who();
        const cx = service.codex;
        const m = request.method;
        const a = parts[2];
        if (m === "GET" && !a) return json(cx.show(me));
        if (m === "POST" && parts.length === 3) {
          const b = await body(request);
          if (a === "study") return json(cx.study(me, { heist: text(b.heist), law: text(b.law) }));
          if (a === "working") return json(cx.workOn(me, b.law == null ? null : text(b.law)));
          if (a === "restore") return json(cx.restore(me, text(b.law)));
          if (a === "tier") return json(cx.tier(me, text(b.law), b.to));
        }
        return json({ error: "no_such_route" }, 404);
      }
      if (parts[1] === "survey" && request.method === "GET") {
        // G29's rotating sample: whether this month's survey is this player's.
        return json({ due: service.telemetry.surveyDue(who()) });
      }
      if (parts[1] === "events" && request.method === "POST") {
        return json(service.telemetry.batch(who(), await body(request)), 202);
      }
      if (parts[1] === "metrics" && request.method === "GET") {
        const me = who();
        if (!service.db.prepare("SELECT analyst FROM accounts WHERE id = ?").get(me).analyst) {
          throw new Refused(403, "analysts_only");
        }
        if (parts[2] === "absence") return json(service.telemetry.absence());
        return json(service.telemetry.report({ from: url.searchParams.get("from"), to: url.searchParams.get("to") }));
      }
      if (parts[1] === "stores" && parts[2] === "apple" && parts[3] === "notifications"
          && request.method === "POST") {
        // G32: Apple tells the server of a refund, or of one it reversed; the
        // call carries no session, and is believed only as far as Apple
        // signed it.
        if (!appleNotifications) return json({ error: "not_configured" }, 503);
        const n = appleNotifications(text((await body(request)).signedPayload));
        if (!n) return json({ error: "notification_refused" }, 400);
        if (!n.transaction) return json({ type: n.type });
        return json({ type: n.type, ...(n.type === "REFUND_REVERSED"
          ? service.shop.reverseRefund("app-store", n.transaction)
          : service.shop.refund("app-store", n.transaction)) });
      }
      if (["track", "shop", "cosmetics"].includes(parts[1])) {
        const out = await shopRoute(service, request, url, parts, who);
        return out ?? json({ error: "no_such_route" }, 404);
      }
      if (["workshop", "creators", "moderation"].includes(parts[1])) {
        const out = await workshopRoute(workshop, request, url, parts, who);
        return out ?? json({ error: "no_such_route" }, 404);
      }
      switch (route) {
        case "PUT /v1/islands": {
          const owner = who();
          const realm = parts[2] ?? "heart";
          const island = await bytes(request);
          // §13.3: curation's verbs keep a layout generated; an edited
          // terrain makes it authored (curation.mjs).
          return json(service.publish(owner, island, realm, service.curation.origin(owner, realm, island)), 201);
        }
        case "GET /v1/bundles": {
          const body = service.bundle(parts[2] ?? "");
          if (!body) return json({ error: "not_found" }, 404);
          // §24.1: "cached at the edge for a year" — safe because a bundle is
          // addressed by its own hash and never changes. A target list names
          // players and is deleted an hour after it is superseded, so it is
          // cached no longer than that (G38).
          const list = service.isList(parts[2] ?? "");
          return new Response(body, { headers: {
            "content-type": "application/octet-stream",
            "cache-control": list ? `public, max-age=${TARGET_LISTS_MS / 1000}`
                                  : "public, max-age=31536000, immutable",
          } });
        }
        case "POST /v1/leases": {
          const attacker = who();
          const { bundle, owner, trace = false, mode = "raid", challenge, universe = false } = await body(request);
          return json(service.lease(attacker, text(bundle), text(owner, true),
                                    { trace: trace === true, mode, challenge: text(challenge, true),
                                      universe: universe === true }), 201);
        }
        case "GET /v1/heists": {
          if (parts[3] !== "replay") return json({ error: "no_such_route" }, 404);
          return octets(service.replay(who(), parts[2] ?? ""));
        }
        case "PUT /v1/notifications":
          return json(service.notifications.set(who(), await body(request)));
        case "POST /v1/heists": {
          const attacker = who();
          // TD.34: ?crew=12,15,19 names the roster's characters who went.
          const named = new URL(request.url).searchParams.get("crew");
          const crew = named ? named.split(",").map(Number) : null;
          return json(service.submit(attacker, parts[2] ?? "", await bytes(request), crew));
        }
        case "GET /v1/era": {
          who();
          const { id, name, rule, week, endsAt } = service.era();
          return json({ era: id, name, rule, week, endsAt });
        }
        case "GET /v1/offer": {
          // The server's run of §12.22's steps; the device can run the same
          // `offer` on a downloaded target list. The rating that orders it
          // stays here (TD.18): each target says why it was offered instead.
          const me = who();
          const size = Math.min(5, Math.max(1, Number(url.searchParams.get("size") ?? 3) || 3));
          const mm = service.matchmaking;
          const list = offer(mm.raider(me), mm.candidates(), { size });
          return json({ ...list, targets: list.targets.map(({ rating, deviation, predicted, ...c }) => c) });
        }
        case "GET /v1/observatory":
          return json(service.observatory.view(who()));

        case "GET /v1/balance":
          return json(service.balance(who()));
        case "GET /v1/keeper": {
          // The bar, §12.5's planning at this level for the planner, and the
          // Keeper's name (G58).
          const me = who();
          const keeper = service.keeper.view(me);
          return json({ ...keeper, plan: planning(keeper.level), name: service.keeper.name(me) });
        }
        case "PUT /v1/keeper": {
          if (parts[2] !== "name") return json({ error: "no_such_route" }, 404);
          const q = await body(request);
          return json({ name: service.keeper.setName(who(), { adjective: q.adjective, noun: q.noun }) });
        }
        case "GET /v1/protections":
          // §20.2's protections by age band, which the first launch sums up
          // before any account exists: each band's quiet night and monthly
          // spending cap (none for adults), from their one home.
          return json(Object.fromEntries(Object.entries(facts.NIGHT_HOURS).map(([band, night]) =>
            [band, { night, cap: facts.SPENDING_CAPS_EUR[band] ?? null }])));
        case "GET /v1/words":
          // The name word lists, which a first launch reads before any
          // account exists (§25.2, G58): nothing in them is anyone's.
          return json(WORDS);
        case "GET /v1/forms":
          return json(service.home.album(who()));
        case "GET /v1/sages":
          return json(service.keeper.sages(who()));
        case "PUT /v1/sages": {
          if (parts[2] !== "guardian") return json({ error: "no_such_route" }, 404);
          const me = who();
          const { sage = null } = await body(request);
          if (sage !== null && typeof sage !== "string") return json({ error: "malformed_body" }, 400);
          return json(service.keeper.setGuardian(me, sage));
        }
        case "GET /v1/targets":
          who();
          return json(service.targets());
        case "PUT /v1/age": {
          const me = who();
          const { band } = await body(request);
          // §20.11: "no accounts below 13, and immediate deletion of
          // anything collected from someone who turns out to be younger".
          if (band === "under-13") {
            return json({ deleted: true, reason: deleteAccount(service, me, "under-13").reason });
          }
          return json(workshop.setAgeBand(me, band));
        }
        case "GET /account/delete": {
          // G39: deletion without the app, proven with Sign in with Google.
          if (!webClientId) return json({ error: "not_configured" }, 503);
          return deletePage(service, webClientId);
        }
        case "POST /v1/account": {
          if (parts[2] !== "delete") return json({ error: "no_such_route" }, 404);
          // The page's Google ID token, bound to its cookie (auth_http.mjs).
          return await deleteByGoogle(service, request, { signIn, read: body, webClientId });
        }
        case "DELETE /v1/account": {
          // F43: the deletion screen's "withdraw my islands too".
          const me = who();
          const { withdrawIslands = false } = await optional(request);
          return json({ deleted: true, reason: deleteAccount(service, me, "requested",
                                                             { withdraw: withdrawIslands }).reason });
        }
        default:
          return json({ error: "no_such_route" }, 404);
      }
    } catch (err) {
      if (err instanceof Refused) {
        const out = json({ error: err.reason, ...err.detail }, err.status);
        if (err.status === 429 && err.detail?.retryAfter != null) {
          out.headers.set("retry-after", String(err.detail.retryAfter));
        }
        return out;
      }
      if (err instanceof SyntaxError) return json({ error: "malformed_json" }, 400);
      // Anything else is the server's own failure, answered and logged: a
      // request never rejects, so no one request stops a process that is
      // serving the rest.
      console.error(`${route}:`, err);
      return json({ error: "internal" }, 500);
    }
  }
}
