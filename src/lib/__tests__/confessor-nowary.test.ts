import { describe, it, expect, afterEach, vi } from "vitest";
import { getNowAiring } from "@/lib/confessor";

// Trimmed real response from confessor.kpfk.org/_nu_do_api.php?req=nowary&json=1.
// Includes the `global` block with leaked Icecast creds to prove we never read it.
const NOWARY_FIXTURE = {
  global: {
    listenurl: "https://streams.pacifica.org:9000/kpfk_128",
    gl_iceuser: "admin",
    gl_icepass: "dank808",
  },
  current: {
    sh_altid: "lawyersguild",
    sh_name: "Lawyers Guild, The",
    sh_djname: "Jim Lafferty, Maria Hall",
    sh_desc: "A public affairs program.",
    cur_start: "3:00 PM",
    cur_end: "4:00 PM",
    pl_song: "",
    pl_artist: "",
    listeners: 111,
  },
  next: {
    sh_altid: "dn",
    sh_name: "Democracy Now!",
    nxt_start: "4:00 PM",
    nxt_end: "5:00 PM",
  },
};

function mockFetchOnce(payload: unknown, ok = true) {
  vi.stubGlobal(
    "fetch",
    vi.fn(async () => ({
      ok,
      status: ok ? 200 : 502,
      json: async () => payload,
    }))
  );
}

afterEach(() => {
  vi.unstubAllGlobals();
  vi.restoreAllMocks();
});

describe("getNowAiring", () => {
  it("extracts the live listener count and current/next shows", async () => {
    mockFetchOnce(NOWARY_FIXTURE);
    const now = await getNowAiring();

    expect(now?.listeners).toBe(111);
    expect(now?.current?.sh_altid).toBe("lawyersguild");
    expect(now?.current?.sh_name).toBe("Lawyers Guild, The");
    expect(now?.next?.sh_name).toBe("Democracy Now!");
    expect(now?.next?.sh_altid).toBe("dn");
  });

  it("never surfaces the global block (leaked Icecast credentials)", async () => {
    mockFetchOnce(NOWARY_FIXTURE);
    const now = await getNowAiring();

    const serialized = JSON.stringify(now);
    expect(serialized).not.toContain("dank808");
    expect(serialized).not.toContain("gl_icepass");
    expect(now).not.toHaveProperty("global");
  });

  it("decodes HTML entities in show fields", async () => {
    mockFetchOnce({
      current: {
        sh_altid: "x",
        sh_name: "Rock &amp; Roll",
        sh_djname: "DJ &quot;Spin&quot;",
        listeners: 5,
      },
    });
    const now = await getNowAiring();

    expect(now?.current?.sh_name).toBe("Rock & Roll");
    expect(now?.current?.sh_djname).toBe('DJ "Spin"');
  });

  it("returns null listeners when the field is absent", async () => {
    mockFetchOnce({ current: { sh_altid: "x", sh_name: "Show" } });
    const now = await getNowAiring();

    expect(now?.current?.sh_altid).toBe("x");
    expect(now?.listeners).toBeNull();
  });

  it("returns null when Confessor responds with an error", async () => {
    mockFetchOnce({}, false);
    expect(await getNowAiring()).toBeNull();
  });

  it("tolerates an empty array for current (no show airing)", async () => {
    mockFetchOnce({ current: [], next: [] });
    const now = await getNowAiring();

    expect(now?.current).toBeNull();
    expect(now?.next).toBeNull();
    expect(now?.listeners).toBeNull();
  });
});
