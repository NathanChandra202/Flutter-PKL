"use client";

import { useEffect, useState } from "react";
import type { Booking } from "@/lib/api";
import { formatDate } from "@/lib/utils";

type StatusFilter = "ALL" | "PENDING" | "APPROVED" | "REJECTED";

const STATUS_STYLE: Record<string, string> = {
  PENDING: "bg-brand-black/10 text-brand-black border-gray-200",
  APPROVED: "bg-brand-green/10 text-brand-green border-brand-green/20",
  REJECTED: "bg-red-50 text-red-600 border-red-200",
};

export default function BookingsPage() {
  const [allBookings, setAllBookings] = useState<Booking[]>([]);
  const [filter, setFilter] = useState<StatusFilter>("PENDING");
  const [loading, setLoading] = useState(true);
  const [toast, setToast] = useState<{ msg: string; ok: boolean } | null>(null);

  function showToast(msg: string, ok = true) {
    setToast({ msg, ok });
    setTimeout(() => setToast(null), 3500);
  }

  async function loadBookings() {
    setLoading(true);
    try {
      const res = await fetch("/api/proxy?path=%2Fbookings%2Fall");
      if (res.ok) setAllBookings(await res.json());
    } finally {
      setLoading(false);
    }
  }

  useEffect(() => { loadBookings(); }, []);

  // Client-side filter
  const bookings = filter === "ALL"
    ? allBookings
    : allBookings.filter((b) => b.status === filter);

  async function updateStatus(bookingId: number, status: "APPROVED" | "REJECTED") {
    try {
      const res = await fetch(
        `/api/proxy?path=${encodeURIComponent(`/bookings/${bookingId}/status`)}`,
        {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify({ status }),
        }
      );
      if (!res.ok) throw new Error("Gagal update status");
      showToast(`Booking berhasil ${status === "APPROVED" ? "disetujui" : "ditolak"}!`, status === "APPROVED");
      await loadBookings();
    } catch (e: unknown) {
      showToast(e instanceof Error ? e.message : "Error", false);
    }
  }

  async function approveRenewal(bookingId: number) {
    try {
      const res = await fetch(
        `/api/proxy?path=${encodeURIComponent(`/bookings/${bookingId}/approve-renewal`)}`,
        { method: "POST" }
      );
      if (!res.ok) throw new Error("Gagal menyetujui perpanjangan");
      const data = await res.json();
      showToast(`Perpanjangan disetujui! Selesai sewa baru: ${formatDate(data.new_end_date)}`);
      await loadBookings();
    } catch (e: unknown) {
      showToast(e instanceof Error ? e.message : "Error", false);
    }
  }

  const filterLabels: { value: StatusFilter; label: string; count: number }[] = [
    { value: "ALL",      label: "Semua",   count: allBookings.length },
    { value: "PENDING",  label: "Pending", count: allBookings.filter(b => b.status === "PENDING").length },
    { value: "APPROVED", label: "Aktif",   count: allBookings.filter(b => b.status === "APPROVED").length },
    { value: "REJECTED", label: "Ditolak", count: allBookings.filter(b => b.status === "REJECTED").length },
  ];

  return (
    <div className="space-y-6">
      {toast && (
        <div className={`fixed top-6 right-6 z-100 px-5 py-3 rounded-xl shadow-lg text-sm font-medium ${toast.ok ? "bg-emerald-500 text-white" : "bg-red-600 text-white"}`}>
          {toast.msg}
        </div>
      )}

      <div className="flex items-center justify-between flex-wrap gap-3">
        <div>
          <h1 className="text-xl font-bold text-brand-black">Kelola Booking</h1>
          <p className="text-brand-muted text-sm mt-0.5">{allBookings.length} total booking</p>
        </div>

        {/* Filter tabs */}
        <div className="flex items-center gap-2 bg-gray-100 p-1 rounded-xl">
          {filterLabels.map(({ value, label, count }) => (
            <button
              key={value}
              onClick={() => setFilter(value)}
              className={`px-3 py-1.5 rounded-lg text-xs font-semibold transition-colors ${
                filter === value
                  ? "bg-white text-brand-black shadow-sm"
                  : "text-brand-muted hover:text-brand-black"
              }`}
            >
              {label}
              {count > 0 && (
                <span className={`ml-1.5 px-1.5 py-0.5 rounded-full text-[10px] font-bold ${
                  filter === value ? "bg-brand-black text-white" : "bg-gray-300 text-gray-600"
                }`}>
                  {count}
                </span>
              )}
            </button>
          ))}
        </div>
      </div>

      <div className="bg-brand-surface border border-gray-200 rounded-2xl overflow-hidden">
        {loading ? (
          <div className="flex items-center justify-center py-20 text-brand-muted">Memuat data...</div>
        ) : bookings.length === 0 ? (
          <div className="text-center py-20">
            <p className="text-4xl mb-3">✅</p>
            <p className="text-brand-black font-medium">
              {filter === "PENDING" ? "Tidak ada booking pending" : `Tidak ada booking ${filter.toLowerCase()}`}
            </p>
            <p className="text-brand-muted text-sm mt-1">
              {filter === "PENDING" ? "Semua booking sudah diproses" : "Coba filter lain"}
            </p>
          </div>
        ) : (
          <div className="overflow-x-auto">
            <table className="w-full text-sm">
              <thead>
                <tr className="border-b border-gray-200">
                  {["ID", "Nama Penyewa", "Email", "Kamar", "Tgl Booking", "Mulai Sewa", "Selesai Sewa", "Durasi", "Status", "Aksi"].map((h) => (
                    <th key={h} className="text-left px-4 py-3.5 text-xs font-semibold text-brand-muted uppercase tracking-wide whitespace-nowrap">{h}</th>
                  ))}
                </tr>
              </thead>
              <tbody className="divide-y divide-gray-100">
                {bookings.map((b) => {
                  const hasRenewal = (b as unknown as Record<string, unknown>)["is_renewal_requested"] === true;
                  const endDate = (b as unknown as Record<string, unknown>)["end_date"] as string | null;
                  const durationMonths = (b as unknown as Record<string, unknown>)["duration_months"] as number | null;

                  return (
                    <tr key={b.id} className="hover:bg-gray-50 transition-colors">
                      <td className="px-4 py-4 text-brand-muted font-mono text-xs">#{b.id}</td>
                      <td className="px-4 py-4 text-brand-black font-medium">{b.user_name || "—"}</td>
                      <td className="px-4 py-4 text-brand-muted text-xs">{b.user_email}</td>
                      <td className="px-4 py-4 text-brand-black">{b.room_name}</td>
                      <td className="px-4 py-4 text-brand-muted whitespace-nowrap text-xs">{formatDate(b.booking_date)}</td>
                      <td className="px-4 py-4 text-brand-muted whitespace-nowrap text-xs">{formatDate(b.start_date)}</td>
                      <td className="px-4 py-4 text-brand-muted whitespace-nowrap text-xs">
                        {endDate ? formatDate(endDate) : <span className="text-gray-400 italic">—</span>}
                      </td>
                      <td className="px-4 py-4 text-brand-muted whitespace-nowrap text-xs">
                        {durationMonths ? `${durationMonths} bln` : "—"}
                      </td>
                      <td className="px-4 py-4">
                        <div className="flex flex-col gap-1">
                          <span className={`inline-flex items-center px-2.5 py-1 rounded-full text-xs font-medium border ${STATUS_STYLE[b.status] ?? STATUS_STYLE.PENDING}`}>
                            {b.status}
                          </span>
                          {hasRenewal && (
                            <span className="inline-flex items-center px-2 py-0.5 rounded-full text-[10px] font-semibold bg-amber-50 text-amber-700 border border-amber-200">
                              🔄 Minta Perpanjangan
                            </span>
                          )}
                        </div>
                      </td>
                      <td className="px-4 py-4">
                        <div className="flex items-center gap-1.5 flex-wrap">
                          {b.status === "PENDING" && (
                            <>
                              <button
                                onClick={() => updateStatus(b.id, "APPROVED")}
                                className="px-2.5 py-1.5 bg-brand-green/10 hover:bg-emerald-500/20 text-brand-green rounded-lg text-xs font-medium border border-brand-green/20 transition-colors whitespace-nowrap"
                              >
                                ✓ Setujui
                              </button>
                              <button
                                onClick={() => updateStatus(b.id, "REJECTED")}
                                className="px-2.5 py-1.5 bg-red-50 hover:bg-red-600/20 text-red-600 rounded-lg text-xs font-medium border border-red-200 transition-colors whitespace-nowrap"
                              >
                                ✗ Tolak
                              </button>
                            </>
                          )}
                          {hasRenewal && b.status === "APPROVED" && (
                            <button
                              onClick={() => approveRenewal(b.id)}
                              className="px-2.5 py-1.5 bg-amber-50 hover:bg-amber-100 text-amber-700 rounded-lg text-xs font-medium border border-amber-200 transition-colors whitespace-nowrap"
                            >
                              ✓ Setujui Perpanjangan
                            </button>
                          )}
                          {b.bukti_bayar_url && (
                            <a
                              href={b.bukti_bayar_url}
                              target="_blank"
                              rel="noreferrer"
                              className="px-2.5 py-1.5 bg-blue-50 hover:bg-blue-600/20 text-blue-600 rounded-lg text-xs font-medium border border-blue-200 transition-colors whitespace-nowrap"
                            >
                              📄 Lihat Bukti
                            </a>
                          )}
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
    </div>
  );
}
