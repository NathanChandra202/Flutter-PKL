"use client";

import { useState, useEffect } from "react";
import { Settings as SettingsIcon } from "lucide-react";

export default function SettingsPage() {
  const [waLink, setWaLink] = useState("");
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [toast, setToast] = useState<{ msg: string; ok: boolean } | null>(null);

  function showToast(msg: string, ok = true) {
    setToast({ msg, ok });
    setTimeout(() => setToast(null), 3000);
  }

  useEffect(() => {
    // Simulasi fetch data dari backend (TODO: ganti dengan pemanggilan API sungguhan)
    const loadSettings = async () => {
      setLoading(true);
      try {
        // Simulasi network delay
        await new Promise((resolve) => setTimeout(resolve, 500));
        // Untuk sementara, kita mock nilai link-nya
        setWaLink(""); 
      } catch (err) {
        showToast("Gagal memuat pengaturan", false);
      } finally {
        setLoading(false);
      }
    };

    loadSettings();
  }, []);

  async function handleSave(e: React.FormEvent) {
    e.preventDefault();
    setSaving(true);
    try {
      // Simulasi update data ke backend (TODO: integrasi API sungguhan `/settings`)
      await new Promise((resolve) => setTimeout(resolve, 800));
      showToast("Pengaturan berhasil disimpan!");
    } catch (err) {
      showToast("Gagal menyimpan pengaturan", false);
    } finally {
      setSaving(false);
    }
  }

  return (
    <div className="max-w-3xl space-y-6">
      {toast && (
        <div className={`fixed top-6 right-6 z-50 px-5 py-3 rounded-xl shadow-lg text-sm font-medium transition-all ${toast.ok ? "bg-emerald-500 text-white" : "bg-red-600 text-white"}`}>
          {toast.msg}
        </div>
      )}

      <div className="flex items-center gap-3">
        <div className="w-10 h-10 bg-brand-gold-light rounded-xl flex items-center justify-center text-brand-black shrink-0">
          <SettingsIcon size={20} />
        </div>
        <div>
          <h1 className="text-xl font-bold text-brand-black">Pengaturan Kost</h1>
          <p className="text-brand-muted text-sm mt-0.5">Atur informasi properti dan integrasi aplikasi.</p>
        </div>
      </div>

      <div className="bg-brand-surface border border-gray-200 rounded-2xl overflow-hidden shadow-sm">
        <div className="px-6 py-5 border-b border-gray-100 bg-gray-50/50">
          <h2 className="text-brand-black font-semibold">Integrasi WhatsApp</h2>
          <p className="text-brand-muted text-xs mt-1">Atur tautan (link) grup atau komunitas WhatsApp untuk pelaporan masalah kost anonim.</p>
        </div>

        {loading ? (
          <div className="p-8 text-center text-brand-muted text-sm">Memuat pengaturan...</div>
        ) : (
          <form onSubmit={handleSave} className="p-6 space-y-5">
            <div>
              <label className="text-brand-black text-sm font-medium block mb-1">
                Link Grup WhatsApp
              </label>
              <input
                type="url"
                value={waLink}
                onChange={(e) => setWaLink(e.target.value)}
                placeholder="https://whatsapp.com/channel/..."
                className="w-full bg-gray-50 border border-gray-300 rounded-xl px-4 py-2.5 text-brand-black text-sm focus:outline-none focus:ring-2 focus:ring-brand-black/20 transition-all"
              />
              <p className="text-brand-muted text-xs mt-2 leading-relaxed">
                Masukkan link Grup (Group) WhatsApp Kostraktor. Link ini akan muncul di aplikasi penghuni agar mereka bisa bergabung dan melihat laporan fasilitas.
              </p>
            </div>

            <div className="pt-2">
              <button
                type="submit"
                disabled={saving}
                className="px-6 py-2.5 bg-brand-black hover:bg-gray-900 disabled:opacity-60 text-white rounded-xl text-sm font-bold transition-colors"
              >
                {saving ? "Menyimpan..." : "Simpan Pengaturan"}
              </button>
            </div>
          </form>
        )}
      </div>
    </div>
  );
}
