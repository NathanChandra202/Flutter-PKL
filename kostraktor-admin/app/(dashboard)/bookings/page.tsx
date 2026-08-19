"use client";

import { useEffect, useState } from "react";
import type { Booking } from "@/lib/api";
import { formatDate } from "@/lib/utils";

const STATUS_STYLE: Record<string, string> = {
  PENDING: "bg-brand-black/10 text-brand-black border-gray-200",
  APPROVED: "bg-brand-green/10 text-brand-green border-brand-green/20",
  REJECTED: "bg-red-50 text-red-600 border-red-200",
};

export default function BookingsPage() {
  const [bookings, setBookings] = useState<Booking[]>([]);
  const [loading, setLoading] = useState(true);
  const [toast, setToast] = useState<{ msg: string; ok: boolean } | null>(null);
  const [filter, setFilter] = useState<string>("PENDING");

  function showToast(msg: string, ok = true) {
    setToast({ msg, ok });
    setTimeout(() => setToast(null), 3000);
  }

  async function loadBookings() {
    setLoading(true);
    try {
      const res = await fetch("/api/proxy?path=%2Fbookings%2Fall");
      if (res.ok) setBookings(await res.json());
    } finally {
      setLoading(false);
    }
  }

  useEffect(() => { loadBookings(); }, []);

  async function updateStatus(bookingId: number, status: "APPROVED" | "REJECTED") {
    try {
      const res = await fetch(`/api/proxy?path=${encodeURIComponent(`/bookings/${bookingId}/status`)}`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ status }),
      });
      if (!res.ok) throw new Error("Gagal update status");
      showToast(`Booking berhasil ${status === "APPROVED" ? "disetujui" : "ditolak"}!`, status === "APPROVED");
      await loadBookings();
    } catch (e: unknown) {
      showToast(e instanceof Error ? e.message : "Error", false);
    }
  }

  const filteredBookings = bookings.filter(b => filter === "ALL" || b.status === filter);

  return (
    <div className="space-y-6">
      {toast && (
        <div className={`fixed top-6 right-6 z-[100] px-5 py-3 rounded-xl shadow-lg text-sm font-medium ${toast.ok ? "bg-emerald-500 text-brand-black" : "bg-red-600 text-brand-black"}`}>
          {toast.msg}
        </div>
      )}

      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
        <div>
          <h1 className="text-xl font-bold text-brand-black">Kelola Booking</h1>
          <p className="text-brand-muted text-sm mt-0.5">{filteredBookings.length} booking ditampilkan</p>
        </div>
        <select
          value={filter}
          onChange={(e) => setFilter(e.target.value)}
          className="bg-brand-surface border border-gray-200 rounded-xl px-4 py-2 text-sm text-brand-black focus:outline-none focus:ring-2 focus:ring-brand-black/20"
        >
          <option value="ALL">Semua Status</option>
          <option value="PENDING">Pending</option>
          <option value="APPROVED">Disetujui</option>
          <option value="REJECTED">Ditolak</option>
        </select>
      </div>

      <div className="bg-brand-surface border border-gray-200 rounded-2xl overflow-hidden">
        {loading ? (
          <div className="flex items-center justify-center py-20 text-brand-muted">Memuat data...</div>
        ) : filteredBookings.length === 0 ? (
          <div className="text-center py-20">
            <p className="text-4xl mb-3">✅</p>
            <p className="text-brand-black font-medium">Tidak ada booking {filter !== "ALL" ? filter.toLowerCase() : ""}</p>
            <p className="text-brand-muted text-sm mt-1">Data kosong</p>
          </div>
        ) : (
          <div className="overflow-x-auto">
            <table className="w-full text-sm">
              <thead>
                <tr className="border-b border-gray-200">
                  {["ID", "Nama Penyewa", "Email", "Kamar", "Tanggal Booking", "Mulai Huni", "Status", "Aksi"].map((h) => (
                    <th key={h} className="text-left px-5 py-3.5 text-xs font-semibold text-brand-muted uppercase tracking-wide whitespace-nowrap">{h}</th>
                  ))}
                </tr>
              </thead>
              <tbody className="divide-y divide-gray-100">
                {filteredBookings.map((b) => (
                  <tr key={b.id} className="hover:bg-gray-50 transition-colors">
                    <td className="px-5 py-4 text-brand-muted font-mono text-xs">#{b.id}</td>
                    <td className="px-5 py-4 text-brand-black font-medium">{b.user_name || "—"}</td>
                    <td className="px-5 py-4 text-brand-muted">{b.user_email}</td>
                    <td className="px-5 py-4 text-brand-black">{b.room_name}</td>
                    <td className="px-5 py-4 text-brand-muted whitespace-nowrap">{formatDate(b.booking_date)}</td>
                    <td className="px-5 py-4 text-brand-muted whitespace-nowrap">{formatDate(b.start_date)}</td>
                    <td className="px-5 py-4">
                      <span className={`inline-flex items-center px-2.5 py-1 rounded-full text-xs font-medium border ${STATUS_STYLE[b.status] ?? STATUS_STYLE.PENDING}`}>
                        {b.status}
                      </span>
                    </td>
                    <td className="px-5 py-4">
                      {b.status === "PENDING" && (
                        <div className="flex items-center gap-2">
                          <button
                            onClick={() => updateStatus(b.id, "APPROVED")}
                            className="px-3 py-1.5 bg-brand-green/10 hover:bg-emerald-500/20 text-brand-green rounded-lg text-xs font-medium border border-brand-green/20 transition-colors"
                          >
                            ✓ Setujui
                          </button>
                          <button
                            onClick={() => updateStatus(b.id, "REJECTED")}
                            className="px-3 py-1.5 bg-red-50 hover:bg-red-600/20 text-red-600 rounded-lg text-xs font-medium border border-red-200 transition-colors"
                          >
                            ✗ Tolak
                          </button>
                        </div>
                      )}
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
      </div>
    </div>
  );
}
