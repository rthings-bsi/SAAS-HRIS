"use client";

import React, { useState, useMemo } from "react";
import {
  Calendar as CalendarIcon,
  ChevronLeft,
  ChevronRight,
  RotateCcw,
  Check,
  CalendarRange,
} from "lucide-react";

export interface SingleDateRangePickerProps {
  startDate: string; // Format: YYYY-MM-DD
  endDate: string; // Format: YYYY-MM-DD
  onChange: (range: { startDate: string; endDate: string }) => void;
  label?: string;
  required?: boolean;
  minDate?: string; // Optional: YYYY-MM-DD
  maxDate?: string; // Optional: YYYY-MM-DD
  helperText?: string;
  defaultExpanded?: boolean;
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
 * Format YYYY-MM-DD to standard Indonesian date display (e.g. "20 Okt 2026")
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

/**
 * Helper to get local date ISO string YYYY-MM-DD from a Date object
 */
function toLocalIso(d: Date): string {
  const y = d.getFullYear();
  const m = String(d.getMonth() + 1).padStart(2, "0");
  const day = String(d.getDate()).padStart(2, "0");
  return `${y}-${m}-${day}`;
}

export function SingleDateRangePicker({
  startDate,
  endDate,
  onChange,
  label = "Rentang Tanggal Cuti",
  required = false,
  minDate,
  maxDate,
  helperText,
  defaultExpanded = true,
}: SingleDateRangePickerProps) {
  const [isExpanded, setIsExpanded] = useState(defaultExpanded);
  const [hoveredDate, setHoveredDate] = useState<string | null>(null);

  // Active step: "start" (selecting start date) or "end" (selecting end date)
  const [selectionStep, setSelectionStep] = useState<"start" | "end">(() => {
    if (startDate && !endDate) return "end";
    return "start";
  });

  // Calendar view month & year
  const [viewDate, setViewDate] = useState<Date>(() => {
    if (startDate) {
      const [y, m] = startDate.split("-").map(Number);
      return new Date(y, m - 1, 1);
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

  const handleMonthChange = (newMonth: number) => {
    setViewDate(new Date(currentYear, newMonth, 1));
  };

  const handleYearChange = (newYear: number) => {
    setViewDate(new Date(newYear, currentMonth, 1));
  };

  // Day cell click handler
  const handleDateClick = (dateStr: string) => {
    if (selectionStep === "start") {
      // First click: sets start date, clears end date, and transitions to step 'end'
      onChange({ startDate: dateStr, endDate: "" });
      setSelectionStep("end");
    } else {
      // Second click:
      if (!startDate) {
        onChange({ startDate: dateStr, endDate: "" });
        setSelectionStep("end");
      } else if (dateStr < startDate) {
        // User clicked an earlier date: treat as new start date
        onChange({ startDate: dateStr, endDate: "" });
        setSelectionStep("end");
      } else {
        // Valid end date (>= start date, including same date for 1-day leave)
        onChange({ startDate, endDate: dateStr });
        setSelectionStep("start"); // Ready for next cycle if user wants to re-pick
      }
    }
  };

  // Reset handler
  const handleReset = (e?: React.MouseEvent) => {
    if (e) e.stopPropagation();
    onChange({ startDate: "", endDate: "" });
    setSelectionStep("start");
    setHoveredDate(null);
  };

  // Preset shortcuts handler
  const applyPreset = (daysCount: number, offsetDays = 0) => {
    const start = new Date();
    start.setDate(start.getDate() + offsetDays);

    const end = new Date(start);
    end.setDate(end.getDate() + (daysCount - 1));

    const startIso = toLocalIso(start);
    const endIso = toLocalIso(end);

    setViewDate(new Date(start.getFullYear(), start.getMonth(), 1));
    onChange({ startDate: startIso, endDate: endIso });
    setSelectionStep("start");
    setHoveredDate(null);
  };

  // Calculate day difference for display
  const durationDays = useMemo(() => {
    if (!startDate) return 0;
    if (!endDate) return 1;
    const d1 = new Date(startDate);
    const d2 = new Date(endDate);
    const diff = Math.round((d2.getTime() - d1.getTime()) / (1000 * 60 * 60 * 24)) + 1;
    return diff > 0 ? diff : 0;
  }, [startDate, endDate]);

  // Calendar cells generation
  const calendarCells = useMemo(() => {
    const firstDayOfWeek = new Date(currentYear, currentMonth, 1).getDay(); // 0: Sunday
    const daysInMonth = new Date(currentYear, currentMonth + 1, 0).getDate();

    const cells: Array<{
      day: number;
      dateStr: string;
      isDisabled: boolean;
      isSelectedStart: boolean;
      isSelectedEnd: boolean;
      isInRange: boolean;
      isHoverRange: boolean;
      isToday: boolean;
    }> = [];

    const todayIso = toLocalIso(new Date());

    // Leading empty slots
    for (let i = 0; i < firstDayOfWeek; i++) {
      cells.push({
        day: 0,
        dateStr: "",
        isDisabled: true,
        isSelectedStart: false,
        isSelectedEnd: false,
        isInRange: false,
        isHoverRange: false,
        isToday: false,
      });
    }

    // Days in current month
    for (let day = 1; day <= daysInMonth; day++) {
      const dateStr = `${currentYear}-${String(currentMonth + 1).padStart(2, "0")}-${String(
        day
      ).padStart(2, "0")}`;

      const isDisabled = Boolean(
        (minDate && dateStr < minDate) || (maxDate && dateStr > maxDate)
      );

      const isSelectedStart = startDate === dateStr;
      const isSelectedEnd = endDate === dateStr;

      // In committed range
      const isInRange = Boolean(
        startDate &&
          endDate &&
          dateStr >= startDate &&
          dateStr <= endDate &&
          startDate !== endDate
      );

      // In temporary hover preview range
      const isHoverRange = Boolean(
        selectionStep === "end" &&
          startDate &&
          !endDate &&
          hoveredDate &&
          hoveredDate >= startDate &&
          dateStr >= startDate &&
          dateStr <= hoveredDate
      );

      cells.push({
        day,
        dateStr,
        isDisabled,
        isSelectedStart,
        isSelectedEnd,
        isInRange,
        isHoverRange,
        isToday: dateStr === todayIso,
      });
    }

    return cells;
  }, [currentYear, currentMonth, minDate, maxDate, startDate, endDate, selectionStep, hoveredDate]);

  // Generate Year options (current - 2 to current + 3)
  const yearOptions = useMemo(() => {
    const nowY = new Date().getFullYear();
    const years = [];
    for (let y = nowY - 2; y <= nowY + 3; y++) {
      years.push(y);
    }
    return years;
  }, []);

  return (
    <div className="space-y-2">
      {/* Label & Active Status */}
      <div className="flex items-center justify-between">
        <label className="block text-xs font-semibold text-slate-700">
          {label} {required && <span className="text-rose-500">*</span>}
        </label>
        {startDate && (
          <button
            type="button"
            onClick={handleReset}
            className="text-[11px] font-medium text-slate-500 hover:text-rose-600 transition-colors inline-flex items-center gap-1 cursor-pointer"
          >
            <RotateCcw className="w-3 h-3" />
            <span>Reset</span>
          </button>
        )}
      </div>

      {/* Unified Trigger / Summary Display Box */}
      <div
        onClick={() => setIsExpanded(!isExpanded)}
        role="button"
        tabIndex={0}
        onKeyDown={(e) => {
          if (e.key === "Enter" || e.key === " ") {
            e.preventDefault();
            setIsExpanded(!isExpanded);
          }
        }}
        className={`w-full p-3 rounded-2xl border transition-all cursor-pointer flex items-center justify-between ${
          isExpanded
            ? "border-emerald-600/70 bg-emerald-50/20 ring-2 ring-emerald-600/20 shadow-xs"
            : "border-slate-200/90 bg-white hover:bg-slate-50/60 shadow-2xs"
        }`}
        aria-expanded={isExpanded}
        aria-label="Tampilkan atau sembunyikan kalender pemilihan tanggal"
      >
        <div className="flex items-center gap-2.5 min-w-0">
          <div
            className={`w-9 h-9 rounded-xl flex items-center justify-center flex-shrink-0 transition-colors ${
              startDate
                ? "bg-[#16A34A] text-white shadow-2xs"
                : "bg-slate-100 text-slate-500"
            }`}
          >
            <CalendarRange className="w-4 h-4" aria-hidden="true" />
          </div>
          <div className="min-w-0 text-left">
            <div className="text-[10px] font-bold uppercase tracking-wider text-slate-400">
              Rentang Pengajuan
            </div>
            <div className="text-xs font-bold text-slate-900 truncate">
              {startDate && endDate ? (
                <span>
                  {formatDisplayDate(startDate)}
                  {startDate === endDate ? " (1 Hari)" : ` s/d ${formatDisplayDate(endDate)}`}
                </span>
              ) : startDate ? (
                <span className="text-emerald-700 font-semibold">
                  Mulai: {formatDisplayDate(startDate)} (Pilih tanggal selesai)
                </span>
              ) : (
                <span className="text-slate-400 font-normal">
                  Klik untuk memilih rentang tanggal cuti
                </span>
              )}
            </div>
          </div>
        </div>

        <div className="flex items-center gap-2 flex-shrink-0">
          {startDate && endDate && (
            <span className="px-2 py-0.5 rounded-full text-[10px] font-extrabold bg-[#DCFCE7] text-[#15803D] border border-[#BBF7D0]">
              {durationDays} Hari
            </span>
          )}
          <span className="text-xs font-semibold text-slate-500 hover:text-slate-700 px-1 py-0.5 rounded-md">
            {isExpanded ? "Tutup" : "Pilih"}
          </span>
        </div>
      </div>

      {/* Interactive Single Calendar Container */}
      {isExpanded && (
        <div className="p-3.5 rounded-2xl border border-slate-200/80 bg-white shadow-xs space-y-3 animate-in fade-in duration-150">
          {/* Quick Presets Chips */}
          <div className="flex items-center gap-1.5 overflow-x-auto pb-1 text-[11px] scrollbar-none">
            <span className="text-slate-400 text-[10px] font-medium mr-0.5">Pintasan:</span>
            <button
              type="button"
              onClick={() => applyPreset(1, 0)}
              className="px-2.5 py-1 rounded-xl bg-slate-100 hover:bg-emerald-50 hover:text-emerald-700 font-medium text-slate-600 transition-colors cursor-pointer shrink-0"
            >
              Hari Ini
            </button>
            <button
              type="button"
              onClick={() => applyPreset(1, 1)}
              className="px-2.5 py-1 rounded-xl bg-slate-100 hover:bg-emerald-50 hover:text-emerald-700 font-medium text-slate-600 transition-colors cursor-pointer shrink-0"
            >
              Besok
            </button>
            <button
              type="button"
              onClick={() => applyPreset(3, 0)}
              className="px-2.5 py-1 rounded-xl bg-slate-100 hover:bg-emerald-50 hover:text-emerald-700 font-medium text-slate-600 transition-colors cursor-pointer shrink-0"
            >
              3 Hari
            </button>
            <button
              type="button"
              onClick={() => applyPreset(5, 0)}
              className="px-2.5 py-1 rounded-xl bg-slate-100 hover:bg-emerald-50 hover:text-emerald-700 font-medium text-slate-600 transition-colors cursor-pointer shrink-0"
            >
              5 Hari Kerja
            </button>
            <button
              type="button"
              onClick={() => applyPreset(7, 0)}
              className="px-2.5 py-1 rounded-xl bg-slate-100 hover:bg-emerald-50 hover:text-emerald-700 font-medium text-slate-600 transition-colors cursor-pointer shrink-0"
            >
              1 Minggu
            </button>
          </div>

          {/* Calendar Header Navigation */}
          <div className="flex items-center justify-between pt-1">
            <div className="flex items-center gap-1.5">
              <select
                aria-label="Pilih Bulan Kalender"
                value={currentMonth}
                onChange={(e) => handleMonthChange(Number(e.target.value))}
                className="text-xs font-bold text-slate-800 bg-slate-50 border border-slate-200/80 rounded-xl px-2.5 py-1.5 focus:outline-none focus:ring-1 focus:ring-emerald-600 cursor-pointer"
              >
                {MONTH_NAMES.map((m, idx) => (
                  <option key={m} value={idx}>
                    {m}
                  </option>
                ))}
              </select>

              <select
                aria-label="Pilih Tahun Kalender"
                value={currentYear}
                onChange={(e) => handleYearChange(Number(e.target.value))}
                className="text-xs font-bold text-slate-800 bg-slate-50 border border-slate-200/80 rounded-xl px-2.5 py-1.5 focus:outline-none focus:ring-1 focus:ring-emerald-600 cursor-pointer"
              >
                {yearOptions.map((y) => (
                  <option key={y} value={y}>
                    {y}
                  </option>
                ))}
              </select>
            </div>

            <div className="flex items-center gap-1">
              <button
                type="button"
                onClick={handlePrevMonth}
                aria-label="Bulan Sebelumnya"
                className="p-1.5 rounded-xl border border-slate-200/80 hover:bg-slate-50 active:scale-95 text-slate-600 transition-all cursor-pointer min-w-[32px] min-h-[32px] flex items-center justify-center"
              >
                <ChevronLeft className="w-4 h-4" />
              </button>
              <button
                type="button"
                onClick={handleNextMonth}
                aria-label="Bulan Berikutnya"
                className="p-1.5 rounded-xl border border-slate-200/80 hover:bg-slate-50 active:scale-95 text-slate-600 transition-all cursor-pointer min-w-[32px] min-h-[32px] flex items-center justify-center"
              >
                <ChevronRight className="w-4 h-4" />
              </button>
            </div>
          </div>

          {/* Weekday Header */}
          <div className="grid grid-cols-7 gap-1 text-center">
            {WEEKDAY_NAMES.map((w, idx) => (
              <span
                key={w}
                className={`text-[11px] font-bold py-1 ${
                  idx === 0 || idx === 6 ? "text-rose-500" : "text-slate-500"
                }`}
              >
                {w}
              </span>
            ))}
          </div>

          {/* Calendar Grid of Days */}
          <div
            className="grid grid-cols-7 gap-y-1 gap-x-0.5"
            onMouseLeave={() => setHoveredDate(null)}
          >
            {calendarCells.map((cell, idx) => {
              if (cell.day === 0) {
                return <div key={`empty-${idx}`} className="h-9 w-full" />;
              }

              const isStart = cell.isSelectedStart;
              const isEnd = cell.isSelectedEnd;
              const isSingleDay = startDate && endDate && startDate === endDate && isStart;
              const inRange = cell.isInRange || cell.isHoverRange;

              // Background styling for range connector
              let containerStyle = "relative flex items-center justify-center h-9 w-full";
              if (inRange) {
                containerStyle += " bg-emerald-100/70";
              }
              if (isStart && endDate && !isSingleDay) {
                containerStyle += " rounded-l-xl bg-gradient-to-r from-transparent 50% to-emerald-100/70 50%";
              }
              if (isEnd && startDate && !isSingleDay) {
                containerStyle += " rounded-r-xl bg-gradient-to-l from-transparent 50% to-emerald-100/70 50%";
              }

              // Button pill styling
              let buttonStyle =
                "w-8 h-8 rounded-xl text-xs font-semibold flex items-center justify-center transition-all cursor-pointer z-10 ";

              if (isStart || isEnd) {
                buttonStyle +=
                  " bg-[#16A34A] text-white font-extrabold shadow-sm scale-105";
              } else if (inRange) {
                buttonStyle += " text-emerald-900 font-bold hover:bg-emerald-200/60";
              } else if (cell.isToday) {
                buttonStyle +=
                  " border border-emerald-600/80 text-emerald-700 font-bold hover:bg-emerald-50";
              } else if (cell.isDisabled) {
                buttonStyle += " text-slate-300 cursor-not-allowed";
              } else {
                buttonStyle += " text-slate-700 hover:bg-slate-100 active:scale-95";
              }

              return (
                <div key={cell.dateStr} className={containerStyle}>
                  <button
                    type="button"
                    disabled={cell.isDisabled}
                    onClick={() => handleDateClick(cell.dateStr)}
                    onMouseEnter={() => {
                      if (selectionStep === "end" && startDate) {
                        setHoveredDate(cell.dateStr);
                      }
                    }}
                    className={buttonStyle}
                    aria-label={`Pilih tanggal ${cell.dateStr}`}
                  >
                    {cell.day}
                  </button>
                </div>
              );
            })}
          </div>

          {/* Guidance Status Footer */}
          <div className="pt-2 border-t border-slate-100 flex items-center justify-between text-[11px]">
            <div className="text-slate-500 flex items-center gap-1.5">
              {!startDate ? (
                <>
                  <span className="w-2 h-2 rounded-full bg-slate-300" />
                  <span>Klik tanggal mulai cuti</span>
                </>
              ) : !endDate ? (
                <>
                  <span className="w-2 h-2 rounded-full bg-amber-400 animate-pulse" />
                  <span className="text-amber-800 font-medium">
                    Pilih tanggal selesai (atau klik tanggal sama untuk cuti 1 hari)
                  </span>
                </>
              ) : (
                <>
                  <Check className="w-3.5 h-3.5 text-emerald-600" />
                  <span className="text-emerald-700 font-bold">
                    Rentang {durationDays} hari siap diajukan
                  </span>
                </>
              )}
            </div>

            {startDate && endDate && (
              <button
                type="button"
                onClick={() => setIsExpanded(false)}
                className="text-[11px] font-bold text-emerald-700 hover:text-emerald-800 bg-emerald-50 px-2 py-0.5 rounded-lg border border-emerald-200 transition-colors cursor-pointer"
              >
                Selesai
              </button>
            )}
          </div>
        </div>
      )}

      {helperText && <p className="text-[11px] text-slate-400">{helperText}</p>}
    </div>
  );
}
