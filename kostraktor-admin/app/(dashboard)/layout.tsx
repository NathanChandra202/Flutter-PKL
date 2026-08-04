"use client";

import { useEffect, useState, useCallback } from "react";
import Link from "next/link";
import { usePathname, useRouter } from "next/navigation";
import Image from "next/image";
import type { MeResponse } from "@/lib/api";

import { LayoutDashboard, BedDouble, ClipboardList, ShoppingBag, Wrench, Star, LogOut, ClipboardCheck } from "lucide-react";

const NAV_ITEMS = [
  { href: "/", label: "Dashboard", icon: <LayoutDashboard size={18} /> },
  { href: "/rooms", label: "Kelola Kamar", icon: <BedDouble size={18} /> },
  { href: "/bookings", label: "Kelola Booking", icon: <ClipboardList size={18} /> },
  { href: "/jastip", label: "Kelola Jastip", icon: <ShoppingBag size={18} /> },
  { href: "/tools", label: "Kelola Alat", icon: <Wrench size={18} /> },
  { href: "/reviews", label: "Kelola Ulasan", icon: <Star size={18} /> },
  { href: "/reports", label: "Audit Laporan", icon: <ClipboardCheck size={18} /> },
];

export default function DashboardLayout({ children }: { children: React.ReactNode }) {
  const pathname = usePathname();
  const router = useRouter();
  const [me, setMe] = useState<MeResponse | null>(null);
  const [sidebarOpen, setSidebarOpen] = useState(false);

  const fetchMe = useCallback(async () => {
    try {
      const res = await fetch("/api/me");
      if (!res.ok) { router.push("/login"); return; }
      setMe(await res.json());
    } catch {
      router.push("/login");
    }
  }, [router]);

  useEffect(() => { fetchMe(); }, [fetchMe]);

  async function handleLogout() {
    await fetch("/api/logout", { method: "POST" });
    router.push("/login");
  }

  return (
    <div className="min-h-screen bg-brand-bg flex">
      {/* Mobile overlay */}
      {sidebarOpen && (
        <div
          className="fixed inset-0 bg-black/60 z-20 lg:hidden"
          onClick={() => setSidebarOpen(false)}
        />
      )}

      {/* ── Sidebar ──────────────────────────────────────────────────────────── */}
      <aside className={`
        fixed lg:static inset-y-0 left-0 z-30 w-64 bg-brand-surface border-r border-gray-200
        flex flex-col transition-transform duration-300 shadow-sm
        ${sidebarOpen ? "translate-x-0" : "-translate-x-full lg:translate-x-0"}
      `}>
        {/* Brand */}
        <div className="h-16 flex items-center gap-3 px-4 border-b border-gray-100 shrink-0">
          <Image
            src="https://cdn.duaenam.id/logos/kostraktor.png" 
            alt="Kostraktor"
            width={40}
            height={40}
            className="rounded-lg shrink-0 w-auto h-auto"
          />
          <div>
            <p className="text-brand-black font-heading font-bold text-sm leading-tight tracking-tight">KOSTRAKTOR</p>
            <p className="text-brand-muted text-xs">Admin Dashboard</p>
          </div>
        </div>

        {/* Nav */}
        <nav className="flex-1 px-3 py-4 space-y-1 overflow-y-auto">
          {NAV_ITEMS.map((item) => {
            const active = item.href === "/" ? pathname === "/" : pathname.startsWith(item.href);
            return (
              <Link
                key={item.href}
                href={item.href}
                onClick={() => setSidebarOpen(false)}
                className={`
                  flex items-center gap-3 px-3 py-2.5 rounded-xl text-sm font-semibold transition-all
                  ${active
                    ? "bg-brand-gold-light text-brand-black shadow-sm"
                    : "text-brand-muted hover:text-brand-black hover:bg-gray-50"
                  }
                `}
              >
                <span className="text-brand-black/70 flex items-center justify-center">{item.icon}</span>
                {item.label}
              </Link>
            );
          })}
        </nav>

        {/* User + Logout */}
        <div className="p-3 border-t border-gray-100 shrink-0">
          {me && (
            <div className="flex items-center gap-3 px-3 py-2 mb-2">
              <div className="w-8 h-8 bg-brand-gold rounded-full flex items-center justify-center text-brand-black font-bold text-xs shrink-0 shadow-sm">
                {(me.nama_lengkap ?? me.email)[0].toUpperCase()}
              </div>
              <div className="min-w-0">
                <p className="text-brand-black text-xs font-bold truncate">{me.nama_lengkap ?? "Admin"}</p>
                <p className="text-brand-muted text-xs truncate">{me.email}</p>
              </div>
            </div>
          )}
          <button
            onClick={handleLogout}
            className="w-full flex items-center gap-3 px-3 py-2.5 rounded-xl text-sm font-semibold text-brand-muted hover:text-red-600 hover:bg-red-50 transition-all"
          >
            <LogOut size={18} /> Logout
          </button>
        </div>
      </aside>

      {/* ── Main content ─────────────────────────────────────────────────────── */}
      <div className="flex-1 flex flex-col min-w-0">
        {/* Top bar */}
        <header className="h-16 bg-brand-surface border-b border-gray-200 flex items-center gap-4 px-6 shrink-0 shadow-sm">
          <button
            className="lg:hidden text-brand-muted hover:text-brand-black"
            onClick={() => setSidebarOpen(true)}
          >
            <svg className="w-6 h-6" fill="none" viewBox="0 0 24 24" strokeWidth={2} stroke="currentColor">
              <path strokeLinecap="round" strokeLinejoin="round" d="M3.75 6.75h16.5M3.75 12h16.5m-16.5 5.25h16.5" />
            </svg>
          </button>

          <div className="flex-1" />

          {me && (
            <div className="flex items-center gap-2 text-sm">
              <span className="text-brand-muted">Halo,</span>
              <span className="text-brand-black font-bold">{me.nama_lengkap ?? me.email}</span>
              <span className="px-2 py-0.5 bg-brand-gold-light text-brand-black text-xs font-bold rounded-full border border-brand-gold">
                {me.role}
              </span>
            </div>
          )}
        </header>

        <main className="flex-1 overflow-auto p-6">
          {children}
        </main>
      </div>
    </div>
  );
}
