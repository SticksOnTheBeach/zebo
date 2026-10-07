import assert from "node:assert/strict";
import { test } from "node:test";
import { GitHub, type Release } from "../src/github.ts";

/** Answers each call with the next response, and keeps the requests. */
function fakeFetch(responses: { status: number; body: unknown }[]) {
  const requests: { url: string; init: RequestInit }[] = [];
  const fetcher = (async (url: string | URL | Request, init: RequestInit = {}) => {
    requests.push({ url: String(url), init });
    const next = responses.shift() ?? { status: 500, body: {} };
    return new Response(JSON.stringify(next.body), { status: next.status });
  }) as typeof fetch;
  return { fetcher, requests };
}

const release: Release = {
  id: 1,
  html_url: "https://github.com/o/r/releases/tag/v1.0.0",
  upload_url: "https://uploads.github.com/repos/o/r/releases/1/assets{?name,label}",
  assets: [],
};

test("a release is created for the tag, as the latest, with the token", async () => {
  const { fetcher, requests } = fakeFetch([{ status: 201, body: release }]);
  await new GitHub("t0ken", "o/r", fetcher).createRelease("v1.0.0", "Zebo 1.0.0", "notes");
  const [request] = requests;
  assert.equal(request?.url, "https://api.github.com/repos/o/r/releases");
  assert.equal((request?.init.headers as Record<string, string>).authorization, "Bearer t0ken");
  assert.deepEqual(JSON.parse(String(request?.init.body)), {
    tag_name: "v1.0.0",
    name: "Zebo 1.0.0",
    body: "notes",
    make_latest: "true",
  });
});

test("the zip goes to the release's upload address", async () => {
  const { fetcher, requests } = fakeFetch([{ status: 201, body: { name: "Zebo-1.0.0.zip" } }]);
  await new GitHub("t", "o/r", fetcher).uploadAsset(release, "Zebo-1.0.0.zip", new Uint8Array([1, 2]));
  assert.equal(requests[0]?.url, "https://uploads.github.com/repos/o/r/releases/1/assets?name=Zebo-1.0.0.zip");
});

test("a missing tag or release is not an error, other failures are", async () => {
  const { fetcher } = fakeFetch([
    { status: 404, body: { message: "Not Found" } },
    { status: 404, body: { message: "Not Found" } },
    { status: 401, body: { message: "Bad credentials" } },
  ]);
  const github = new GitHub("t", "o/r", fetcher);
  assert.equal(await github.tagExists("v1.0.0"), false);
  assert.equal(await github.releaseForTag("v1.0.0"), undefined);
  await assert.rejects(github.tagExists("v1.0.0"), /401: Bad credentials/);
});
