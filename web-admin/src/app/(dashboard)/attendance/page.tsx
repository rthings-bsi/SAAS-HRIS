"use client";

import React, { useState } from "react";
import { useQuery } from "@tanstack/react-query";
import { RotateCcw } from "lucide-react";
import { Button } from "@/components/ui/Button";
import { Card, CardHeader, CardTitle } from "@/components/ui/Card";
import { StatusBadge } from "@/components/ui/StatusBadge";
import { TableSkeleton } from "@/components/ui/LoadingSkeleton";
import { EmptyState } from "@/components/ui/EmptyState";
import { ErrorState } from "@/components/ui/ErrorState";
import apiClient from "@/lib/axios";
import type { ApiResponse, Attendance } from "@/types";

export default function AttendancePage() {
  const [selectedDate, setSelectedDate] = useState(() => {
    const today = new Date();
    return today.toISOString().split("T")[0];
  });

  const {
    data: attendances = [],
    isLoading,
    isError,
    error,
    refetch,
  } = useQuery({
    queryKey: ["attendance-recap", selectedDate],
    queryFn: async () => {
      const response = await apiClient.get<
        ApiResponse<Attendance[] | { attendances: Attendance[] }>
      >("/attendance/recap", {
        params: { date: selectedDate },
      });
      if (response.data.success && response.data.data) {
        if (Array.isArray(response.data.data)) {
          return response.data.data;
        }
        if (
          typeof response.data.data === "object" &&
          "attendances" in response.data.data &&
          Array.isArray(response.data.data.attendances)
        ) {
          return response.data.data.attendances;
        }
      }
      return [];
    },
  });

  return (
    <div className="space-y-6 max-w-7xl mx-auto">
      <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
        <div>
          <h1 className="text-2xl font-bold tracking-tight text-slate-900">
            Presensi Kehadiran
          </h1>
          <p className="text-sm text-slate-500 mt-0.5">
            Log presensi staf berbasis verifikasi titik GPS dan swafoto perangkat.
          </p>
        </div>

        <div className="flex items-center gap-2">
          <input
            type="date"
            value={selectedDate}
            onChange={(e) => setSelectedDate(e.target.value)}
            className="rounded-xl border border-slate-200/80 bg-white/95 px-3 py-1.5 text-xs font-mono text-slate-800 shadow-2xs focus:border-orange-500 focus:outline-none focus:ring-2 focus:ring-orange-500/20"
          />
          <Button
            variant="secondary"
            size="sm"
            onClick={() => refetch()}
            leftIcon={<RotateCcw className="w-4 h-4 text-slate-500" />}
          >
            Segarkan
          </Button>
        </div>
      </div>

      <Card>
        <CardHeader className="p-5 border-b border-slate-100/80 flex flex-row items-center justify-between">
          <div>
            <CardTitle>Rekap Kehadiran Harian</CardTitle>
            <p className="text-xs text-slate-500 mt-1">
              Data presensi masuk dan jam pulang tanggal <span className="font-mono">{selectedDate}</span>.
            </p>
          </div>
        </CardHeader>

        {isLoading ? (
          <TableSkeleton rows={4} columns={7} />
        ) : isError ? (
          <div className="p-6">
            <ErrorState
              title="Gagal Memuat Presensi"
              message={error instanceof Error ? error.message : "Terjadi kendala saat memuat log presensi."}
              onRetry={() => refetch()}
            />
          </div>
        ) : attendances.length === 0 ? (
          <div className="p-6">
            <EmptyState
              title="Belum ada presensi pada tanggal ini"
              description="Belum ada data staf yang melakukan clock-in pada tanggal yang dipilih."
            />
          </div>
        ) : (
          <div className="overflow-x-auto">
            <table className="w-full text-left text-sm">
              <thead>
                <tr className="bg-slate-50/80 backdrop-blur-xs border-b border-slate-200/70 text-xs font-semibold text-slate-500 uppercase tracking-wider">
                  <th scope="col" className="px-5 py-3">Nama Pegawai</th>
                  <th scope="col" className="px-4 py-3">Tanggal</th>
                  <th scope="col" className="px-4 py-3 font-mono">Clock In</th>
                  <th scope="col" className="px-4 py-3 font-mono">Clock Out</th>
                  <th scope="col" className="px-4 py-3 text-center">Akurasi GPS</th>
                  <th scope="col" className="px-4 py-3 text-center font-mono">Terlambat</th>
                  <th scope="col" className="px-5 py-3 text-right">Status</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-slate-100">
                {attendances.map((item) => (
                  <tr key={item.id_attendances} className="hover:bg-slate-50/60 transition-colors">
                    <td className="px-5 py-3.5 font-medium text-slate-900">
                      {item.employee?.user?.name || item.employee?.name || `Karyawan #${item.id_employees}`}
                    </td>
                    <td className="px-4 py-3.5 text-xs text-slate-500 font-mono">
                      {item.date}
                    </td>
                    <td className="px-4 py-3.5 text-xs font-mono tabular-nums text-slate-900">
                      {item.clock_in_time ? `${item.clock_in_time.slice(0, 5)} WIB` : "-"}
                    </td>
                    <td className="px-4 py-3.5 text-xs font-mono tabular-nums text-slate-500">
                      {item.clock_out_time ? `${item.clock_out_time.slice(0, 5)} WIB` : "-"}
                    </td>
                    <td className="px-4 py-3.5 text-xs font-mono tabular-nums text-center text-slate-500">
                      {item.clock_in_distance_meters !== null && item.clock_in_distance_meters !== undefined
                        ? `${item.clock_in_distance_meters}m`
                        : "-"}
                    </td>
                    <td className="px-4 py-3.5 text-xs font-mono tabular-nums text-center text-amber-700">
                      {item.late_duration_minutes > 0 ? `${item.late_duration_minutes} menit` : "-"}
                    </td>
                    <td className="px-5 py-3.5 text-right">
                      <StatusBadge
                        status={
                          item.status === "on_time"
                            ? "on_time"
                            : item.status === "present"
                            ? "hadir"
                            : item.status === "late"
                            ? "terlambat"
                            : item.status === "absent"
                            ? "alpha"
                            : "cuti"
                        }
                      />
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
      </Card>
    </div>
  );
}
