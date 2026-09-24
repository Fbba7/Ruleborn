// The edge function: a web-standard Request in, a Response out (§24.1:
// "Edge functions against a managed serverless SQL database"). It routes and
// translates; every decision is the service's.
//
//   POST /v1/session             {"credential": …}          → {account, token}
//   PUT  /v1/islands/:realm      island bundle bytes         → {bundle}
//   GET  /v1/bundles/:hash       — immutable, cached a year  → bundle bytes
//   POST /v1/leases              {"bundle": hash, "owner"?, "trace"?} → the lease
//   GET  /v1/offer?size=3                                    → §12.22's list for the caller
//   GET  /v1/heists/:token/replay                            → the replay, to its raider or defender (§13)
//   PUT  /v1/notifications       {"utcOffset", "reminder", "nightQuiet", "pushToken"} → the settings
//   POST /v1/heists/:token       replay bytes                → what was settled
//   GET  /v1/balance                                         → {starlight, essence, starglass}
//   GET  /v1/targets                                         → {band: list hash}
//   PUT  /v1/age                 {"band": "13-15"|"16-17"|"18+"} → {ageBand}
//                                {"band": "under-13"}         → the account deleted (§20.11)
//   DELETE /v1/account                                       → the account deleted (§20.5)
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
//   GET  /v1/constellations/:id                              → it, and its members
//   POST /v1/constellations/:id/join                         → joined
//   POST /v1/constellations/:id/roles {"account", "role"}    → an elder named, or unnamed
//   POST /v1/constellations/leave                            → left
//   POST /v1/crews                                           → a crew, and its invite
//   POST /v1/crews/join          {"invite"}                  → joined
//   POST /v1/crews/leave                                     → left
//   GET  /v1/crews/:id                                       → it
//
// The season track (§18.2, §18.8; track.mjs), Starglass and cosmetics
// (§20.2, §22.1; shop.mjs):
//
//   GET  /v1/track?season=N                                  → the track, this season's by default
//   POST /v1/track/claim         {"season"}                  → the next tier, claimed
//   POST /v1/track/premium       {"season"}                  → the premium track, bought with Starglass
//   POST /v1/shop/intents        {"product"}                 → an intent, held under a minor's cap
//   POST /v1/shop/receipts       {"store", "receipt"}        → the Starglass granted
//   GET  /v1/shop/summary                                    → §20.2's monthly spending summary
//   GET  /v1/cosmetics                                       → the catalogue, owned and worn
//   POST /v1/cosmetics/:id/buy                               → bought with Starglass
//   POST /v1/cosmetics/equip     {"kind", "item", "target"?} → what is worn
//
// Telemetry (§24, §24.3; telemetry.mjs):
//
//   POST /v1/events              [{"kind", "data", "at"?}, …] → {recorded}, a batch from the device
//   GET  /v1/metrics?from=&to=                               → the launch gates' figures (analysts)
//   GET  /v1/metrics/absence                                 → §25.3's recency of absence (analysts)
//
// A target list is fetched like a bundle, by its hash (§24.8: "a file, not a
// query"); the index naming the current ones is the only thing that changes.
//
// Everything but the session and a bundle needs `Authorization: Bearer …`.

import { deleteAccount } from "./accounts.mjs";
import { offer } from "./matchmaking.mjs";
import { Refused } from "./service.mjs";
import { Social } from "./social.mjs";
import { WORDS, Workshop } from "./workshop.mjs";

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
 *  is still a few kilobytes. */
async function body(request) {
  const raw = await bytes(request);
  return JSON.parse(new TextDecoder().decode(raw));
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
    if (m === "GET" && a) return json(social.constellation(a));
    if (m === "POST" && a && b === "join") return json(social.join(me, a));
    if (m === "POST" && a && b === "roles") {
      const { account, role } = await body(request);
      return json(social.appoint(me, account, role));
    }
  }
  if (area === "crews") {
    if (m === "POST" && !a) return json(social.startCrew(me), 201);
    if (m === "POST" && a === "join") return json(social.joinCrew(me, (await body(request)).invite));
    if (m === "POST" && a === "leave") return json(social.leaveCrew(me));
    if (m === "GET" && a) return json(social.crew(a));
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
    if (m === "POST" && a === "premium") return json(service.track.buyPremium(me, (await body(request)).season));
  }
  if (area === "shop") {
    if (m === "POST" && a === "intents") return json(service.shop.intent(me, (await body(request)).product), 201);
    if (m === "POST" && a === "receipts") {
      const { store, receipt } = await body(request);
      return json(service.shop.redeem(me, store, receipt), 201);
    }
    if (m === "GET" && a === "summary") return json(service.shop.summary(me));
  }
  if (area === "cosmetics") {
    if (m === "GET" && !a) return json(service.shop.catalogue(me));
    if (m === "POST" && a === "equip") return json(service.shop.equip(me, await body(request)));
    if (m === "POST" && a && b === "buy") return json(service.shop.buy(me, a));
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
                                Number(url.searchParams.get("limit") ?? 20)));
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

export function handler(service) {
  const workshop = new Workshop(service);
  const social = new Social(service);
  return async function handle(request) {
    const url = new URL(request.url);
    const parts = url.pathname.split("/").filter(Boolean);
    const route = `${request.method} /${parts.slice(0, 2).join("/")}`;
    const who = () => service.account(
      (request.headers.get("authorization") ?? "").replace(/^Bearer /, ""));
    try {
      if (["league", "seasons", "constellations", "crews"].includes(parts[1])) {
        const out = await socialRoute(service, social, request, parts, who);
        return out ?? json({ error: "no_such_route" }, 404);
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
      if (["track", "shop", "cosmetics"].includes(parts[1])) {
        const out = await shopRoute(service, request, url, parts, who);
        return out ?? json({ error: "no_such_route" }, 404);
      }
      if (["workshop", "creators", "moderation"].includes(parts[1])) {
        const out = await workshopRoute(workshop, request, url, parts, who);
        return out ?? json({ error: "no_such_route" }, 404);
      }
      switch (route) {
        case "POST /v1/session": {
          const { credential } = await request.json();
          await service.preparePlatform(credential);
          return json(service.session(credential));
        }
        case "PUT /v1/islands": {
          const owner = who();
          return json(service.publish(owner, await bytes(request), parts[2] ?? "heart"), 201);
        }
        case "GET /v1/bundles": {
          const body = service.bundle(parts[2] ?? "");
          if (!body) return json({ error: "not_found" }, 404);
          // §24.1: "cached at the edge for a year" — safe because a bundle is
          // addressed by its own hash and never changes.
          return new Response(body, { headers: {
            "content-type": "application/octet-stream",
            "cache-control": "public, max-age=31536000, immutable",
          } });
        }
        case "POST /v1/leases": {
          const attacker = who();
          const { bundle, owner = null, trace = false } = await request.json();
          return json(service.lease(attacker, bundle, owner, { trace: trace === true }), 201);
        }
        case "GET /v1/heists": {
          if (parts[3] !== "replay") return json({ error: "no_such_route" }, 404);
          return octets(service.replay(who(), parts[2] ?? ""));
        }
        case "PUT /v1/notifications":
          return json(service.notifications.set(who(), await body(request)));
        case "POST /v1/heists": {
          const attacker = who();
          return json(service.submit(attacker, parts[2] ?? "", await bytes(request)));
        }
        case "GET /v1/offer": {
          // The server's run of §12.22's steps; the device can run the same
          // `offer` on a downloaded target list.
          const me = who();
          const size = Math.min(5, Math.max(1, Number(url.searchParams.get("size") ?? 3) || 3));
          const mm = service.matchmaking;
          return json(offer(mm.raider(me), mm.candidates(), { size }));
        }
        case "GET /v1/balance":
          return json(service.balance(who()));
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
        case "DELETE /v1/account":
          return json({ deleted: true, reason: deleteAccount(service, who(), "requested").reason });
        default:
          return json({ error: "no_such_route" }, 404);
      }
    } catch (err) {
      if (err instanceof Refused) return json({ error: err.reason, ...err.detail }, err.status);
      if (err instanceof SyntaxError) return json({ error: "malformed_json" }, 400);
      throw err;
    }
  };
}
