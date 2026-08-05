"use client";

import { useEffect, useState } from "react";
import type { Review } from "@/lib/api";
import { formatDate } from "@/lib/utils";

function StarRating({ rating }: { rating: number }) {
  return (
    <div className="flex gap-0.5">
      {[1, 2, 3, 4, 5].map((s) => (
        <span key={s} className={`text-sm ${s <= Math.round(rating) ? "text-amber-400" : "text-slate-700"}`}>★</span>
      ))}
    </div>
  );
}

// ─── Manual Review Dialog ────────────────────────────────────────────────────────

function ManualReviewDialog({ onClose, onSuccess }: { onClose: () => void; onSuccess: () => void }) {
  const [form, setForm] = useState({ reviewer_name: "", rating: 5, comment: "", room_type: "" });
  const [saving, setSaving] = useState(false);
  const [err, setErr] = useState<string | null>(null);

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    setSaving(true);
    setErr(null);
    try {
      const res = await fetch(`/api/proxy?path=${encodeURIComponent("/reviews/manual")}`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          reviewer_name: form.reviewer_name.trim(),
          rating: form.rating,
          comment: form.comment.trim(),
          room_type: form.room_type.trim() || null,
        }),
      });
      if (!res.ok) {
        const errData = await res.json().catch(() => ({ detail: "Gagal mengirim" }));
        throw new Error(errData.detail ?? "Gagal mengirim ulasan");
      }
      onSuccess();
      onClose();
    } catch (e: unknown) {
      setErr(e instanceof Error ? e.message : "Gagal mengirim ulasan");
    } finally {
      setSaving(false);
    }
  }
  return (
    <div className="fixed inset-0 bg-black/50 backdrop-blur-sm z-50 flex items-center justify-center p-4">
      <div className="bg-brand-surface border border-gray-200 rounded-2xl w-full max-w-md shadow-2xl overflow-hidden">
        <div className="flex items-center justify-between px-6 py-4 border-b border-gray-200">
          <h2 className="text-brand-black font-semibold">Tambah Ulasan Manual</h2>
          <button onClick={onClose} className="text-brand-muted hover:text-brand-black text-lg">✕</button>
        </div>

        <form onSubmit={handleSubmit} className="p-6 space-y-4">
          {err && (
            <p className="text-red-600 text-sm bg-red-50 border border-red-200 rounded-xl px-4 py-2">{err}</p>
          )}

          <div>
            <label className="text-brand-black text-sm font-medium block mb-1">Nama Pengulas *</label>
            <input
              type="text"
              required
              id="manual-reviewer-name"
              value={form.reviewer_name}
              onChange={(e) => setForm((f) => ({ ...f, reviewer_name: e.target.value }))}
              placeholder="Nama penghuni..."
              className="w-full bg-gray-50 border border-gray-300 rounded-xl px-4 py-2.5 text-brand-black text-sm focus:outline-none focus:ring-2 focus:ring-brand-black/20"
            />
          </div>

          <div>
            <label className="text-brand-black text-sm font-medium block mb-2">Rating *</label>
            <div className="flex gap-2">
              {[1, 2, 3, 4, 5].map((s) => (
                <button
                  key={s}
                  type="button"
                  id={`rating-star-${s}`}
                  onClick={() => setForm((f) => ({ ...f, rating: s }))}
                  className={`text-2xl transition-transform hover:scale-110 ${s <= form.rating ? "text-amber-400" : "text-gray-300"}`}
                >
                  ★
                </button>
              ))}
              <span className="text-brand-muted text-sm self-center ml-1">{form.rating}/5</span>
            </div>
          </div>

          <div>
            <label className="text-brand-black text-sm font-medium block mb-1">Komentar *</label>
            <textarea
              required
              id="manual-review-comment"
              rows={3}
              value={form.comment}
              onChange={(e) => setForm((f) => ({ ...f, comment: e.target.value }))}
              placeholder="Tulis ulasan..."
              className="w-full bg-gray-50 border border-gray-300 rounded-xl px-4 py-2.5 text-brand-black text-sm focus:outline-none focus:ring-2 focus:ring-brand-black/20 resize-none"
            />
          </div>
          <div>
            <label className="text-brand-black text-sm font-medium block mb-1">Tipe Kamar <span className="text-brand-muted font-normal">(opsional)</span></label>
            <input
              type="text"
              id="manual-review-room-type"
              value={form.room_type}
              onChange={(e) => setForm((f) => ({ ...f, room_type: e.target.value }))}
              placeholder="Tipe AC Premium, Standard, ..."
              className="w-full bg-gray-50 border border-gray-300 rounded-xl px-4 py-2.5 text-brand-black text-sm focus:outline-none focus:ring-2 focus:ring-brand-black/20"
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
              id="manual-review-submit"
              className="flex-1 py-2.5 bg-brand-black hover:bg-gray-900 disabled:opacity-60 text-white rounded-xl text-sm font-bold transition-colors"
            >
              {saving ? "Menyimpan..." : "Simpan Ulasan"}
            </button>
          </div>
        </form>
      </div>
    </div>
  );
}

// ─── Main Page ──────────────────────────────────────────────────────────────────

export default function ReviewsPage() {
  const [reviews, setReviews] = useState<Review[]>([]);
  const [loading, setLoading] = useState(true);
  const [showManualForm, setShowManualForm] = useState(false);
  const [toast, setToast] = useState<{ msg: string; ok: boolean } | null>(null);

  function showToast(msg: string, ok = true) {
    setToast({ msg, ok });
    setTimeout(() => setToast(null), 3000);
  }

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
      {/* Toast */}
      {toast && (
        <div className={`fixed top-6 right-6 z-[100] px-5 py-3 rounded-xl shadow-lg text-sm font-medium transition-all ${toast.ok ? "bg-emerald-500 text-white" : "bg-red-600 text-white"}`}>
          {toast.msg}
        </div>
      )}

      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-xl font-bold text-brand-black">Kelola Ulasan</h1>
          <p className="text-brand-muted text-sm mt-0.5">{reviews.length} ulasan dari penghuni</p>
        </div>
        <button
          id="add-manual-review-btn"
          onClick={() => setShowManualForm(true)}
          className="flex items-center gap-2 px-4 py-2.5 bg-brand-black hover:bg-gray-900 text-white font-semibold rounded-xl text-sm transition-colors"
        >
          ✍️ Tambah Ulasan
        </button>
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

      {/* Manual Review Modal */}
      {showManualForm && (
        <ManualReviewDialog
          onClose={() => setShowManualForm(false)}
          onSuccess={() => {
            showToast("Ulasan berhasil ditambahkan!");
            load();
          }}
        />
      )}
    </div>
  );
}