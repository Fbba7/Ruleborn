// A refusal with an HTTP status, so the edge layer need not guess one.

export class Refused extends Error {
  constructor(status, reason, detail = {}) {
    super(reason);
    this.status = status;
    this.reason = reason;
    this.detail = detail;
  }
}
