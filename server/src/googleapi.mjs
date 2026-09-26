// Google's APIs, called as a service account (§22.1, §24.1).
//
// Two things only Google can say about a Play purchase, and a signed
// receipt cannot: whether it is still paid for, and whether it was a
// licence tester's free purchase. And one thing only Google can do:
// acknowledge it — or, for a gift, which can be bought again, consume it —
// without which Play refunds it after three days whatever the server
// granted (D67). So a Play purchase is looked up and settled with the Play
// Developer API before it is granted, and the purchases Google has voided
// since are asked for once a day (G32).
//
// A service account signs a JWT (RS256) that Google exchanges for an access
// token, kept until shortly before it expires. `fetch` is injected, so the
// tests stand in for Google; nothing here runs without it.

import { createPrivateKey, sign } from "node:crypto";

const b64url = (b) => Buffer.from(b).toString("base64url");

/** How long before its expiry an access token is replaced. */
export const TOKEN_MARGIN_MS = 60 * 1000;
/** How long a call to Google may take. */
export const GOOGLE_TIMEOUT_MS = 10 * 1000;

export const ANDROID_PUBLISHER = "https://www.googleapis.com/auth/androidpublisher";
const PUBLISHER = "https://androidpublisher.googleapis.com/androidpublisher/v3/applications";

/**
 * A service account's access tokens, one per scope. `serviceAccount` is the
 * JSON key Google issues ({client_email, private_key, token_uri}).
 */
export class ServiceAccount {
  constructor({ serviceAccount, fetch, now = () => Date.now() }) {
    const { client_email: email, private_key: key, token_uri: tokenUri } = serviceAccount ?? {};
    if (typeof email !== "string" || typeof key !== "string") throw new Error("a service account needs client_email and private_key");
    this.email = email;
    this.key = createPrivateKey(key);
    this.tokenUri = tokenUri ?? "https://oauth2.googleapis.com/token";
    if (!/^https:\/\/oauth2\.googleapis\.com\//.test(this.tokenUri)) throw new Error("a service account's token_uri must be Google's");
    Object.assign(this, { fetch, now });
    this.tokens = new Map();
    this.pending = new Map();
  }

  /** An access token for `scope`: the one held, or a new one. Callers at
   *  the same moment share one exchange. */
  async token(scope) {
    const held = this.tokens.get(scope);
    if (held && this.now() < held.expires - TOKEN_MARGIN_MS) return held.token;
    if (!this.pending.has(scope)) {
      this.pending.set(scope, this.exchange(scope).finally(() => this.pending.delete(scope)));
    }
    return this.pending.get(scope);
  }

  async exchange(scope) {
    const iat = Math.floor(this.now() / 1000);
    const head = b64url(JSON.stringify({ alg: "RS256", typ: "JWT" }));
    const body = b64url(JSON.stringify({ iss: this.email, scope, aud: this.tokenUri, iat, exp: iat + 3600 }));
    const assertion = `${head}.${body}.${b64url(sign("sha256", Buffer.from(`${head}.${body}`), this.key))}`;
    const response = await this.fetch(this.tokenUri, {
      method: "POST",
      headers: { "content-type": "application/x-www-form-urlencoded" },
      body: new URLSearchParams({ grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer", assertion }).toString(),
      redirect: "error",
      signal: AbortSignal.timeout(GOOGLE_TIMEOUT_MS),
    });
    if (!response.ok) throw new Error(`token exchange: ${response.status}`);
    const answer = await response.json();
    if (typeof answer?.access_token !== "string") throw new Error("token exchange: no access token");
    const life = Number(answer.expires_in) > 0 ? Number(answer.expires_in) * 1000 : 3600 * 1000;
    this.tokens.set(scope, { token: answer.access_token, expires: this.now() + life });
    return answer.access_token;
  }

  /** A call to a Google API with this account's token; `json` is its body. */
  async call(url, { method = "GET", scope, json }) {
    const token = await this.token(scope);
    const body = json === undefined ? undefined : JSON.stringify(json);
    return this.fetch(url, {
      method,
      headers: { authorization: `Bearer ${token}`,
                 ...(body ? { "content-type": "application/json" } : method === "POST" ? { "content-length": "0" } : {}) },
      body,
      redirect: "error",
      signal: AbortSignal.timeout(GOOGLE_TIMEOUT_MS),
    });
  }
}

/**
 * The Play Developer API's side of a purchase. `settle(proof)` resolves
 * `{ok: true}` once Google says the purchase is paid for, not a licence
 * tester's (unless `test`), and acknowledged — acknowledging it now if it is
 * not — or `{ok: false, reason}`. Under F41 an item is bought once and kept,
 * so it is acknowledged, not consumed; a gift ("gift." before the item) can
 * be bought again, so it is consumed. A purchase already acknowledged or
 * consumed is still paid for, and settles: the grant that follows is once
 * per purchase token, so a grant stopped after the store step is made on a
 * retry. `voided(since)` lists the purchases Google has refunded or
 * revoked since then, for G32's daily check.
 */
export class PlayPurchases {
  constructor({ account, packageName, test = false }) {
    Object.assign(this, { account, packageName, test });
  }

  url(proof, verb = "") {
    const e = encodeURIComponent;
    return `${PUBLISHER}/${e(this.packageName)}/purchases/products/${e(proof.product)}/tokens/${e(proof.transaction)}${verb}`;
  }

  async settle(proof) {
    let p;
    try {
      const response = await this.account.call(this.url(proof), { scope: ANDROID_PUBLISHER });
      if (response.status === 404 || response.status === 410) return { ok: false, reason: "no_such_purchase" };
      if (!response.ok) return { ok: false, reason: "store_unavailable" };
      p = await response.json();
    } catch {
      return { ok: false, reason: "store_unavailable" };
    }
    // purchaseState 0 is purchased; 1 cancelled; 2 pending.
    if (p?.purchaseState !== 0) return { ok: false, reason: "not_paid" };
    // purchaseType is absent on a real purchase; 0 is a licence tester's.
    if (p.purchaseType === 0 && !this.test) return { ok: false, reason: "test_purchase" };
    const gift = String(proof.product).startsWith("gift.");
    const settled = gift ? p.consumptionState === 1 : p.acknowledgementState === 1;
    if (!settled) {
      try {
        const done = await this.account.call(this.url(proof, gift ? ":consume" : ":acknowledge"),
                                             { method: "POST", scope: ANDROID_PUBLISHER });
        if (!done.ok) return { ok: false, reason: "store_unavailable" };
      } catch {
        return { ok: false, reason: "store_unavailable" };
      }
    }
    return { ok: true };
  }

  /**
   * The purchase tokens Google has voided — refunded, charged back or
   * revoked — since `since` (ms), across its pages: Play's Voided Purchases
   * API, which keeps 30 days. Rejects if Google cannot be asked, so the
   * caller tries again on its next run rather than skipping a day.
   */
  async voided(since) {
    const e = encodeURIComponent;
    const tokens = [];
    let page = null;
    do {
      const url = `${PUBLISHER}/${e(this.packageName)}/purchases/voidedpurchases?startTime=${Math.floor(since)}` +
                  `&maxResults=1000${page ? `&token=${e(page)}` : ""}`;
      const response = await this.account.call(url, { scope: ANDROID_PUBLISHER });
      if (!response.ok) throw new Error(`voided purchases: ${response.status}`);
      const answer = await response.json();
      for (const v of answer.voidedPurchases ?? []) {
        if (typeof v.purchaseToken === "string") tokens.push(v.purchaseToken);
      }
      page = answer.tokenPagination?.nextPageToken ?? null;
    } while (page);
    return tokens;
  }
}
