#!/usr/bin/env python3
"""The documentation consistency check of the agent program (backlog task BT-06).

    python3 tools/docs/protocol_check.py              # check the repository
    python3 tools/docs/protocol_check.py --root DIR   # check a copy of it
    python3 tools/docs/protocol_check.py --self-test  # prove it fails on planted mismatches

The program's state names and file formats are written down in several places:
the brief (docs/guides/agent-brief.md), the protocol
(docs/guides/agent-protocol.md), section 3 of the UI report
(docs/art/ui-quality/report.md), the JSON schemas in docs/progress/schema/,
and the live files themselves (docs/progress/backlog.json, its example
docs/progress/backlog.example.json, docs/progress/status/*.json and
docs/progress/requests.md). This check fails, naming file and line, when they
disagree:

  States   the protocol's task_state and agent_state tables, the brief's lists,
           the schemas' enums, every state the brief, the protocol's state and
           status sections and the report's section 3 name in backticks, the
           request states (the protocol's "**Request states.**" sentence, the
           schema's request_state, the headings of requests.md).
  Fields   the protocol's task format table, status-file field table, message
           example, merge lock and lead.json paragraph, and the brief's field
           lists, against the schemas' properties.
  Examples the protocol's status-file and message examples, the example
           backlog, the live backlog, every status file and lead.json,
           validated against the schemas.

It reads only files in the repository (no network) and needs only the
standard library: the schemas use a small subset of JSON Schema (type, enum,
const, required, properties, additionalProperties, items, $ref, anyOf,
pattern, minimum), which validate() below implements.
"""

from __future__ import annotations

import argparse
import json
import pathlib
import re
import shutil
import sys
import tempfile

ROOT = pathlib.Path(__file__).resolve().parents[2]

BRIEF = "docs/guides/agent-brief.md"
PROTOCOL = "docs/guides/agent-protocol.md"
REPORT = "docs/art/ui-quality/report.md"
SCHEMA_BACKLOG = "docs/progress/schema/backlog.json"
SCHEMA_STATUS = "docs/progress/schema/status.json"
SCHEMA_LEAD = "docs/progress/schema/lead.json"
BACKLOG = "docs/progress/backlog.json"
BACKLOG_EXAMPLE = "docs/progress/backlog.example.json"
STATUS_DIR = "docs/progress/status"
REQUESTS = "docs/progress/requests.md"

# Identifiers the documents put in backticks that are not the program's state
# names or file fields: tools, commands, other formats' fields. A backticked
# lowercase identifier in the brief or in section 3 of the report that is none
# of these, no state and no schema field is reported, so a misspelt state
# (`parkd`) or a field the schemas lack cannot slip in.
OTHER_IDENTIFIERS = {
    "consumers", "version",                    # a frozen contract's head
    "critique", "result",                      # a gate verdict (BT-05's schema)
    "create_session", "send_later",            # session tools
    "gdlint", "playwright", "sleep",           # commands
    "null", "true", "false",
    "opusplan",                                # a model setting in report 3.9
}

# requests.md's sections that are not a request state.
REQUESTS_OTHER_SECTIONS = {"expected", "owner steps"}

IDENT = re.compile(r"`([a-z_][a-z0-9_]*)`")


class Problems:
    def __init__(self) -> None:
        self.items: list[tuple[str, int, str]] = []

    def add(self, path: str, line: int, msg: str) -> None:
        self.items.append((path, line, msg))

    def lines(self) -> list[str]:
        return [f"{p}:{n}: {m}" for p, n, m in self.items]


# ---------------------------------------------------------------- JSON with lines

class LinedJSON:
    """A JSON parser that records the line of every value, by path."""

    _ws = re.compile(r"[ \t\r\n]*")
    _num = re.compile(r"-?(?:0|[1-9][0-9]*)(?:\.[0-9]+)?(?:[eE][+-]?[0-9]+)?")

    def __init__(self, text: str, first_line: int = 1) -> None:
        self.text = text
        self.first = first_line
        self.lines: dict[tuple, int] = {}
        self.i = 0

    def line_at(self, i: int) -> int:
        return self.first + self.text.count("\n", 0, i)

    def skip(self) -> None:
        self.i = self._ws.match(self.text, self.i).end()

    def parse(self):
        self.skip()
        v = self.value(())
        self.skip()
        if self.i != len(self.text):
            raise ValueError(f"line {self.line_at(self.i)}: extra data")
        return v

    def value(self, path: tuple):
        self.skip()
        self.lines[path] = self.line_at(self.i)
        c = self.text[self.i:self.i + 1]
        if c == "{":
            self.i += 1
            out = {}
            self.skip()
            if self.text[self.i] == "}":
                self.i += 1
                return out
            while True:
                self.skip()
                key = self.string()
                self.skip()
                self.expect(":")
                out[key] = self.value(path + (key,))
                self.skip()
                if self.text[self.i] == ",":
                    self.i += 1
                    continue
                self.expect("}")
                return out
        if c == "[":
            self.i += 1
            out = []
            self.skip()
            if self.text[self.i] == "]":
                self.i += 1
                return out
            while True:
                out.append(self.value(path + (len(out),)))
                self.skip()
                if self.text[self.i] == ",":
                    self.i += 1
                    continue
                self.expect("]")
                return out
        if c == '"':
            return self.string()
        for word, val in (("true", True), ("false", False), ("null", None)):
            if self.text.startswith(word, self.i):
                self.i += len(word)
                return val
        m = self._num.match(self.text, self.i)
        if not m or not m.group():
            raise ValueError(f"line {self.line_at(self.i)}: not JSON")
        self.i = m.end()
        return json.loads(m.group())

    def string(self) -> str:
        if self.text[self.i] != '"':
            raise ValueError(f"line {self.line_at(self.i)}: expected a string")
        s, self.i = json.decoder.scanstring(self.text, self.i + 1)
        return s

    def expect(self, ch: str) -> None:
        if self.text[self.i:self.i + 1] != ch:
            raise ValueError(f"line {self.line_at(self.i)}: expected {ch!r}")
        self.i += 1


def load_lined(root: pathlib.Path, rel: str, problems: Problems):
    try:
        p = LinedJSON((root / rel).read_text())
        return p.parse(), p.lines
    except (OSError, ValueError) as e:
        problems.add(rel, 1, f"cannot read as JSON: {e}")
        return None, {}


# ---------------------------------------------------------------- the schema subset

TYPES = {
    "object": lambda v: isinstance(v, dict),
    "array": lambda v: isinstance(v, list),
    "string": lambda v: isinstance(v, str),
    "integer": lambda v: isinstance(v, int) and not isinstance(v, bool),
    "number": lambda v: isinstance(v, (int, float)) and not isinstance(v, bool),
    "boolean": lambda v: isinstance(v, bool),
    "null": lambda v: v is None,
}


def resolve(root_schema: dict, schema: dict) -> dict:
    while "$ref" in schema:
        ref = schema["$ref"]
        if not ref.startswith("#/"):
            raise ValueError(f"unsupported $ref {ref}")
        node = root_schema
        for part in ref[2:].split("/"):
            node = node[part]
        schema = node
    return schema


def validate(value, schema: dict, root_schema: dict, path: tuple = ()) -> list[tuple[tuple, str]]:
    """Return [(path, message)] for every way value breaks schema."""
    schema = resolve(root_schema, schema)
    errs: list[tuple[tuple, str]] = []
    if "anyOf" in schema:
        branches = [validate(value, s, root_schema, path) for s in schema["anyOf"]]
        if all(branches):
            # Report the branch whose type fits, else a summary.
            fitting = [b for b, s in zip(branches, schema["anyOf"])
                       if type_ok(value, resolve(root_schema, s))]
            errs += fitting[0] if fitting else [(path, f"{short(value)} matches none of the allowed forms")]
        return errs
    if "type" in schema and not type_ok(value, schema):
        want = schema["type"] if isinstance(schema["type"], str) else " or ".join(schema["type"])
        return [(path, f"{short(value)} is not of type {want}")]
    if "const" in schema and value != schema["const"]:
        errs.append((path, f"{short(value)} is not {json.dumps(schema['const'])}"))
    if "enum" in schema and value not in schema["enum"]:
        errs.append((path, f"{short(value)} is not one of {', '.join(json.dumps(e) for e in schema['enum'])}"))
    if isinstance(value, str) and "pattern" in schema and not re.search(schema["pattern"], value):
        errs.append((path, f"{short(value)} does not match {schema['pattern']}"))
    if isinstance(value, (int, float)) and not isinstance(value, bool) and "minimum" in schema \
            and value < schema["minimum"]:
        errs.append((path, f"{value} is below {schema['minimum']}"))
    if isinstance(value, dict):
        props = schema.get("properties", {})
        for key in schema.get("required", []):
            if key not in value:
                errs.append((path, f"missing required field {key!r}"))
        extra = schema.get("additionalProperties", True)
        for key, sub in value.items():
            if key in props:
                errs += validate(sub, props[key], root_schema, path + (key,))
            elif extra is False:
                errs.append((path + (key,), f"field {key!r} is not in the schema"))
            elif isinstance(extra, dict):
                errs += validate(sub, extra, root_schema, path + (key,))
    if isinstance(value, list) and "items" in schema:
        for n, item in enumerate(value):
            errs += validate(item, schema["items"], root_schema, path + (n,))
    return errs


def type_ok(value, schema: dict) -> bool:
    t = schema.get("type")
    if t is None:
        return True
    return any(TYPES[x](value) for x in ([t] if isinstance(t, str) else t))


def short(value) -> str:
    s = json.dumps(value)
    return s if len(s) <= 60 else s[:57] + "..."


def where(path: tuple) -> str:
    out = ""
    for p in path:
        out += f"[{p}]" if isinstance(p, int) else (f".{p}" if out else p)
    return out or "(top)"


def line_of(lines: dict, path: tuple) -> int:
    while path not in lines and path:
        path = path[:-1]
    return lines.get(path, 1)


def check_json(problems: Problems, rel: str, value, lines: dict, schema: dict, root_schema: dict,
               label: str = "") -> None:
    for path, msg in validate(value, schema, root_schema):
        problems.add(rel, line_of(lines, path), f"{label}{where(path)}: {msg}")


# ---------------------------------------------------------------- reading the documents

class Doc:
    def __init__(self, root: pathlib.Path, rel: str) -> None:
        self.rel = rel
        self.lines = (root / rel).read_text().split("\n")

    def section(self, start: str, stop_prefixes: tuple[str, ...]) -> tuple[int, int]:
        """(first, end) line indexes (0-based) of the section whose heading starts with start."""
        first = next((i for i, l in enumerate(self.lines) if l.startswith(start)), None)
        if first is None:
            raise LookupError(f"{self.rel}: no section {start!r}")
        end = next((i for i in range(first + 1, len(self.lines))
                    if self.lines[i].startswith(stop_prefixes)), len(self.lines))
        return first, end

    def find(self, needle: str, lo: int = 0, hi: int | None = None) -> int:
        hi = len(self.lines) if hi is None else hi
        for i in range(lo, hi):
            if needle in self.lines[i]:
                return i
        raise LookupError(f"{self.rel}: {needle!r} not found")

    def idents(self, lo: int, hi: int):
        """(line number, identifier) for every backticked lowercase identifier."""
        for i in range(lo, hi):
            for m in IDENT.finditer(self.lines[i]):
                yield i + 1, m.group(1)

    def json_block(self, lo: int, hi: int):
        """The first ```json block in [lo, hi): (text, line number of its first line)."""
        for i in range(lo, hi):
            if self.lines[i].strip() == "```json":
                j = next(k for k in range(i + 1, hi) if self.lines[k].strip() == "```")
                return "\n".join(self.lines[i + 1:j]), i + 2
        raise LookupError(f"{self.rel}: no json block in lines {lo + 1}-{hi}")

    def table(self, lo: int, hi: int):
        """(line number, first cell, other cells) of each table row in [lo, hi), headers skipped."""
        rows = []
        for i in range(lo, hi):
            l = self.lines[i].strip()
            if not l.startswith("|") or set(l) <= set("|-: "):
                continue
            cells = [c.strip() for c in l.strip("|").split("|")]
            if i + 1 < hi and set(self.lines[i + 1].strip()) <= set("|-: ") and self.lines[i + 1].strip():
                continue  # the header row
            rows.append((i + 1, cells[0], cells[1:]))
        return rows

    def joined(self, lo: int, hi: int) -> str:
        return "\n".join(self.lines[lo:hi])

    def line_of_offset(self, lo: int, offset: int) -> int:
        return lo + 1 + self.joined(lo, len(self.lines)).count("\n", 0, offset)


def keylist(text: str) -> list[str] | None:
    """The keys of the first {...} in text: {"a", "b"} or {"a": "<v>", "b": [...]}."""
    m = re.search(r"\{[^{}]*\}", text)
    if not m:
        return None
    body = re.sub(r':\s*("[^"]*"|\[[^\]]*\])', ":", m.group())
    keys = re.findall(r'"([a-z_]+)"', body)
    return keys or None


def obj_props(root_schema: dict, schema: dict) -> set[str] | None:
    """The properties of schema's object form (through $ref and anyOf), or None."""
    schema = resolve(root_schema, schema)
    if "properties" in schema:
        return set(schema["properties"])
    for s in schema.get("anyOf", []):
        p = obj_props(root_schema, s)
        if p is not None:
            return p
    if schema.get("type") == "array" and "items" in schema:
        return obj_props(root_schema, schema["items"])
    return None


def all_fields(schema: dict) -> set[str]:
    out: set[str] = set()

    def walk(node):
        if isinstance(node, dict):
            for k, v in node.items():
                if k == "properties" and isinstance(v, dict):
                    out.update(v)
                walk(v)
        elif isinstance(node, list):
            for v in node:
                walk(v)
    walk(schema)
    return out


def compare(problems: Problems, rel: str, line: int, what: str, doc: set, schema: set, schema_rel: str) -> None:
    for name in sorted(doc - schema):
        problems.add(rel, line, f"{what}: {name!r} is in the document but not in {schema_rel}")
    for name in sorted(schema - doc):
        problems.add(rel, line, f"{what}: {name!r} is in {schema_rel} but the document does not name it")


# ---------------------------------------------------------------- the check

def run(root: pathlib.Path) -> Problems:
    problems = Problems()
    schemas, schema_lines = {}, {}
    for rel in (SCHEMA_BACKLOG, SCHEMA_STATUS, SCHEMA_LEAD):
        value, lines = load_lined(root, rel, problems)
        if value is None:
            return problems
        schemas[rel], schema_lines[rel] = value, lines
    sb, ss, sl = schemas[SCHEMA_BACKLOG], schemas[SCHEMA_STATUS], schemas[SCHEMA_LEAD]
    try:
        check_documents(root, problems, sb, ss, sl, schema_lines)
    except LookupError as e:
        problems.add(str(e).split(":")[0], 1, f"cannot find what the check reads: {e}")
    check_live(root, problems, sb, ss, sl)
    return problems


def check_documents(root, problems, sb, ss, sl, schema_lines) -> None:
    proto = Doc(root, PROTOCOL)
    brief = Doc(root, BRIEF)
    report = Doc(root, REPORT)

    task_states_backlog = set(sb["$defs"]["task_state"]["enum"])
    task_states_status = set(ss["$defs"]["task_state"]["enum"])
    agent_states = set(ss["properties"]["agent_state"]["enum"])
    request_states = set(ss["$defs"]["request_state"]["enum"])
    if task_states_backlog != task_states_status:
        problems.add(SCHEMA_STATUS, line_of(schema_lines[SCHEMA_STATUS], ("$defs", "task_state", "enum")),
                     f"task_state enum {sorted(task_states_status)} differs from "
                     f"{SCHEMA_BACKLOG}'s {sorted(task_states_backlog)}")
    task_states = task_states_backlog

    # -- the protocol's state tables
    lo, hi = proto.section("## Tasks and their states", ("## ",))
    transitions = proto.find("**Transitions.**", lo, hi)
    own = proto.find("**The agent's own state**", lo, hi)
    fmt = proto.find("### The task format", lo, hi)
    rows = proto.table(lo, transitions)
    doc_task = {}
    for line, cell, _ in rows:
        m = re.fullmatch(r"`([a-z_]+)`", cell)
        if not m:
            problems.add(PROTOCOL, line, f"task_state table row {cell!r} is not one backticked state")
            continue
        doc_task[m.group(1)] = line
    compare(problems, PROTOCOL, lo + 1, "task_state table", set(doc_task), task_states, SCHEMA_BACKLOG)
    doc_agent = {}
    for line, cell, _ in proto.table(own, fmt):
        m = re.fullmatch(r"`([a-z_]+)`", cell)
        if m:
            doc_agent[m.group(1)] = line
    compare(problems, PROTOCOL, own + 1, "agent_state table", set(doc_agent), agent_states, SCHEMA_STATUS)
    # Every state the transitions paragraph names is a task state.
    fields = all_fields(sb) | all_fields(ss) | all_fields(sl)
    for line, word in proto.idents(transitions, own):
        if word not in task_states and word not in fields:
            problems.add(PROTOCOL, line, f"the transitions name {word!r}, which is no task_state")

    # -- the task format table
    lo_f, hi_f = proto.section("### The task format", ("## ", "### "))
    task_props = set(sb["$defs"]["task"]["properties"])
    doc_fields: set[str] = set()
    for line, cell, rest in proto.table(lo_f, hi_f):
        names = IDENT.findall(cell)
        doc_fields.update(names)
        text = " ".join(rest)
        if names == ["claim"]:
            sub = {w for w in IDENT.findall(text) if w != "null"}
            compare(problems, PROTOCOL, line, "the claim's fields", sub,
                    set(sb["$defs"]["claim"]["properties"]), SCHEMA_BACKLOG)
        if names == ["gate_items"]:
            keys = keylist(text) or []
            compare(problems, PROTOCOL, line, "a gate item's fields", set(keys),
                    set(sb["$defs"]["gate_item"]["properties"]), SCHEMA_BACKLOG)
        if names == ["state"]:
            pass  # the states are checked above
    compare(problems, PROTOCOL, lo_f + 1, "the task format table", doc_fields, task_props, SCHEMA_BACKLOG)
    # The backlog's own top-level fields are named in the protocol somewhere.
    proto_words = {w for _, w in proto.idents(0, len(proto.lines))}
    for name in sorted(set(sb["properties"]) - {"_comment", "tasks", "messages"}):
        if name not in proto_words:
            problems.add(PROTOCOL, lo_f + 1, f"the backlog's top-level field {name!r} ({SCHEMA_BACKLOG}) "
                         "is named nowhere in the protocol")

    # -- the status file: example and field table
    lo_s, hi_s = proto.section("## The status file", ("## ",))
    text, first = proto.json_block(lo_s, hi_s)
    try:
        p = LinedJSON(text, first)
        example = p.parse()
        check_json(problems, PROTOCOL, example, p.lines, ss, ss, "the status file example: ")
    except ValueError as e:
        problems.add(PROTOCOL, first, f"the status file example is not JSON: {e}")
    status_props = ss["properties"]
    for line, cell, rest in proto.table(lo_s, hi_s):
        names = IDENT.findall(cell)
        for name in names:
            if name not in status_props:
                problems.add(PROTOCOL, line, f"the status file table names {name!r}, which is not in {SCHEMA_STATUS}")
                continue
            sub = obj_props(ss, status_props[name])
            if sub is None or name in ("requests", "answers"):
                continue
            text_ = " ".join(rest)
            keys = keylist(text_)
            doc_sub = set(keys) if keys else set(IDENT.findall(text_.split(". ")[0])) - {"null"}
            if keys or doc_sub:
                compare(problems, PROTOCOL, line, f"{name}'s fields", doc_sub, sub, SCHEMA_STATUS)

    # -- messages and request states
    lo_m, hi_m = proto.section("## Messages and requests", ("## ",))
    text, first = proto.json_block(lo_m, hi_m)
    try:
        p = LinedJSON(text, first)
        msg = p.parse()
        check_json(problems, PROTOCOL, msg, p.lines, sb["$defs"]["message"], sb, "the message example: ")
    except ValueError as e:
        problems.add(PROTOCOL, first, f"the message example is not JSON: {e}")
    try:
        rs = proto.find("**Request states.**", lo_m, hi_m)
        j = rs
        while j + 1 < hi_m and proto.lines[j + 1].strip():
            j += 1
        doc_rs = {w for _, w in proto.idents(rs, j + 1)} - {"state"}
        compare(problems, PROTOCOL, rs + 1, "the request states", doc_rs, request_states, SCHEMA_STATUS)
    except LookupError:
        problems.add(PROTOCOL, lo_m + 1, "'Messages and requests' has no '**Request states.**' sentence naming "
                     f"the request states; {SCHEMA_STATUS} has {', '.join(sorted(request_states))}")
    req = Doc(root, REQUESTS)
    for i, l in enumerate(req.lines):
        if l.startswith("## "):
            head = l[3:].strip().lower()
            word = head.split()[0]
            if head not in REQUESTS_OTHER_SECTIONS and word not in request_states:
                problems.add(REQUESTS, i + 1, f"section {l[3:].strip()!r} starts with no request state "
                             f"({', '.join(sorted(request_states))})")

    # -- the lead's status
    lo_l = proto.find("`status/lead.json` holds")
    hi_l = proto.find("A second scheduled task", lo_l)
    para = proto.joined(lo_l, hi_l + 1)
    para = para[para.index("`status/lead.json` holds") + len("`status/lead.json` holds"):para.index("A second scheduled task")]
    para_flat = re.sub(r"\([^()]*(\([^()]*\)[^()]*)*\)", "", para)
    doc_lead = set(IDENT.findall(para_flat)) - {"null"}
    compare(problems, PROTOCOL, lo_l + 1, "status/lead.json's fields", doc_lead, set(sl["properties"]), SCHEMA_LEAD)
    lm = re.search(r"`last_merged` \(`(\{[^`]*\})`\)", para)
    if lm:
        compare(problems, PROTOCOL, lo_l + 1, "last_merged's fields", set(keylist(lm.group(1)) or []),
                obj_props(sl, sl["properties"]["last_merged"]), SCHEMA_LEAD)
    ml = proto.find("`merging` in `status/lead.json` on main:")
    keys = keylist(proto.lines[ml + 1]) or keylist(proto.lines[ml])
    compare(problems, PROTOCOL, ml + 2, "the merge lock's fields", set(keys or []),
            obj_props(sl, sl["properties"]["merging"]), SCHEMA_LEAD)

    # -- the brief
    known = task_states | agent_states | request_states | all_fields(sb) | all_fields(ss) | all_fields(sl) \
        | OTHER_IDENTIFIERS
    lo_b, hi_b = brief.section("## Your status file", ("## ",))
    body = brief.joined(lo_b, hi_b)
    m = re.search(r"`agent_state`\s*\(([^)]*)\)", body)
    if not m:
        problems.add(BRIEF, lo_b + 1, "'Your status file' lists no agent states as `agent_state` (...)")
    else:
        compare(problems, BRIEF, brief.line_of_offset(lo_b, m.start()), "the brief's agent states",
                set(IDENT.findall(m.group(1))), agent_states, SCHEMA_STATUS)
    m = re.search(r"`task_state`\s*\(([^)]*)\)", body)
    if not m:
        problems.add(BRIEF, lo_b + 1, "'Your status file' lists no task states as `task_state` (...)")
    else:
        compare(problems, BRIEF, brief.line_of_offset(lo_b, m.start()), "the brief's task states",
                set(IDENT.findall(m.group(1))), task_states, SCHEMA_BACKLOG)
    for sub in ("progress_marker", "long_run", "gate_request"):
        for mm in re.finditer(r"`%s(?::\s*|`:?\s*`)(\{[^`]*\})`" % sub, brief.joined(0, len(brief.lines))):
            line = brief.line_of_offset(0, mm.start())
            compare(problems, BRIEF, line, f"{sub}'s fields", set(keylist(mm.group(1)) or []),
                    obj_props(ss, ss["properties"][sub]), SCHEMA_STATUS)
    lo_r, hi_r = brief.section("## Requests and messages", ("## ",))
    body = brief.joined(lo_r, hi_r)
    req_props = set(ss["$defs"]["request"]["properties"])
    req_required = set(ss["$defs"]["request"]["required"])
    m = re.search(r"`requests`:\s*`(\{[^`]*\})`", body)
    if not m:
        problems.add(BRIEF, lo_r + 1, "'Requests and messages' gives no request format as `requests`: `{...}`")
    else:
        doc = set(keylist(m.group(1)) or [])
        compare(problems, BRIEF, brief.line_of_offset(lo_r, m.start()), "a request's fields", doc,
                req_required | (doc & req_props), SCHEMA_STATUS)
    m = re.search(r"`answers`\s*\(`(\{[^`]*\})`\)", body)
    if not m:
        problems.add(BRIEF, lo_r + 1, "'Requests and messages' gives no answer format as `answers` (`{...}`)")
    else:
        compare(problems, BRIEF, brief.line_of_offset(lo_r, m.start()), "an answer's fields",
                set(keylist(m.group(1)) or []), set(ss["$defs"]["answer"]["properties"]), SCHEMA_STATUS)
    for line, word in brief.idents(0, len(brief.lines)):
        if word not in known:
            problems.add(BRIEF, line, f"`{word}` is no state, no schema field and no known identifier")

    # -- the protocol's own state and status sections
    for start in ("## Tasks and their states", "## The status file", "## Messages and requests"):
        a, b = proto.section(start, ("## ",))
        for line, word in proto.idents(a, b):
            if word not in known:
                problems.add(PROTOCOL, line, f"`{word}` is no state, no schema field and no known identifier")

    # -- section 3 of the report
    a, b = report.section("## 3.", ("## ",))
    for line, word in report.idents(a, b):
        if word not in known:
            problems.add(REPORT, line, f"`{word}` is no state, no schema field and no known identifier")


def check_live(root, problems, sb, ss, sl) -> None:
    for rel in (BACKLOG_EXAMPLE, BACKLOG):
        value, lines = load_lined(root, rel, problems)
        if value is not None:
            check_json(problems, rel, value, lines, sb, sb)
    for path in sorted((root / STATUS_DIR).glob("*.json")):
        rel = f"{STATUS_DIR}/{path.name}"
        value, lines = load_lined(root, rel, problems)
        if value is None:
            continue
        schema = sl if path.name == "lead.json" else ss
        check_json(problems, rel, value, lines, schema, schema)
        if path.name != "lead.json" and isinstance(value, dict) and value.get("agent") != path.stem:
            problems.add(rel, line_of(lines, ("agent",)), f"agent {value.get('agent')!r} is not the file's name")


# ---------------------------------------------------------------- the self-test

def copy_fixture(dest: pathlib.Path) -> None:
    for rel in (BRIEF, PROTOCOL, REPORT, SCHEMA_BACKLOG, SCHEMA_STATUS, SCHEMA_LEAD, BACKLOG,
                BACKLOG_EXAMPLE, REQUESTS):
        (dest / rel).parent.mkdir(parents=True, exist_ok=True)
        shutil.copy(ROOT / rel, dest / rel)
    (dest / STATUS_DIR).mkdir(parents=True, exist_ok=True)
    for path in (ROOT / STATUS_DIR).glob("*.json"):
        shutil.copy(path, dest / STATUS_DIR / path.name)


def plant(dest: pathlib.Path, rel: str, old: str, new: str) -> int:
    """Replace the first old with new in the copy; return the line it is on."""
    p = dest / rel
    text = p.read_text()
    i = text.index(old)
    p.write_text(text[:i] + new + text[i + len(old):])
    return text.count("\n", 0, i) + 1


PLANTS = [
    # (what, file, old, new)
    ("a task state renamed in the protocol's table", PROTOCOL, "| `parked` |", "| `paused` |"),
    ("an agent state renamed in the protocol's table", PROTOCOL, "| `waiting` |", "| `idle` |"),
    ("a task state misspelt in the brief's list", BRIEF, "`blocked`, `parked`;", "`blocked`, `parkd`;"),
    ("an agent state dropped from the brief's list", BRIEF, "(`active`, `waiting`, `stopped`, `done`)",
     "(`active`, `waiting`, `stopped`)"),
    ("a request field dropped from the brief's format", BRIEF, '"blocking", "created_at",', '"created_at",'),
    ("a field misspelt in the protocol's task format table", PROTOCOL, "| `critical` |", "| `critcal` |"),
    ("a state misspelt in section 3 of the report", REPORT, "sends the task to `resync`",
     "sends the task to `resynch`"),
    ("a wrong state in the protocol's status file example", PROTOCOL, '"task_state": "working"',
     '"task_state": "in_progress"'),
    ("a field renamed in the protocol's message example", PROTOCOL, '"ack_by":', '"ack_until":'),
    ("a state the schemas lack in the example backlog", BACKLOG_EXAMPLE, '"state": "working"',
     '"state": "doing"'),
    ("a required field missing from lead.json", f"{STATUS_DIR}/lead.json", '"cycle":', '"cycles":'),
    ("an enum changed in one schema only", SCHEMA_STATUS, '"merged", "parked"]', '"merged", "paused"]'),
]


def self_test() -> int:
    base = run(ROOT)
    failed = 0
    with tempfile.TemporaryDirectory(prefix="protocol_check.") as tmp:
        tmp = pathlib.Path(tmp)
        copy_fixture(tmp / "clean")
        clean = run(tmp / "clean")
        if sorted(clean.lines()) != sorted(base.lines()):
            print("FAIL: the fixture copy does not check the same as the repository")
            failed += 1
        else:
            print(f"ok   the fixture copy checks the same as the repository ({len(base.items)} problems today)")
        for n, (what, rel, old, new) in enumerate(PLANTS):
            dest = tmp / f"plant{n}"
            copy_fixture(dest)
            try:
                line = plant(dest, rel, old, new)
            except ValueError:
                print(f"FAIL: cannot plant {what}: {old!r} is not in {rel}")
                failed += 1
                continue
            got = run(dest)
            new_items = [p for p in got.items if p not in clean.items]
            # The line the planted text is on, or within the few lines of the
            # list or paragraph it belongs to.
            hits = [p for p in new_items if p[0] == rel and abs(p[1] - line) <= 3]
            if hits:
                print(f"ok   {what}: {hits[0][0]}:{hits[0][1]}: {hits[0][2]}")
            elif new_items:
                print(f"FAIL: {what}: reported, but not at {rel}:{line}: " +
                      "; ".join(f"{p}:{n_}: {m}" for p, n_, m in new_items[:3]))
                failed += 1
            else:
                print(f"FAIL: {what} ({rel}:{line}) was not reported")
                failed += 1
    print(f"protocol_check self-test: {len(PLANTS) - failed if failed <= len(PLANTS) else 0} of "
          f"{len(PLANTS)} planted mismatches caught" + ("" if not failed else f", {failed} failure(s)"))
    return 1 if failed else 0


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    ap.add_argument("--root", type=pathlib.Path, default=ROOT, help="the repository (or a copy) to check")
    ap.add_argument("--self-test", action="store_true", help="plant mismatches in fixture copies and prove they fail")
    args = ap.parse_args()
    if args.self_test:
        return self_test()
    problems = run(args.root.resolve())
    for line in problems.lines():
        print(line)
    if problems.items:
        print(f"protocol_check: {len(problems.items)} mismatch(es)")
        return 1
    print("protocol_check: the brief, the protocol, the report's section 3, the schemas and the live files agree")
    return 0


if __name__ == "__main__":
    sys.exit(main())
