import { NextRequest, NextResponse } from "next/server";
import { downloadCourse } from "@/lib/overpass";

export const runtime = "nodejs";
export const maxDuration = 60;

export async function GET(
  request: NextRequest,
  { params }: { params: Promise<{ osmType: string; osmId: string }> }
) {
  const { osmType, osmId: osmIdStr } = await params;
  const osmId = parseInt(osmIdStr, 10);
  const { searchParams } = request.nextUrl;
  const name = searchParams.get("name") ?? "Golf Course";
  const lat = searchParams.get("lat");
  const lon = searchParams.get("lon");

  if (!["node", "way", "relation"].includes(osmType)) {
    return NextResponse.json({ error: "Invalid osmType" }, { status: 400 });
  }
  if (!Number.isFinite(osmId)) {
    return NextResponse.json({ error: "Invalid osmId" }, { status: 400 });
  }

  try {
    const course = await downloadCourse(
      osmType,
      osmId,
      name,
      lat ? parseFloat(lat) : undefined,
      lon ? parseFloat(lon) : undefined
    );
    return NextResponse.json(course);
  } catch (error) {
    const message = error instanceof Error ? error.message : "Download failed";
    return NextResponse.json({ error: message }, { status: 502 });
  }
}
