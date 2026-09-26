// Push notifications through Firebase Cloud Messaging (§14.6, §24.1; D68).
//
// §24.1 names Firebase Cloud Messaging for push; it reaches Android devices
// and, through Apple's service, iPhones, by one registration token a
// device. A message is sent with FCM's HTTP v1 API as the project's service
// account (googleapi.mjs). What the player reads is the device's own
// language: the message names localisation keys, which the app's native
// string tables hold, and its data carries what the app needs to open the
// right screen. The outcome is what notifications.deliver acts on: sent, a
// token that is gone, one to try again, or one refused for good.

export const FCM_SCOPE = "https://www.googleapis.com/auth/firebase.messaging";

/** The localisation keys each kind of notification names (the client's
 *  native string tables must hold them), and its arguments. */
export const KEYS = {
  raided: (m) => ({ title: "ruleborn_raided_title", body: "ruleborn_raided_body",
                    args: [String(m.heists?.length ?? 1)] }),
  // A day's raids gathered into the reminder (G34) are named in it, so a
  // player with a reminder still reads that they were raided.
  reminder: (m) => (m.heists?.length
    ? { title: "ruleborn_reminder_raided_title", body: "ruleborn_reminder_raided_body",
        args: [String(m.heists.length)] }
    : { title: "ruleborn_reminder_title", body: "ruleborn_reminder_body", args: [] }),
};

export class Fcm {
  constructor({ account, projectId }) {
    if (typeof projectId !== "string" || !/^[a-z0-9-]{1,64}$/.test(projectId)) throw new Error("an FCM project id is needed");
    Object.assign(this, { account, projectId });
    this.url = `https://fcm.googleapis.com/v1/projects/${projectId}/messages:send`;
  }

  /**
   * The v1 message for one device: localisation keys to show, and as data
   * only what the app needs to open the right screen — a raid notification
   * says how many raids and the latest, never the whole night's list, which
   * would outgrow FCM's 4 KB and tell Google and Apple more than they need.
   * It expires when `expiresAt` says (Notifications.expires): FCM and Apple
   * hold it for a phone that is off or asleep only until then. Each kind
   * collapses only with its own kind, so a reminder never replaces a raid.
   */
  message(token, m, { expiresAt, now } = {}) {
    const keys = (KEYS[m.kind] ?? KEYS.reminder)(m);
    const data = { kind: String(m.kind) };
    if (Array.isArray(m.heists)) {
      data.count = String(m.heists.length);
      data.latest = String(m.heists.at(-1)?.heist ?? "");
    }
    if (typeof m.day === "string") data.day = m.day;
    const android = { priority: "high", collapse_key: String(m.kind), notification: {
      tag: String(m.kind), title_loc_key: keys.title, body_loc_key: keys.body, body_loc_args: keys.args } };
    const headers = { "apns-priority": "10", "apns-collapse-id": String(m.kind) };
    if (Number.isFinite(expiresAt) && Number.isFinite(now)) {
      android.ttl = `${Math.max(0, Math.floor((expiresAt - now) / 1000))}s`;
      headers["apns-expiration"] = String(Math.max(0, Math.floor(expiresAt / 1000)));
    }
    return { message: {
      token, data, android,
      apns: { headers, payload: { aps: { alert: {
        "title-loc-key": keys.title, "loc-key": keys.body, "loc-args": keys.args } } } },
    } };
  }

  /** Send one; resolves what became of it, never rejects. A retry names
   *  its reason, for the operator's log. */
  async send(token, m, options = {}) {
    let response;
    try {
      response = await this.account.call(this.url, { method: "POST", scope: FCM_SCOPE, json: this.message(token, m, options) });
    } catch (err) {
      return { retry: true, reason: /token exchange/.test(String(err?.message)) ? "token exchange" : "network" };
    }
    if (response.ok) return { ok: true };
    let error = null;
    try {
      error = (await response.json())?.error;
    } catch {
      // no body to read
    }
    const details = Array.isArray(error?.details) ? error.details : [];
    const code = details.find((d) => d?.errorCode)?.errorCode ?? error?.status;
    const status = response.status;
    // The device uninstalled the app or its token was replaced; or the token
    // itself is malformed, which FCM names as the field at fault.
    const badToken = details.some((d) => Array.isArray(d?.fieldViolations)
      && d.fieldViolations.some((v) => v?.field === "message.token"));
    if (status === 404 || code === "UNREGISTERED" || badToken) return { gone: true };
    // Busy, down, or the server's own credentials failing: try again later,
    // and say why, so a broken key shows in the log.
    if (status === 429 || status >= 500 || status === 401 || status === 403) return { retry: true, status, code: code ?? null };
    // Anything else — a message FCM will never take — is not sent twice.
    return { dropped: true, status, code: code ?? null };
  }
}
