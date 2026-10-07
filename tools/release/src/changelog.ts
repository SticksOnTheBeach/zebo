/** A version as CHANGELOG.md describes it: `## 0.7.0 — Title (2026-10-07)` and its notes. */
export interface ChangelogEntry {
  version: string;
  title: string;
  date: string;
  notes: string;
}

const heading = /^## (\d+\.\d+\.\d+) — (.+) \((\d{4}-\d{2}-\d{2})\)$/;

/** Every version in the changelog, newest first, as written. */
export function parseChangelog(text: string): ChangelogEntry[] {
  const entries: ChangelogEntry[] = [];
  let current: ChangelogEntry | undefined;
  const lines: string[] = [];
  const close = () => {
    if (current) entries.push({ ...current, notes: lines.join("\n").trim() });
    lines.length = 0;
  };
  for (const line of text.split("\n")) {
    const match = heading.exec(line);
    if (match) {
      close();
      const [, version = "", title = "", date = ""] = match;
      current = { version, title, date, notes: "" };
    } else if (line.startsWith("## ")) {
      throw new Error(`Malformed changelog heading: "${line}" (expected "## X.Y.Z — Title (YYYY-MM-DD)")`);
    } else if (current) {
      lines.push(line);
    }
  }
  close();
  return entries;
}

/** The entry of one version; a release without notes is a mistake. */
export function entryFor(version: string, entries: ChangelogEntry[]): ChangelogEntry {
  const entry = entries.find((candidate) => candidate.version === version);
  if (!entry) throw new Error(`CHANGELOG.md has no entry for ${version}: add one before releasing.`);
  if (!entry.notes) throw new Error(`The CHANGELOG.md entry for ${version} is empty.`);
  return entry;
}
