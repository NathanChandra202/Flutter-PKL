import type { NextConfig } from "next";

// URL API backend (dengan /api/v1)
const API_BASE =
  process.env.NEXT_PUBLIC_API_BASE_URL ??
  "https://dev-api-kostraktor.duaenam.id/api/v1";

// Origin backend tanpa /api/v1
// Kalau development dan tidak ada env override, default ke localhost:8000
const BACKEND_ORIGIN = API_BASE.replace(/\/api\/v1\/?$/, "");

// Ekstrak hostname secara aman
let backendHostname = "dev-api-kostraktor.duaenam.id";
try {
  backendHostname = new URL(BACKEND_ORIGIN).hostname;
} catch {}

const nextConfig: NextConfig = {
  images: {
    remotePatterns: [
      { protocol: "https", hostname: "cdn.duaenam.id" },
      {
        // Izinkan gambar dari backend production
        protocol: "https",
        hostname: backendHostname,
      },
      {
        // Izinkan gambar dari backend lokal (development)
        protocol: "http",
        hostname: "localhost",
        port: "8000",
      },
      {
        // Izinkan dari 127.0.0.1 juga
        protocol: "http",
        hostname: "127.0.0.1",
        port: "8000",
      },
    ],
  },
  async rewrites() {
    return [
      {
        // Proxy /uploads/* ke backend (lokal atau production sesuai env)
        source: "/uploads/:path*",
        destination: `${BACKEND_ORIGIN}/uploads/:path*`,
      },
    ];
  },
};

export default nextConfig;