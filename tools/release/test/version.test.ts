import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
import { test } from "node:test";
import { releaseText } from "../src/notes.ts";
import { tagFor, versionFromInfoPlist } from "../src/version.ts";

test("the version comes from Info.plist, and its tag is vX.Y.Z", () => {
  const plist = "<key>CFBundleShortVersionString</key>\n    <string>1.2.3</string>";
  assert.equal(versionFromInfoPlist(plist), "1.2.3");
  assert.equal(tagFor("1.2.3"), "v1.2.3");
  assert.throws(() => versionFromInfoPlist("<key>CFBundleShortVersionString</key><string>beta</string>"));
});

test("the real Info.plist has a version in the changelog format", () => {
  const plist = readFileSync(new URL("../../../Info.plist", import.meta.url), "utf8");
  assert.match(versionFromInfoPlist(plist), /^\d+\.\d+\.\d+$/);
});

test("a release with the app explains how to install it", () => {
  const entry = { version: "0.7.0", title: "Initiatives", date: "2026-10-07", notes: "- Y and N." };
  const withApp = releaseText(entry, "Zebo-0.7.0.zip");
  assert.equal(withApp.name, "Zebo 0.7.0 — Initiatives");
  assert.match(withApp.body, /^- Y and N\.\n\n### Install/);
  assert.match(withApp.body, /Zebo-0.7.0.zip/);
  assert.match(releaseText(entry, undefined).body, /Source only/);
});
