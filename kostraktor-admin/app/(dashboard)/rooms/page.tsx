"use client";

import { useEffect, useState, useRef } from "react";
import Image from "next/image";
import type { Room } from "@/lib/api";
import { formatRupiah, resolveMediaUrl } from "@/lib/utils";

// ─── Helpers ────────────────────────────────────────────────────────────────────

function parseImages(room: Room): string[] {
  const imgs: string[] = [];
  if (room.image_url) imgs.push(room.image_url);
  if (room.additional_images) {
    room.additional_images.split(",").forEach((u) => {
      const t = u.trim();
      if (t) imgs.push(t);
    });
  }
  return imgs;
}

// ─── Room Form Dialog ───────────────────────────────────────────────────────────

interface RoomFormProps {
  initial?: Room;
  onSave: (data: Partial<Room>, imageFiles?: FileList) => Promise<void>;
  onClose: () => void;
}

function RoomFormDialog({ initial, onSave, onClose }: RoomFormProps) {
  const [form, setForm] = useState({
    name: initial?.name ?? "",
    description: initial?.description ?? "",
    price_per_month: initial?.price_per_month ?? 0,
    is_available: initial?.is_available ?? true,
    facilities: initial?.facilities ?? "",
    room_type: initial?.room_type ?? "",
  });
  const [files, setFiles] = useState<FileList | null>(null);
  const [saving, setSaving] = useState(false);
  const [err, setErr] = useState<string | null>(null);
  const fileRef = useRef<HTMLInputElement>(null);

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    setSaving(true);
    setErr(null);
    try {
      await onSave(form, files ?? undefined);
    } catch (e: unknown) {
      setErr(e instanceof Error ? e.message : "Gagal menyimpan");
    } finally {
      setSaving(false);
    }
  }

  return (
    <div className="fixed inset-0 bg-black/50 backdrop-blur-sm z-50 flex items-center justify-center p-4">
      <div className="bg-brand-surface border border-gray-200 rounded-2xl w-full max-w-lg shadow-2xl overflow-hidden">
        <div className="flex items-center justify-between px-6 py-4 border-b border-gray-200">
          <h2 className="text-brand-black font-semibold">{initial ? "Edit Kamar" : "Tambah Kamar Baru"}</h2>
          <button onClick={onClose} className="text-brand-muted hover:text-brand-black">✕</button>
        </div>

        <form onSubmit={handleSubmit} className="p-6 space-y-4 max-h-[70vh] overflow-y-auto">
          {err && (
            <p className="text-red-600 text-sm bg-red-50 border border-red-200 rounded-xl px-4 py-2">{err}</p>
          )}

          {[
            { label: "Nama Kamar *", key: "name", type: "text", required: true },
            { label: "Tipe Kamar", key: "room_type", type: "text" },
          ].map(({ label, key, type, required }) => (
            <div key={key}>
              <label className="text-brand-black text-sm font-medium block mb-1">{label}</label>
              <input
                type={type}
                required={required}
                value={String(form[key as keyof typeof form])}
                onChange={(e) => setForm((f) => ({ ...f, [key]: e.target.value }))}
                className="w-full bg-gray-50 border border-gray-300 rounded-xl px-4 py-2.5 text-brand-black text-sm focus:outline-none focus:ring-2 focus:ring-brand-black/20"
              />
            </div>
          ))}

          <div>
            <label className="text-brand-black text-sm font-medium block mb-1">Deskripsi</label>
            <textarea
              rows={3}
              value={form.description}
              onChange={(e) => setForm((f) => ({ ...f, description: e.target.value }))}
              className="w-full bg-gray-50 border border-gray-300 rounded-xl px-4 py-2.5 text-brand-black text-sm focus:outline-none focus:ring-2 focus:ring-brand-black/20 resize-none"
            />
          </div>

          <div>
            <label className="text-brand-black text-sm font-medium block mb-1">Harga / Bulan (Rp) *</label>
            <input
              type="number"
              required
              min={0}
              value={form.price_per_month}
              onChange={(e) => setForm((f) => ({ ...f, price_per_month: Number(e.target.value) }))}
              className="w-full bg-gray-50 border border-gray-300 rounded-xl px-4 py-2.5 text-brand-black text-sm focus:outline-none focus:ring-2 focus:ring-brand-black/20"
            />
          </div>

          <div>
            <label className="text-brand-black text-sm font-medium block mb-1">Fasilitas (pisahkan koma)</label>
            <input
              type="text"
              value={form.facilities}
              onChange={(e) => setForm((f) => ({ ...f, facilities: e.target.value }))}
              placeholder="AC, WiFi, Kasur, ..."
              className="w-full bg-gray-50 border border-gray-300 rounded-xl px-4 py-2.5 text-brand-black text-sm focus:outline-none focus:ring-2 focus:ring-brand-black/20"
            />
          </div>

          <div className="flex items-center gap-3">
            <label className="relative inline-flex items-center cursor-pointer">
              <input
                type="checkbox"
                checked={form.is_available}
                onChange={(e) => setForm((f) => ({ ...f, is_available: e.target.checked }))}
                className="sr-only peer"
              />
              <div className="w-10 h-6 bg-gray-200 peer-focus:ring-2 peer-focus:ring-brand-black/20 rounded-full peer peer-checked:after:translate-x-full after:content-[''] after:absolute after:top-[2px] after:left-[2px] after:bg-white after:rounded-full after:h-5 after:w-5 after:transition-all peer-checked:bg-brand-black" />
            </label>
            <span className="text-brand-black text-sm">Tersedia untuk disewa</span>
          </div>

          <div>
            <label className="text-brand-black text-sm font-medium block mb-1">
              {initial ? "Tambah Gambar Baru" : "Upload Gambar"}
            </label>
            <div
              onClick={() => fileRef.current?.click()}
              className="border-2 border-dashed border-gray-300 hover:border-brand-black rounded-xl p-4 text-center cursor-pointer transition-colors"
            >
              <p className="text-brand-muted text-sm">
                {files && files.length > 0
                  ? `${files.length} file dipilih`
                  : "Klik atau seret file gambar (bisa lebih dari 1)"}
              </p>
            </div>
            <input
              ref={fileRef}
              type="file"
              multiple
              accept="image/*"
              className="hidden"
              onChange={(e) => setFiles(e.target.files)}
            />
          </div>

          <div className="flex gap-3 pt-2">
            <button
              type="button"
              onClick={onClose}
              className="flex-1 py-2.5 bg-gray-50 hover:bg-gray-200 text-brand-black rounded-xl text-sm font-medium transition-colors"
            >
              Batal
            </button>
            <button
              type="submit"
              disabled={saving}
              className="flex-1 py-2.5 bg-brand-black hover:bg-gray-900 disabled:opacity-60 text-white rounded-xl text-sm font-bold transition-colors"
            >
              {saving ? "Menyimpan..." : "Simpan"}
            </button>
          </div>
        </form>
      </div>
    </div>
  );
}

// ─── Image Gallery Dialog ────────────────────────────────────────────────────────

function ImageGalleryDialog({
  room,
  onDelete,
  onClose,
}: {
  room: Room;
  onDelete: (url: string) => Promise<void>;
  onClose: () => void;
}) {
  const images = parseImages(room);

  return (
    <div className="fixed inset-0 bg-black/50 backdrop-blur-sm z-50 flex items-center justify-center p-4">
      <div className="bg-brand-surface border border-gray-200 rounded-2xl w-full max-w-2xl shadow-2xl overflow-hidden">
        <div className="flex items-center justify-between px-6 py-4 border-b border-gray-200">
          <h2 className="text-brand-black font-semibold">Gambar — {room.name}</h2>
          <button onClick={onClose} className="text-brand-muted hover:text-brand-black">✕</button>
        </div>
        <div className="p-6">
          {images.length === 0 ? (
            <p className="text-brand-muted text-center py-8">Belum ada gambar</p>
          ) : (
            <div className="grid grid-cols-3 gap-3">
              {images.map((url, i) => (
                <div key={i} className="relative group aspect-video bg-gray-50 rounded-xl overflow-hidden">
                  <Image
                    src={resolveMediaUrl(url)}
                    alt={`Room ${i + 1}`}
                    fill
                    className="object-cover"
                    sizes="200px"
                    unoptimized
                  />
                  <button
                    onClick={() => onDelete(url)}
                    className="absolute inset-0 bg-red-600/80 opacity-0 group-hover:opacity-100 transition-opacity flex items-center justify-center text-brand-black text-xs font-medium"
                  >
                    🗑 Hapus
                  </button>
                </div>
              ))}
            </div>
          )}
          <div className="mt-4 text-right">
            <button onClick={onClose} className="px-4 py-2 bg-gray-50 hover:bg-gray-200 text-brand-black rounded-xl text-sm">Tutup</button>
          </div>
        </div>
      </div>
    </div>
  );
}

// ─── Main Page ──────────────────────────────────────────────────────────────────

export default function RoomsPage() {
  const [rooms, setRooms] = useState<Room[]>([]);
  const [loading, setLoading] = useState(true);
  const [showForm, setShowForm] = useState(false);
  const [editRoom, setEditRoom] = useState<Room | undefined>();
  const [galleryRoom, setGalleryRoom] = useState<Room | undefined>();
  const [confirmDelete, setConfirmDelete] = useState<Room | null>(null);
  const [toast, setToast] = useState<{ msg: string; ok: boolean } | null>(null);

  function showToast(msg: string, ok = true) {
    setToast({ msg, ok });
    setTimeout(() => setToast(null), 3000);
  }

  async function apiWithToken<T>(path: string, options: RequestInit = {}): Promise<T> {
    const res = await fetch(`/api/proxy?path=${encodeURIComponent(path)}`, {
      ...options,
      headers: { ...(options.headers ?? {}) },
    });
    if (!res.ok) {
      const err = await res.json().catch(() => ({ detail: res.statusText }));
      throw new Error(err.detail ?? "Request gagal");
    }
    return res.json();
  }

  async function loadRooms() {
    setLoading(true);
    try {
      const res = await fetch("/api/proxy?path=%2Frooms%2F%3Fall%3Dtrue");
      if (res.ok) setRooms(await res.json());
    } finally {
      setLoading(false);
    }
  }

  useEffect(() => { loadRooms(); }, []);

  async function handleSave(data: Partial<Room>, files?: FileList) {
    if (editRoom) {
      // Update existing room
      await apiWithToken<Room>(`/rooms/${editRoom.id}`, {
        method: "PUT",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(data),
      });
      // Upload new images if selected
      if (files && files.length > 0) {
        const form = new FormData();
        Array.from(files).forEach((f) => form.append("files", f));
        await apiWithToken(`/rooms/${editRoom.id}/upload-images`, { method: "POST", body: form });
      }
      showToast("Kamar berhasil diupdate!");
    } else {
      // Create new room first, then upload images
      const newRoom = await apiWithToken<Room>("/rooms/", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(data),
      });
      if (files && files.length > 0) {
        const form = new FormData();
        Array.from(files).forEach((f) => form.append("files", f));
        await apiWithToken(`/rooms/${newRoom.id}/upload-images`, { method: "POST", body: form });
      }
      showToast("Kamar berhasil ditambahkan!");
    }
    setShowForm(false);
    setEditRoom(undefined);
    await loadRooms();
  }

  async function handleDelete(room: Room) {
    try {
      await apiWithToken(`/rooms/${room.id}`, { method: "DELETE" });
      showToast("Kamar berhasil dihapus (dinonaktifkan)");
      setConfirmDelete(null);
      await loadRooms();
    } catch (e: unknown) {
      showToast(e instanceof Error ? e.message : "Gagal menghapus", false);
    }
  }

  async function handleDeleteImage(room: Room, imageUrl: string) {
    try {
      await apiWithToken(`/rooms/${room.id}/images?image_url=${encodeURIComponent(imageUrl)}`, { method: "DELETE" });
      showToast("Gambar berhasil dihapus");
      await loadRooms();
      // Refresh gallery
      setGalleryRoom((prev) => prev ? rooms.find((r) => r.id === prev.id) : undefined);
    } catch (e: unknown) {
      showToast(e instanceof Error ? e.message : "Gagal hapus gambar", false);
    }
  }

  return (
    <div className="space-y-6">
      {/* Toast */}
      {toast && (
        <div className={`fixed top-6 right-6 z-[100] px-5 py-3 rounded-xl shadow-lg text-sm font-medium transition-all ${toast.ok ? "bg-emerald-500 text-brand-black" : "bg-red-600 text-brand-black"}`}>
          {toast.msg}
        </div>
      )}

      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-xl font-bold text-brand-black">Kelola Kamar</h1>
          <p className="text-brand-muted text-sm mt-0.5">{rooms.length} kamar terdaftar</p>
        </div>
        <button
          onClick={() => { setEditRoom(undefined); setShowForm(true); }}
          className="flex items-center gap-2 px-4 py-2.5 bg-brand-black hover:bg-gray-900 text-white font-semibold rounded-xl text-sm transition-colors"
        >
          + Tambah Kamar
        </button>
      </div>

      {/* Table */}
      <div className="bg-brand-surface border border-gray-200 rounded-2xl overflow-hidden">
        {loading ? (
          <div className="flex items-center justify-center py-20 text-brand-muted">Memuat data...</div>
        ) : rooms.length === 0 ? (
          <div className="text-center py-20 text-brand-muted">Belum ada kamar. Tambah kamar pertama!</div>
        ) : (
          <div className="overflow-x-auto">
            <table className="w-full text-sm">
              <thead>
                <tr className="border-b border-gray-200">
                  {["Gambar", "Nama", "Tipe", "Harga/Bulan", "Status", "Fasilitas", "Aksi"].map((h) => (
                    <th key={h} className="text-left px-5 py-3.5 text-xs font-semibold text-brand-muted uppercase tracking-wide whitespace-nowrap">{h}</th>
                  ))}
                </tr>
              </thead>
              <tbody className="divide-y divide-gray-100">
                {rooms.map((room) => {
                  const imgs = parseImages(room);
                  const thumb = imgs[0] ? resolveMediaUrl(imgs[0]) : null;
                  return (
                    <tr key={room.id} className="hover:bg-gray-50 transition-colors">
                      <td className="px-5 py-3">
                        <button onClick={() => setGalleryRoom(room)} className="relative w-14 h-10 rounded-lg overflow-hidden bg-gray-50 block border border-gray-300 hover:border-brand-black transition-colors">
                          {thumb ? (
                            <Image src={thumb} alt={room.name} fill className="object-cover" sizes="56px" unoptimized />
                          ) : (
                            <span className="flex items-center justify-center h-full text-gray-400 text-xs">No img</span>
                          )}
                          {imgs.length > 1 && (
                            <span className="absolute bottom-0.5 right-0.5 bg-black/50 text-brand-black text-[10px] rounded px-1">+{imgs.length - 1}</span>
                          )}
                        </button>
                      </td>
                      <td className="px-5 py-3 font-medium text-brand-black">{room.name}</td>
                      <td className="px-5 py-3 text-brand-muted">{room.room_type ?? "—"}</td>
                      <td className="px-5 py-3 text-brand-black font-medium whitespace-nowrap">{formatRupiah(room.price_per_month)}</td>
                      <td className="px-5 py-3">
                        <span className={`inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full text-xs font-medium ${room.is_available ? "bg-brand-green/10 text-brand-green border border-brand-green/20" : "bg-gray-200 text-brand-muted border border-slate-600/50"}`}>
                          <span className={`w-1.5 h-1.5 rounded-full ${room.is_available ? "bg-brand-green" : "bg-slate-500"}`} />
                          {room.is_available ? "Tersedia" : "Tidak tersedia"}
                        </span>
                      </td>
                      <td className="px-5 py-3 text-brand-muted max-w-xs truncate">{room.facilities ?? "—"}</td>
                      <td className="px-5 py-3">
                        <div className="flex items-center gap-2">
                          <button
                            onClick={() => { setEditRoom(room); setShowForm(true); }}
                            className="px-3 py-1.5 bg-gray-50 hover:bg-gray-200 text-brand-black rounded-lg text-xs font-medium transition-colors"
                          >
                            Edit
                          </button>
                          <button
                            onClick={() => setConfirmDelete(room)}
                            className="px-3 py-1.5 bg-red-50 hover:bg-red-600/20 text-red-600 rounded-lg text-xs font-medium transition-colors border border-red-200"
                          >
                            Hapus
                          </button>
                        </div>
                      </td>
                    </tr>
                  );
                })}
              </tbody>
            </table>
          </div>
        )}
      </div>

      {/* Modals */}
      {showForm && (
        <RoomFormDialog
          initial={editRoom}
          onSave={handleSave}
          onClose={() => { setShowForm(false); setEditRoom(undefined); }}
        />
      )}

      {galleryRoom && (
        <ImageGalleryDialog
          room={galleryRoom}
          onDelete={(url) => handleDeleteImage(galleryRoom, url)}
          onClose={() => setGalleryRoom(undefined)}
        />
      )}

      {confirmDelete && (
        <div className="fixed inset-0 bg-black/50 z-50 flex items-center justify-center p-4">
          <div className="bg-brand-surface border border-gray-200 rounded-2xl p-6 max-w-sm w-full shadow-2xl">
            <h3 className="text-brand-black font-semibold mb-2">Hapus Kamar?</h3>
            <p className="text-brand-muted text-sm mb-6">Kamar <span className="text-brand-black font-medium">"{confirmDelete.name}"</span> akan dinonaktifkan (soft delete). Data tidak hilang permanen.</p>
            <div className="flex gap-3">
              <button onClick={() => setConfirmDelete(null)} className="flex-1 py-2.5 bg-gray-50 hover:bg-gray-200 text-brand-black rounded-xl text-sm">Batal</button>
              <button onClick={() => handleDelete(confirmDelete)} className="flex-1 py-2.5 bg-red-600 hover:bg-red-700 text-brand-black rounded-xl text-sm font-medium">Ya, Hapus</button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
