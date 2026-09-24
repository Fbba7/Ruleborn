// The edge function: a web-standard Request in, a Response out (§24.1:
// "Edge functions against a managed serverless SQL database"). It routes and
// translates; every decision is the service's.
//
//   POST /v1/session             {"credential": …}          → {account, token}
//   PUT  /v1/islands/:realm      island bundle bytes         → {bundle}
//   GET  /v1/bundles/:hash       — immutable, cached a year  → bundle bytes
//   POST /v1/leases              {"bundle": hash, "owner"?}  → the lease
//   POST /v1/heists/:token       replay bytes                → what was settled
//   GET  /v1/balance                                         → {starlight, essence}
//   GET  /v1/targets                                         → {band: list hash}
//   PUT  /v1/age                 {"band": "13-15"|"16-17"|"18+"} → {ageBand}
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
// A target list is fetched like a bundle, by its hash (§24.8: "a file, not a
// query"); the index naming the current ones is the only thing that changes.
//
// Everything but the session and a bundle needs `Authorization: Bearer …`.

import { Refused } from "./service.mjs";
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
  return async function handle(request) {
    const url = new URL(request.url);
    const parts = url.pathname.split("/").filter(Boolean);
    const route = `${request.method} /${parts.slice(0, 2).join("/")}`;
    const who = () => service.account(
      (request.headers.get("authorization") ?? "").replace(/^Bearer /, ""));
    try {
      if (["workshop", "creators", "moderation"].includes(parts[1])) {
        const out = await workshopRoute(workshop, request, url, parts, who);
        return out ?? json({ error: "no_such_route" }, 404);
      }
      switch (route) {
        case "POST /v1/session": {
          const { credential } = await request.json();
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
          const { bundle, owner = null } = await request.json();
          return json(service.lease(attacker, bundle, owner), 201);
        }
        case "POST /v1/heists": {
          const attacker = who();
          return json(service.submit(attacker, parts[2] ?? "", await bytes(request)));
        }
        case "GET /v1/balance":
          return json(service.balance(who()));
        case "GET /v1/targets":
          who();
          return json(service.targets());
        case "PUT /v1/age":
          return json(workshop.setAgeBand(who(), (await body(request)).band));
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
