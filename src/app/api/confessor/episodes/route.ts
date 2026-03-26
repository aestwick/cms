import { NextRequest, NextResponse } from "next/server";

export interface ConfessorEpisode {
  title: string;
  date: string;
  shortDate: string;
  duration: string;
  audioUrl: string;
  timestamp: number;
  headline: string | null;
  guest: string | null;
  summary: string | null;
}

interface ConfessorRawEpisode {
  title?: string;
  mp3?: string;
  date?: string;
  def_time?: number;
  lsecs?: number;
  producer?: string;
  pubfile?: Array<{
    pf_gname?: string;
    pf_gtopic?: string;
  }>;
}

function fixAudioUrl(url: string): string {
  if (url.includes("confessor.kpfk.org/home/kpfkarch/public_html/mp3/")) {
    const filename = url.split("/mp3/")[1];
    return filename ? `https://archive.kpfk.org/mp3/${filename}` : url;
  }
  return url;
}

// GET /api/confessor/episodes?program=<altid>&num=<count>
export async function GET(request: NextRequest) {
  const confessorBase = process.env.CONFESSOR_API_BASE_URL;
  if (!confessorBase) {
    return NextResponse.json(
      { error: "Confessor not configured" },
      { status: 503 }
    );
  }

  const { searchParams } = request.nextUrl;
  const programSlug = searchParams.get("program");
  const num = Math.min(parseInt(searchParams.get("num") || "20"), 50);

  if (!programSlug) {
    return NextResponse.json(
      { error: "program parameter required" },
      { status: 400 }
    );
  }

  try {
    const url = `${confessorBase}/_nu_do_api.php?req=fil&id=${encodeURIComponent(programSlug)}&num=${num}&json=1`;
    const res = await fetch(url, { next: { revalidate: 300 } });

    if (!res.ok) {
      return NextResponse.json(
        { error: "Confessor unavailable" },
        { status: 502 }
      );
    }

    const text = await res.text();
    let raw: ConfessorRawEpisode[] = [];
    try {
      raw = JSON.parse(text);
    } catch {
      return NextResponse.json(
        { error: "Invalid response from Confessor" },
        { status: 502 }
      );
    }

    if (!Array.isArray(raw)) {
      return NextResponse.json({ episodes: [] });
    }

    const episodes: ConfessorEpisode[] = [];
    for (const item of raw) {
      if (!item.mp3) continue;

      const audioUrl = fixAudioUrl(item.mp3);
      let dateStr = "Recent";
      let shortDate = "";
      let timestamp = 0;

      if (item.date) {
        const d = new Date(item.date);
        dateStr = d.toLocaleDateString("en-US", {
          weekday: "long",
          month: "long",
          day: "numeric",
          year: "numeric",
        });
        shortDate = d.toLocaleDateString("en-US", {
          month: "short",
          day: "numeric",
          year: "numeric",
        });
        timestamp = d.getTime();
      } else if (item.def_time) {
        const d = new Date(item.def_time * 1000);
        dateStr = d.toLocaleDateString("en-US", {
          weekday: "long",
          month: "long",
          day: "numeric",
          year: "numeric",
        });
        shortDate = d.toLocaleDateString("en-US", {
          month: "short",
          day: "numeric",
          year: "numeric",
        });
        timestamp = d.getTime();
      }

      let duration = "";
      if (item.lsecs) {
        const mins = Math.floor(item.lsecs / 60);
        const secs = item.lsecs % 60;
        duration = `${mins}:${secs.toString().padStart(2, "0")}`;
      }

      let headline: string | null = null;
      let guest: string | null = null;
      let summary: string | null = null;

      if (item.pubfile?.[0]) {
        const pf = item.pubfile[0];
        if (pf.pf_gname) guest = pf.pf_gname;
        if (pf.pf_gtopic) {
          if (pf.pf_gtopic.length <= 150) headline = pf.pf_gtopic;
          else summary = pf.pf_gtopic;
        }
      }

      episodes.push({
        title: item.title || "Untitled Episode",
        date: dateStr,
        shortDate,
        duration,
        audioUrl,
        timestamp,
        headline,
        guest,
        summary,
      });
    }

    return NextResponse.json({ episodes });
  } catch {
    return NextResponse.json(
      { error: "Failed to reach Confessor" },
      { status: 502 }
    );
  }
}
