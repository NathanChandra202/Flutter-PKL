import { NextRequest, NextResponse } from "next/server";

export async function POST(req: NextRequest) {
  void req;
  const response = NextResponse.json({ ok: true });
  response.cookies.set("kostraktor_admin_token", "", {
    httpOnly: true,
    path: "/",
    maxAge: 0,
  });
  return response;
}
