// The edge function: a web-standard Request in, a Response out (§24.1:
// "Edge functions against a managed serverless SQL database"). It routes and
// translates; every decision is the service's.
//
//   POST /v1/session             {"credential": …}          → {account, token}
//   PUT  /v1/islands/:realm      island bundle bytes         → {bundle}
//   GET  /v1/bundles/:hash       — immutable, cached a year  → bundle bytes
//   POST /v1/leases              {"bundle": hash}            → the lease
//   POST /v1/heists/:token       replay bytes                → what was settled
//   GET  /v1/balance                                         → {starlight, essence}
//
// Everything but the session and a bundle needs `Authorization: Bearer …`.

import { Refused } from "./service.mjs";

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

export function handler(service) {
  return async function handle(request) {
    const url = new URL(request.url);
    const parts = url.pathname.split("/").filter(Boolean);
    const route = `${request.method} /${parts.slice(0, 2).join("/")}`;
    const who = () => service.account(
      (request.headers.get("authorization") ?? "").replace(/^Bearer /, ""));
    try {
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
          const { bundle } = await request.json();
          return json(service.lease(attacker, bundle), 201);
        }
        case "POST /v1/heists": {
          const attacker = who();
          return json(service.submit(attacker, parts[2] ?? "", await bytes(request)));
        }
        case "GET /v1/balance":
          return json(service.balance(who()));
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
