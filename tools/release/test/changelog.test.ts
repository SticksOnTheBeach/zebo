import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
import { test } from "node:test";
import { entryFor, parseChangelog } from "../src/changelog.ts";

const sample = `# Changelog

Intro.

## 0.2.0 — Setup (2026-10-05)

- First launch.

## 0.1.0 — Zebo in the notch (2026-10-05)

- A pink cloud.
`;

test("each version keeps its title, date and notes, newest first", () => {
  const entries = parseChangelog(sample);
  assert.deepEqual(
    entries.map((entry) => entry.version),
    ["0.2.0", "0.1.0"],
  );
  assert.deepEqual(entries[0], { version: "0.2.0", title: "Setup", date: "2026-10-05", notes: "- First launch." });
});

test("a malformed version heading is refused", () => {
  assert.throws(() => parseChangelog("## 0.3 Alcove\n- x"), /Malformed changelog heading/);
});

test("releasing a version needs its notes", () => {
  const entries = parseChangelog(sample);
  assert.equal(entryFor("0.1.0", entries).notes, "- A pink cloud.");
  assert.throws(() => entryFor("9.9.9", entries), /no entry for 9.9.9/);
});

test("the real CHANGELOG.md has an entry for every version", () => {
  const text = readFileSync(new URL("../../../CHANGELOG.md", import.meta.url), "utf8");
  const versions = parseChangelog(text).map((entry) => entry.version);
  assert.ok(versions.includes("0.1.0"));
  assert.equal(new Set(versions).size, versions.length);
});
