/**
 * Generic API proxy route — runs on Node.js runtime (not Edge).
 * Node.js is required to correctly reconstruct multipart/form-data
 * (file uploads) before forwarding to the backend. Edge runtime
 * silently drops file content, causing "upload succeeded" but no file saved.
 *
 * Client components can't read httpOnly cookies, so all authenticated backend
 * requests go through here: /api/proxy?path=<encoded backend path>
 *
 * Supports GET, POST, PUT, DELETE, and passes body/FormData through.
 */
import { NextRequest, NextResponse } from "next/server";

export const runtime = "nodejs";

const BASE =
  process.env.NEXT_PUBLIC_API_BASE_URL ??
  "https://dev-api-kostraktor.duaenam.id/api/v1";

export async function GET(req: NextRequest) {
  return proxyRequest(req, "GET");
}
export async function POST(req: NextRequest) {
  return proxyRequest(req, "POST");
}
export async function PUT(req: NextRequest) {
  return proxyRequest(req, "PUT");
}
export async function DELETE(req: NextRequest) {
  return proxyRequest(req, "DELETE");
}

async function proxyRequest(req: NextRequest, method: string) {
  const token = req.cookies.get("kostraktor_admin_token")?.value;
  if (!token) {
    return NextResponse.json({ detail: "Unauthorized" }, { status: 401 });
  }

  const { searchParams } = new URL(req.url);
  const path = searchParams.get("path") ?? "/";

  const headers: Record<string, string> = {
    Authorization: `Bearer ${token}`,
  };

  // Forward Content-Type only if it's JSON (FormData sets its own boundary)
  const ct = req.headers.get("content-type");
  if (ct && ct.includes("application/json")) {
    headers["Content-Type"] = "application/json";
  }

  let body: BodyInit | null = null;
  if (method !== "GET" && method !== "DELETE") {
    if (ct?.includes("application/json")) {
      body = await req.text();
    } else if (ct?.includes("multipart/form-data")) {
      // Parse as FormData so fetch can correctly reconstruct the multipart body and boundary
      body = await req.formData();
    }
  }

  try {
    const upstream = await fetch(`${BASE}${path}`, {
      method,
      headers,
      body: body ?? undefined,
    });

    const responseHeaders: Record<string, string> = {};
    const upstreamCt = upstream.headers.get("content-type");
    if (upstreamCt) responseHeaders["content-type"] = upstreamCt;

    const data = await upstream.text();
    return new NextResponse(data, {
      status: upstream.status,
      headers: responseHeaders,
    });
  } catch (e) {
    console.error("Proxy error:", e);
    return NextResponse.json({ detail: "Backend tidak dapat dijangkau" }, { status: 502 });
  }
}
