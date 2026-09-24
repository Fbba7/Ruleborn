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
import { mkdirSync, readFileSync, writeFileSync, existsSync, renameSync, unlinkSync } from "node:fs";
import { join } from "node:path";

export const sha256 = (bytes) => createHash("sha256").update(bytes).digest("hex");

const KEY = /^[0-9a-f]{64}$/;

export class Store {
  /** In memory without a directory; on disk with one. */
  constructor(dir = null) {
    this.dir = dir;
    this.memory = new Map();
    if (dir) mkdirSync(dir, { recursive: true });
  }

  path(key) {
    return join(this.dir, key.slice(0, 2), key);
  }

  /** Store bytes under their hash and return it. Idempotent. */
  put(bytes, expected = null) {
    const key = sha256(bytes);
    if (expected !== null && expected !== key) {
      throw new Error(`hash disagreement: storage ${key}, simulation ${expected}`);
    }
    if (this.dir) {
      const path = this.path(key);
      if (!existsSync(path)) {
        mkdirSync(join(this.dir, key.slice(0, 2)), { recursive: true });
        // Written beside and renamed, so a reader never sees half an object.
        writeFileSync(`${path}.part`, bytes);
        renameSync(`${path}.part`, path);
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

  get(key) {
    if (!KEY.test(key)) return null;
    if (this.dir) {
      const path = this.path(key);
      return existsSync(path) ? new Uint8Array(readFileSync(path)) : null;
    }
    return this.memory.get(key) ?? null;
  }
}
