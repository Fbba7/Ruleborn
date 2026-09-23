// Run the server locally:
//
//     node server/src/main.mjs [port]
//
// The edge function (`http.mjs`) behind a plain node:http listener, with the
// database and the object store on disk under server/.data/ and the one
// simulation build this checkout compiles. Platform sign-in is stubbed — a
// credential is taken as the identity it names — because Game Center and Play
// Games need the stores' services; do not expose this to a network.

import { createServer } from "node:http";
import { randomBytes } from "node:crypto";
import { fileURLToPath } from "node:url";
import { dirname, join } from "node:path";

import { open } from "./db.mjs";
import { handler } from "./http.mjs";
import { Service } from "./service.mjs";
import { Builds } from "./sim.mjs";
import { Store } from "./store.mjs";

const here = dirname(fileURLToPath(import.meta.url));
const root = join(here, "..", "..");
const data = join(here, "..", ".data");

const service = new Service({
  db: open(join(data, "ruleborn.sqlite")),
  store: new Store(join(data, "bundles")),
  builds: Builds.load([join(root, "sim/target/wasm32-unknown-unknown/release/ruleborn_sim.wasm")]),
  secret: process.env.RULEBORN_SECRET ?? randomBytes(32).toString("hex"),
  verifyPlatform: (credential) => (typeof credential === "string" && credential ? credential : null),
});
const handle = handler(service);

const port = Number(process.argv[2] ?? 8787);
createServer(async (req, res) => {
  const chunks = [];
  for await (const chunk of req) chunks.push(chunk);
  const body = chunks.length ? Buffer.concat(chunks) : undefined;
  const request = new Request(`http://localhost${req.url}`, {
    method: req.method, headers: req.headers,
    body: req.method === "GET" || req.method === "HEAD" ? undefined : body,
  });
  const response = await handle(request);
  res.writeHead(response.status, Object.fromEntries(response.headers));
  res.end(Buffer.from(await response.arrayBuffer()));
}).listen(port, "127.0.0.1", () => {
  console.log(`ruleborn server on http://127.0.0.1:${port} (rules ${service.builds.current.rulesVersion.slice(0, 12)})`);
});
