/** The version shown to users (CFBundleShortVersionString) in Info.plist. */
export function versionFromInfoPlist(plist: string): string {
  const match = /<key>CFBundleShortVersionString<\/key>\s*<string>([^<]+)<\/string>/.exec(plist);
  const version = match?.[1]?.trim();
  if (!version || !/^\d+\.\d+\.\d+$/.test(version)) {
    throw new Error("Info.plist has no X.Y.Z CFBundleShortVersionString.");
  }
  return version;
}

export const tagFor = (version: string) => `v${version}`;
