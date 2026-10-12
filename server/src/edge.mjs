// An under-13 player's islands, purged from the edge's cache (§20.11, D70).
//
// §20.11: "immediate deletion of anything collected from someone who turns
// out to be younger". An under-13 deletion deletes their islands' bytes from
// the server's store (accounts.mjs), but a bundle is "cached at the edge for
// a year" (§24.1's architecture) by its hash, so the bytes would go on being
// served from the edge's cache for a year after the store let them go.
//
// So the deletion's transaction also queues each erased bundle's URL in
// `edge_purges`, and `purgeEdge` asks the edge to drop them, a batch at a
// time. A purge is never given up: one the edge refuses or cannot take now
// waits PURGE_RETRY_MS a try, up to PURGE_RETRY_MAX_MS, and the operator's
// log says why every time. The row is deleted when the edge confirms, so
// what is kept is only what is still to purge.
//
// The edge is Cloudflare's (§24.1's prices are its Workers', D1's and R2's),
// and `CloudflarePurge` is its purge-by-URL call. Without one configured —
// the node server in development, the tests — the purges wait.

/** URLs a purge call: Cloudflare's limit for purging by URL. */
export const PURGE_BATCH = 30;
export const PURGE_RETRY_MS = 5 * 60 * 1000;
export const PURGE_RETRY_MAX_MS = 6 * 60 * 60 * 1000;
const FETCH_TIMEOUT_MS = 5000;

/** Where a bundle is served (http.mjs: GET /v1/bundles/:hash). */
export const bundlePath = (hash) => `/v1/bundles/${hash}`;

/** Cloudflare's purge by URL, for a zone, with an API token that may purge
 *  it. `origin` is the public origin the bundles are served under. */
export class CloudflarePurge {
  constructor({ zone, token, origin, fetch: get = fetch }) {
    if (!/^[0-9a-f]{32}$/.test(zone ?? "")) throw new Error("a Cloudflare zone id is 32 hex digits");
    if (!token) throw new Error("a Cloudflare purge needs an API token");
    if (!/^https:\/\/[^/]+$/.test(origin ?? "")) throw new Error("the bundles' origin is https://host, no path");
    Object.assign(this, { zone, token, origin, get });
  }

  /** `{ok: true}` once the edge has taken every path, or `{ok: false,
   *  reason}`. */
  async purge(paths) {
    try {
      const response = await this.get(`https://api.cloudflare.com/client/v4/zones/${this.zone}/purge_cache`, {
        method: "POST",
        redirect: "error",
        signal: AbortSignal.timeout(FETCH_TIMEOUT_MS),
        headers: { authorization: `Bearer ${this.token}`, "content-type": "application/json" },
        body: JSON.stringify({ files: paths.map((p) => `${this.origin}${p}`) }),
      });
      const body = await response.json().catch(() => ({}));
      if (response.ok && body.success === true) return { ok: true };
      const code = body.errors?.[0]?.code;
      return { ok: false, reason: `${response.status}${code ? ` ${code}` : ""}` };
    } catch (err) {
      return { ok: false, reason: err.name === "TimeoutError" ? "timeout" : "unreachable" };
    }
  }
}

/** Queue a bundle's purge, inside the deletion's transaction. */
export function queuePurge(db, hash, now) {
  db.prepare("INSERT OR IGNORE INTO edge_purges (path, queued_at, due_at) VALUES (?, ?, ?)")
    .run(bundlePath(hash), now, now);
}

/**
 * Every purge due, asked of `service.edge` a batch at a time. Returns what
 * became of them: `{purged, waiting, reasons}`, `waiting` counting those
 * left for later, with no edge or after a refusal. A call still purging
 * makes the next one wait.
 */
export async function purgeEdge(service, now = service.now()) {
  const db = service.db;
  const waiting = () => db.prepare("SELECT COUNT(*) AS n FROM edge_purges").get().n;
  if (!service.edge || service.purging) return { purged: 0, waiting: waiting(), reasons: {} };
  service.purging = true;
  const reasons = {};
  let purged = 0;
  try {
    const due = db.prepare("SELECT path, attempts FROM edge_purges WHERE due_at <= ? ORDER BY queued_at, path")
      .all(now);
    for (let i = 0; i < due.length; i += PURGE_BATCH) {
      const batch = due.slice(i, i + PURGE_BATCH);
      const outcome = await service.edge.purge(batch.map((p) => p.path));
      for (const p of batch) {
        if (outcome?.ok) {
          db.prepare("DELETE FROM edge_purges WHERE path = ?").run(p.path);
          purged++;
        } else {
          const attempts = p.attempts + 1;
          const wait = Math.min(PURGE_RETRY_MS * 2 ** (attempts - 1), PURGE_RETRY_MAX_MS);
          db.prepare("UPDATE edge_purges SET attempts = ?, due_at = ? WHERE path = ?").run(attempts, now + wait, p.path);
        }
      }
      if (!outcome?.ok) {
        const why = outcome?.reason ?? "unknown";
        reasons[why] = (reasons[why] ?? 0) + batch.length;
      }
    }
  } finally {
    service.purging = false;
  }
  return { purged, waiting: waiting(), reasons };
}
