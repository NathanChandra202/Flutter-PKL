"use client";

import { useState, useEffect, useCallback } from "react";
import { useRouter } from "next/navigation";
import Image from "next/image";
import { ClipboardCheck, Search, Filter, AlertCircle, CheckCircle, Clock, X, MessageSquare } from "lucide-react";

type Report = {
  id: number;
  user_id: number;
  user_name: string;
  title: string;
  description: string;
  category: string;
  photo_url: string | null;
  status: string;
  admin_response: string | null;
  created_at: string;
  resolved_at: string | null;
};

export default function ReportsPage() {
  const router = useRouter();
  const [reports, setReports] = useState<Report[]>([]);
  const [loading, setLoading] = useState(true);
  const [filter, setFilter] = useState("ALL");
  
  const [selectedReport, setSelectedReport] = useState<Report | null>(null);
  const [responseStatus, setResponseStatus] = useState("IN_PROGRESS");
  const [responseText, setResponseText] = useState("");
  const [submitting, setSubmitting] = useState(false);

  const fetchReports = useCallback(async () => {
    try {
      setLoading(true);
      const res = await fetch("/api/proxy?path=/reports/");
      if (res.status === 401 || res.status === 403) {
        router.push("/login");
        return;
      }
      if (res.ok) {
        const data = await res.json();
        setReports(data);
      }
    } catch (e) {
      console.error(e);
    } finally {
      setLoading(false);
    }
  }, [router]);

  useEffect(() => {
    fetchReports();
  }, [fetchReports]);

  const filteredReports = reports.filter(r => filter === "ALL" || r.status === filter);

  const handleRespond = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!selectedReport) return;
    
    setSubmitting(true);
    try {
      const res = await fetch(`/api/proxy?path=/reports/${selectedReport.id}/respond`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          status: responseStatus,
          admin_response: responseText,
        }),
      });
      if (res.ok) {
        await fetchReports();
        setSelectedReport(null);
      } else {
        alert("Gagal menyimpan tanggapan.");
      }
    } catch (e) {
      alert("Terjadi kesalahan.");
    } finally {
      setSubmitting(false);
    }
  };

  const getStatusBadge = (status: string) => {
    switch (status) {
      case "OPEN":
        return <span className="px-2.5 py-1 rounded-full text-xs font-bold bg-orange-100 text-orange-700 border border-orange-200">Menunggu</span>;
      case "IN_PROGRESS":
        return <span className="px-2.5 py-1 rounded-full text-xs font-bold bg-blue-100 text-blue-700 border border-blue-200">Diproses</span>;
      case "RESOLVED":
        return <span className="px-2.5 py-1 rounded-full text-xs font-bold bg-green-100 text-green-700 border border-green-200">Selesai</span>;
      default:
        return null;
    }
  };

  return (
    <div className="space-y-6">
      <div className="flex flex-col md:flex-row md:items-center justify-between gap-4">
        <div>
          <h1 className="text-2xl font-heading font-bold text-brand-black flex items-center gap-2">
            <ClipboardCheck className="text-brand-gold" />
            Audit Laporan
          </h1>
          <p className="text-brand-muted mt-1 text-sm">
            Kelola keluhan dan laporan dari penghuni kost.
          </p>
        </div>
      </div>

      <div className="bg-brand-surface rounded-2xl border border-gray-200 shadow-sm overflow-hidden flex flex-col min-h-[500px]">
        {/* Toolbar */}
        <div className="p-4 border-b border-gray-100 flex flex-wrap gap-4 items-center justify-between bg-gray-50/50">
          <div className="flex items-center gap-2">
            <Filter size={16} className="text-brand-muted" />
            <select
              className="text-sm border-gray-300 rounded-lg focus:ring-brand-gold focus:border-brand-gold"
              value={filter}
              onChange={(e) => setFilter(e.target.value)}
            >
              <option value="ALL">Semua Status</option>
              <option value="OPEN">Menunggu (Open)</option>
              <option value="IN_PROGRESS">Diproses (In Progress)</option>
              <option value="RESOLVED">Selesai (Resolved)</option>
            </select>
          </div>
        </div>

        {/* List */}
        <div className="flex-1 p-4">
          {loading ? (
            <div className="flex justify-center items-center h-full text-brand-muted">
              <div className="animate-spin rounded-full h-8 w-8 border-2 border-brand-gold border-t-transparent" />
            </div>
          ) : filteredReports.length === 0 ? (
            <div className="flex flex-col items-center justify-center h-full text-brand-muted py-20">
              <ClipboardCheck size={48} className="opacity-20 mb-4" />
              <p>Belum ada laporan {filter !== "ALL" ? "dengan status ini" : ""}.</p>
            </div>
          ) : (
            <div className="grid grid-cols-1 md:grid-cols-2 xl:grid-cols-3 gap-4">
              {filteredReports.map((report) => (
                <div key={report.id} className="border border-gray-200 rounded-xl p-4 hover:shadow-md transition-shadow bg-white flex flex-col">
                  <div className="flex justify-between items-start mb-3">
                    <div className="flex items-center gap-2">
                      <span className="text-xs font-bold bg-gray-100 text-gray-600 px-2 py-1 rounded">
                        {report.category || "Lainnya"}
                      </span>
                    </div>
                    {getStatusBadge(report.status)}
                  </div>
                  
                  <h3 className="font-bold text-brand-black text-lg leading-tight mb-1">{report.title}</h3>
                  <p className="text-xs text-brand-muted mb-3 flex items-center gap-1">
                    <Clock size={12} /> {new Date(report.created_at).toLocaleString("id-ID")}
                  </p>
                  
                  <p className="text-sm text-gray-700 mb-4 line-clamp-3">{report.description}</p>
                  
                  <div className="mt-auto pt-4 border-t border-gray-100 flex items-center justify-between">
                    <div className="text-xs">
                      <span className="text-gray-500">Pelapor: </span>
                      <span className="font-semibold text-brand-black">{report.user_name}</span>
                    </div>
                    <button
                      onClick={() => {
                        setSelectedReport(report);
                        setResponseStatus(report.status === "OPEN" ? "IN_PROGRESS" : report.status);
                        setResponseText(report.admin_response || "");
                      }}
                      className="text-sm font-semibold text-brand-gold-dark hover:text-brand-black transition-colors"
                    >
                      Tinjau &rarr;
                    </button>
                  </div>
                </div>
              ))}
            </div>
          )}
        </div>
      </div>

      {/* Modal Respond */}
      {selectedReport && (
        <div className="fixed inset-0 bg-black/60 z-50 flex items-center justify-center p-4">
          <div className="bg-white rounded-2xl w-full max-w-2xl max-h-[90vh] overflow-y-auto shadow-xl">
            <div className="sticky top-0 bg-white border-b border-gray-100 p-4 flex items-center justify-between z-10">
              <h2 className="text-lg font-bold">Detail Laporan #{selectedReport.id}</h2>
              <button onClick={() => setSelectedReport(null)} className="p-1 text-gray-400 hover:text-gray-800 rounded-full hover:bg-gray-100 transition-colors">
                <X size={20} />
              </button>
            </div>
            
            <div className="p-6">
              <div className="flex flex-wrap gap-6 mb-6">
                {selectedReport.photo_url && (
                  <div className="w-full sm:w-1/3 shrink-0">
                    <div className="aspect-[3/4] relative rounded-xl overflow-hidden border border-gray-200">
                      <Image
                        src={selectedReport.photo_url.startsWith('http') ? selectedReport.photo_url : `${process.env.NEXT_PUBLIC_API_URL?.replace('/api/v1', '') || ''}${selectedReport.photo_url}`}
                        alt="Foto Laporan"
                        fill
                        className="object-cover"
                        unoptimized
                      />
                    </div>
                  </div>
                )}
                
                <div className="flex-1 min-w-[250px]">
                  <div className="mb-4">
                    <div className="flex items-center gap-2 mb-2">
                      <span className="text-xs font-bold bg-gray-100 text-gray-600 px-2 py-1 rounded">
                        {selectedReport.category || "Lainnya"}
                      </span>
                      {getStatusBadge(selectedReport.status)}
                    </div>
                    <h3 className="text-xl font-bold text-brand-black mb-1">{selectedReport.title}</h3>
                    <p className="text-sm text-gray-500 mb-4">{new Date(selectedReport.created_at).toLocaleString("id-ID")} &bull; Oleh {selectedReport.user_name}</p>
                    
                    <div className="bg-gray-50 p-4 rounded-xl text-sm text-gray-700 border border-gray-100">
                      {selectedReport.description}
                    </div>
                  </div>
                </div>
              </div>
              
              {/* Form Tanggapan */}
              <div className="border-t border-gray-100 pt-6">
                <h4 className="font-bold flex items-center gap-2 mb-4">
                  <MessageSquare size={18} className="text-brand-gold-dark" />
                  Tanggapan Admin
                </h4>
                
                <form onSubmit={handleRespond} className="space-y-4">
                  <div>
                    <label className="block text-sm font-semibold text-gray-700 mb-1">Ubah Status</label>
                    <select
                      className="w-full border-gray-300 rounded-xl focus:ring-brand-gold focus:border-brand-gold"
                      value={responseStatus}
                      onChange={(e) => setResponseStatus(e.target.value)}
                    >
                      <option value="OPEN">Menunggu (Open)</option>
                      <option value="IN_PROGRESS">Diproses (In Progress)</option>
                      <option value="RESOLVED">Selesai (Resolved)</option>
                    </select>
                  </div>
                  
                  <div>
                    <label className="block text-sm font-semibold text-gray-700 mb-1">Pesan Tanggapan</label>
                    <textarea
                      required
                      rows={3}
                      className="w-full border-gray-300 rounded-xl focus:ring-brand-gold focus:border-brand-gold placeholder:text-gray-400"
                      placeholder="Tuliskan tanggapan Anda untuk pengguna..."
                      value={responseText}
                      onChange={(e) => setResponseText(e.target.value)}
                    />
                  </div>
                  
                  <div className="flex justify-end pt-2">
                    <button
                      type="submit"
                      disabled={submitting}
                      className="bg-brand-black text-white px-6 py-2.5 rounded-xl font-bold hover:bg-gray-800 transition-colors disabled:opacity-70 disabled:cursor-not-allowed flex items-center gap-2"
                    >
                      {submitting ? (
                        <div className="w-4 h-4 border-2 border-white border-t-transparent rounded-full animate-spin" />
                      ) : <CheckCircle size={18} />}
                      Simpan Tanggapan
                    </button>
                  </div>
                </form>
              </div>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
