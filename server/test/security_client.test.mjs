// Security review, second pass: the Godot client's own code
// (docs/security/review.md, SR-27). The client's behaviour is Godot's; what
// Godot does was measured with the engine itself, and each pin here holds
// the client's code to the setting that measurement asks for.

import assert from "node:assert/strict";
import { readdirSync, readFileSync } from "node:fs";
import { test } from "node:test";

const source = (path) => readFileSync(new URL(`../../client/${path}`, import.meta.url), "utf8");

// SR-27: Godot 4.7.2's HTTPRequest follows up to eight redirects and sends
// every header again to wherever one points — another host, plain http —
// so a redirect from anything in front of the server (a proxy rule, a
// moved domain) handed the session token on in the clear. Measured: a 302
// from 127.0.0.1 to http://localhost on another port, and the second host
// was sent "Authorization: Bearer". The server never redirects, so the
// client follows none: Godot then answers RESULT_REDIRECT_LIMIT_REACHED and
// the token stays with the host it was meant for.
test("SR-27: the client follows no redirect, so its token goes to no other host", () => {
  const transport = source("data/http_transport.gd");
  const send = transport.slice(transport.indexOf("func send("));
  const made = send.indexOf("HTTPRequest.new()");
  const capped = send.indexOf("request.max_redirects = 0");
  assert.ok(made > 0 && capped > made && capped < send.indexOf("request.request_raw("),
            "every request is made with no redirects before it is sent");
  // And the transport is the only place the client makes a request.
  const scripts = readdirSync(new URL("../../client/", import.meta.url), { recursive: true })
    .filter((p) => p.endsWith(".gd") && !p.startsWith("tests") && !p.startsWith(".godot"));
  const making = scripts.filter((p) => /HTTP(Request|Client)\.new\(\)/.test(source(p)));
  assert.deepEqual(making, ["data/http_transport.gd"]);
});
