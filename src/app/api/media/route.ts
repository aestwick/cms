import { getSupabaseAdmin } from "@/lib/supabase/admin";
import { getCmsUser } from "@/lib/auth";
import { NextRequest, NextResponse } from "next/server";

const BUCKET = "cms-media";

export async function GET(request: NextRequest) {
  const user = await getCmsUser();
  if (!user) {
    return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
  }

  const supabase = getSupabaseAdmin();

  const { data: media, error } = await supabase
    .from("cms_media")
    .select(
      "id, storage_path, filename, mime_type, size_bytes, width, height, alt_text, created_at"
    )
    .eq("station_id", user.station_id)
    .order("created_at", { ascending: false });

  if (error) {
    return NextResponse.json({ error: error.message }, { status: 500 });
  }

  return NextResponse.json({ media });
}

export async function POST(request: NextRequest) {
  const user = await getCmsUser();
  if (!user) {
    return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
  }

  if (user.role !== "admin" && user.role !== "editor") {
    return NextResponse.json({ error: "Forbidden" }, { status: 403 });
  }

  let formData: FormData;
  try {
    formData = await request.formData();
  } catch {
    return NextResponse.json(
      { error: "Invalid form data" },
      { status: 400 }
    );
  }

  const file = formData.get("file") as File | null;
  if (!file) {
    return NextResponse.json({ error: "No file provided" }, { status: 400 });
  }

  // Validate mime type
  if (!file.type.startsWith("image/")) {
    return NextResponse.json(
      { error: "Only image files are accepted" },
      { status: 400 }
    );
  }

  // Validate file size (10 MB max)
  const MAX_SIZE = 10 * 1024 * 1024;
  if (file.size > MAX_SIZE) {
    return NextResponse.json(
      { error: "File too large. Maximum size is 10 MB." },
      { status: 400 }
    );
  }

  const supabase = getSupabaseAdmin();

  // Generate a unique storage path
  const timestamp = Date.now();
  const safeName = file.name.replace(/[^a-zA-Z0-9._-]/g, "_");
  const storagePath = `${BUCKET}/${user.station_id}/${timestamp}_${safeName}`;

  // Read file into buffer
  const arrayBuffer = await file.arrayBuffer();
  const buffer = Buffer.from(arrayBuffer);

  // Upload to Supabase Storage
  const { error: uploadError } = await supabase.storage
    .from(BUCKET)
    .upload(`${user.station_id}/${timestamp}_${safeName}`, buffer, {
      contentType: file.type,
      upsert: false,
    });

  if (uploadError) {
    return NextResponse.json(
      { error: `Storage upload failed: ${uploadError.message}` },
      { status: 500 }
    );
  }

  // Try to get image dimensions (best-effort)
  let width: number | null = null;
  let height: number | null = null;

  try {
    // Dynamic import to avoid issues if sharp is not installed
    const sharp = (await import("sharp")).default;
    const metadata = await sharp(buffer).metadata();
    width = metadata.width ?? null;
    height = metadata.height ?? null;
  } catch {
    // sharp not available or image not parseable — skip dimensions
  }

  // Create cms_media record
  const { data: record, error: insertError } = await supabase
    .from("cms_media")
    .insert({
      station_id: user.station_id,
      storage_path: storagePath,
      filename: file.name,
      mime_type: file.type,
      size_bytes: file.size,
      width,
      height,
      uploaded_by: user.id,
    })
    .select("id, storage_path, filename, mime_type, size_bytes, width, height, created_at")
    .single();

  if (insertError) {
    return NextResponse.json(
      { error: `Database insert failed: ${insertError.message}` },
      { status: 500 }
    );
  }

  return NextResponse.json({ media: record }, { status: 201 });
}
