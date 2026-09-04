// ─── API base URL ──────────────────────────────────────────────────────────────
const BASE = process.env.NEXT_PUBLIC_API_BASE_URL ?? "https://dev-api-kostraktor.duaenam.id/api/v1";

// ─── Cookie helpers (browser-side) ─────────────────────────────────────────────
const TOKEN_KEY = "kostraktor_admin_token";

export function saveToken(token: string) {
  // httpOnly cookie is set server-side (see app/api/login/route.ts).
  // This function is a no-op; token is handled via server route.
  void token;
}

export function getToken(): string | null {
  if (typeof document === "undefined") return null;
  const match = document.cookie.match(new RegExp(`(?:^|; )${TOKEN_KEY}=([^;]*)`));
  return match ? decodeURIComponent(match[1]) : null;
}

export function removeToken() {
  document.cookie = `${TOKEN_KEY}=; path=/; max-age=0`;
}

// ─── Generic fetch wrapper ─────────────────────────────────────────────────────
interface FetchOptions extends RequestInit {
  token?: string | null;
}

async function apiFetch<T>(path: string, options: FetchOptions = {}): Promise<T> {
  const { token, ...init } = options;
  const headers = new Headers(init.headers);
  if (token) headers.set("Authorization", `Bearer ${token}`);
  if (!headers.has("Content-Type") && !(init.body instanceof FormData)) {
    headers.set("Content-Type", "application/json");
  }

  const res = await fetch(`${BASE}${path}`, { ...init, headers });
  if (!res.ok) {
    const err = await res.json().catch(() => ({ detail: res.statusText }));
    throw new Error(err.detail ?? "Request failed");
  }
  // 204 No Content
  if (res.status === 204) return undefined as T;
  return res.json();
}

// ─── Auth ──────────────────────────────────────────────────────────────────────
export interface MeResponse {
  id: number;
  email: string;
  role: string;
  nama_lengkap: string | null;
  is_face_verified: boolean;
}

export async function loginApi(email: string, password: string): Promise<string> {
  const body = new URLSearchParams({ username: email, password });
  const data = await apiFetch<{ access_token: string }>("/auth/login", {
    method: "POST",
    body,
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
  });
  return data.access_token;
}

export async function getMeApi(token: string): Promise<MeResponse> {
  return apiFetch<MeResponse>("/auth/me", { token });
}

// ─── Rooms ─────────────────────────────────────────────────────────────────────
export interface Room {
  id: number;
  name: string;
  description: string;
  price_per_month: number;
  is_available: boolean;
  image_url: string | null;
  additional_images: string | null;
  facilities: string | null;
  room_type: string | null;
}

export async function getRoomsApi(token: string): Promise<Room[]> {
  return apiFetch<Room[]>("/rooms/?all=true", { token });
}

export async function createRoomApi(token: string, data: Omit<Room, "id">): Promise<Room> {
  return apiFetch<Room>("/rooms/", { method: "POST", body: JSON.stringify(data), token });
}

export async function updateRoomApi(token: string, id: number, data: Partial<Omit<Room, "id">>): Promise<Room> {
  return apiFetch<Room>(`/rooms/${id}`, { method: "PUT", body: JSON.stringify(data), token });
}

export async function deleteRoomApi(token: string, id: number): Promise<void> {
  return apiFetch<void>(`/rooms/${id}`, { method: "DELETE", token });
}

export async function uploadRoomImagesApi(token: string, roomId: number, files: FileList): Promise<{ additional_images: string[] }> {
  const form = new FormData();
  Array.from(files).forEach((f) => form.append("files", f));
  return apiFetch(`/rooms/${roomId}/upload-images`, {
    method: "POST",
    body: form,
    token,
    headers: {}, // let browser set multipart boundary
  });
}

export async function deleteRoomImageApi(token: string, roomId: number, imageUrl: string): Promise<void> {
  return apiFetch<void>(`/rooms/${roomId}/images?image_url=${encodeURIComponent(imageUrl)}`, {
    method: "DELETE",
    token,
  });
}

// ─── Bookings ─────────────────────────────────────────────────────────────────
export interface Booking {
  id: number;
  user_id: number;
  room_id: number;
  booking_date: string;
  start_date: string;
  status: string;
  duration_months: number | null;
  end_date: string | null;
  is_renewal_requested: boolean | null;
  pending_renewal_months: number | null;
  room_name: string | null;
  user_email: string | null;
  user_name: string | null;
  bukti_bayar_url: string | null;
}

export async function getPendingBookingsApi(token: string): Promise<Booking[]> {
  return apiFetch<Booking[]>("/bookings/pending", { token });
}

export async function updateBookingStatusApi(
  token: string,
  bookingId: number,
  status: "APPROVED" | "REJECTED"
): Promise<Booking> {
  return apiFetch<Booking>(`/bookings/${bookingId}/status`, {
    method: "POST",
    body: JSON.stringify({ status }),
    token,
  });
}

// ─── Jastip ───────────────────────────────────────────────────────────────────
export interface Jastip {
  id: number;
  title: string;
  description: string;
  price: string;
  wa_number: string;
  user_id: number;
  author_name: string | null;
  is_active: boolean;
  created_at: string;
}

export async function getJastipApi(token: string): Promise<Jastip[]> {
  return apiFetch<Jastip[]>("/jastip/", { token });
}

export async function deleteJastipApi(token: string, id: number): Promise<void> {
  return apiFetch<void>(`/jastip/${id}`, { method: "DELETE", token });
}

// ─── Tools ────────────────────────────────────────────────────────────────────
export interface Tool {
  id: number;
  name: string;
  icon_name: string;
  is_available: boolean;
  borrowed_by_name: string | null;
  borrowed_at: string | null;
}

export async function getToolsApi(token: string): Promise<Tool[]> {
  return apiFetch<Tool[]>("/tools/", { token });
}

// ─── Reviews ──────────────────────────────────────────────────────────────────
export interface Review {
  id: number;
  user_name: string;
  user_email: string;
  rating: number;
  comment: string;
  room_type: string | null;
  created_at: string;
}

export async function getReviewsApi(token: string): Promise<Review[]> {
  return apiFetch<Review[]>("/reviews/", { token });
}

// ─── Settings ─────────────────────────────────────────────────────────────────
export interface Setting {
  id: number;
  key: string;
  value: string;
}

export async function getSettingApi(token: string, key: string): Promise<Setting> {
  return apiFetch<Setting>(`/settings/${key}`, { token });
}

export async function updateSettingApi(token: string, key: string, value: string): Promise<Setting> {
  return apiFetch<Setting>(`/settings/${key}`, { 
    method: "PUT",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ value }),
    token 
  });
}

