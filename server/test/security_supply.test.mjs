// Security review, second pass: what the build downloads and ships
// (docs/security/review.md, SR-26).

import assert from "node:assert/strict";
import { spawnSync } from "node:child_process";
import { chmodSync, existsSync, mkdirSync, mkdtempSync, readFileSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { test } from "node:test";
import { fileURLToPath } from "node:url";

const client = fileURLToPath(new URL("../../client/", import.meta.url));
// Godot's own SHA512-SUMS.txt for 4.7.2-stable, read 27 October 2026; the
// editor's matched a fresh download and the binary these checks run.
const EDITOR = "9aa00f7a605200940bce3027a567b782f49bd8e940dd06ae9e987bd65aee1b1467edd56ed84fcdcbdd44354bf613bdbb4e5d2913e925850368e150c59ed54c65";
const TEMPLATES = "ca4d71c4d7b81dfc15d1a98baa07534aa95b03fdda78a0075b06672e1648d2e5f40980c9adc28d23e1b92e732ee7bf3461997aa804af74ec2fcd7a93ccb84079";

// SR-26: the Godot editor the checks run, and the export templates that
// become the app players install, were fetched and unpacked with no check
// of what arrived. Now each is held to Godot's published SHA-512 first.
test("SR-26: a Godot download that is not Godot's own is refused before it is unpacked", () => {
  const home = mkdtempSync(join(tmpdir(), "rb-sr26-"));
  const bin = join(home, "bin");
  mkdirSync(bin);
  // A curl that answers every download with someone else's bytes, as a
  // swapped release asset or a trusted proxy would.
  writeFileSync(join(bin, "curl"), `#!/usr/bin/env bash
while [ $# -gt 0 ]; do if [ "$1" = -o ]; then out="$2"; shift; fi; shift; done
python3 - "$out" <<'EOF'
import sys, zipfile
with zipfile.ZipFile(sys.argv[1], "w") as z:
    z.writestr("Godot_v4.7.2-stable_linux.x86_64", "#!/bin/sh\\necho tampered\\n")
EOF
`);
  chmodSync(join(bin, "curl"), 0o755);
  const env = { ...process.env, HOME: home, PATH: `${bin}:${process.env.PATH}` };
  delete env.RULEBORN_GODOT;
  const run = spawnSync("bash", [join(client, "build.sh")], { env, encoding: "utf8" });
  assert.notEqual(run.status, 0, "the build stops");
  assert.match(run.stderr, /does not match its pinned sum/);
  const cache = join(home, ".cache", "ruleborn");
  assert.ok(!existsSync(join(cache, "Godot_v4.7.2-stable_linux.x86_64")), "nothing unpacked");
  assert.ok(!existsSync(join(cache, "Godot_v4.7.2-stable_linux.x86_64.zip")), "and the download is gone");

  // The pins are Godot's, and the templates are checked before they are
  // unpacked into the export directory.
  assert.ok(readFileSync(join(client, "build.sh"), "utf8").includes(EDITOR));
  const exporter = readFileSync(join(client, "export.sh"), "utf8");
  const checked = exporter.indexOf(TEMPLATES);
  assert.ok(checked > 0 && checked < exporter.indexOf("zipfile.ZipFile(sys.argv[1])"), "templates checked first");
});
