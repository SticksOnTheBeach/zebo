/** Just enough of the GitHub REST API to publish a release and attach a file. */
export interface Release {
  id: number;
  html_url: string;
  upload_url: string;
  assets: { name: string }[];
}

export class GitHub {
  readonly #token: string;
  readonly #repo: string;
  readonly #fetch: typeof fetch;

  constructor(token: string, repo: string, fetcher: typeof fetch = fetch) {
    this.#token = token;
    this.#repo = repo;
    this.#fetch = fetcher;
  }

  /** The release of this tag, if it exists. */
  async releaseForTag(tag: string): Promise<Release | undefined> {
    const response = await this.#call(`/repos/${this.#repo}/releases/tags/${tag}`);
    if (response.status === 404) return undefined;
    return (await this.#json(response)) as Release;
  }

  async tagExists(tag: string): Promise<boolean> {
    const response = await this.#call(`/repos/${this.#repo}/git/ref/tags/${tag}`);
    if (response.status === 404) return false;
    await this.#json(response);
    return true;
  }

  async createRelease(tag: string, name: string, body: string): Promise<Release> {
    const response = await this.#call(`/repos/${this.#repo}/releases`, {
      method: "POST",
      headers: { "content-type": "application/json" },
      body: JSON.stringify({ tag_name: tag, name, body, make_latest: "true" }),
    });
    return (await this.#json(response)) as Release;
  }

  async uploadAsset(release: Release, name: string, data: Uint8Array<ArrayBuffer>): Promise<void> {
    const url = `${release.upload_url.split("{")[0]}?name=${encodeURIComponent(name)}`;
    const response = await this.#call(url, {
      method: "POST",
      headers: { "content-type": "application/zip" },
      body: data,
    });
    await this.#json(response);
  }

  #call(path: string, init: RequestInit = {}): Promise<Response> {
    const url = path.startsWith("https://") ? path : `https://api.github.com${path}`;
    return this.#fetch(url, {
      ...init,
      headers: {
        accept: "application/vnd.github+json",
        authorization: `Bearer ${this.#token}`,
        "x-github-api-version": "2022-11-28",
        ...init.headers,
      },
    });
  }

  async #json(response: Response): Promise<unknown> {
    const body: unknown = await response.json().catch(() => undefined);
    if (!response.ok) {
      const message = (body as { message?: string } | undefined)?.message ?? response.statusText;
      throw new Error(`GitHub answered ${response.status}: ${message}`);
    }
    return body;
  }
}
