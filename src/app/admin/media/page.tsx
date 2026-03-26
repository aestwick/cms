import { requireRole } from "@/lib/auth";
import { getSupabaseAdmin } from "@/lib/supabase/admin";
import type { Metadata } from "next";
import { MediaUpload } from "@/components/media-upload";

export const dynamic = "force-dynamic";

export const metadata: Metadata = {
  title: "Media Library — KPFK CMS",
};

const STORAGE_BASE =
  "https://czjhwhfqohpmwprhasve.supabase.co/storage/v1/object/public";

function formatBytes(bytes: number): string {
  if (bytes === 0) return "0 B";
  const units = ["B", "KB", "MB", "GB"];
  const i = Math.floor(Math.log(bytes) / Math.log(1024));
  return `${(bytes / Math.pow(1024, i)).toFixed(i === 0 ? 0 : 1)} ${units[i]}`;
}

function formatDate(iso: string): string {
  return new Date(iso).toLocaleDateString("en-US", {
    month: "short",
    day: "numeric",
    year: "numeric",
  });
}

export default async function MediaLibraryPage() {
  const user = await requireRole("admin", "editor");
  const supabase = getSupabaseAdmin();

  const { data: media } = await supabase
    .from("cms_media")
    .select(
      "id, storage_path, filename, mime_type, size_bytes, width, height, alt_text, created_at"
    )
    .eq("station_id", user.station_id)
    .order("created_at", { ascending: false });

  return (
    <div>
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold text-charcoal">Media Library</h1>
          <p className="mt-1 text-sm text-charcoal/50">
            {media?.length ?? 0} files
          </p>
        </div>
        <MediaUpload stationId={user.station_id} />
      </div>

      {(!media || media.length === 0) && (
        <div className="mt-12 text-center">
          <p className="text-base text-charcoal/40">
            No media uploaded yet. Use the upload button to add images.
          </p>
        </div>
      )}

      {media && media.length > 0 && (
        <div className="mt-6 grid grid-cols-2 gap-4 sm:grid-cols-3 lg:grid-cols-4">
          {media.map((item) => {
            const publicUrl = `${STORAGE_BASE}/${item.storage_path}`;
            const isImage = item.mime_type.startsWith("image/");

            return (
              <div
                key={item.id}
                className="group border border-charcoal/20 overflow-hidden"
              >
                {/* Preview */}
                <div className="relative aspect-square bg-charcoal/5">
                  {isImage ? (
                    // eslint-disable-next-line @next/next/no-img-element
                    <img
                      src={publicUrl}
                      alt={item.alt_text || item.filename}
                      className="h-full w-full object-cover"
                      loading="lazy"
                    />
                  ) : (
                    <div className="flex h-full w-full items-center justify-center">
                      <span className="font-mono text-xs uppercase text-charcoal/30">
                        {item.mime_type.split("/")[1] || "file"}
                      </span>
                    </div>
                  )}
                </div>

                {/* Metadata */}
                <div className="p-3">
                  <p
                    className="truncate text-sm font-medium text-charcoal"
                    title={item.filename}
                  >
                    {item.filename}
                  </p>
                  <p className="mt-1 font-mono text-xs text-charcoal/40">
                    {formatBytes(item.size_bytes)}
                    {item.width && item.height && (
                      <span className="ml-2">
                        {item.width}&times;{item.height}
                      </span>
                    )}
                  </p>
                  <p className="mt-0.5 text-xs text-charcoal/30">
                    {formatDate(item.created_at)}
                  </p>
                  <button
                    data-copy-url={publicUrl}
                    className="mt-2 w-full border border-charcoal/15 px-2 py-1 text-xs text-charcoal/60 hover:border-charcoal/30 hover:text-charcoal transition-colors cursor-pointer"
                    onClick={undefined}
                  >
                    Copy URL
                  </button>
                </div>
              </div>
            );
          })}
        </div>
      )}

      {/* Client-side script for copy-to-clipboard on server-rendered buttons */}
      <script
        dangerouslySetInnerHTML={{
          __html: `
            document.addEventListener('click', function(e) {
              var btn = e.target.closest('[data-copy-url]');
              if (!btn) return;
              var url = btn.getAttribute('data-copy-url');
              navigator.clipboard.writeText(url).then(function() {
                var orig = btn.textContent;
                btn.textContent = 'Copied!';
                setTimeout(function() { btn.textContent = orig; }, 2000);
              });
            });
          `,
        }}
      />
    </div>
  );
}
