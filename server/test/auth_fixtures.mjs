// The real sign-in, for the auth tests: Game Center against the stand-in
// Apple chain (fixtures/apple), Google against keys made here, behind the
// service the other tests use.

import { X509Certificate, createPrivateKey, createSign, generateKeyPairSync, sign } from "node:crypto";
import { readFileSync } from "node:fs";

import { platformProofs } from "../src/auth_proofs.mjs";
import { GameCenter, GoogleSignIn } from "../src/stores.mjs";
import { server } from "./setup.mjs";

const fixture = (name) => readFileSync(new URL(`./fixtures/apple/${name}`, import.meta.url));
const cert = (name) => new X509Certificate(fixture(`${name}.pem`));
const ROOT = cert("root");
const INTERMEDIATE = cert("intermediate");
const GAMECENTER = cert("gamecenter");
export const DEVELOPER = cert("developer");
const BUNDLE = "com.example.ruleborn";
export const NOW = Date.parse(ROOT.validFrom) + 24 * 60 * 60 * 1000;
export const GC_URL = "https://static.gc.apple.com/public-key/gc-prod-6.cer";
export const CLIENT = "123-android.apps.googleusercontent.com";
export const WEB = "123-web.apps.googleusercontent.com";
export const b64url = (b) => Buffer.from(b).toString("base64url");

/** A server whose sign-in is the real one, at the stand-in chain's date. */
export function real({ fetchCertificate = async () => GAMECENTER.raw, ...options } = {}) {
  const clock = { now: NOW };
  const pair = generateKeyPairSync("rsa", { modulusLength: 2048 });
  const jwk = { ...pair.publicKey.export({ format: "jwk" }), kid: "g1", alg: "RS256", use: "sig" };
  const fetched = [];
  const gameCenter = new GameCenter({ roots: [INTERMEDIATE, ROOT], bundleId: BUNDLE, now: () => clock.now,
    fetchCertificate: async (url) => { fetched.push(url); return fetchCertificate(url); } });
  const google = new GoogleSignIn({ clientIds: [CLIENT, WEB], now: () => clock.now,
    fetchKeys: async () => ({ keys: [jwk], maxAgeMs: 3600 * 1000 }) });
  const proofs = platformProofs({ gameCenter, google });
  const t = server({ verifyPlatform: proofs.verify, preparePlatform: proofs.prepare, now: () => clock.now, ...options });
  const idToken = (claims = {}, { alg = "RS256", key = pair.privateKey, kid = "g1" } = {}) => {
    const s = Math.floor(clock.now / 1000);
    const head = b64url(JSON.stringify({ alg, kid, typ: "JWT" }));
    const body = b64url(JSON.stringify({ iss: "https://accounts.google.com", aud: CLIENT, sub: "1098765432101234567",
      iat: s, exp: s + 3600, ...claims }));
    return `${head}.${body}.${b64url(sign("sha256", Buffer.from(`${head}.${body}`), key))}`;
  };
  const signIn = async (credential) => {
    await t.service.preparePlatform(credential);
    return t.service.session(credential);
  };
  return { t, clock, idToken, signIn, fetched, proofs };
}

/** A Game Center identity signature, as the device gets one. */
export function gc({ playerId = "T:_player1", bundleId = BUNDLE, timestamp = NOW, url = GC_URL, salt = "salt-0001",
              key = "gamecenter.key" } = {}) {
  const stamp = Buffer.alloc(8);
  stamp.writeBigUInt64BE(BigInt(timestamp));
  const signer = createSign("RSA-SHA256");
  signer.update(Buffer.concat([Buffer.from(playerId), Buffer.from(bundleId), stamp, Buffer.from(salt)]));
  return { playerId, bundleId, timestamp, publicKeyUrl: url, salt: Buffer.from(salt).toString("base64"),
           signature: signer.sign(createPrivateKey(fixture(key))).toString("base64") };
}

