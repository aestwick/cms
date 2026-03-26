"use client";

import { useRef, useState } from "react";
import { useRouter } from "next/navigation";

type UploadState = "idle" | "uploading" | "success" | "error";

export function MediaUpload({ stationId }: { stationId: string }) {
  const [state, setState] = useState<UploadState>("idle");
  const [errorMessage, setErrorMessage] = useState("");
  const fileInputRef = useRef<HTMLInputElement>(null);
  const router = useRouter();

  async function handleUpload() {
    const file = fileInputRef.current?.files?.[0];
    if (!file) return;

    setState("uploading");
    setErrorMessage("");

    try {
      const formData = new FormData();
      formData.append("file", file);
      formData.append("station_id", stationId);

      const res = await fetch("/api/media", {
        method: "POST",
        body: formData,
      });

      if (!res.ok) {
        const body = await res.json().catch(() => null);
        throw new Error(body?.error || `Upload failed (${res.status})`);
      }

      setState("success");

      // Reset file input
      if (fileInputRef.current) {
        fileInputRef.current.value = "";
      }

      // Refresh the page to show the new upload
      router.refresh();

      // Reset state after a moment
      setTimeout(() => setState("idle"), 2000);
    } catch (err) {
      setState("error");
      setErrorMessage(
        err instanceof Error ? err.message : "Upload failed"
      );
    }
  }

  return (
    <div className="flex items-center gap-3">
      {state === "success" && (
        <span className="text-sm text-green-600">Uploaded!</span>
      )}
      {state === "error" && (
        <span className="text-sm text-red-600">{errorMessage}</span>
      )}

      <label className="flex cursor-pointer items-center gap-2 border-2 border-charcoal bg-charcoal px-5 py-2.5 text-base font-medium text-off-white hover:bg-charcoal/90">
        <input
          ref={fileInputRef}
          type="file"
          accept="image/*"
          className="sr-only"
          onChange={handleUpload}
          disabled={state === "uploading"}
        />
        {state === "uploading" ? "Uploading..." : "Upload image"}
      </label>
    </div>
  );
}
