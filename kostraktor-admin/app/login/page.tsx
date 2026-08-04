"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";
import Image from "next/image";

export default function LoginPage() {
  const router = useRouter();
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [error, setError] = useState<string | null>(null);
  const [loading, setLoading] = useState(false);

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    setError(null);
    setLoading(true);
    try {
      const res = await fetch("/api/login", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ email, password }),
      });
      const data = await res.json();
      if (!res.ok) {
        setError(data.error ?? "Login gagal");
        return;
      }
      router.push("/rooms");
      router.refresh();
    } catch {
      setError("Tidak dapat terhubung ke server");
    } finally {
      setLoading(false);
    }
  }

  return (
    <div className="min-h-screen bg-brand-bg flex items-center justify-center p-4">
      <div className="w-full max-w-md">
        {/* Logo / Branding */}
        <div className="text-center mb-8">
          <div className="inline-flex items-center justify-center mb-4">
            <Image
              src="https://cdn.duaenam.id/logos/kostraktor.png"
              alt="Kostraktor"
              width={200}
              height={200}
              className="rounded-2xl shadow-lg w-auto h-auto"
              priority
            />
          </div>
          <p className="text-slate-400 text-sm mt-1">Dashboard Manajemen Kost</p>
        </div>

        {/* Card */}
        <div className="bg-brand-surface border border-gray-200 rounded-2xl p-8 shadow-xl shadow-black/5">
          <h2 className="text-lg font-bold text-brand-black mb-6">Masuk ke Akun Anda</h2>

          {error && (
            <div className="mb-4 p-3 bg-red-50 border border-red-200 rounded-xl text-red-600 text-sm flex items-start gap-2">
              <svg className="w-4 h-4 mt-0.5 shrink-0" fill="none" viewBox="0 0 24 24" strokeWidth={2} stroke="currentColor">
                <path strokeLinecap="round" strokeLinejoin="round" d="M12 9v3.75m-9.303 3.376c-.866 1.5.217 3.374 1.948 3.374h14.71c1.73 0 2.813-1.874 1.948-3.374L13.949 3.378c-.866-1.5-3.032-1.5-3.898 0L2.697 16.126zM12 15.75h.007v.008H12v-.008z" />
              </svg>
              {error}
            </div>
          )}

          <form onSubmit={handleSubmit} className="space-y-4">
            <div>
              <label htmlFor="email" className="block text-sm font-semibold text-brand-black mb-1.5">
                Email Admin
              </label>
              <input
                id="email"
                type="email"
                required
                autoComplete="email"
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                placeholder="admin@kostraktor.com"
                className="w-full px-4 py-3 bg-brand-bg border border-gray-300 rounded-xl text-brand-black placeholder-gray-400 text-sm focus:outline-none focus:ring-2 focus:ring-brand-black focus:border-brand-black transition-all"
              />
            </div>

            <div>
              <label htmlFor="password" className="block text-sm font-semibold text-brand-black mb-1.5">
                Password
              </label>
              <input
                id="password"
                type="password"
                required
                autoComplete="current-password"
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                placeholder="••••••••"
                className="w-full px-4 py-3 bg-brand-bg border border-gray-300 rounded-xl text-brand-black placeholder-gray-400 text-sm focus:outline-none focus:ring-2 focus:ring-brand-black focus:border-brand-black transition-all"
              />
            </div>

            <button
              type="submit"
              disabled={loading}
              className="w-full py-4 bg-brand-black hover:bg-gray-900 disabled:opacity-60 disabled:cursor-not-allowed text-white font-bold rounded-xl transition-colors text-sm mt-4 flex items-center justify-center gap-2 shadow-md"
            >
              {loading ? (
                <>
                  <svg className="w-4 h-4 animate-spin" fill="none" viewBox="0 0 24 24">
                    <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4" />
                    <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4z" />
                  </svg>
                  Masuk...
                </>
              ) : (
                "Masuk"
              )}
            </button>
          </form>

          <p className="mt-6 text-center text-xs text-brand-muted">
            Hanya akun dengan role <span className="text-brand-black font-bold">Admin</span> yang memiliki akses.
          </p>
        </div>
      </div>
    </div>
  );
}
