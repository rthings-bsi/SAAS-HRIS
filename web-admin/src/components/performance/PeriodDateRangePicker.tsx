"use client";

import React, { useState, useMemo } from "react";
import {
  Calendar,
  ChevronLeft,
  ChevronRight,
  Lock,
  RotateCcw,
} from "lucide-react";

export interface PeriodDateRangePickerProps {
  startDate: string; // Format: YYYY-MM-DD
  endDate: string; // Format: YYYY-MM-DD
  onStartDateChange: (date: string) => void;
  onEndDateChange: (date: string) => void;
  existingPeriods: Array<{
    id_performance_periods?: number;
    name: string;
    start_date: string;
    end_date: string;
    status?: string;
  }>;
}

const MONTH_NAMES = [
  "Januari",
  "Februari",
  "Maret",
  "April",
  "Mei",
  "Juni",
  "Juli",
  "Agustus",
  "September",
  "Oktober",
  "November",
  "Desember",
];

const WEEKDAY_NAMES = ["Min", "Sen", "Sel", "Rab", "Kam", "Jum", "Sab"];

/**
 * Normalizes any date value (UTC ISO timestamp or YYYY-MM-DD) into local YYYY-MM-DD string.
 */
function normalizeToLocalDateIso(val: string | Date | null | undefined): string {
  if (!val) return "";
  if (typeof val === "string") {
    if (val.includes("T")) {
      const d = new Date(val);
      if (isNaN(d.getTime())) return "";
      const y = d.getFullYear();
      const m = String(d.getMonth() + 1).padStart(2, "0");
      const day = String(d.getDate()).padStart(2, "0");
      return `${y}-${m}-${day}`;
    }
    const parts = val.split("-");
    if (parts.length === 3) {
      return val.substring(0, 10);
    }
  }
  const d = new Date(val);
  if (isNaN(d.getTime())) return "";
  const y = d.getFullYear();
  const m = String(d.getMonth() + 1).padStart(2, "0");
  const day = String(d.getDate()).padStart(2, "0");
  return `${y}-${m}-${day}`;
}

/**
 * Formats YYYY-MM-DD to standard Indonesian date display (e.g., "1 Jul 2026").
 */
function formatDisplayDate(iso: string): string {
  if (!iso) return "";
  const parts = iso.split("-");
  if (parts.length === 3) {
    const year = parseInt(parts[0], 10);
    const month = parseInt(parts[1], 10) - 1;
    const day = parseInt(parts[2], 10);
    const d = new Date(year, month, day);
    return d.toLocaleDateString("id-ID", {
      day: "numeric",
      month: "short",
      year: "numeric",
    });
  }
  return iso;
}

export function PeriodDateRangePicker({
  startDate,
  endDate,
  onStartDateChange,
  onEndDateChange,
  existingPeriods,
}: PeriodDateRangePickerProps) {
  // 1. Process and normalize existing periods
  const parsedPeriods = useMemo(() => {
    return existingPeriods
      .map((p) => {
        const startIso = normalizeToLocalDateIso(p.start_date);
        const endIso = normalizeToLocalDateIso(p.end_date);
        return {
          id: p.id_performance_periods,
          name: p.name,
          startIso,
          endIso,
          formattedRange: `${formatDisplayDate(startIso)} s/d ${formatDisplayDate(endIso)}`,
        };
      })
      .filter((p) => p.startIso && p.endIso)
      .sort((a, b) => a.startIso.localeCompare(b.startIso));
  }, [existingPeriods]);

  // 2. Active field selection state ('start' or 'end')
  const [activeField, setActiveField] = useState<"start" | "end">(() => {
    if (startDate && !endDate) return "end";
    return "start";
  });

  const [hoveredDate, setHoveredDate] = useState<string | null>(null);

  // 3. Determine initial viewing month & year
  const [viewDate, setViewDate] = useState<Date>(() => {
    if (startDate) {
      const [y, m] = startDate.split("-").map(Number);
      return new Date(y, m - 1, 1);
    }
    // If there are existing periods, smart jump to the month right after the latest period
    if (parsedPeriods.length > 0) {
      const latestEnd = parsedPeriods[parsedPeriods.length - 1].endIso;
      const [y, m, d] = latestEnd.split("-").map(Number);
      // Next day after latest end date
      const nextDay = new Date(y, m - 1, d + 1);
      return new Date(nextDay.getFullYear(), nextDay.getMonth(), 1);
    }
    return new Date();
  });

  const currentYear = viewDate.getFullYear();
  const currentMonth = viewDate.getMonth();

  // Navigation handlers
  const handlePrevMonth = () => {
    setViewDate(new Date(currentYear, currentMonth - 1, 1));
  };

  const handleNextMonth = () => {
    setViewDate(new Date(currentYear, currentMonth + 1, 1));
  };

  const handleMonthSelect = (monthIndex: number) => {
    setViewDate(new Date(currentYear, monthIndex, 1));
  };

  const handleYearSelect = (yearValue: number) => {
    setViewDate(new Date(yearValue, currentMonth, 1));
  };

  // Find the earliest existing period that starts after the chosen startDate
  const nextBlockedPeriod = useMemo(() => {
    if (!startDate) return null;
    return parsedPeriods.find((p) => p.startIso > startDate) || null;
  }, [startDate, parsedPeriods]);

  const maxSelectableEndDate = nextBlockedPeriod ? nextBlockedPeriod.startIso : null;

  // Calendar cells generation
  const calendarCells = useMemo(() => {
    const firstDayOfWeek = new Date(currentYear, currentMonth, 1).getDay(); // 0 is Sunday
    const daysInMonth = new Date(currentYear, currentMonth + 1, 0).getDate();

    const cells: Array<{
      day: number;
      dateStr: string;
      isBooked: boolean;
      bookedBy?: { name: string; formattedRange: string };
      isBeforeStart: boolean;
      isBeyondNextPeriod: boolean;
      isDisabled: boolean;
      isSelectedStart: boolean;
      isSelectedEnd: boolean;
      isInRange: boolean;
      isHoverRange: boolean;
    }> = [];

    // Prefix empty slots
    for (let i = 0; i < firstDayOfWeek; i++) {
      cells.push({
        day: 0,
        dateStr: "",
        isBooked: false,
        isBeforeStart: false,
        isBeyondNextPeriod: false,
        isDisabled: true,
        isSelectedStart: false,
        isSelectedEnd: false,
        isInRange: false,
        isHoverRange: false,
      });
    }

    // Days of current month
    for (let day = 1; day <= daysInMonth; day++) {
      const dateStr = `${currentYear}-${String(currentMonth + 1).padStart(2, "0")}-${String(day).padStart(2, "0")}`;

      // Check if already booked by an existing registered period
      const booked = parsedPeriods.find(
        (p) => dateStr >= p.startIso && dateStr <= p.endIso
      );

      // Check if before start date when selecting end date
      const isBeforeStart = Boolean(
        activeField === "end" && startDate && dateStr < startDate
      );

      // Check if beyond the next blocked period (cannot cross over an existing period)
      const isBeyondNextPeriod = Boolean(
        activeField === "end" && maxSelectableEndDate && dateStr >= maxSelectableEndDate
      );

      const isDisabled = Boolean(booked || isBeforeStart || isBeyondNextPeriod);

      const isSelectedStart = Boolean(startDate && dateStr === startDate);
      const isSelectedEnd = Boolean(endDate && dateStr === endDate);
      const isInRange = Boolean(
        startDate && endDate && dateStr > startDate && dateStr < endDate
      );
      const isHoverRange = Boolean(
        activeField === "end" &&
          startDate &&
          !endDate &&
          hoveredDate &&
          dateStr > startDate &&
          dateStr <= hoveredDate &&
          (!maxSelectableEndDate || dateStr < maxSelectableEndDate)
      );

      cells.push({
        day,
        dateStr,
        isBooked: Boolean(booked),
        bookedBy: booked
          ? { name: booked.name, formattedRange: booked.formattedRange }
          : undefined,
        isBeforeStart,
        isBeyondNextPeriod,
        isDisabled,
        isSelectedStart,
        isSelectedEnd,
        isInRange,
        isHoverRange,
      });
    }

    return cells;
  }, [
    currentYear,
    currentMonth,
    parsedPeriods,
    activeField,
    startDate,
    endDate,
    hoveredDate,
    maxSelectableEndDate,
  ]);

  // Handle cell click
  const handleDateClick = (dateStr: string) => {
    if (activeField === "start") {
      onStartDateChange(dateStr);
      // If end date is already set and invalid (e.g. before start or overlapping an existing period), reset it
      if (endDate) {
        const isConflict =
          endDate < dateStr ||
          parsedPeriods.some(
            (p) => p.startIso <= endDate && p.endIso >= dateStr
          );
        if (isConflict) {
          onEndDateChange("");
        }
      }
      setActiveField("end");
    } else {
      // Selecting end date
      if (!startDate) {
        onStartDateChange(dateStr);
        setActiveField("end");
      } else {
        onEndDateChange(dateStr);
      }
    }
  };

  const handleReset = () => {
    onStartDateChange("");
    onEndDateChange("");
    setActiveField("start");
  };

  // Calculate day difference for display
  const totalDays = useMemo(() => {
    if (!startDate || !endDate) return null;
    const d1 = new Date(startDate);
    const d2 = new Date(endDate);
    const diff = Math.round((d2.getTime() - d1.getTime()) / (1000 * 60 * 60 * 24)) + 1;
    return diff > 0 ? diff : null;
  }, [startDate, endDate]);

  return (
    <div className="space-y-4">
      {/* 1. Date Range Input Trigger Cards */}
      <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
        {/* Tanggal Mulai Card */}
        <button
          type="button"
          onClick={() => setActiveField("start")}
          className={`relative text-left p-3.5 rounded-2xl border transition-all cursor-pointer min-h-[58px] ${
            activeField === "start"
              ? "border-emerald-600 bg-emerald-50/30 ring-2 ring-emerald-600/20 shadow-xs"
              : "border-slate-200/80 bg-white hover:bg-slate-50/60"
          }`}
          aria-pressed={activeField === "start"}
        >
          <div className="flex items-center justify-between mb-1">
            <span className="text-[11px] font-bold uppercase tracking-wider text-slate-500">
              Tanggal Mulai <span className="text-rose-500">*</span>
            </span>
            {activeField === "start" && (
              <span className="inline-flex items-center px-1.5 py-0.5 rounded-md text-[10px] font-bold bg-emerald-600 text-white">
                Pilih
              </span>
            )}
          </div>
          <div className="flex items-center gap-2">
            <Calendar
              className={`w-4 h-4 ${
                activeField === "start" ? "text-emerald-600" : "text-slate-400"
              }`}
            />
            <span
              className={`text-xs font-semibold ${
                startDate ? "font-mono text-slate-900" : "text-slate-400 font-normal"
              }`}
            >
              {startDate ? formatDisplayDate(startDate) : "Pilih tanggal mulai"}
            </span>
          </div>
        </button>

        {/* Tanggal Akhir Card */}
        <button
          type="button"
          onClick={() => setActiveField("end")}
          className={`relative text-left p-3.5 rounded-2xl border transition-all cursor-pointer min-h-[58px] ${
            activeField === "end"
              ? "border-emerald-600 bg-emerald-50/30 ring-2 ring-emerald-600/20 shadow-xs"
              : "border-slate-200/80 bg-white hover:bg-slate-50/60"
          }`}
          aria-pressed={activeField === "end"}
        >
          <div className="flex items-center justify-between mb-1">
            <span className="text-[11px] font-bold uppercase tracking-wider text-slate-500">
              Tanggal Akhir <span className="text-rose-500">*</span>
            </span>
            {activeField === "end" && (
              <span className="inline-flex items-center px-1.5 py-0.5 rounded-md text-[10px] font-bold bg-emerald-600 text-white">
                Pilih
              </span>
            )}
          </div>
          <div className="flex items-center gap-2">
            <Calendar
              className={`w-4 h-4 ${
                activeField === "end" ? "text-emerald-600" : "text-slate-400"
              }`}
            />
            <span
              className={`text-xs font-semibold ${
                endDate ? "font-mono text-slate-900" : "text-slate-400 font-normal"
              }`}
            >
              {endDate ? formatDisplayDate(endDate) : "Pilih tanggal akhir"}
            </span>
          </div>
        </button>
      </div>

      {/* 2. Interactive Calendar Container */}
      <div className="rounded-2xl border border-slate-200/80 bg-white p-3.5 sm:p-4 shadow-2xs">
        {/* Calendar Header with Month/Year Navigation */}
        <div className="flex flex-wrap items-center justify-between gap-2 pb-3 mb-3 border-b border-slate-100">
          <div className="flex items-center gap-1.5">
            <select
              aria-label="Pilih Bulan"
              value={currentMonth}
              onChange={(e) => handleMonthSelect(Number(e.target.value))}
              className="text-xs font-bold text-slate-800 bg-slate-50 border border-slate-200/80 rounded-xl px-2.5 py-1.5 focus:outline-none focus:ring-2 focus:ring-emerald-600/20 cursor-pointer"
            >
              {MONTH_NAMES.map((name, idx) => (
                <option key={name} value={idx}>
                  {name}
                </option>
              ))}
            </select>

            <select
              aria-label="Pilih Tahun"
              value={currentYear}
              onChange={(e) => handleYearSelect(Number(e.target.value))}
              className="text-xs font-mono font-bold text-slate-800 bg-slate-50 border border-slate-200/80 rounded-xl px-2 py-1.5 focus:outline-none focus:ring-2 focus:ring-emerald-600/20 cursor-pointer"
            >
              {Array.from({ length: 8 }, (_, i) => currentYear - 2 + i).map(
                (yr) => (
                  <option key={yr} value={yr}>
                    {yr}
                  </option>
                )
              )}
            </select>
          </div>

          <div className="flex items-center gap-1">
            {(startDate || endDate) && (
              <button
                type="button"
                onClick={handleReset}
                title="Reset Tanggal"
                className="inline-flex items-center gap-1 px-2 py-1.5 rounded-xl text-[11px] font-semibold text-slate-500 hover:text-slate-800 hover:bg-slate-100 transition-colors cursor-pointer mr-1"
              >
                <RotateCcw className="w-3 h-3" />
                <span>Reset</span>
              </button>
            )}

            <button
              type="button"
              onClick={handlePrevMonth}
              title="Bulan Sebelumnya"
              aria-label="Bulan Sebelumnya"
              className="p-1.5 rounded-xl text-slate-500 hover:text-slate-900 hover:bg-slate-100 transition-colors cursor-pointer min-h-[34px] min-w-[34px] flex items-center justify-center"
            >
              <ChevronLeft className="w-4 h-4" />
            </button>
            <button
              type="button"
              onClick={handleNextMonth}
              title="Bulan Berikutnya"
              aria-label="Bulan Berikutnya"
              className="p-1.5 rounded-xl text-slate-500 hover:text-slate-900 hover:bg-slate-100 transition-colors cursor-pointer min-h-[34px] min-w-[34px] flex items-center justify-center"
            >
              <ChevronRight className="w-4 h-4" />
            </button>
          </div>
        </div>

        {/* Selection Status Prompt */}
        <div className="mb-3 px-3 py-2 rounded-xl bg-slate-50 border border-slate-200/60 flex items-center justify-between text-xs">
          <div className="flex items-center gap-2">
            {activeField === "start" ? (
              <>
                <div className="w-2 h-2 rounded-full bg-emerald-500 animate-pulse" />
                <span className="font-medium text-slate-700">
                  Klik tanggal untuk menentukan{" "}
                  <strong className="text-emerald-700">Tanggal Mulai</strong>
                </span>
              </>
            ) : (
              <>
                <div className="w-2 h-2 rounded-full bg-sky-500 animate-pulse" />
                <span className="font-medium text-slate-700">
                  {startDate ? (
                    <>
                      Mulai: <strong className="font-mono text-slate-900">{formatDisplayDate(startDate)}</strong>. Sekarang klik <strong className="text-sky-700">Tanggal Akhir</strong>
                    </>
                  ) : (
                    "Pilih tanggal awal terlebih dahulu"
                  )}
                </span>
              </>
            )}
          </div>
          {totalDays && (
            <span className="text-[11px] font-semibold font-mono text-emerald-800 bg-emerald-100/70 px-2 py-0.5 rounded-md">
              {totalDays} Hari
            </span>
          )}
        </div>

        {/* Weekday Labels */}
        <div className="grid grid-cols-7 gap-1 text-center mb-1">
          {WEEKDAY_NAMES.map((w, idx) => (
            <div
              key={w}
              className={`text-[11px] font-bold py-1 select-none ${
                idx === 0 || idx === 6 ? "text-rose-500" : "text-slate-500"
              }`}
            >
              {w}
            </div>
          ))}
        </div>

        {/* Days Grid */}
        <div className="grid grid-cols-7 gap-1">
          {calendarCells.map((cell, idx) => {
            if (cell.day === 0) {
              return <div key={`empty-${idx}`} className="h-9 w-full" />;
            }

            // Determine styling based on disabled/booked, selected, or available
            let buttonClasses =
              "h-9 w-full text-xs font-medium rounded-xl transition-all flex items-center justify-center relative ";

            if (cell.isBooked) {
              // Abu-abu & tidak bisa dipilih
              buttonClasses +=
                "bg-slate-100 text-slate-400 border border-slate-200/50 line-through cursor-not-allowed select-none opacity-60";
            } else if (cell.isBeforeStart || cell.isBeyondNextPeriod) {
              // Abu-abu karena constraint rentang
              buttonClasses +=
                "bg-slate-50 text-slate-300 border border-transparent cursor-not-allowed select-none";
            } else if (cell.isSelectedStart || cell.isSelectedEnd) {
              // Terpilih
              buttonClasses +=
                "bg-[#16A34A] text-white font-bold shadow-xs hover:bg-[#15803D] cursor-pointer z-10";
            } else if (cell.isInRange) {
              // Di dalam rentang terpilih
              buttonClasses +=
                "bg-emerald-50 text-emerald-800 font-semibold border-y border-emerald-100 rounded-none hover:bg-emerald-100 cursor-pointer";
            } else if (cell.isHoverRange) {
              // Hover preview
              buttonClasses +=
                "bg-emerald-50/70 text-emerald-700 border-y border-dashed border-emerald-200 rounded-none cursor-pointer";
            } else {
              // Bebas / Tersedia
              buttonClasses +=
                "bg-white text-slate-800 hover:bg-emerald-50 hover:text-emerald-700 hover:border-emerald-200 border border-slate-100 cursor-pointer";
            }

            // Title tooltip
            let tooltip = cell.dateStr;
            if (cell.bookedBy) {
              tooltip = `Terkunci: Sudah terdaftar pada '${cell.bookedBy.name}' (${cell.bookedBy.formattedRange})`;
            } else if (cell.isBeforeStart) {
              tooltip = `Tidak dapat dipilih: Sebelum tanggal mulai (${formatDisplayDate(startDate)})`;
            } else if (cell.isBeyondNextPeriod && nextBlockedPeriod) {
              tooltip = `Tidak dapat melompati periode '${nextBlockedPeriod.name}' (${nextBlockedPeriod.formattedRange})`;
            }

            return (
              <button
                key={cell.dateStr}
                type="button"
                disabled={cell.isDisabled}
                onClick={() => handleDateClick(cell.dateStr)}
                onMouseEnter={() => setHoveredDate(cell.dateStr)}
                onMouseLeave={() => setHoveredDate(null)}
                title={tooltip}
                aria-label={tooltip}
                aria-disabled={cell.isDisabled}
                aria-pressed={cell.isSelectedStart || cell.isSelectedEnd}
                className={buttonClasses}
              >
                <span>{cell.day}</span>
                {cell.isBooked && (
                  <span
                    className="absolute bottom-1 w-1 h-1 rounded-full bg-slate-400"
                    aria-hidden="true"
                  />
                )}
              </button>
            );
          })}
        </div>

        {/* 3. Visual Legend */}
        <div className="mt-4 pt-3 border-t border-slate-100 flex flex-wrap items-center gap-3.5 text-[11px] text-slate-600">
          <div className="flex items-center gap-1.5">
            <span className="w-3.5 h-3.5 rounded-md bg-[#16A34A] text-white flex items-center justify-center shadow-2xs font-bold text-[9px]">
              ✓
            </span>
            <span className="font-semibold text-slate-800">Terpilih</span>
          </div>

          <div className="flex items-center gap-1.5">
            <span className="w-3.5 h-3.5 rounded-md bg-white border border-slate-300" />
            <span>Tersedia</span>
          </div>

          <div className="flex items-center gap-1.5">
            <span className="w-3.5 h-3.5 rounded-md bg-slate-100 border border-slate-300 text-slate-400 flex items-center justify-center font-bold text-[9px] line-through">
              —
            </span>
            <span className="font-semibold text-slate-500">Terkunci (Sudah Terdaftar)</span>
          </div>
        </div>
      </div>

      {/* 4. Registered Periods Notice List */}
      {parsedPeriods.length > 0 && (
        <div className="rounded-xl border border-slate-200/70 bg-slate-50/70 p-3 text-xs">
          <div className="flex items-center gap-1.5 text-slate-600 font-semibold mb-2">
            <Lock className="w-3.5 h-3.5 text-slate-500" />
            <span>Periode yang Sudah Terdaftar (Terkunci):</span>
          </div>
          <div className="flex flex-wrap gap-1.5">
            {parsedPeriods.map((p) => (
              <span
                key={p.id ?? p.name}
                className="inline-flex items-center gap-1 px-2.5 py-1 rounded-lg bg-white border border-slate-200 text-[11px] text-slate-700 font-medium shadow-2xs"
              >
                <span className="font-bold text-slate-900">{p.name}:</span>
                <span className="font-mono text-slate-600">{p.formattedRange}</span>
              </span>
            ))}
          </div>
          <p className="mt-2 text-[11px] text-slate-500">
            Tanggal yang telah terdaftar di atas secara otomatis di-abu-abu dan tidak dapat dipilih untuk periode baru guna mencegah bentrok data evaluasi.
          </p>
        </div>
      )}
    </div>
  );
}
