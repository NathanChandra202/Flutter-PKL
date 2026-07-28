import { NextRequest, NextResponse } from "next/server";
import { loginApi, getMeApi } from "@/lib/api";

export async function POST(req: NextRequest) {
  const { email, password } = await req.json();

  let token: string;
  try {
    token = await loginApi(email, password);
  } catch (e: unknown) {
    const msg = e instanceof Error ? e.message : "Login gagal";
    return NextResponse.json({ error: msg }, { status: 401 });
  }

  // Validate that the user has Admin role
  let me;
  try {
    me = await getMeApi(token);
  } catch {
    return NextResponse.json({ error: "Gagal mengambil profil" }, { status: 401 });
  }

  if (me.role !== "Admin" && me.role !== "SuperAdmin") {
    return NextResponse.json(
      { error: "Akses ditolak. Hanya Admin yang bisa masuk ke dashboard ini." },
      { status: 403 }
    );
  }

  // Set httpOnly cookie — secure from XSS
  const response = NextResponse.json({
    ok: true,
    user: { name: me.nama_lengkap, email: me.email, role: me.role },
  });

  response.cookies.set("kostraktor_admin_token", token, {
    httpOnly: true,
    secure: process.env.NODE_ENV === "production",
    sameSite: "lax",
    path: "/",
    maxAge: 60 * 60 * 8, // 8 hours
  });

  return response;
}
