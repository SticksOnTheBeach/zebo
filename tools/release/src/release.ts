/**
 * Publishes the GitHub release of the version in Info.plist:
 * notes from CHANGELOG.md, and build/Zebo-<version>.zip (from `make package`) attached.
 * The tag must already be pushed. `--dry-run` shows what would be published.
 *
 * The token comes from GH_TOKEN, or else from the one git already uses for github.com.
 */
import { execFileSync } from "node:child_process";
import { existsSync, readFileSync } from "node:fs";
import { join, resolve } from "node:path";
import { entryFor, parseChangelog } from "./changelog.ts";
import { GitHub } from "./github.ts";
import { releaseText } from "./notes.ts";
import { tagFor, versionFromInfoPlist } from "./version.ts";

const root = resolve(import.meta.dirname, "../../..");
const repo = "SticksOnTheBeach/zebo";
const isDryRun = process.argv.includes("--dry-run");

function gitToken(): string {
  if (process.env.GH_TOKEN) return process.env.GH_TOKEN;
  const answer = execFileSync("git", ["credential", "fill"], {
    input: "protocol=https\nhost=github.com\n\n",
    encoding: "utf8",
  });
  const token = /^password=(.+)$/m.exec(answer)?.[1];
  if (!token) throw new Error("No GitHub token: set GH_TOKEN, or let git log in to github.com once.");
  return token;
}

async function main() {
  const version = versionFromInfoPlist(readFileSync(join(root, "Info.plist"), "utf8"));
  const entry = entryFor(version, parseChangelog(readFileSync(join(root, "CHANGELOG.md"), "utf8")));
  const tag = tagFor(version);
  const archiveName = `Zebo-${version}.zip`;
  const archive = join(root, "build", archiveName);
  if (!existsSync(archive)) throw new Error(`${archive} is missing: run \`make package\` first.`);
  const { name, body } = releaseText(entry, archiveName);

  if (isDryRun) {
    console.log(`Would publish ${tag} with ${archiveName}\n\n# ${name}\n\n${body}`);
    return;
  }

  const github = new GitHub(gitToken(), repo);
  if (!(await github.tagExists(tag))) {
    throw new Error(`The tag ${tag} isn't on GitHub: tag the release commit and push it first.`);
  }
  if (await github.releaseForTag(tag)) {
    throw new Error(`${tag} is already released.`);
  }
  const release = await github.createRelease(tag, name, body);
  await github.uploadAsset(release, archiveName, new Uint8Array(readFileSync(archive)));
  console.log(`Published ${release.html_url}`);
}

main().catch((error: unknown) => {
  console.error(error instanceof Error ? error.message : error);
  process.exitCode = 1;
});
