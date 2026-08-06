import { clsx, type ClassValue } from "clsx"
import { twMerge } from "tailwind-merge"

export function cn(...inputs: ClassValue[]) {
  return twMerge(clsx(inputs))
}

/**
 * Format tanggal ISO/string ke format lokal Indonesia
 * Contoh: "2024-01-15T10:30:00Z" → "15 Jan 2024, 17:30"
 */
export function formatDate(value: string | Date | null | undefined): string {
  if (!value) return "-";
  try {
    const date = typeof value === "string" ? new Date(value) : value;
    if (isNaN(date.getTime())) return String(value);
    return date.toLocaleString("id-ID", {
      day: "numeric",
      month: "short",
      year: "numeric",
      hour: "2-digit",
      minute: "2-digit",
    });
  } catch {
    return String(value);
  }
}

/**
 * Format angka ke format mata uang Rupiah
 * Contoh: 150000 → "Rp 150.000"
 */
export function formatRupiah(value: number | string | null | undefined): string {
  if (value === null || value === undefined || value === "") return "-";
  const num = typeof value === "string" ? parseFloat(value) : value;
  if (isNaN(num)) return String(value);
  return new Intl.NumberFormat("id-ID", {
    style: "currency",
    currency: "IDR",
    minimumFractionDigits: 0,
    maximumFractionDigits: 0,
  }).format(num);
}

/**
 * Resolve URL media dari backend — handle URL absolut, relatif, dan undefined.
 * Menggunakan NEXT_PUBLIC_API_BASE_URL (tanpa /api/v1) sebagai origin.
 * Contoh: "/uploads/rooms/foto.jpg" → "https://dev-api-kostraktor.duaenam.id/uploads/rooms/foto.jpg"
 */
export function resolveMediaUrl(path: string | null | undefined): string {
  if (!path) return "";
  if (path.startsWith("http://") || path.startsWith("https://")) return path;
  // Strip /api/v1 suffix to get server origin
  const origin = (
    process.env.NEXT_PUBLIC_API_BASE_URL ?? "https://dev-api-kostraktor.duaenam.id/api/v1"
  ).replace(/\/api\/v1\/?$/, "");
  return `${origin}${path.startsWith("/") ? "" : "/"}${path}`;
}
