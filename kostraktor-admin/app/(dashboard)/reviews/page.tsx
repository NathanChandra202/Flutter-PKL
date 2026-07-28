"use client";

import { useEffect, useState } from "react";
import type { Review } from "@/lib/api";
import { formatDate } from "@/lib/utils";

function StarRating({ rating }: { rating: number }) {
  return (
    <div className="flex gap-0.5">
      {[1, 2, 3, 4, 5].map((s) => (
        <span key={s} className={`text-sm ${s <= Math.round(rating) ? "text-brand-black" : "text-slate-700"}`}>★</span>
      ))}
    </div>
  );
}

export default function ReviewsPage() {
  const [reviews, setReviews] = useState<Review[]>([]);
  const [loading, setLoading] = useState(true);

  async function load() {
    setLoading(true);
    try {
      const res = await fetch("/api/proxy?path=%2Freviews%2F");
      if (res.ok) setReviews(await res.json());
    } finally {
      setLoading(false);
    }
  }

  useEffect(() => { load(); }, []);

  const avg = reviews.length > 0
    ? (reviews.reduce((s, r) => s + r.rating, 0) / reviews.length).toFixed(1)
    : "—";

  const dist = [5, 4, 3, 2, 1].map((star) => ({
    star,
    count: reviews.filter((r) => Math.round(r.rating) === star).length,
  }));

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-xl font-bold text-brand-black">Kelola Ulasan</h1>
        <p className="text-brand-muted text-sm mt-0.5">{reviews.length} ulasan dari penghuni</p>
      </div>

      {/* Stats */}
      {reviews.length > 0 && (
        <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
          {/* Average */}
          <div className="bg-brand-surface border border-gray-200 rounded-2xl p-5 flex items-center gap-4">
            <div className="text-5xl font-black text-brand-black">{avg}</div>
            <div>
              <StarRating rating={Number(avg)} />
              <p className="text-brand-muted text-xs mt-1">{reviews.length} ulasan</p>
            </div>
          </div>
          {/* Distribution */}
          <div className="md:col-span-2 bg-brand-surface border border-gray-200 rounded-2xl p-5">
            <p className="text-brand-muted text-xs font-semibold uppercase tracking-wide mb-3">Distribusi Rating</p>
            <div className="space-y-2">
              {dist.map(({ star, count }) => {
                const pct = reviews.length > 0 ? (count / reviews.length) * 100 : 0;
                return (
                  <div key={star} className="flex items-center gap-3">
                    <span className="text-brand-black text-xs w-4">{star}★</span>
                    <div className="flex-1 h-2 bg-gray-50 rounded-full overflow-hidden">
                      <div className="h-2 bg-brand-black rounded-full transition-all" style={{ width: `${pct}%` }} />
                    </div>
                    <span className="text-brand-muted text-xs w-4 text-right">{count}</span>
                  </div>
                );
              })}
            </div>
          </div>
        </div>
      )}

      {/* Reviews list */}
      <div className="bg-brand-surface border border-gray-200 rounded-2xl overflow-hidden">
        {loading ? (
          <div className="flex items-center justify-center py-20 text-brand-muted">Memuat data...</div>
        ) : reviews.length === 0 ? (
          <div className="text-center py-20">
            <p className="text-4xl mb-3">💬</p>
            <p className="text-brand-black font-medium">Belum ada ulasan</p>
            <p className="text-brand-muted text-sm mt-1">Ulasan dari penghuni akan muncul di sini</p>
          </div>
        ) : (
          <div className="overflow-x-auto">
            <table className="w-full text-sm">
              <thead>
                <tr className="border-b border-gray-200">
                  {["Pengguna", "Rating", "Tipe Kamar", "Komentar", "Tanggal"].map((h) => (
                    <th key={h} className="text-left px-5 py-3.5 text-xs font-semibold text-brand-muted uppercase tracking-wide whitespace-nowrap">{h}</th>
                  ))}
                </tr>
              </thead>
              <tbody className="divide-y divide-gray-100">
                {reviews.map((r) => (
                  <tr key={r.id} className="hover:bg-gray-50 transition-colors">
                    <td className="px-5 py-4">
                      <p className="text-brand-black font-medium">{r.user_name}</p>
                      <p className="text-brand-muted text-xs">{r.user_email}</p>
                    </td>
                    <td className="px-5 py-4">
                      <StarRating rating={r.rating} />
                      <span className="text-brand-muted text-xs">{r.rating.toFixed(1)}</span>
                    </td>
                    <td className="px-5 py-4 text-brand-muted">{r.room_type ?? "—"}</td>
                    <td className="px-5 py-4 text-brand-black max-w-sm">
                      <p className="line-clamp-2">{r.comment}</p>
                    </td>
                    <td className="px-5 py-4 text-brand-muted whitespace-nowrap">{formatDate(r.created_at)}</td>
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
