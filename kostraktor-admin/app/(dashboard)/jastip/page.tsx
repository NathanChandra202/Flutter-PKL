"use client";

import { useEffect, useState } from "react";
import type { Jastip } from "@/lib/api";
import { formatDate } from "@/lib/utils";

export default function JastipPage() {
  const [items, setItems] = useState<Jastip[]>([]);
  const [loading, setLoading] = useState(true);
  const [confirmDelete, setConfirmDelete] = useState<Jastip | null>(null);
  const [toast, setToast] = useState<{ msg: string; ok: boolean } | null>(null);

  function showToast(msg: string, ok = true) {
    setToast({ msg, ok });
    setTimeout(() => setToast(null), 3000);
  }

  async function load() {
    setLoading(true);
    try {
      const res = await fetch("/api/proxy?path=%2Fjastip%2F");
      if (res.ok) setItems(await res.json());
    } finally {
      setLoading(false);
    }
  }

  useEffect(() => { load(); }, []);

  async function handleDelete(id: number) {
    try {
      const res = await fetch(`/api/proxy?path=${encodeURIComponent(`/jastip/${id}`)}`, { method: "DELETE" });
      if (!res.ok) throw new Error("Gagal menghapus");
      showToast("Listing jastip berhasil dihapus");
      setConfirmDelete(null);
      await load();
    } catch (e: unknown) {
      showToast(e instanceof Error ? e.message : "Error", false);
    }
  }

  return (
    <div className="space-y-6">
      {toast && (
        <div className={`fixed top-6 right-6 z-[100] px-5 py-3 rounded-xl shadow-lg text-sm font-medium ${toast.ok ? "bg-emerald-500 text-brand-black" : "bg-red-600 text-brand-black"}`}>
          {toast.msg}
        </div>
      )}

      <div>
        <h1 className="text-xl font-bold text-brand-black">Kelola Jastip</h1>
        <p className="text-brand-muted text-sm mt-0.5">{items.length} listing aktif</p>
      </div>

      <div className="bg-brand-surface border border-gray-200 rounded-2xl overflow-hidden">
        {loading ? (
          <div className="flex items-center justify-center py-20 text-brand-muted">Memuat data...</div>
        ) : items.length === 0 ? (
          <div className="text-center py-20 text-brand-muted">Belum ada listing jastip</div>
        ) : (
          <div className="overflow-x-auto">
            <table className="w-full text-sm">
              <thead>
                <tr className="border-b border-gray-200">
                  {["Judul", "Deskripsi", "Harga", "Pemilik", "WA", "Dibuat", "Aksi"].map((h) => (
                    <th key={h} className="text-left px-5 py-3.5 text-xs font-semibold text-brand-muted uppercase tracking-wide whitespace-nowrap">{h}</th>
                  ))}
                </tr>
              </thead>
              <tbody className="divide-y divide-gray-100">
                {items.map((item) => (
                  <tr key={item.id} className="hover:bg-gray-50 transition-colors">
                    <td className="px-5 py-4 font-medium text-brand-black max-w-[180px] truncate">{item.title}</td>
                    <td className="px-5 py-4 text-brand-muted max-w-xs truncate">{item.description}</td>
                    <td className="px-5 py-4 text-brand-black font-medium whitespace-nowrap">{item.price}</td>
                    <td className="px-5 py-4 text-brand-black">{item.author_name ?? "—"}</td>
                    <td className="px-5 py-4">
                      <a
                        href={`https://wa.me/${item.wa_number}`}
                        target="_blank"
                        rel="noopener noreferrer"
                        className="text-green-400 hover:text-green-300 text-xs font-medium"
                      >
                        {item.wa_number}
                      </a>
                    </td>
                    <td className="px-5 py-4 text-brand-muted whitespace-nowrap">{formatDate(item.created_at)}</td>
                    <td className="px-5 py-4">
                      <button
                        onClick={() => setConfirmDelete(item)}
                        className="px-3 py-1.5 bg-red-50 hover:bg-red-600/20 text-red-600 rounded-lg text-xs font-medium border border-red-200 transition-colors"
                      >
                        Hapus
                      </button>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
      </div>

      {confirmDelete && (
        <div className="fixed inset-0 bg-black/50 z-50 flex items-center justify-center p-4">
          <div className="bg-brand-surface border border-gray-200 rounded-2xl p-6 max-w-sm w-full shadow-2xl">
            <h3 className="text-brand-black font-semibold mb-2">Hapus Listing?</h3>
            <p className="text-brand-muted text-sm mb-6">Listing <span className="text-brand-black font-medium">"{confirmDelete.title}"</span> akan dihapus secara permanen.</p>
            <div className="flex gap-3">
              <button onClick={() => setConfirmDelete(null)} className="flex-1 py-2.5 bg-gray-50 hover:bg-gray-200 text-brand-black rounded-xl text-sm">Batal</button>
              <button onClick={() => handleDelete(confirmDelete.id)} className="flex-1 py-2.5 bg-red-600 hover:bg-red-700 text-brand-black rounded-xl text-sm font-medium">Hapus</button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
