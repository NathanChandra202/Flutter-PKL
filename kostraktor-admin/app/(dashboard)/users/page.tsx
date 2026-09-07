"use client";

import { useEffect, useState } from "react";
import type { AdminUser } from "@/lib/api";
import { formatDate } from "@/lib/utils";

// ─── Constants ────────────────────────────────────────────────────────────────
const ROLES = ["Customer", "Admin", "SuperAdmin"] as const;

const ROLE_STYLE: Record<string, string> = {
  Customer:   "bg-gray-100 text-gray-700 border-gray-200",
  Admin:      "bg-brand-gold-light text-brand-black border-brand-gold",
  SuperAdmin: "bg-purple-50 text-purple-700 border-purple-200",
};

const STATUS_STYLE: Record<string, string> = {
  true:  "bg-emerald-50 text-emerald-700 border-emerald-200",
  false: "bg-red-50 text-red-500 border-red-200",
};

// ─── Page ─────────────────────────────────────────────────────────────────────
export default function UsersPage() {
  const [users, setUsers]       = useState<AdminUser[]>([]);
  const [loading, setLoading]   = useState(true);
  const [search, setSearch]     = useState("");
  const [roleFilter, setRoleFilter] = useState<string>("ALL");
  const [toast, setToast]       = useState<{ msg: string; ok: boolean } | null>(null);
  const [saving, setSaving]     = useState<number | null>(null); // userId being saved

  function showToast(msg: string, ok = true) {
    setToast({ msg, ok });
    setTimeout(() => setToast(null), 3500);
  }

  async function loadUsers() {
    setLoading(true);
    try {
      const res = await fetch("/api/proxy?path=%2Fusers%2F");
      if (res.ok) setUsers(await res.json());
      else showToast("Gagal memuat data user", false);
    } finally {
      setLoading(false);
    }
  }

  useEffect(() => { loadUsers(); }, []);

  // ── Filtered list ──
  const filtered = users.filter((u) => {
    const matchRole   = roleFilter === "ALL" || u.role === roleFilter;
    const q           = search.toLowerCase();
    const matchSearch = !q || u.email.toLowerCase().includes(q) || (u.nama_lengkap ?? "").toLowerCase().includes(q);
    return matchRole && matchSearch;
  });

  // ── Actions ──
  async function handleRoleChange(userId: number, roleName: string) {
    setSaving(userId);
    try {
      const res = await fetch(
        `/api/proxy?path=${encodeURIComponent(`/users/${userId}/role`)}`,
        {
          method: "PUT",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify({ role_name: roleName }),
        }
      );
      if (!res.ok) throw new Error((await res.json()).detail ?? "Gagal");
      showToast(`Role berhasil diubah ke ${roleName}`);
      await loadUsers();
    } catch (e: unknown) {
      showToast(e instanceof Error ? e.message : "Error", false);
    } finally {
      setSaving(null);
    }
  }

  async function handleToggleActive(userId: number, currentActive: boolean) {
    setSaving(userId);
    try {
      const res = await fetch(
        `/api/proxy?path=${encodeURIComponent(`/users/${userId}/toggle-active`)}`,
        { method: "PUT" }
      );
      if (!res.ok) throw new Error((await res.json()).detail ?? "Gagal");
      showToast(`Akun berhasil ${currentActive ? "dinonaktifkan" : "diaktifkan"}`);
      await loadUsers();
    } catch (e: unknown) {
      showToast(e instanceof Error ? e.message : "Error", false);
    } finally {
      setSaving(null);
    }
  }

  // ── Counts ──
  const counts = {
    ALL:        users.length,
    Customer:   users.filter(u => u.role === "Customer").length,
    Admin:      users.filter(u => u.role === "Admin").length,
    SuperAdmin: users.filter(u => u.role === "SuperAdmin").length,
  };

  return (
    <div className="space-y-6">
      {/* Toast */}
      {toast && (
        <div className={`fixed top-6 right-6 z-50 px-5 py-3 rounded-xl shadow-lg text-sm font-medium transition-all ${toast.ok ? "bg-emerald-500 text-white" : "bg-red-600 text-white"}`}>
          {toast.msg}
        </div>
      )}

      {/* Header */}
      <div className="flex items-start justify-between flex-wrap gap-3">
        <div>
          <h1 className="text-xl font-bold text-brand-black">Kelola User</h1>
          <p className="text-brand-muted text-sm mt-0.5">{users.length} user terdaftar di sistem</p>
        </div>
        <div className="flex items-center gap-2 px-3 py-1.5 rounded-xl bg-purple-50 border border-purple-200">
          <span className="w-2 h-2 rounded-full bg-purple-500 animate-pulse" />
          <span className="text-xs font-semibold text-purple-700">SuperAdmin Only</span>
        </div>
      </div>

      {/* Filters row */}
      <div className="flex flex-wrap items-center gap-3">
        {/* Search */}
        <div className="relative flex-1 min-w-48">
          <svg className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-gray-400" fill="none" viewBox="0 0 24 24" strokeWidth={2} stroke="currentColor">
            <path strokeLinecap="round" strokeLinejoin="round" d="m21 21-4.35-4.35M17 11A6 6 0 1 1 5 11a6 6 0 0 1 12 0Z" />
          </svg>
          <input
            type="text"
            placeholder="Cari nama atau email..."
            value={search}
            onChange={(e) => setSearch(e.target.value)}
            className="w-full pl-9 pr-4 py-2 text-sm bg-white border border-gray-200 rounded-xl focus:outline-none focus:ring-2 focus:ring-brand-gold/40 focus:border-brand-gold transition-colors"
          />
        </div>

        {/* Role filter tabs */}
        <div className="flex items-center gap-1 bg-gray-100 p-1 rounded-xl">
          {(["ALL", "Customer", "Admin", "SuperAdmin"] as const).map((r) => (
            <button
              key={r}
              onClick={() => setRoleFilter(r)}
              className={`px-3 py-1.5 rounded-lg text-xs font-semibold transition-colors ${
                roleFilter === r
                  ? "bg-white text-brand-black shadow-sm"
                  : "text-brand-muted hover:text-brand-black"
              }`}
            >
              {r === "ALL" ? "Semua" : r}
              <span className={`ml-1.5 px-1.5 py-0.5 rounded-full text-[10px] font-bold ${
                roleFilter === r ? "bg-brand-black text-white" : "bg-gray-300 text-gray-600"
              }`}>
                {counts[r]}
              </span>
            </button>
          ))}
        </div>
      </div>

      {/* Table */}
      <div className="bg-brand-surface border border-gray-200 rounded-2xl overflow-hidden">
        {loading ? (
          <div className="flex items-center justify-center py-20 text-brand-muted text-sm">Memuat data user...</div>
        ) : filtered.length === 0 ? (
          <div className="text-center py-20">
            <p className="text-4xl mb-3">👥</p>
            <p className="text-brand-black font-medium">Tidak ada user ditemukan</p>
            <p className="text-brand-muted text-sm mt-1">Coba ubah filter atau kata kunci pencarian</p>
          </div>
        ) : (
          <div className="overflow-x-auto">
            <table className="w-full text-sm">
              <thead>
                <tr className="border-b border-gray-200">
                  {["ID", "Nama", "Email", "No HP", "Role", "Status", "Verifikasi", "Kamar", "Tgl Daftar", "Aksi"].map((h) => (
                    <th key={h} className="text-left px-4 py-3.5 text-xs font-semibold text-brand-muted uppercase tracking-wide whitespace-nowrap">
                      {h}
                    </th>
                  ))}
                </tr>
              </thead>
              <tbody className="divide-y divide-gray-100">
                {filtered.map((u) => {
                  const isSaving = saving === u.id;
                  return (
                    <tr key={u.id} className={`hover:bg-gray-50 transition-colors ${!u.is_active ? "opacity-60" : ""}`}>
                      <td className="px-4 py-4 text-brand-muted font-mono text-xs">#{u.id}</td>
                      <td className="px-4 py-4 text-brand-black font-medium whitespace-nowrap">
                        {u.nama_lengkap || <span className="italic text-gray-400">—</span>}
                      </td>
                      <td className="px-4 py-4 text-brand-muted text-xs">{u.email}</td>
                      <td className="px-4 py-4 text-brand-muted text-xs whitespace-nowrap">
                        {u.no_hp || <span className="italic text-gray-400">—</span>}
                      </td>

                      {/* Role — dropdown */}
                      <td className="px-4 py-4">
                        <select
                          value={u.role ?? "Customer"}
                          disabled={isSaving}
                          onChange={(e) => handleRoleChange(u.id, e.target.value)}
                          className={`px-2.5 py-1 rounded-lg text-xs font-semibold border cursor-pointer transition-all focus:outline-none focus:ring-2 focus:ring-brand-gold/40 disabled:cursor-not-allowed
                            ${ROLE_STYLE[u.role ?? "Customer"]}`}
                        >
                          {ROLES.map((r) => (
                            <option key={r} value={r}>{r}</option>
                          ))}
                        </select>
                      </td>

                      {/* Status */}
                      <td className="px-4 py-4">
                        <span className={`inline-flex items-center px-2.5 py-1 rounded-full text-xs font-medium border ${STATUS_STYLE[String(u.is_active)]}`}>
                          {u.is_active ? "Aktif" : "Nonaktif"}
                        </span>
                      </td>

                      {/* Face verified */}
                      <td className="px-4 py-4 text-center">
                        {u.is_face_verified
                          ? <span className="text-emerald-500 font-bold text-base" title="Terverifikasi">✓</span>
                          : <span className="text-gray-300 text-base" title="Belum diverifikasi">—</span>
                        }
                      </td>

                      {/* Current room */}
                      <td className="px-4 py-4 text-xs text-brand-muted">
                        {u.current_room_id
                          ? <span className="px-2 py-0.5 rounded-md bg-blue-50 text-blue-600 border border-blue-100 font-medium">Kamar #{u.current_room_id}</span>
                          : <span className="italic text-gray-400">—</span>
                        }
                      </td>

                      {/* Created at */}
                      <td className="px-4 py-4 text-brand-muted whitespace-nowrap text-xs">
                        {formatDate(u.created_at)}
                      </td>

                      {/* Aksi */}
                      <td className="px-4 py-4">
                        <button
                          disabled={isSaving}
                          onClick={() => handleToggleActive(u.id, u.is_active)}
                          className={`px-2.5 py-1.5 rounded-lg text-xs font-medium border transition-colors whitespace-nowrap disabled:opacity-50 disabled:cursor-not-allowed ${
                            u.is_active
                              ? "bg-red-50 hover:bg-red-100 text-red-600 border-red-200"
                              : "bg-emerald-50 hover:bg-emerald-100 text-emerald-700 border-emerald-200"
                          }`}
                        >
                          {isSaving ? "..." : u.is_active ? "Nonaktifkan" : "Aktifkan"}
                        </button>
                      </td>
                    </tr>
                  );
                })}
              </tbody>
            </table>
          </div>
        )}
      </div>
    </div>
  );
}
