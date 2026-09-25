// What the server stores, declared (§20.5, §20.11, §20.12).
//
// §20.10: "What cannot be avoided: truthful privacy declarations on both
// stores". A declaration typed into a store's form is true on the day it is
// typed; this one is read from `server/privacy.json`, which names every
// column of every table — the store data type it is, why it is kept, how
// long, and what deleting its account does to it — and is checked against
// the schema the server actually opens, so a column cannot be added without
// being declared. server/test/privacy.test.mjs checks the deletions and the
// retention it states by doing them.
//
//     node server/src/privacy.mjs            print the declarations
//     node server/src/privacy.mjs --write    write server/declarations.md
//     node server/src/privacy.mjs --check    fail if either has drifted
//
// The answers are in the stores' own words: App Store Connect's App Privacy
// (data types, purposes, linked, tracking) and Google Play's Data safety
// (data types, collected or shared, required or optional, purposes).

import { readFileSync, writeFileSync } from "node:fs";
import { fileURLToPath } from "node:url";

import { open } from "./db.mjs";

export const PRIVACY = new URL("../privacy.json", import.meta.url);
export const DECLARATIONS = new URL("../declarations.md", import.meta.url);

const DELETIONS = ["erased", "severed", "erased-under-13", "kept"];
const COLUMN_DELETIONS = ["cleared", "replaced"];
const UNDER_13 = ["cleared", "unplayed"];
const KEEPS = ["account", "record", "ever", "current", "ban"];
const NAMES = ["account", "account-realm", "pseudonym"];

export function load() {
  return JSON.parse(readFileSync(PRIVACY, "utf8"));
}

/** Every table and its columns, as the server's own schema makes them. */
export function schema(db = open()) {
  const tables = db.prepare(
    "SELECT name FROM sqlite_master WHERE type = 'table' AND name NOT LIKE 'sqlite_%' ORDER BY name").all();
  return Object.fromEntries(tables.map(({ name }) => [name,
    db.prepare(`PRAGMA table_info(${name})`).all().map((c) => c.name)]));
}

/** What is wrong with the declaration: a column stored and not declared, one
 *  declared and not stored, a word the declaration does not know. Empty is
 *  right. */
export function problems(doc = load(), tables = schema()) {
  const out = [];
  for (const [table, columns] of Object.entries(tables)) {
    const d = doc.tables[table];
    if (!d) {
      out.push(`${table}: stored, not declared`);
      continue;
    }
    for (const c of columns) if (!d.columns[c]) out.push(`${table}.${c}: stored, not declared`);
    for (const c of Object.keys(d.columns)) if (!columns.includes(c)) out.push(`${table}.${c}: declared, not stored`);
  }
  for (const table of Object.keys(doc.tables)) if (!tables[table]) out.push(`${table}: declared, not stored`);
  const keep = (where, k) => {
    if (!k) return;
    if (k.days !== undefined) {
      if (!Number.isInteger(k.days) || k.days <= 0 || typeof k.by !== "string") out.push(`${where}: a kept-for-days needs days and by`);
    } else if (!KEEPS.includes(k.for)) {
      out.push(`${where}: kept for ${k.for}?`);
    }
  };
  for (const [table, d] of Object.entries(doc.tables)) {
    if (!DELETIONS.includes(d.deletion)) out.push(`${table}: deletion ${d.deletion}?`);
    keep(table, d.keep);
    if (!d.keep) out.push(`${table}: no keep`);
    // "As long as the account" is false of a row its deletion leaves behind.
    if (d.keep?.for === "account" && d.deletion !== "erased") {
      out.push(`${table}: kept as long as the account, and ${d.deletion} when it is deleted`);
    }
    for (const p of d.purposes ?? []) if (!doc.purposes[p]) out.push(`${table}: purpose ${p}?`);
    if (!d.purposes?.length) out.push(`${table}: no purpose`);
    for (const [c, col] of Object.entries(d.columns)) {
      const where = `${table}.${c}`;
      for (const t of [col.type, ...(col.also ?? [])]) {
        if (t !== "none" && !doc.types[t]) out.push(`${where}: type ${t}?`);
      }
      if (col.deletion && !COLUMN_DELETIONS.includes(col.deletion) && !DELETIONS.includes(col.deletion)) {
        out.push(`${where}: deletion ${col.deletion}?`);
      }
      if (col.deletion_under_13 && !UNDER_13.includes(col.deletion_under_13)) {
        out.push(`${where}: deletion_under_13 ${col.deletion_under_13}?`);
      }
      if (col.names && !NAMES.includes(col.names)) out.push(`${where}: names ${col.names}?`);
      for (const p of col.purposes ?? []) if (!doc.purposes[p]) out.push(`${where}: purpose ${p}?`);
      keep(where, col.keep);
    }
  }
  return out;
}

/** Each data type collected, with the columns that are it, their purposes,
 *  and whether any is tied to a person. The telemetry pseudonym counts as
 *  tied: the server holds the key it is made under, and uses it to delete a
 *  player's events (accounts.mjs), so the stores' "not linked" would not be
 *  true. */
export function collected(doc = load()) {
  const types = new Map();
  for (const [table, d] of Object.entries(doc.tables)) {
    const linked = Object.values(d.columns).some((c) => c.names) || table === "bans";
    for (const [c, col] of Object.entries(d.columns)) {
      for (const t of [col.type, ...(col.also ?? [])]) {
        if (t === "none") continue;
        if (!types.has(t)) types.set(t, { type: t, columns: [], purposes: new Set(), linked: false });
        const entry = types.get(t);
        entry.columns.push(`${table}.${c}`);
        for (const p of col.purposes ?? d.purposes) entry.purposes.add(p);
        entry.linked ||= linked;
      }
    }
  }
  for (const [name, f] of Object.entries(doc.files ?? {})) {
    if (f.type !== "none" && types.has(f.type)) types.get(f.type).columns.push(`files: ${name}`);
  }
  return [...types.values()].sort((a, b) => Object.keys(doc.types).indexOf(a.type) - Object.keys(doc.types).indexOf(b.type));
}

const yes = (b) => (b ? "Yes" : "No");
const uniq = (xs) => [...new Set(xs)];

/** The declarations, as a page the owner fills the two forms from. */
export function render(doc = load()) {
  const types = collected(doc);
  const L = [];
  L.push("# Store declarations");
  L.push("");
  L.push("Written by `server/src/privacy.mjs` from `server/privacy.json`, which declares every column the");
  L.push("server stores; do not edit here. What the forms ask, answered from what the server does.");
  L.push("");
  L.push("## App Store Connect: App Privacy");
  L.push("");
  L.push(`Do you or your third-party partners collect data from this app? **Yes.** Used to track you: **none** — no data type is used for tracking, and Ruleborn has no advertising (§20.2).`);
  L.push("");
  L.push("| Category | Data type | Purposes | Linked to the user | Used for tracking | What it is |");
  L.push("|---|---|---|---|---|---|");
  const appleRows = new Map();
  for (const t of types) {
    const [category, name] = doc.types[t.type].apple;
    const key = `${category}|${name}`;
    const row = appleRows.get(key) ?? { category, name, purposes: [], linked: false, about: [] };
    row.purposes.push(...[...t.purposes].map((p) => doc.purposes[p].apple));
    row.linked ||= t.linked;
    row.about.push(doc.types[t.type].about);
    appleRows.set(key, row);
  }
  for (const r of appleRows.values()) {
    L.push(`| ${r.category} | ${r.name} | ${uniq(r.purposes).sort().join(", ")} | ${yes(r.linked)} | No | ${uniq(r.about).join("; ")} |`);
  }
  L.push("");
  L.push("## Google Play: Data safety");
  L.push("");
  const a = doc.answers;
  L.push(`- Does your app collect or share any of the required user data types? **Yes** (collected; shared: **${yes(a.shared)}**).`);
  L.push(`- Is all of the user data collected by your app encrypted in transit? **${yes(a.encryptedInTransit)}**.`);
  L.push(`- Account creation: **${a.accountCreation}**.`);
  L.push(`- Deletion: account deletion inside the app **${yes(a.deletionInApp)}**; a web link to request deletion: **${a.deletionUrl ?? "none yet (G39)"}**; deleting some data without the account: **${yes(a.partialDeletion)}**.`);
  L.push("");
  L.push("| Category | Data type | Collected | Shared | Processed ephemerally | Required or optional | Purposes |");
  L.push("|---|---|---|---|---|---|---|");
  const googleRows = new Map();
  for (const t of types) {
    const [category, name] = doc.types[t.type].google;
    const key = `${category}|${name}`;
    const row = googleRows.get(key) ?? { category, name, purposes: [], optional: true };
    row.purposes.push(...[...t.purposes].map((p) => doc.purposes[p].google));
    row.optional &&= Boolean(doc.types[t.type].optional);
    googleRows.set(key, row);
  }
  for (const r of googleRows.values()) {
    L.push(`| ${r.category} | ${r.name} | Yes | No | No | ${r.optional ? "Optional" : "Required"} | ${uniq(r.purposes).sort().join(", ")} |`);
  }
  L.push("");
  L.push("## Where each data type is stored");
  L.push("");
  for (const t of types) {
    L.push(`- **${doc.types[t.type].apple[1]}** (${doc.types[t.type].about}): ${t.columns.map((c) => `\`${c}\``).join(", ")}.`);
  }
  L.push("");
  L.push("## What deleting an account does, table by table");
  L.push("");
  L.push("Erased: gone. Severed: kept, under an account id that no longer leads to anyone (F43). Kept: not about a person.");
  L.push("");
  L.push("| Table | Deleted at the player's request | Deleted because the player is under 13 | Kept for |");
  L.push("|---|---|---|---|");
  const kept = (k) => (k.days !== undefined ? `${k.days} days${k.after ? ` after ${k.after}` : ""} (\`${k.by}\`)` : {
    account: "as long as the account", record: "good: a record (F43)", ever: "good: not about a person",
    current: "while current", ban: "as long as the ban" }[k.for]);
  for (const [table, d] of Object.entries(doc.tables)) {
    const requested = d.deletion === "erased-under-13" ? "severed" : d.deletion;
    const young = d.deletion === "erased-under-13" ? "erased" : d.deletion;
    const note = d.deletion_note ? ` — ${d.deletion_note}` : "";
    L.push(`| \`${table}\` | ${requested} | ${young}${note} | ${kept(d.keep)} |`);
  }
  L.push("");
  L.push("## Outside the database");
  L.push("");
  for (const [name, f] of Object.entries(doc.files)) {
    L.push(`- \`${name}\`: ${f.about}. Kept ${f.keep}. On deletion: ${f.deletion}.`);
  }
  for (const f of doc.flows) L.push(`- ${f.what}: ${f.carries}; to ${f.to}.`);
  L.push("");
  return L.join("\n");
}

if (process.argv[1] === fileURLToPath(import.meta.url)) {
  const found = problems();
  if (found.length) {
    for (const p of found) console.error(`  ${p}`);
    console.error(`server/privacy.json: ${found.length} problem(s)`);
    process.exit(1);
  }
  const page = render();
  if (process.argv.includes("--write")) {
    writeFileSync(DECLARATIONS, page);
    console.log(`  wrote server/declarations.md: ${collected().length} data types`);
  } else if (process.argv.includes("--check")) {
    let had = "";
    try { had = readFileSync(DECLARATIONS, "utf8"); } catch {}
    if (had !== page) {
      console.error("server/declarations.md has drifted from server/privacy.json: node server/src/privacy.mjs --write");
      process.exit(1);
    }
    const n = Object.values(load().tables).reduce((s, t) => s + Object.keys(t.columns).length, 0);
    console.log(`  privacy: every one of ${n} stored columns declared; server/declarations.md matches`);
  } else {
    process.stdout.write(page);
  }
}
