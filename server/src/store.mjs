// Content-addressed object storage (§24.1, §24.8).
//
// "Large immutable things in storage, addressed by the hash of their
// contents. … Publishing writes an immutable bundle to storage under its own
// hash. Nothing is ever updated in place, which is what makes year-long
// caching safe."
//
// A key is the SHA-256 of the bytes, computed here with Node's own
// implementation. When the caller also has the simulation's hash of the same
// bytes, `put` requires the two to agree, so sim/'s SHA-256 is checked against
// an independent one on every island the server stores.

import { createHash } from "node:crypto";
import { closeSync, existsSync, fsyncSync, mkdirSync, openSync, readFileSync, readdirSync, renameSync, statfsSync,
  unlinkSync, writeFileSync } from "node:fs";
import { join } from "node:path";

import { Refused } from "./refused.mjs";

export const sha256 = (bytes) => createHash("sha256").update(bytes).digest("hex");

const KEY = /^[0-9a-f]{64}$/;

/** A directory's entries onto the disk, so a file renamed into it stays. */
function syncDirectory(dir) {
  const fd = openSync(dir, "r");
  try {
    fsyncSync(fd);
  } finally {
    closeSync(fd);
  }
}

export class Store {
  /** In memory without a directory; on disk with one. `minFreeBytes`, when
   *  set, refuses a new object (503 storage_low) while the volume has less
   *  free than that, so a filling store stops before the database and the
   *  deletions journal run out of room (SEC-18). */
  constructor(dir = null, { minFreeBytes = 0 } = {}) {
    this.dir = dir;
    this.minFreeBytes = minFreeBytes;
    this.memory = new Map();
    if (dir) mkdirSync(dir, { recursive: true });
  }

  path(key) {
    return join(this.dir, key.slice(0, 2), key);
  }

  /** Store bytes under their hash and return it. Idempotent. `durable`
   *  waits until the object, and its name in its directory, are on the disk
   *  itself, not only in the system's cache: a write that must survive a
   *  crash before what follows it is made (the deletion journal, F50). */
  put(bytes, expected = null, { durable = false } = {}) {
    const key = sha256(bytes);
    if (expected !== null && expected !== key) {
      throw new Error(`hash disagreement: storage ${key}, simulation ${expected}`);
    }
    if (this.dir) {
      const path = this.path(key);
      if (!existsSync(path)) {
        if (this.minFreeBytes) {
          const fs = statfsSync(this.dir);
          if (fs.bavail * fs.bsize < this.minFreeBytes) throw new Refused(503, "storage_low");
        }
        mkdirSync(join(this.dir, key.slice(0, 2)), { recursive: true });
        // Written beside and renamed, so a reader never sees half an object.
        if (durable) {
          const fd = openSync(`${path}.part`, "w");
          try {
            writeFileSync(fd, bytes);
            fsyncSync(fd);
          } finally {
            closeSync(fd);
          }
        } else {
          writeFileSync(`${path}.part`, bytes);
        }
        renameSync(`${path}.part`, path);
        if (durable) {
          syncDirectory(join(this.dir, key.slice(0, 2)));
          syncDirectory(this.dir);
        }
      }
    } else if (!this.memory.has(key)) {
      this.memory.set(key, Uint8Array.from(bytes));
    }
    return key;
  }

  /** Remove an object. Content-addressed storage is never changed in place,
   *  but some of it is kept only so long: §24.3's replays. */
  delete(key) {
    if (!KEY.test(key)) return;
    if (this.dir) {
      const path = this.path(key);
      if (existsSync(path)) unlinkSync(path);
    } else {
      this.memory.delete(key);
    }
  }

  /** Every key held. */
  keys() {
    if (!this.dir) return [...this.memory.keys()];
    return readdirSync(this.dir).filter((d) => /^[0-9a-f]{2}$/.test(d))
      .flatMap((d) => readdirSync(join(this.dir, d)).filter((k) => KEY.test(k)));
  }

  get(key) {
    if (!KEY.test(key)) return null;
    if (this.dir) {
      const path = this.path(key);
      return existsSync(path) ? new Uint8Array(readFileSync(path)) : null;
    }
    return this.memory.get(key) ?? null;
  }
}
