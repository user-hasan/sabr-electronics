import Constants from "expo-constants";
import * as Linking from "expo-linking";

export const RELEASES_URL = "https://github.com/user-hasan/sabr-electronics/releases";
const LATEST_RELEASE_API = "https://api.github.com/repos/user-hasan/sabr-electronics/releases/latest";

export type AppUpdate = { version: string; name: string; notes: string; apkUrl: string; pageUrl: string };

function versionParts(value: string) { return value.replace(/^v/, "").split(".").map((part) => Number.parseInt(part, 10) || 0); }
export function isNewerVersion(latest: string, current = Constants.expoConfig?.version ?? "1.0.0") {
  const a = versionParts(latest); const b = versionParts(current); const length = Math.max(a.length, b.length);
  for (let index = 0; index < length; index += 1) { if ((a[index] ?? 0) !== (b[index] ?? 0)) return (a[index] ?? 0) > (b[index] ?? 0); }
  return false;
}

export async function checkForUpdate(): Promise<AppUpdate | null> {
  const response = await fetch(LATEST_RELEASE_API, { headers: { Accept: "application/vnd.github+json" } });
  if (!response.ok) throw new Error(`GitHub release check failed: ${response.status}`);
  const release = await response.json() as { tag_name?: string; name?: string; body?: string; html_url?: string; assets?: Array<{ name?: string; browser_download_url?: string }> };
  const version = release.tag_name ?? "";
  const apk = release.assets?.find((asset) => asset.name?.endsWith(".apk"));
  if (!version || !apk?.browser_download_url || !isNewerVersion(version)) return null;
  return { version, name: release.name ?? `الإصدار ${version}`, notes: release.body ?? "", apkUrl: apk.browser_download_url, pageUrl: release.html_url ?? RELEASES_URL };
}

export async function openUpdate(update: AppUpdate) { await Linking.openURL(update.apkUrl); }
