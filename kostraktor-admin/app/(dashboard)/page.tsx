"use client";

import { useEffect, useState } from "react";
import { useRouter } from "next/navigation";
import {
  PieChart, Pie, Cell, Tooltip, ResponsiveContainer, Legend,
} from "recharts";
import { BedDouble, ClipboardList, CheckCircle, Home, TrendingUp, AlertCircle } from "lucide-react";
import BookingRadarChart from "@/components/BookingRadarChart";

const ROOM_COLORS = ["#10b981", "#f59e0b"];
const BOOKING_FILL: Record<string, string> = {
  PENDING: "#f59e0b",
  APPROVED: "#10b981",
  REJECTED: "#ef4444",
};

function StatCard({ icon, label, value, accent, sub }: {
  icon: React.ReactNode;
  label: string;
  value: number;
  accent: string;
  sub?: string;
}) {
  return (
    <div className="bg-brand-surface rounded-2xl p-5 border border-gray-200 shadow-sm flex items-center gap-4 relative overflow-hidden group hover:shadow-md transition-shadow">
      <div className={`w-12 h-12 rounded-xl flex items-center justify-center shrink-0 ${accent}`}>
        {icon}
      </div>
      <div className="min-w-0">
        <p className="text-brand-muted text-xs font-semibold uppercase tracking-wide">{label}</p>
        <p className="text-2xl font-bold text-brand-black leading-tight">{value}</p>
        {sub && <p className="text-xs text-brand-muted mt-0.5">{sub}</p>}
      </div>
      <div className="absolute -right-4 -bottom-4 w-20 h-20 rounded-full bg-gray-100 opacity-0 group-hover:opacity-50 transition-opacity" />
    </div>
  );
}

function SkeletonCard() {
  return (
    <div className="bg-brand-surface rounded-2xl p-5 border border-gray-200 shadow-sm flex items-center gap-4 animate-pulse">
      <div className="w-12 h-12 rounded-xl bg-gray-200 shrink-0" />
      <div className="space-y-2 flex-1">
        <div className="h-3 bg-gray-200 rounded w-24" />
        <div className="h-7 bg-gray-200 rounded w-12" />
      </div>
    </div>
  );
}

export default function DashboardOverviewPage() {
  const router = useRouter();
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [stats, setStats] = useState({
    totalRooms: 0,
    availableRooms: 0,
    occupiedRooms: 0,
    pendingBookings: 0,
    approvedBookings: 0,
    rejectedBookings: 0,
    unhandledReports: 0,
  });

  useEffect(() => {
    async function fetchDashboardData() {
      try {
        setLoading(true);
        setError(null);
        
        // Fetch rooms
        const roomsRes = await fetch("/api/proxy?path=/rooms/?all=true");
        if (roomsRes.status === 401) {
          router.push("/login");
          return;
        }
        
        let rooms = [];
        if (roomsRes.ok) {
          rooms = await roomsRes.json();
        }

        const totalRooms = rooms.length;
        const availableRooms = rooms.filter((r: any) => r.is_available).length;
        const occupiedRooms = totalRooms - availableRooms;

        // Fetch all bookings
        const bookingsRes = await fetch("/api/proxy?path=/bookings/all");
        let allBookings = [];
        if (bookingsRes.ok) {
          allBookings = await bookingsRes.json();
        }

        const pendingBookings = allBookings.filter((b: any) => b.status === "PENDING").length;
        const approvedBookings = allBookings.filter((b: any) => b.status === "APPROVED").length;
        const rejectedBookings = allBookings.filter((b: any) => b.status === "REJECTED").length;

        // Fetch reports
        const reportsRes = await fetch("/api/proxy?path=/reports/");
        let unhandledReports = 0;
        if (reportsRes.ok) {
          const allReports = await reportsRes.json();
          unhandledReports = allReports.filter((r: any) => r.status === "OPEN").length;
        }

        setStats({
          totalRooms,
          availableRooms,
          occupiedRooms,
          pendingBookings,
          approvedBookings,
          rejectedBookings,
          unhandledReports,
        });
      } catch (err) {
        console.error("Failed to fetch dashboard data", err);
        setError("Gagal mengambil data statistik.");
      } finally {
        setLoading(false);
      }
    }

    fetchDashboardData();
  }, [router]);



  const roomChartData = [
    { name: "Tersedia", value: stats.availableRooms },
    { name: "Terisi", value: stats.occupiedRooms },
  ];

  const bookingChartData = [
    { status: "Pending", jumlah: stats.pendingBookings, fill: BOOKING_FILL.PENDING },
    { status: "Disetujui", jumlah: stats.approvedBookings, fill: BOOKING_FILL.APPROVED },
    { status: "Ditolak", jumlah: stats.rejectedBookings, fill: BOOKING_FILL.REJECTED },
  ];

  const totalBookings = stats.pendingBookings + stats.approvedBookings + stats.rejectedBookings;

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-heading font-bold text-brand-black">Dashboard Overview</h1>
          <p className="text-brand-muted mt-1 text-sm">
            Ringkasan statistik Kostraktor —{" "}
            <span className="font-semibold">
              {new Date().toLocaleDateString("id-ID", { weekday: "long", day: "numeric", month: "long", year: "numeric" })}
            </span>
          </p>
        </div>
        {!loading && !error && (
          <button
            onClick={() => window.location.reload()}
            className="flex items-center gap-2 text-sm text-brand-muted hover:text-brand-black transition-colors px-3 py-1.5 rounded-lg hover:bg-gray-100"
          >
            <TrendingUp size={15} />
            Refresh
          </button>
        )}
      </div>

      {/* Stat Cards */}
      <div className="grid grid-cols-1 md:grid-cols-2 xl:grid-cols-4 gap-4">
        {loading ? (
          <>
            <SkeletonCard />
            <SkeletonCard />
            <SkeletonCard />
            <SkeletonCard />
            <SkeletonCard />
          </>
        ) : error ? (
          <div className="col-span-full p-5 bg-red-50 border border-red-200 rounded-2xl flex items-start gap-3 text-red-700">
            <AlertCircle size={20} className="shrink-0 mt-0.5" />
            <div>
              <p className="font-bold text-sm">Gagal memuat data</p>
              <p className="text-sm mt-0.5">{error}</p>
            </div>
          </div>
        ) : (
          <>
            <StatCard
              icon={<Home size={22} className="text-blue-600" />}
              label="Total Kamar"
              value={stats.totalRooms}
              accent="bg-blue-50"
            />
            <StatCard
              icon={<BedDouble size={22} className="text-emerald-600" />}
              label="Kamar Tersedia"
              value={stats.availableRooms}
              accent="bg-emerald-50"
              sub={stats.totalRooms > 0 ? `${Math.round((stats.availableRooms / stats.totalRooms) * 100)}% dari total` : undefined}
            />
            <StatCard
              icon={<ClipboardList size={22} className="text-orange-600" />}
              label="Booking Pending"
              value={stats.pendingBookings}
              accent="bg-orange-50"
              sub="Menunggu persetujuan"
            />
            <StatCard
              icon={<AlertCircle size={22} className="text-red-600" />}
              label="Laporan Baru"
              value={stats.unhandledReports}
              accent="bg-red-50"
              sub="Menunggu ditangani"
            />
            <StatCard
              icon={<CheckCircle size={22} className="text-brand-black" />}
              label="Booking Disetujui"
              value={stats.approvedBookings}
              accent="bg-brand-gold-light border border-brand-gold/30"
              sub="Estimasi penyewa aktif*"
            />
          </>
        )}
      </div>

      {/* Resident data gap notice */}
      {!loading && !error && (
        <div className="flex items-start gap-2.5 px-4 py-3 bg-blue-50 border border-blue-200 rounded-xl text-blue-700 text-xs">
          <AlertCircle size={14} className="shrink-0 mt-0.5" />
          <p>
            <span className="font-bold">Catatan:</span> &quot;Booking Disetujui&quot; digunakan sebagai estimasi penyewa aktif karena
            perubahan status <em>resident</em> saat ini masih dikelola secara lokal di app Flutter dan belum tersinkron ke database backend.
          </p>
        </div>
      )}

      {/* Charts — skeleton while loading */}
      {loading && (
        <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
          {[1, 2].map((i) => (
            <div key={i} className="bg-brand-surface border border-gray-200 rounded-2xl p-6 shadow-sm animate-pulse">
              <div className="h-4 bg-gray-200 rounded w-40 mb-2" />
              <div className="h-3 bg-gray-200 rounded w-56 mb-6" />
              <div className="h-56 bg-gray-100 rounded-xl" />
            </div>
          ))}
        </div>
      )}

      {/* Charts — real data */}
      {!loading && !error && (
        <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
          {/* Donut Chart */}
          <div className="bg-brand-surface border border-gray-200 rounded-2xl p-6 shadow-sm">
            <div className="mb-5">
              <h2 className="text-base font-bold text-brand-black">Status Ketersediaan Kamar</h2>
              <p className="text-xs text-brand-muted mt-0.5">Perbandingan kamar tersedia vs terisi</p>
            </div>
            {stats.totalRooms > 0 ? (
              <div className="h-64 w-full">
                <ResponsiveContainer width="100%" height="100%">
                  <PieChart>
                    <Pie
                      data={roomChartData}
                      cx="50%"
                      cy="50%"
                      innerRadius={65}
                      outerRadius={90}
                      paddingAngle={4}
                      dataKey="value"
                    >
                      {roomChartData.map((_, index) => (
                        <Cell key={`cell-${index}`} fill={ROOM_COLORS[index]} strokeWidth={0} />
                      ))}
                    </Pie>
                    <Tooltip
                      contentStyle={{ borderRadius: "12px", border: "1px solid #e5e7eb", boxShadow: "0 4px 6px -1px rgb(0 0 0 / 0.1)", fontSize: "13px" }}
                      formatter={(value, name) => [`${value ?? 0} kamar`, String(name)]}
                    />
                    <Legend verticalAlign="bottom" height={36}
                      formatter={(value) => <span className="text-xs font-semibold text-brand-black">{value}</span>}
                    />
                  </PieChart>
                </ResponsiveContainer>
              </div>
            ) : (
              <div className="h-64 w-full flex flex-col items-center justify-center text-brand-muted gap-2">
                <BedDouble size={32} className="opacity-30" />
                <p className="text-sm">Belum ada data kamar</p>
              </div>
            )}
          </div>

          {/* Bar Chart — Booking Status */}
          <div className="bg-brand-surface border border-gray-200 rounded-2xl p-6 shadow-sm">
            <div className="mb-5">
              <h2 className="text-base font-bold text-brand-black">Distribusi Status Booking</h2>
              <p className="text-xs text-brand-muted mt-0.5">Total {totalBookings} booking terdaftar di sistem</p>
            </div>
            {totalBookings > 0 ? (
              <div className="h-64 w-full flex items-center justify-center">
                <BookingRadarChart
                  pending={stats.pendingBookings}
                  approved={stats.approvedBookings}
                  rejected={stats.rejectedBookings}
                />
              </div>
            ) : (
              <div className="h-64 w-full flex flex-col items-center justify-center text-brand-muted gap-2">
                <ClipboardList size={32} className="opacity-30" />
                <p className="text-sm">Belum ada data booking</p>
              </div>
            )}
          </div>
        </div>
      )}
    </div>
  );
}
