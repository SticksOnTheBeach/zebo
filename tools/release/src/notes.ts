import type { ChangelogEntry } from "./changelog.ts";

/** The release title and body, from the changelog entry; install steps when the app is attached. */
export function releaseText(entry: ChangelogEntry, archiveName: string | undefined) {
  const install = archiveName
    ? [
        "### Install",
        "",
        `Download \`${archiveName}\`, unzip it and move \`Zebo.app\` to Applications. ` +
          "Zebo isn't notarized by Apple: the first time, right-click `Zebo.app` and choose **Ouvrir** " +
          "(or run `xattr -dr com.apple.quarantine /Applications/Zebo.app`). Requires macOS 14 or later.",
      ]
    : ["Source only: build it with `make run` (see the README)."];
  return {
    name: `Zebo ${entry.version} — ${entry.title}`,
    body: [entry.notes, "", ...install].join("\n"),
  };
}
