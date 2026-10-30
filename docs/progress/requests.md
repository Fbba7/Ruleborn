# Requests

The register of asks between agents, copied by the lead from each agent's
status file at every cycle ([agent-protocol.md](../guides/agent-protocol.md#messages-and-requests)),
grouped under the addressee, with the answer once one is pushed. Read it at
session start and at each checkpoint; answer in your own status file's
`answers`.

Requests of T17's work order (T17-R1 to T17-R10) are all answered; see
[`status/T17.json`](status/T17.json).

## Open

Nothing is open.

## Expected

The lead owns `tools/check_all.sh`, so wiring a new check into it is a request
to the lead. Two are expected in phase 0:

- **AD**, from P0-AD-rubric: run the gate's own self-tests (`tools/ui_gate/`)
  in `tools/check_all.sh`.
- **K1**, from P0-K1-contract: run the bake's contract check in
  `tools/check_all.sh`.
