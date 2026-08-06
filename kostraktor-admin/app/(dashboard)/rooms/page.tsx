"use client";

import { useEffect, useState, useRef } from "react";
import Image from "next/image";
import type { Room } from "@/lib/api";
import { formatRupiah, resolveMediaUrl } from "@/lib/utils";
import {
  DndContext,
  closestCenter,
  PointerSensor,
  useSensor,
  useSensors,
  DragEndEvent,
  DragOverlay,
  DragStartEvent,
} from "@dnd-kit/core";
import {
  arrayMove,
  SortableContext,
  rectSortingStrategy,
  useSortable,
} from "@dnd-kit/sortable";
import { CSS } from "@dnd-kit/utilities";

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
// ─── Image Gallery Dialog (with drag-and-drop reorder) ──────────────────────────

/** Single sortable thumbnail inside the gallery */
function SortableImage({
  url,
  index,
  onDelete,
  isFirst,
}: {
  url: string;
  index: number;
  onDelete: (url: string) => void;
  isFirst: boolean;
}) {
  const { attributes, listeners, setNodeRef, transform, transition, isDragging } =
    useSortable({ id: url });

  const style: React.CSSProperties = {
    transform: CSS.Transform.toString(transform),
    transition,
    opacity: isDragging ? 0.4 : 1,
    zIndex: isDragging ? 50 : "auto",
  };

  return (
    <div
      ref={setNodeRef}
      style={style}
      className="relative group aspect-video bg-gray-50 rounded-xl overflow-hidden border-2 border-transparent hover:border-brand-black transition-colors"
    >
      {/* Drag handle — full card is draggable */}
      <div
        {...attributes}
        {...listeners}
        className="absolute inset-0 z-10 cursor-grab active:cursor-grabbing"
        title="Seret untuk mengubah urutan"
      />

      <Image
        src={resolveMediaUrl(url)}
        alt={`Room ${index + 1}`}
        fill
        className="object-cover pointer-events-none"
        sizes="200px"
        unoptimized
      />

      {/* Foto utama badge */}
      {isFirst && (
        <div className="absolute top-1.5 left-1.5 z-20 bg-brand-black text-white text-[10px] font-semibold px-1.5 py-0.5 rounded-md pointer-events-none">
          Utama
        </div>
      )}

      {/* Delete button — sits above drag handle */}
      <button
        onClick={(e) => { e.stopPropagation(); onDelete(url); }}
        className="absolute top-1.5 right-1.5 z-20 w-7 h-7 bg-red-600 text-white rounded-lg opacity-0 group-hover:opacity-100 transition-opacity flex items-center justify-center text-xs shadow"
        title="Hapus foto"
      >
        🗑
      </button>

      {/* Drag indicator */}
      <div className="absolute bottom-1.5 left-1/2 -translate-x-1/2 z-20 opacity-0 group-hover:opacity-100 transition-opacity pointer-events-none">
        <div className="bg-black/50 text-white text-[9px] px-1.5 py-0.5 rounded-full">⠿ seret</div>
      </div>
    </div>
  );
}

function ImageGalleryDialog({
  room,
  onDelete,
  onReorder,
  onClose,
}: {
  room: Room;
  onDelete: (url: string) => Promise<void>;
  onReorder: (newImageUrl: string, newAdditionalImages: string) => Promise<void>;
  onClose: () => void;
}) {
  const [images, setImages] = useState<string[]>(() => parseImages(room));
  const [activeUrl, setActiveUrl] = useState<string | null>(null);
  const [saving, setSaving] = useState(false);
  const [saveMsg, setSaveMsg] = useState<string | null>(null);

  // Keep in sync when room prop changes (e.g. after external delete)
  useEffect(() => {
    setImages(parseImages(room));
  }, [room]);

  const sensors = useSensors(
    useSensor(PointerSensor, { activationConstraint: { distance: 8 } })
  );

  function handleDragStart(event: DragStartEvent) {
    setActiveUrl(String(event.active.id));
  }

  async function handleDragEnd(event: DragEndEvent) {
    const { active, over } = event;
    setActiveUrl(null);
    if (!over || active.id === over.id) return;

    const oldIdx = images.indexOf(String(active.id));
    const newIdx = images.indexOf(String(over.id));
    const reordered = arrayMove(images, oldIdx, newIdx);
    setImages(reordered);

    // Auto-save: first image → image_url, rest → additional_images
    setSaving(true);
    setSaveMsg(null);
    try {
      const [first, ...rest] = reordered;
      await onReorder(first ?? "", rest.join(","));
      setSaveMsg("✓ Urutan tersimpan");
      setTimeout(() => setSaveMsg(null), 2000);
    } catch {
      setSaveMsg("⚠ Gagal menyimpan urutan");
    } finally {
      setSaving(false);
    }
  }

  async function handleDelete(url: string) {
    await onDelete(url);
    setImages((prev) => prev.filter((u) => u !== url));
  }

  return (
    <div className="fixed inset-0 bg-black/50 backdrop-blur-sm z-50 flex items-center justify-center p-4">
      <div className="bg-brand-surface border border-gray-200 rounded-2xl w-full max-w-2xl shadow-2xl overflow-hidden">
        <div className="flex items-center justify-between px-6 py-4 border-b border-gray-200">
          <div>
            <h2 className="text-brand-black font-semibold">Gambar — {room.name}</h2>
            {images.length > 1 && (
              <p className="text-brand-muted text-xs mt-0.5">Seret foto untuk mengubah urutan. Foto pertama jadi foto utama.</p>
            )}
          </div>
          <button onClick={onClose} className="text-brand-muted hover:text-brand-black">✕</button>
        </div>

        <div className="p-6">
          {images.length === 0 ? (
            <p className="text-brand-muted text-center py-8">Belum ada gambar</p>
          ) : (
            <DndContext
              sensors={sensors}
              collisionDetection={closestCenter}
              onDragStart={handleDragStart}
              onDragEnd={handleDragEnd}
            >
              <SortableContext items={images} strategy={rectSortingStrategy}>
                <div className="grid grid-cols-3 gap-3">
                  {images.map((url, i) => (
                    <SortableImage
                      key={url}
                      url={url}
                      index={i}
                      isFirst={i === 0}
                      onDelete={handleDelete}
                    />
                  ))}
                </div>
              </SortableContext>

              {/* Drag overlay — shows a scaled-up preview while dragging */}
              <DragOverlay>
                {activeUrl && (
                  <div className="relative aspect-video w-40 rounded-xl overflow-hidden shadow-2xl ring-2 ring-brand-black scale-105">
                    <Image
                      src={resolveMediaUrl(activeUrl)}
                      alt="dragging"
                      fill
                      className="object-cover"
                      sizes="160px"
                      unoptimized
                    />
                  </div>
                )}
              </DragOverlay>
            </DndContext>
          )}

          <div className="mt-4 flex items-center justify-between">
            <span className={`text-xs transition-opacity ${saveMsg ? "opacity-100" : "opacity-0"} ${saveMsg?.startsWith("⚠") ? "text-red-500" : "text-emerald-600"}`}>
              {saving ? "Menyimpan..." : saveMsg ?? ""}
            </span>
            <button onClick={onClose} className="px-4 py-2 bg-gray-50 hover:bg-gray-200 text-brand-black rounded-xl text-sm">
              Tutup
            </button>
          </div>
        </div>
      </div>
    </div>
  );
}
// ─── Room Detail Dialog ──────────────────────────────────────────────────────────

interface TenantInfo {
  user_id: number | null;
  name: string;
  email: string;
  start_date: string | null;
  booking_id: number;
}

function RoomDetailDialog({ room, onClose }: { room: Room; onClose: () => void }) {
  const images = parseImages(room);
  const [tenant, setTenant] = useState<TenantInfo | null | undefined>(undefined);

  useEffect(() => {
    if (!room.is_available) {
      fetch(`/api/proxy?path=${encodeURIComponent(`/rooms/${room.id}/tenant`)}`)
        .then((r) => r.json())
        .then((data) => setTenant(data.tenant ?? null))
        .catch(() => setTenant(null));
    } else {
      setTenant(null);
    }
  }, [room]);

  const facilities = room.facilities ? room.facilities.split(",").map((f) => f.trim()).filter(Boolean) : [];

  return (
    <div className="fixed inset-0 bg-black/50 backdrop-blur-sm z-50 flex items-center justify-center p-4">
      <div className="bg-brand-surface border border-gray-200 rounded-2xl w-full max-w-2xl shadow-2xl overflow-hidden max-h-[90vh] flex flex-col">
        <div className="flex items-center justify-between px-6 py-4 border-b border-gray-200 shrink-0">
          <h2 className="text-brand-black font-semibold">Detail Kamar</h2>
          <button onClick={onClose} className="text-brand-muted hover:text-brand-black text-lg">✕</button>
        </div>

        <div className="overflow-y-auto p-6 space-y-6">
          {images.length > 0 && (
            <div className="grid grid-cols-3 gap-2">
              {images.map((url, i) => (
                <div key={i} className="relative aspect-video rounded-xl overflow-hidden bg-gray-100">
                  <Image src={resolveMediaUrl(url)} alt={`img ${i + 1}`} fill className="object-cover" sizes="200px" unoptimized />
                </div>
              ))}
            </div>
          )}

          <div className="space-y-3">
            <div className="flex items-start justify-between gap-4">
              <div>
                <h3 className="text-xl font-bold text-brand-black">{room.name}</h3>
                {room.room_type && <p className="text-brand-muted text-sm mt-0.5">{room.room_type}</p>}
              </div>
              <div className="text-right shrink-0">
                <p className="text-brand-black font-bold text-lg">{formatRupiah(room.price_per_month)}</p>
                <p className="text-brand-muted text-xs">per bulan</p>
              </div>
            </div>
            <span className={`inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full text-xs font-medium ${room.is_available ? "bg-emerald-50 text-emerald-700 border border-emerald-200" : "bg-gray-100 text-gray-500 border border-gray-300"}`}>
              <span className={`w-1.5 h-1.5 rounded-full ${room.is_available ? "bg-emerald-500" : "bg-gray-400"}`} />
              {room.is_available ? "Tersedia" : "Terisi"}
            </span>

            {room.description && (
              <p className="text-brand-black text-sm leading-relaxed">{room.description}</p>
            )}

            {facilities.length > 0 && (
              <div>
                <p className="text-xs font-semibold text-brand-muted uppercase tracking-wide mb-2">Fasilitas</p>
                <div className="flex flex-wrap gap-2">
                  {facilities.map((f) => (
                    <span key={f} className="px-3 py-1 bg-gray-100 text-brand-black text-xs rounded-full border border-gray-200">{f}</span>
                  ))}
                </div>
              </div>
            )}
          </div>

          {!room.is_available && (
            <div className="border border-gray-200 rounded-xl p-4 bg-amber-50/50">
              <p className="text-xs font-semibold text-brand-muted uppercase tracking-wide mb-3">👤 Info Penyewa Aktif</p>
              {tenant === undefined ? (
                <p className="text-brand-muted text-sm">Memuat info penyewa...</p>
              ) : tenant === null ? (
                <p className="text-brand-muted text-sm italic">Data penyewa tidak ditemukan</p>
              ) : (
                <div className="space-y-1.5">
                  <div className="flex items-center gap-2">
                    <span className="text-brand-muted text-xs w-24">Nama</span>
                    <span className="text-brand-black text-sm font-medium">{tenant.name}</span>
                  </div>
                  <div className="flex items-center gap-2">
                    <span className="text-brand-muted text-xs w-24">Email</span>
                    <span className="text-brand-black text-sm">{tenant.email}</span>
                  </div>
                  {tenant.start_date && (
                    <div className="flex items-center gap-2">
                      <span className="text-brand-muted text-xs w-24">Mulai Sewa</span>
                      <span className="text-brand-black text-sm">
                        {new Date(tenant.start_date).toLocaleDateString("id-ID", { day: "numeric", month: "long", year: "numeric" })}
                      </span>
                    </div>
                  )}
                </div>
              )}
            </div>
          )}
        </div>

        <div className="px-6 py-4 border-t border-gray-200 text-right shrink-0">
          <button onClick={onClose} className="px-5 py-2 bg-gray-100 hover:bg-gray-200 text-brand-black rounded-xl text-sm font-medium transition-colors">
            Tutup
          </button>
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
  const [detailRoom, setDetailRoom] = useState<Room | undefined>();
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
      await apiWithToken<Room>(`/rooms/${editRoom.id}`, {
        method: "PUT",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(data),
      });
      if (files && files.length > 0) {
        const form = new FormData();
        Array.from(files).forEach((f) => form.append("files", f));
        await apiWithToken(`/rooms/${editRoom.id}/upload-images`, { method: "POST", body: form });
      }
      showToast("Kamar berhasil diupdate!");
    } else {
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
      setGalleryRoom((prev) => prev ? rooms.find((r) => r.id === prev.id) : undefined);
    } catch (e: unknown) {
      showToast(e instanceof Error ? e.message : "Gagal hapus gambar", false);
    }
  }

  async function handleReorderImages(room: Room, newImageUrl: string, newAdditionalImages: string) {
    await apiWithToken(`/rooms/${room.id}`, {
      method: "PUT",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        image_url: newImageUrl || null,
        additional_images: newAdditionalImages || null,
      }),
    });
    // Refresh rooms list so thumbnail in table updates too
    await loadRooms();
    setGalleryRoom((prev) => prev ? rooms.find((r) => r.id === prev.id) : undefined);
  }

  return (
    <div className="space-y-6">
      {toast && (
        <div className={`fixed top-6 right-6 z-100 px-5 py-3 rounded-xl shadow-lg text-sm font-medium transition-all ${toast.ok ? "bg-emerald-500 text-white" : "bg-red-600 text-white"}`}>
          {toast.msg}
        </div>
      )}

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
                            <span className="absolute bottom-0.5 right-0.5 bg-black/50 text-white text-[10px] rounded px-1">+{imgs.length - 1}</span>
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
                            id={`detail-room-${room.id}`}
                            onClick={() => setDetailRoom(room)}
                            title="Lihat detail"
                            className="px-3 py-1.5 bg-blue-50 hover:bg-blue-100 text-blue-700 rounded-lg text-xs font-medium transition-colors border border-blue-200"
                          >
                            👁 Detail
                          </button>
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
          onReorder={(newImageUrl, newAdditionalImages) =>
            handleReorderImages(galleryRoom, newImageUrl, newAdditionalImages)
          }
          onClose={() => setGalleryRoom(undefined)}
        />
      )}

      {detailRoom && (
        <RoomDetailDialog
          room={detailRoom}
          onClose={() => setDetailRoom(undefined)}
        />
      )}

      {confirmDelete && (
        <div className="fixed inset-0 bg-black/50 z-50 flex items-center justify-center p-4">
          <div className="bg-brand-surface border border-gray-200 rounded-2xl p-6 max-w-sm w-full shadow-2xl">
            <h3 className="text-brand-black font-semibold mb-2">Hapus Kamar?</h3>
            <p className="text-brand-muted text-sm mb-6">Kamar <span className="text-brand-black font-medium">"{confirmDelete.name}"</span> akan dinonaktifkan (soft delete). Data tidak hilang permanen.</p>
            <div className="flex gap-3">
              <button onClick={() => setConfirmDelete(null)} className="flex-1 py-2.5 bg-gray-50 hover:bg-gray-200 text-brand-black rounded-xl text-sm">Batal</button>
              <button onClick={() => handleDelete(confirmDelete)} className="flex-1 py-2.5 bg-red-600 hover:bg-red-700 text-white rounded-xl text-sm font-medium">Ya, Hapus</button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}