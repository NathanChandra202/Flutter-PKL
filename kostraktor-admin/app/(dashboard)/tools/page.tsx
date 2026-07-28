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
  const [loading, setLoading] = useState(true);
  const [toast, setToast] = useState<{ msg: string; ok: boolean } | null>(null);

  function showToast(msg: string, ok = true) {
    setToast({ msg, ok });
    setTimeout(() => setToast(null), 3000);
  }

  async function load() {
    setLoading(true);
    try {
      const res = await fetch("/api/proxy?path=%2Ftools%2F");
      if (res.ok) setTools(await res.json());
    } finally {
      setLoading(false);
    }
  }

  useEffect(() => { load(); }, []);

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

      <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
        {loading ? (
          <div className="col-span-2 flex items-center justify-center py-20 text-brand-muted">Memuat data...</div>
        ) : tools.length === 0 ? (
          <div className="col-span-2 text-center py-20 text-brand-muted">Belum ada alat terdaftar. Seed tools via backend.</div>
        ) : (
          tools.map((tool) => (
            <div
              key={tool.id}
              className={`bg-brand-surface border rounded-2xl p-5 flex items-start gap-4 transition-colors ${
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
                    <p>👤 Peminjam: <span className="text-brand-black">{tool.borrowed_by_name ?? "—"}</span></p>
                    {tool.borrowed_at && (
                      <p>📅 Sejak: <span className="text-brand-black">{formatDate(tool.borrowed_at)}</span></p>
                    )}
                  </div>
                )}
              </div>
            </div>
          ))
        )}
      </div>

      <div className="bg-brand-surface border border-gray-200 rounded-xl p-4 text-sm text-brand-muted">
        💡 <span className="text-brand-black">Catatan:</span> Peminjaman dan pengembalian alat dilakukan langsung oleh penghuni dari app Flutter. Dashboard ini hanya menampilkan status real-time.
      </div>
    </div>
  );
}
