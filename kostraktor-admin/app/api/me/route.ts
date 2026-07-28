import { NextRequest, NextResponse } from "next/server";
import { getMeApi } from "@/lib/api";

export async function GET(req: NextRequest) {
  const token = req.cookies.get("kostraktor_admin_token")?.value;
  if (!token) {
    return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
  }
  try {
    const me = await getMeApi(token);
    return NextResponse.json(me);
  } catch {
    return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
  }
}
