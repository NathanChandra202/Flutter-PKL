"use client";

import { useEffect, useState } from "react";
import type { Tool } from "@/lib/api";
import { formatDate } from "@/lib/utils";

const ICON_MAP: Record<string, string> = {
  cleaning_services: "🧹",
  straighten: "📏",
  handyman: "🔨",
  shopping_cart: "🛒",
};

export default function ToolsPage() {
  const [tools, setTools] = useState<Tool[]>([]);
  const [pendingTools, setPendingTools] = useState<Tool[]>([]);
  const [loading, setLoading] = useState(true);
  const [toast, setToast] = useState<{ msg: string; ok: boolean } | null>(null);

  // Form state
  const [newName, setNewName] = useState("");
  const [newIcon, setNewIcon] = useState("handyman");
  const [isSubmitting, setIsSubmitting] = useState(false);

  function showToast(msg: string, ok = true) {
    setToast({ msg, ok });
    setTimeout(() => setToast(null), 3000);
  }

  async function load() {
    setLoading(true);
    try {
      const [res, pendingRes] = await Promise.all([
        fetch("/api/proxy?path=%2Ftools%2F"),
        fetch("/api/proxy?path=%2Ftools%2Fpending")
      ]);
      
      if (res.ok) setTools(await res.json());
      if (pendingRes.ok) setPendingTools(await pendingRes.json());
    } finally {
      setLoading(false);
    }
  }

  useEffect(() => { load(); }, []);

  async function handleAddTool(e: React.FormEvent) {
    e.preventDefault();
    if (!newName.trim()) return;
    
    setIsSubmitting(true);
    try {
      const res = await fetch("/api/proxy?path=%2Ftools%2F", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ name: newName.trim(), icon_name: newIcon }),
      });
      if (res.ok) {
        showToast("Alat berhasil ditambahkan");
        setNewName("");
        setNewIcon("handyman");
        load();
      } else {
        showToast("Gagal menambah alat", false);
      }
    } catch (e) {
      showToast("Terjadi kesalahan jaringan", false);
    } finally {
      setIsSubmitting(false);
    }
  }

  async function handleReview(id: number, status: "APPROVED" | "REJECTED") {
    try {
      const res = await fetch(`/api/proxy?path=%2Ftools%2F${id}%2Freview`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ status }),
      });
      if (res.ok) {
        showToast(`Alat berhasil di-${status.toLowerCase()}`);
        load();
      } else {
        showToast("Gagal memproses review", false);
      }
    } catch (e) {
      showToast("Terjadi kesalahan jaringan", false);
    }
  }

  const available = tools.filter((t) => t.is_available).length;
  const borrowed = tools.filter((t) => !t.is_available).length;

  return (
    <div className="space-y-6">
      {toast && (
        <div className={`fixed top-6 right-6 z-[100] px-5 py-3 rounded-xl shadow-lg text-sm font-medium ${toast.ok ? "bg-emerald-500 text-brand-black" : "bg-red-600 text-brand-black"}`}>
          {toast.msg}
        </div>
      )}

      <div>
        <h1 className="text-xl font-bold text-brand-black">Kelola Alat Bersama</h1>
        <p className="text-brand-muted text-sm mt-0.5">{available} tersedia · {borrowed} sedang dipinjam</p>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        <div className="lg:col-span-2 space-y-6">
          {/* Stats */}
          <div className="grid grid-cols-2 gap-4">
            {[
              { label: "Tersedia", value: available, colorClass: "text-brand-green" },
              { label: "Dipinjam", value: borrowed, colorClass: "text-brand-gold" },
            ].map(({ label, value, colorClass }) => (
              <div key={label} className={`bg-brand-surface border border-gray-200 rounded-2xl p-5`}>
                <p className="text-brand-muted text-sm mb-1">{label}</p>
                <p className={`text-3xl font-bold ${colorClass}`}>{value}</p>
              </div>
            ))}
          </div>

          <h2 className="text-lg font-bold text-brand-black pt-4">Daftar Alat</h2>
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            {loading ? (
              <div className="col-span-2 flex items-center justify-center py-10 text-brand-muted">Memuat data...</div>
            ) : tools.length === 0 ? (
              <div className="col-span-2 text-center py-10 text-brand-muted">Belum ada alat terdaftar.</div>
            ) : (
              tools.map((tool) => (
                <div
                  key={tool.id}
                  className={`bg-brand-surface border rounded-2xl p-4 flex items-start gap-4 transition-colors ${
                    tool.is_available ? "border-gray-200" : "border-gray-200 bg-brand-black/5"
                  }`}
                >
                  <div className={`w-12 h-12 rounded-xl flex items-center justify-center text-2xl shrink-0 ${
                    tool.is_available ? "bg-gray-50" : "bg-brand-black/10"
                  }`}>
                    {ICON_MAP[tool.icon_name] ?? "🔧"}
                  </div>
                  <div className="flex-1 min-w-0">
                    <p className="text-brand-black font-semibold">{tool.name}</p>
                    <div className="mt-2 flex flex-wrap gap-2">
                      <span className={`inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full text-xs font-medium border ${
                        tool.is_available
                          ? "bg-brand-green/10 text-brand-green border-brand-green/20"
                          : "bg-brand-black/10 text-brand-black border-gray-200"
                      }`}>
                        <span className={`w-1.5 h-1.5 rounded-full ${tool.is_available ? "bg-brand-green" : "bg-amber-400"}`} />
                        {tool.is_available ? "Tersedia" : "Dipinjam"}
                      </span>
                    </div>
                    {!tool.is_available && (
                      <div className="mt-2 text-xs text-brand-muted space-y-0.5">
                        <p>👤 <span className="text-brand-black">{tool.borrowed_by_name ?? "—"}</span></p>
                        {tool.borrowed_at && (
                          <p>📅 <span className="text-brand-black">{formatDate(tool.borrowed_at)}</span></p>
                        )}
                      </div>
                    )}
                  </div>
                </div>
              ))
            )}
          </div>
        </div>

        <div className="space-y-6">
          <div className="bg-brand-surface border border-gray-200 rounded-2xl p-5">
            <h2 className="text-lg font-bold text-brand-black mb-4">Tambah Alat Baru</h2>
            <form onSubmit={handleAddTool} className="space-y-4">
              <div>
                <label className="block text-sm font-medium text-brand-black mb-1.5">Nama Alat</label>
                <input
                  type="text"
                  required
                  value={newName}
                  onChange={(e) => setNewName(e.target.value)}
                  className="w-full px-3 py-2 rounded-xl border border-gray-200 focus:outline-none focus:ring-2 focus:ring-brand-black/5"
                  placeholder="Contoh: Bor Listrik"
                />
              </div>
              <div>
                <label className="block text-sm font-medium text-brand-black mb-1.5">Ikon</label>
                <div className="grid grid-cols-4 gap-2">
                  {Object.entries(ICON_MAP).map(([key, emoji]) => (
                    <button
                      key={key}
                      type="button"
                      onClick={() => setNewIcon(key)}
                      className={`h-10 rounded-lg text-lg border transition-colors ${
                        newIcon === key 
                          ? "bg-brand-black text-white border-brand-black" 
                          : "bg-gray-50 border-gray-200 text-brand-black hover:bg-gray-100"
                      }`}
                    >
                      {emoji}
                    </button>
                  ))}
                </div>
              </div>
              <button
                type="submit"
                disabled={isSubmitting}
                className="w-full py-2.5 bg-brand-black text-white font-medium rounded-xl disabled:opacity-50"
              >
                {isSubmitting ? "Menambahkan..." : "Tambah Alat"}
              </button>
            </form>
          </div>

          <div className="bg-brand-surface border border-gray-200 rounded-2xl p-5">
            <div className="flex items-center justify-between mb-4">
              <h2 className="text-lg font-bold text-brand-black">Menunggu Persetujuan</h2>
              {pendingTools.length > 0 && (
                <span className="bg-amber-100 text-amber-700 text-xs font-bold px-2 py-0.5 rounded-full">
                  {pendingTools.length}
                </span>
              )}
            </div>
            
            {pendingTools.length === 0 ? (
              <p className="text-brand-muted text-sm text-center py-4">Tidak ada pengajuan alat baru.</p>
            ) : (
              <div className="space-y-3">
                {pendingTools.map((tool) => (
                  <div key={tool.id} className="border border-gray-100 rounded-xl p-3 bg-gray-50">
                    <div className="flex items-center gap-3 mb-3">
                      <div className="w-10 h-10 bg-white rounded-lg border border-gray-100 flex items-center justify-center text-xl shrink-0">
                        {ICON_MAP[tool.icon_name] ?? "🔧"}
                      </div>
                      <div>
                        <p className="font-semibold text-brand-black text-sm">{tool.name}</p>
                        <p className="text-xs text-brand-muted">Pengajuan dari penghuni</p>
                      </div>
                    </div>
                    <div className="flex gap-2">
                      <button 
                        onClick={() => handleReview(tool.id, "APPROVED")}
                        className="flex-1 py-1.5 bg-brand-green/10 text-brand-green text-sm font-medium rounded-lg hover:bg-brand-green/20"
                      >
                        Setujui
                      </button>
                      <button 
                        onClick={() => handleReview(tool.id, "REJECTED")}
                        className="flex-1 py-1.5 bg-red-50 text-red-600 text-sm font-medium rounded-lg hover:bg-red-100"
                      >
                        Tolak
                      </button>
                    </div>
                  </div>
                ))}
              </div>
            )}
          </div>
        </div>
      </div>
    </div>
  );
}
