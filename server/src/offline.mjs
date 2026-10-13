// What the device built, placed and assigned offline, confirmed on
// reconnection (§24's "The device may build, weave and assign work offline,
// confirmed on reconnection; everything else waits for the server").
//
// The server stays authoritative: each action the device kept is made now,
// in the order the player made them, by the same rules as one made online —
// universe.mjs's build and place, home.mjs's work — and answered on its own:
// confirmed, or refused with the reason the online call would have given.
// One refused never stops the rest: a building the Starlight no longer
// covers is refused, and a worker sent to a building that stands is still
// assigned. Each action is its own transaction, as online.
//
// A repeat is confirmed and changes nothing: a build names the level it
// leads to, a placement its tile, and work its building, so a queue the
// phone sends twice — the answer lost on the way back — pays nothing twice.
// The work counts from when the server confirms it (home.mjs's five
// minutes), never from a time the phone claims: the phone's clock is not
// the server's to trust.
//
// Weaving is the third thing §24 lets the device do offline (weaving.mjs):
// a weave names its slot and its law, so it too is confirmed once. Its
// weaving time runs from the server's confirmation, as work's does.

import { Refused } from "./refused.mjs";

/** Actions a reconnecting device may send at once: an evening underground. */
export const MAX_ACTIONS = 50;

const ACTIONS = {
  build: (service, account, a) => service.universe.build(account, a),
  place: (service, account, a) => service.universe.place(account, a),
  work: (service, account, a) => service.home.work(account, a.character,
    a.kind == null ? {} : { realm: a.realm, kind: a.kind, n: a.n ?? 1 }),
  weave: (service, account, a) => service.weaving.weave(account, a),
  unweave: (service, account, a) => service.weaving.unweave(account, a),
};

/** The device's queue made in order: each action's answer, and the
 *  universe and home after them all. */
export function confirm(service, account, actions) {
  if (!Array.isArray(actions) || actions.length === 0 || actions.length > MAX_ACTIONS) {
    throw new Refused(400, "malformed_body", { most: MAX_ACTIONS });
  }
  const results = actions.map((a) => {
    if (a === null || typeof a !== "object" || Array.isArray(a)) return { refused: "malformed_body" };
    const act = Object.hasOwn(ACTIONS, a.do) ? ACTIONS[a.do] : null;
    if (!act) return { refused: "no_such_action" };
    try {
      const answer = act(service, account, a);
      return { confirmed: true, ...(answer?.repeated ? { repeated: true } : {}),
               ...(answer?.keeper ? { keeper: answer.keeper } : {}) };
    } catch (err) {
      if (!(err instanceof Refused)) throw err;
      return { refused: err.reason, ...(err.detail ? { detail: err.detail } : {}) };
    }
  });
  return { results, universe: service.universe.view(account), home: service.home.show(account) };
}
