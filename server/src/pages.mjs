// The pages the stores ask for (§20.10: "a real privacy policy and terms";
// §20.11: "published contact details"), served by the game's own server so
// no other host is needed (§20.10's "hosted free").
//
// The privacy policy is written from server/privacy.json, the same
// declaration the store forms are answered from (privacy.mjs), so the policy
// cannot say something the server does not do, or miss something it does.
// The terms are server/web/terms.md. The support page gives the operator's
// contact address, which the deployment sets (RULEBORN_CONTACT); without it
// the page is not served, since contact details that reach nobody are not
// contact details.

import { createHash } from "node:crypto";

import { collected, load } from "./privacy.mjs";
import { TERMS, TERMS_VERSION } from "./safety.mjs";

/** The declaration's words for a reader, without its references to the
 *  design (§24.8) and the audit (F43), which mean nothing on the page. */
export const plain = (s) => String(s)
  .replace(/\s*\((?:[§A-Z]?[\d.]+[a-z]?|[A-Z]\d+)(?:,\s*(?:[§A-Z]?[\d.]+|[A-Z]\d+))*(?:;[^)]*)?\)/g, "")
  .replace(/§[\d.]+(?:'s)?\s*/g, "").replace(/\s+([.,;:])/g, "$1");

/** With a capital, for the first word of a cell. */
const cap = (s) => s.charAt(0).toUpperCase() + s.slice(1);

const esc = (s) => String(s).replace(/[&<>"]/g, (c) => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;" })[c]);

const STYLE = `body{font:17px/1.5 system-ui,sans-serif;max-width:42rem;margin:0 auto;padding:1rem 1rem 3rem;
color:#221c3a;background:#fbf8f1}h1{font-size:1.6rem}h2{font-size:1.2rem;margin-top:2rem}
table{border-collapse:collapse;width:100%;font-size:15px}td,th{border-top:1px solid #ccc;padding:.4rem;text-align:left;
vertical-align:top}a{color:#1d4f91}@media(prefers-color-scheme:dark){body{background:#17142a;color:#eee8dc}a{color:#9cc2ff}}`;

/** A CSP source for an inline element's exact text. */
export const hashOf = (text) => `'sha256-${createHash("sha256").update(text).digest("base64")}'`;

/** The headers every page is served with: nothing loads but the page's own
 *  style, no other site frames it, and nothing is sniffed into a type (the
 *  security review's SR-04). */
export const PAGE_HEADERS = Object.freeze({
  "content-security-policy": `default-src 'none'; style-src ${hashOf(STYLE)}; base-uri 'none'; `
    + "form-action 'none'; frame-ancestors 'none'",
  "x-content-type-options": "nosniff",
  "referrer-policy": "no-referrer",
});

function page(title, body) {
  return `<!doctype html><html lang="en"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1"><title>${esc(title)}</title>
<style>${STYLE}</style></head><body>${body}
<p><a href="/terms">Terms of use</a> · <a href="/privacy">Privacy policy</a> · <a href="/support">Support</a></p>
</body></html>`;
}

/** The little markdown terms.md uses: headings, paragraphs, and /paths as links. */
function markdown(text) {
  const out = [];
  for (const block of text.trim().split(/\n\s*\n/)) {
    const line = block.trim();
    const inline = (s) => esc(s).replace(/\(\/([a-z/]+)\)/g, '(<a href="/$1">/$1</a>)');
    if (line.startsWith("## ")) out.push(`<h2>${inline(line.slice(3))}</h2>`);
    else if (line.startsWith("# ")) out.push(`<h1>${inline(line.slice(2))}</h1>`);
    else out.push(`<p>${inline(line.replace(/\n/g, " "))}</p>`);
  }
  return out.join("\n");
}

export function termsPage() {
  return page("Ruleborn: terms of use", markdown(TERMS));
}

/** `webDeletion`: whether /account/delete is served (a web client id is set). */
export function privacyPage(doc = load(), { webDeletion = false } = {}) {
  const types = collected(doc);
  const purposes = (t) => [...new Set([...t.purposes].map((p) => doc.purposes[p].google))].sort().join("; ");
  const kept = (k) => (k.days !== undefined ? `${k.days} days${k.after ? ` after ${plain(k.after)}` : ""}` : {
    account: "as long as your account", record: "for good",
    ever: "for good; it is not about a person", current: "while it is current", ban: "as long as a ban lasts" }[k.for]);
  const deletion = (d) => ({
    erased: "deleted", severed: "kept, under an id that no longer leads to you",
    "erased-under-13": "kept under an id that no longer leads to you; deleted at once for a player under 13",
    kept: "kept; it is not about a person" }[d]);
  // A table kept on deletion that still names a person — a ban's identity —
  // is shown too: it is about someone, and outlives their account.
  const personal = (d) => Object.values(d.columns).some((c) => c.type === "user-id");
  const a = doc.answers;
  const body = [];
  body.push("<h1>Ruleborn: privacy policy</h1>");
  body.push(`<p>This policy is written from the declaration the game's server is checked against, which names
every piece of data the server keeps. It covers the game and its server. The operator is named on the
<a href="/support">support page</a>; the <a href="/terms">terms of use</a> (version ${esc(TERMS_VERSION)}) apply too.</p>`);
  body.push("<h2>What the game keeps, and why</h2><table><tr><th>Data</th><th>Why</th></tr>");
  for (const t of types) body.push(`<tr><td>${esc(cap(plain(doc.types[t.type].about)))}</td><td>${esc(purposes(t))}</td></tr>`);
  body.push("</table>");
  body.push(`<p>There is no advertising, no advertising identifier and no tracking across other apps or websites.
Data is ${a.shared ? "shared" : "not shared or sold"}. Everything sent between the game and its server is encrypted in transit.
Analytics are pseudonymous: events are kept under an id made for them, not your account's.</p>`);
  body.push("<h2>Who else it goes to</h2><ul>");
  for (const f of doc.flows) body.push(`<li>${esc(cap(plain(f.what)))}: ${esc(plain(f.carries))}; to ${esc(plain(f.to))}.</li>`);
  body.push("</ul>");
  body.push("<h2>How long it is kept, and what deleting your account does</h2>");
  body.push("<table><tr><th>What</th><th>Kept</th><th>When you delete your account</th></tr>");
  for (const d of Object.values(doc.tables)) {
    if (d.deletion === "kept" && !personal(d)) continue;
    const gone = d.deletion === "kept" ? plain(d.deletion_note ?? deletion(d.deletion)) : deletion(d.deletion);
    body.push(`<tr><td>${esc(cap(plain(d.about)))}</td><td>${esc(kept(d.keep))}</td><td>${esc(gone)}</td></tr>`);
  }
  for (const f of Object.values(doc.files)) {
    body.push(`<tr><td>${esc(cap(plain(f.about)))}</td><td>${esc(plain(f.keep))}</td><td>${esc(plain(f.deletion))}</td></tr>`);
  }
  body.push("</table>");
  // Pointing at the table above, which is written from the declaration, so
  // the words cannot say more is deleted than the tables are.
  const bans = Object.values(doc.tables).some((d) => d.deletion === "kept" && personal(d));
  body.push(`<h2>Your choices</h2><p>You can delete your account from inside the game${a.deletionUrl && webDeletion
    ? `; if you play with a Google sign-in, you can also delete it on the web at <a href="/account/delete">/account/delete</a>`
    : ""}. What goes and what stays is in the table above: the records other players' results and the stores'
accounts rest on are kept, under an id that no longer leads to you; ${bans ? "a ban is kept on the platform identity it was made against, for as long as it lasts; " : ""}everything else about you is deleted. To ask what the game holds about you, write to the address on the
<a href="/support">support page</a>.</p>`);
  body.push(`<h2>Children</h2><p>Ruleborn is for players aged 13 and over. The game asks your age band, not your
birthdate, when it first starts, and makes no account for anyone under 13. An account that turns out to belong to
someone under 13 is deleted at once, and more goes than on an ordinary deletion: the rows the table above marks as
deleted at once for a player under 13, with their replays and their islands' files. The records other players'
results rest on are kept under an id that leads to no one. Players aged 13 to 17 get extra protections, set by age
band.</p>`);
  return page("Ruleborn: privacy policy", body.join("\n"));
}

/** The operator's contact, or null when the deployment sets none. */
export function supportPage(contact) {
  if (!contact) return null;
  return page("Ruleborn: support", `<h1>Ruleborn: support</h1>
<p>The game is operated by ${esc(contact.name)}. Write to <a href="mailto:${esc(contact.email)}">${esc(contact.email)}</a>
for help, to report something, or about your data. Every report is read by a person within 24 hours.</p>
<p>Inside the game you can report a Workshop island, block another player, and delete your account.</p>`);
}
