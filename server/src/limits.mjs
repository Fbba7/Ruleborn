// How fast one account, or one address, may ask (C26, G44). A token bucket
// a caller and a kind of request: it holds `burst` requests and refills at
// `per` milliseconds a request, so a burst — the app's launch, a phone back
// online with its outbox — is answered, and a steady stream past the refill
// is refused with 429 and how long to wait.
//
// The buckets live in the process's memory, never in the database: a limit
// that wrote a row a request would bill more than what it protects (F47).
// On the edge each isolate keeps its own, so a caller spread across isolates
// gets more; the platform's own rate limiting, keyed the same way, is what
// holds it there (G44). Memory is bounded a kind at a time: past `most`
// callers of a kind, the one of that kind longest idle is forgotten, which
// gives it a full bucket back — and never lets callers of one kind, such as
// sign-ins from addresses anyone can vary, push out another's.

/** The kinds, what each covers, and its bucket. */
export const KINDS = {
  // Everything a signed-in player asks, by account: two a second, sixty at
  // once.
  calls: { burst: 60, per: 500 },
  // What runs the simulation, by account — a replay re-simulated (§24.2), an
  // island or a Workshop entry checked — about 15 ms of CPU each (F47): one
  // every 20 seconds, six at once. What waits in the phone's outbox to be
  // sent together is its heists, at most the lease stock's three, and
  // Workshop plays.
  simulations: { burst: 6, per: 20_000 },
  // A sign-in, or G39's deletion without the app, by the account it proves:
  // ten at once, then one every 10 seconds. The app keeps its session for
  // the hour it lasts, so this is the phone signing in again and again.
  signIns: { burst: 10, per: 10_000 },
  // A sign-in that failed, by address: each verified a platform's signature,
  // and some fetched its keys, for nothing. Only failures are counted, so
  // players who share an address — a school's, a carrier's — are never held
  // by each other's sign-ins; twenty at once, then one every 3 seconds.
  failedSignIns: { burst: 20, per: 3_000 },
  // What a caller may ask before signing in that is not a sign-in — a
  // sign-in nonce, the deletion page — by address, where the deployment can
  // tell it: a signed-in player's rate (SEC-34).
  unsigned: { burst: 60, per: 500 },
};

export class Limiter {
  constructor({ kinds = KINDS, most = 50_000 } = {}) {
    this.kinds = kinds;
    this.most = most;
    this.buckets = new Map(Object.keys(kinds).map((k) => [k, new Map()]));
  }

  /** The bucket of `kind` for `key` at `now`, refilled, and taken out of its
   *  map (take and peek put it back as the newest). */
  #refilled(kind, key, now) {
    const { burst, per } = this.kinds[kind];
    const b = this.buckets.get(kind).get(key);
    if (!b) return burst;
    this.buckets.get(kind).delete(key);
    return Math.min(burst, b.tokens + Math.max(0, now - b.at) / per);
  }

  #keep(kind, key, tokens, now) {
    const map = this.buckets.get(kind);
    map.set(key, { tokens, at: now });
    if (map.size > this.most) map.delete(map.keys().next().value);
  }

  /** Take one request of `kind` for `key` at `now`: 0 if it may go ahead,
   *  else the milliseconds until it may. */
  take(kind, key, now) {
    let tokens = this.#refilled(kind, key, now);
    let wait = 0;
    if (tokens >= 1) tokens -= 1;
    else wait = Math.ceil((1 - tokens) * this.kinds[kind].per);
    this.#keep(kind, key, tokens, now);
    return wait;
  }

  /** What take() would answer, taking nothing: a key never seen is not
   *  stored. */
  peek(kind, key, now) {
    if (!this.buckets.get(kind).has(key)) return 0;
    const tokens = this.#refilled(kind, key, now);
    this.#keep(kind, key, tokens, now);
    return tokens >= 1 ? 0 : Math.ceil((1 - tokens) * this.kinds[kind].per);
  }
}

/** The key an address is limited by: an IPv4 address as it is, and an
 *  IPv4-mapped IPv6 address (::ffff:a.b.c.d, however it is written) as its
 *  IPv4 address (FX1-A-10); any other IPv6 one by its /64, the block one
 *  subscriber is given, so a caller cannot take a fresh bucket for each of
 *  its 2^64 addresses. */
export function peerKey(address) {
  const a = String(address ?? "").trim().split("%")[0].toLowerCase();
  if (!a) return null;
  if (!a.includes(":")) return a;
  // A dotted tail is the last two groups.
  const hex = (part) => part ? part.split(":").flatMap((g) => {
    const dotted = /^(\d+)\.(\d+)\.(\d+)\.(\d+)$/.exec(g);
    if (!dotted) return [Number.parseInt(g, 16) || 0];
    const [b0, b1, b2, b3] = dotted.slice(1).map(Number);
    return [b0 * 256 + b1, b2 * 256 + b3];
  }) : [];
  const [head, tail] = a.split("::");
  const h = hex(head);
  const t = a.includes("::") ? hex(tail) : [];
  const groups = a.includes("::") ? [...h, ...Array(Math.max(0, 8 - h.length - t.length)).fill(0), ...t] : h;
  if (groups.length === 8 && groups.slice(0, 5).every((g) => g === 0) && groups[5] === 0xffff) {
    return [groups[6] >> 8, groups[6] & 255, groups[7] >> 8, groups[7] & 255].join(".");
  }
  return `${groups.slice(0, 4).map((g) => g.toString(16)).join(":")}::/64`;
}
