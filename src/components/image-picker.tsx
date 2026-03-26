"use client";

import { useState, useRef, useEffect, useCallback } from "react";
import { resolveImageUrl } from "@/lib/format";

interface MediaItem {
  id: string;
  storage_path: string;
  filename: string;
  mime_type: string;
  width: number | null;
  height: number | null;
}

type Tab = "browse" | "upload" | "url";

interface ImagePickerProps {
  value: string;
  onChange: (path: string) => void;
  label: string;
  placeholder?: string;
}

export function ImagePicker({
  value,
  onChange,
  label,
  placeholder = "e.g. shows/my-show/logo.webp",
}: ImagePickerProps) {
  const [open, setOpen] = useState(false);
  const [tab, setTab] = useState<Tab>("browse");
  const [media, setMedia] = useState<MediaItem[]>([]);
  const [loading, setLoading] = useState(false);
  const [uploading, setUploading] = useState(false);
  const [uploadError, setUploadError] = useState("");
  const [urlInput, setUrlInput] = useState("");
  const fileInputRef = useRef<HTMLInputElement>(null);
  const dialogRef = useRef<HTMLDivElement>(null);

  const fetchMedia = useCallback(async () => {
    setLoading(true);
    try {
      const res = await fetch("/api/media");
      if (res.ok) {
        const data = await res.json();
        setMedia(data.media || []);
      }
    } catch {
      // silent
    }
    setLoading(false);
  }, []);

  // Fetch media when browse tab is opened
  useEffect(() => {
    if (open && tab === "browse" && media.length === 0) {
      fetchMedia();
    }
  }, [open, tab, media.length, fetchMedia]);

  // Close on outside click
  useEffect(() => {
    if (!open) return;
    function handleClick(e: MouseEvent) {
      if (
        dialogRef.current &&
        !dialogRef.current.contains(e.target as Node)
      ) {
        setOpen(false);
      }
    }
    document.addEventListener("mousedown", handleClick);
    return () => document.removeEventListener("mousedown", handleClick);
  }, [open]);

  // Close on Escape
  useEffect(() => {
    if (!open) return;
    function handleKey(e: KeyboardEvent) {
      if (e.key === "Escape") setOpen(false);
    }
    document.addEventListener("keydown", handleKey);
    return () => document.removeEventListener("keydown", handleKey);
  }, [open]);

  async function handleUpload(file: File) {
    setUploading(true);
    setUploadError("");
    try {
      const formData = new FormData();
      formData.append("file", file);

      const res = await fetch("/api/media", {
        method: "POST",
        body: formData,
      });
      if (!res.ok) {
        const body = await res.json().catch(() => null);
        throw new Error(body?.error || `Upload failed (${res.status})`);
      }
      const data = await res.json();
      const uploaded = data.media;
      // Select the uploaded image
      onChange(uploaded.storage_path);
      setMedia((prev) => [uploaded, ...prev]);
      setOpen(false);
    } catch (err) {
      setUploadError(err instanceof Error ? err.message : "Upload failed");
    }
    setUploading(false);
  }

  function handleUrlConfirm() {
    if (urlInput.trim()) {
      onChange(urlInput.trim());
      setUrlInput("");
      setOpen(false);
    }
  }

  function handleSelect(item: MediaItem) {
    onChange(item.storage_path);
    setOpen(false);
  }

  function handleClear() {
    onChange("");
  }

  const hasValue = value.trim().length > 0;
  const previewUrl = hasValue ? resolveImageUrl(value) : null;

  return (
    <div>
      <label className="block text-sm font-medium text-charcoal">
        {label}
      </label>

      <div className="mt-1">
        {/* Preview + current value */}
        {hasValue ? (
          <div className="flex items-start gap-3">
            <div className="relative h-16 w-16 flex-shrink-0 overflow-hidden border border-charcoal/10 bg-charcoal/5">
              {/* eslint-disable-next-line @next/next/no-img-element */}
              <img
                src={previewUrl!}
                alt=""
                className="h-full w-full object-cover"
                onError={(e) => {
                  (e.target as HTMLImageElement).style.display = "none";
                }}
              />
            </div>
            <div className="min-w-0 flex-1">
              <p className="truncate font-mono text-xs text-charcoal/60">
                {value}
              </p>
              <div className="mt-1 flex gap-2">
                <button
                  type="button"
                  onClick={() => setOpen(true)}
                  className="text-xs font-medium text-charcoal/60 underline hover:text-charcoal"
                >
                  Change
                </button>
                <button
                  type="button"
                  onClick={handleClear}
                  className="text-xs font-medium text-kpfk-red/60 underline hover:text-kpfk-red"
                >
                  Remove
                </button>
              </div>
            </div>
          </div>
        ) : (
          <button
            type="button"
            onClick={() => setOpen(true)}
            className="flex h-16 w-full items-center justify-center border-2 border-dashed border-charcoal/20 bg-off-white text-sm text-charcoal/40 transition-colors hover:border-charcoal/40 hover:text-charcoal/60"
          >
            Choose image...
          </button>
        )}
      </div>

      {/* Modal overlay */}
      {open && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-charcoal/40">
          <div
            ref={dialogRef}
            className="mx-4 flex max-h-[80vh] w-full max-w-xl flex-col bg-white shadow-xl"
          >
            {/* Header */}
            <div className="flex items-center justify-between border-b border-charcoal/10 px-5 py-3">
              <h3 className="text-base font-bold text-charcoal">
                Select Image
              </h3>
              <button
                type="button"
                onClick={() => setOpen(false)}
                className="text-charcoal/40 hover:text-charcoal"
              >
                &times;
              </button>
            </div>

            {/* Tabs */}
            <div className="flex border-b border-charcoal/10">
              {(
                [
                  ["browse", "Browse Media"],
                  ["upload", "Upload"],
                  ["url", "URL"],
                ] as [Tab, string][]
              ).map(([t, label]) => (
                <button
                  key={t}
                  type="button"
                  onClick={() => setTab(t)}
                  className={`flex-1 px-4 py-2.5 text-sm font-medium transition-colors ${
                    tab === t
                      ? "border-b-2 border-charcoal text-charcoal"
                      : "text-charcoal/40 hover:text-charcoal/70"
                  }`}
                >
                  {label}
                </button>
              ))}
            </div>

            {/* Tab content */}
            <div className="flex-1 overflow-y-auto p-5">
              {/* Browse media library */}
              {tab === "browse" && (
                <div>
                  {loading ? (
                    <p className="text-center text-sm text-charcoal/40">
                      Loading media...
                    </p>
                  ) : media.length === 0 ? (
                    <div className="py-8 text-center">
                      <p className="text-sm text-charcoal/40">
                        No images in library yet.
                      </p>
                      <button
                        type="button"
                        onClick={() => setTab("upload")}
                        className="mt-2 text-sm font-medium text-charcoal underline hover:text-charcoal/70"
                      >
                        Upload one now
                      </button>
                    </div>
                  ) : (
                    <div className="grid grid-cols-3 gap-2 sm:grid-cols-4">
                      {media.map((item) => {
                        const url = resolveImageUrl(item.storage_path);
                        const isSelected = value === item.storage_path;
                        return (
                          <button
                            key={item.id}
                            type="button"
                            onClick={() => handleSelect(item)}
                            className={`group relative aspect-square overflow-hidden border-2 transition-all ${
                              isSelected
                                ? "border-charcoal ring-1 ring-charcoal"
                                : "border-charcoal/10 hover:border-charcoal/30"
                            }`}
                          >
                            {/* eslint-disable-next-line @next/next/no-img-element */}
                            <img
                              src={url}
                              alt={item.filename}
                              className="h-full w-full object-cover"
                            />
                            <div className="absolute inset-x-0 bottom-0 bg-gradient-to-t from-black/60 to-transparent p-1 opacity-0 transition-opacity group-hover:opacity-100">
                              <p className="truncate text-[10px] text-white">
                                {item.filename}
                              </p>
                            </div>
                          </button>
                        );
                      })}
                    </div>
                  )}
                </div>
              )}

              {/* Upload */}
              {tab === "upload" && (
                <div className="flex flex-col items-center py-6">
                  <input
                    ref={fileInputRef}
                    type="file"
                    accept="image/*"
                    className="sr-only"
                    onChange={(e) => {
                      const file = e.target.files?.[0];
                      if (file) handleUpload(file);
                    }}
                    disabled={uploading}
                  />
                  <button
                    type="button"
                    onClick={() => fileInputRef.current?.click()}
                    disabled={uploading}
                    className="border-2 border-dashed border-charcoal/30 px-8 py-6 text-sm text-charcoal/50 transition-colors hover:border-charcoal/50 hover:text-charcoal disabled:opacity-50"
                  >
                    {uploading
                      ? "Uploading..."
                      : "Click to choose an image (max 10 MB)"}
                  </button>
                  {uploadError && (
                    <p className="mt-3 text-sm text-kpfk-red">{uploadError}</p>
                  )}
                </div>
              )}

              {/* URL */}
              {tab === "url" && (
                <div>
                  <p className="mb-3 text-xs text-charcoal/40">
                    Enter a full URL or a Supabase Storage path.
                  </p>
                  <div className="flex gap-2">
                    <input
                      type="text"
                      value={urlInput}
                      onChange={(e) => setUrlInput(e.target.value)}
                      onKeyDown={(e) => {
                        if (e.key === "Enter") {
                          e.preventDefault();
                          handleUrlConfirm();
                        }
                      }}
                      placeholder={placeholder}
                      className="flex-1 border border-charcoal/20 bg-off-white px-3 py-2 font-mono text-sm focus:border-charcoal focus:outline-none"
                    />
                    <button
                      type="button"
                      onClick={handleUrlConfirm}
                      disabled={!urlInput.trim()}
                      className="border-2 border-charcoal bg-charcoal px-4 py-2 text-sm font-medium text-off-white hover:bg-charcoal/90 disabled:opacity-50"
                    >
                      Use
                    </button>
                  </div>
                </div>
              )}
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
