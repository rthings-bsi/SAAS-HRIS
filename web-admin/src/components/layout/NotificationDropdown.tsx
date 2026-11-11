"use client";

import { useState, useEffect, useRef, useCallback } from "react";
import { createPortal } from "react-dom";
import { useRouter } from "next/navigation";
import {
  Bell,
  CheckCheck,
  Calendar,
  Clock,
  Banknote,
  UserCheck,
  Award,
  Info,
  Trash2,
  RotateCcw,
  ExternalLink,
  X,
  AlertCircle,
} from "lucide-react";
import { apiClient } from "@/lib/axios";
import { formatRelativeTime } from "@/lib/utils";
import type {
  ApiResponse,
  NotificationItem,
  NotificationListResponse,
  NotificationUnreadCountResponse,
  NotificationType,
} from "@/types";

export function NotificationDropdown() {
  const router = useRouter();
  const [isOpen, setIsOpen] = useState(false);
  const [activeTab, setActiveTab] = useState<"all" | "unread">("all");
  const [notifications, setNotifications] = useState<NotificationItem[]>([]);
  const [totalNotifications, setTotalNotifications] = useState<number | null>(null);
  const [unreadCount, setUnreadCount] = useState<number>(0);
  const [isLoading, setIsLoading] = useState(false);
  const [isMarkingAll, setIsMarkingAll] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [actionError, setActionError] = useState<string | null>(null);
  const [isMounted, setIsMounted] = useState(false);

  const containerRef = useRef<HTMLDivElement>(null);
  const triggerRef = useRef<HTMLButtonElement>(null);
  const mobileSheetRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    setIsMounted(true);
  }, []);

  const fetchUnreadCount = useCallback(async () => {
    try {
      const res = await apiClient.get<ApiResponse<NotificationUnreadCountResponse>>(
        "/notifications/unread-count"
      );
      if (res.data?.success && res.data?.data) {
        setUnreadCount(res.data.data.unread_count);
      }
    } catch {
      // Quietly ignore background polling failures.
    }
  }, []);

  const fetchNotifications = useCallback(async () => {
    setIsLoading(true);
    setError(null);
    setActionError(null);
    try {
      const res = await apiClient.get<ApiResponse<NotificationListResponse>>(
        "/notifications",
        {
          params: { per_page: 30 },
        }
      );
      if (res.data?.success && res.data?.data) {
        const list = res.data.data.notifications || [];
        setNotifications(list);
        setUnreadCount(res.data.data.unread_count ?? 0);
        setTotalNotifications(res.data.data.pagination?.total ?? list.length);
      }
    } catch (err: unknown) {
      const message =
        err instanceof Error
          ? err.message
          : "Gagal memuat notifikasi. Silakan periksa koneksi Anda.";
      setError(message);
    } finally {
      setIsLoading(false);
    }
  }, []);

  // Poll unread count every 30s and refresh immediately when tab regains focus.
  useEffect(() => {
    fetchUnreadCount();
    const interval = setInterval(fetchUnreadCount, 30000);
    const handleVisibilityOrFocus = () => {
      if (document.visibilityState === "visible") {
        fetchUnreadCount();
        if (isOpen) {
          fetchNotifications();
        }
      }
    };
    window.addEventListener("focus", handleVisibilityOrFocus);
    document.addEventListener("visibilitychange", handleVisibilityOrFocus);
    return () => {
      clearInterval(interval);
      window.removeEventListener("focus", handleVisibilityOrFocus);
      document.removeEventListener("visibilitychange", handleVisibilityOrFocus);
    };
  }, [fetchUnreadCount, fetchNotifications, isOpen]);

  useEffect(() => {
    if (isOpen) {
      fetchNotifications();
    }
  }, [isOpen, fetchNotifications]);

  useEffect(() => {
    const handleClickOutside = (event: MouseEvent) => {
      const target = event.target as Node;
      if (
        containerRef.current &&
        !containerRef.current.contains(target) &&
        (!mobileSheetRef.current || !mobileSheetRef.current.contains(target))
      ) {
        setIsOpen(false);
      }
    };

    if (isOpen) {
      document.addEventListener("mousedown", handleClickOutside);
    }
    return () => {
      document.removeEventListener("mousedown", handleClickOutside);
    };
  }, [isOpen]);

  useEffect(() => {
    const handleKeyDown = (e: KeyboardEvent) => {
      if (e.key === "Escape" && isOpen) {
        setIsOpen(false);
        triggerRef.current?.focus();
      }
    };
    window.addEventListener("keydown", handleKeyDown);
    return () => window.removeEventListener("keydown", handleKeyDown);
  }, [isOpen]);

  useEffect(() => {
    if (isOpen && typeof window !== "undefined" && window.innerWidth < 640) {
      const originalOverflow = document.body.style.overflow;
      document.body.style.overflow = "hidden";
      return () => {
        document.body.style.overflow = originalOverflow;
      };
    }
  }, [isOpen]);

  const handleMarkAllAsRead = async () => {
    if (unreadCount === 0 || isMarkingAll) return;
    setIsMarkingAll(true);
    setActionError(null);
    const prevNotifications = notifications;
    const prevUnread = unreadCount;

    setNotifications((prev) =>
      prev.map((notif) => ({
        ...notif,
        is_read: true,
        read_at: notif.read_at || new Date().toISOString(),
      }))
    );
    setUnreadCount(0);

    try {
      const res = await apiClient.put<ApiResponse<{ marked_count: number; unread_count: number }>>(
        "/notifications/read-all"
      );
      if (!res.data?.success) {
        throw new Error("Gagal menandai seluruh notifikasi.");
      }
    } catch {
      setNotifications(prevNotifications);
      setUnreadCount(prevUnread);
      setActionError("Gagal menandai seluruh notifikasi sebagai dibaca.");
    } finally {
      setIsMarkingAll(false);
    }
  };

  const handleNotificationClick = async (notif: NotificationItem) => {
    setActionError(null);
    if (!notif.is_read) {
      const prevNotifications = notifications;
      const prevUnread = unreadCount;

      setNotifications((prev) =>
        prev.map((item) =>
          item.id_notifications === notif.id_notifications
            ? { ...item, is_read: true, read_at: new Date().toISOString() }
            : item
        )
      );
      setUnreadCount((prev) => Math.max(0, prev - 1));

      try {
        const res = await apiClient.put<ApiResponse<{ unread_count?: number }>>(
          `/notifications/${notif.id_notifications}/read`
        );
        if (typeof res.data?.data?.unread_count === "number") {
          setUnreadCount(res.data.data.unread_count);
        }
      } catch {
        setNotifications(prevNotifications);
        setUnreadCount(prevUnread);
        setActionError("Gagal memperbarui status notifikasi.");
      }
    }

    setIsOpen(false);

    const targetUrl = notif.data?.url;
    if (targetUrl && typeof targetUrl === "string" && targetUrl.startsWith("/")) {
      router.push(targetUrl);
    }
  };

  const handleDeleteNotification = async (
    e: React.MouseEvent,
    id: number,
    wasUnread: boolean
  ) => {
    e.stopPropagation();
    setActionError(null);
    const prevNotifications = notifications;
    const prevUnread = unreadCount;
    const prevTotal = totalNotifications;

    setNotifications((prev) =>
      prev.filter((item) => item.id_notifications !== id)
    );
    if (wasUnread) {
      setUnreadCount((prev) => Math.max(0, prev - 1));
    }
    if (typeof prevTotal === "number") {
      setTotalNotifications(Math.max(0, prevTotal - 1));
    }

    try {
      const res = await apiClient.delete<ApiResponse<{ unread_count?: number }>>(
        `/notifications/${id}`
      );
      if (typeof res.data?.data?.unread_count === "number") {
        setUnreadCount(res.data.data.unread_count);
      }
    } catch {
      setNotifications(prevNotifications);
      setUnreadCount(prevUnread);
      setTotalNotifications(prevTotal);
      setActionError("Gagal menghapus notifikasi. Silakan coba lagi.");
    }
  };

  const getTypeConfig = (type: NotificationType) => {
    switch (type) {
      case "leave":
        return {
          icon: <Calendar className="w-4 h-4 text-emerald-700" aria-hidden="true" />,
          bg: "bg-emerald-50 border-emerald-200/70 text-emerald-700",
          label: "Cuti",
        };
      case "overtime":
        return {
          icon: <Clock className="w-4 h-4 text-amber-800" aria-hidden="true" />,
          bg: "bg-amber-50 border-amber-200/70 text-amber-800",
          label: "Lembur",
        };
      case "payroll":
        return {
          icon: <Banknote className="w-4 h-4 text-blue-700" aria-hidden="true" />,
          bg: "bg-blue-50 border-blue-200/70 text-blue-700",
          label: "Penggajian",
        };
      case "attendance":
        return {
          icon: <UserCheck className="w-4 h-4 text-purple-700" aria-hidden="true" />,
          bg: "bg-purple-50 border-purple-200/70 text-purple-700",
          label: "Presensi",
        };
      case "performance":
        return {
          icon: <Award className="w-4 h-4 text-indigo-700" aria-hidden="true" />,
          bg: "bg-indigo-50 border-indigo-200/70 text-indigo-700",
          label: "Kinerja",
        };
      default:
        return {
          icon: <Info className="w-4 h-4 text-slate-700" aria-hidden="true" />,
          bg: "bg-slate-100 border-slate-200 text-slate-700",
          label: "Sistem",
        };
    }
  };

  const displayedNotifications =
    activeTab === "unread"
      ? notifications.filter((item) => !item.is_read)
      : notifications;

  const resolvedAllCount =
    totalNotifications !== null ? totalNotifications : notifications.length;
  const allTabLabel =
    isLoading && notifications.length === 0 && totalNotifications === null
      ? "Semua"
      : `Semua (${resolvedAllCount})`;

  const renderNotificationBody = (isMobile: boolean) => (
    <>
      {/* Filter Tabs: Semua / Belum Dibaca */}
      <div className="px-3.5 pt-2.5 pb-2 flex items-center gap-2 border-b border-slate-100 bg-white flex-shrink-0">
        <button
          type="button"
          onClick={() => setActiveTab("all")}
          className={`min-h-[44px] sm:min-h-[36px] px-3.5 py-1.5 rounded-xl text-xs font-semibold transition-all cursor-pointer focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-emerald-600 ${
            activeTab === "all"
              ? "bg-[#0B2545] text-white shadow-2xs"
              : "text-slate-700 hover:bg-slate-100 hover:text-slate-900"
          }`}
        >
          {allTabLabel}
        </button>
        <button
          type="button"
          onClick={() => setActiveTab("unread")}
          className={`min-h-[44px] sm:min-h-[36px] px-3.5 py-1.5 rounded-xl text-xs font-semibold transition-all cursor-pointer focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-emerald-600 ${
            activeTab === "unread"
              ? "bg-[#0B2545] text-white shadow-2xs"
              : "text-slate-700 hover:bg-slate-100 hover:text-slate-900"
          }`}
        >
          Belum Dibaca ({unreadCount})
        </button>
      </div>

      {/* Inline Action Error Feedback */}
      {actionError && (
        <div
          role="alert"
          className="px-3.5 py-2 bg-rose-50 border-b border-rose-200 flex items-center justify-between gap-2 text-xs text-rose-800 flex-shrink-0"
        >
          <div className="flex items-center gap-2 min-w-0">
            <AlertCircle className="w-4 h-4 flex-shrink-0 text-rose-700" aria-hidden="true" />
            <span className="truncate font-medium">{actionError}</span>
          </div>
          <button
            type="button"
            onClick={() => setActionError(null)}
            aria-label="Tutup pesan galat"
            className="min-w-[32px] min-h-[32px] flex items-center justify-center rounded-md text-rose-700 hover:bg-rose-100 cursor-pointer"
          >
            <X className="w-3.5 h-3.5" aria-hidden="true" />
          </button>
        </div>
      )}

      {/* Content Area with Empty, Loading, and Error States */}
      <div className={`${isMobile ? "max-h-[55vh]" : "max-h-96"} overflow-y-auto divide-y divide-slate-100 overscroll-contain flex-1`}>
        {isLoading && notifications.length === 0 && (
          <div className="p-4 space-y-3" aria-busy="true" aria-label="Memuat notifikasi">
            {[1, 2, 3].map((i) => (
              <div key={i} className="flex gap-3 animate-pulse">
                <div className="w-9 h-9 rounded-xl bg-slate-200 flex-shrink-0" />
                <div className="flex-1 space-y-2">
                  <div className="h-3.5 bg-slate-200 rounded w-2/3" />
                  <div className="h-3 bg-slate-100 rounded w-full" />
                  <div className="h-2.5 bg-slate-100 rounded w-1/3" />
                </div>
              </div>
            ))}
          </div>
        )}

        {!isLoading && error && (
          <div className="p-6 text-center space-y-3">
            <div className="w-10 h-10 mx-auto rounded-xl bg-rose-50 border border-rose-200 flex items-center justify-center text-rose-700">
              <Info className="w-5 h-5" aria-hidden="true" />
            </div>
            <div>
              <h4 className="text-xs font-bold text-slate-900">
                Gagal Memuat Notifikasi
              </h4>
              <p className="text-xs text-slate-600 mt-0.5">{error}</p>
            </div>
            <button
              type="button"
              onClick={fetchNotifications}
              className="inline-flex items-center justify-center gap-1.5 min-h-[44px] px-4 py-2 text-xs font-semibold rounded-lg bg-slate-100 hover:bg-slate-200 text-slate-800 transition-colors cursor-pointer focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-emerald-600"
            >
              <RotateCcw className="w-3.5 h-3.5" aria-hidden="true" />
              <span>Coba Lagi</span>
            </button>
          </div>
        )}

        {!isLoading && !error && displayedNotifications.length === 0 && (
          <div className="p-8 text-center space-y-2">
            <div className="w-12 h-12 mx-auto rounded-2xl bg-slate-50 border border-slate-200/80 flex items-center justify-center text-slate-600">
              <Bell className="w-5 h-5" aria-hidden="true" />
            </div>
            <h4 className="text-xs font-bold text-slate-900">
              {activeTab === "unread"
                ? "Tidak Ada Notifikasi Baru"
                : "Belum Ada Notifikasi"}
            </h4>
            <p className="text-xs text-slate-600 max-w-xs mx-auto leading-relaxed">
              {activeTab === "unread"
                ? "Seluruh pemberitahuan operasional telah Anda baca."
                : "Pemberitahuan terkait cuti, lembur, dan slip gaji akan muncul di sini."}
            </p>
          </div>
        )}

        {!error &&
          displayedNotifications.map((notif) => {
            const config = getTypeConfig(notif.type);
            return (
              <div
                key={notif.id_notifications}
                className={`group relative px-3 sm:px-2.5 py-2.5 flex items-start gap-2 transition-colors min-h-[56px] ${
                  !notif.is_read
                    ? "bg-blue-50/40 hover:bg-blue-50/70"
                    : "bg-white hover:bg-slate-50/80"
                }`}
              >
                <button
                  type="button"
                  onMouseDown={(e) => e.preventDefault()}
                  onClick={() => handleNotificationClick(notif)}
                  className="flex-1 min-w-0 flex items-start gap-3 p-1 rounded-xl text-left focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-emerald-600 cursor-pointer"
                >
                  {/* Squircle Type Icon */}
                  <div
                    className={`w-9 h-9 rounded-xl border flex items-center justify-center flex-shrink-0 shadow-2xs ${config.bg}`}
                  >
                    {config.icon}
                  </div>

                  {/* Content Details */}
                  <div className="flex-1 min-w-0">
                    <div className="flex items-center gap-1.5 mb-0.5">
                      <span className="text-[10px] font-bold uppercase tracking-wider text-slate-600">
                        {config.label}
                      </span>
                      <span className="text-slate-500 font-bold text-[10px]" aria-hidden="true">·</span>
                      <span className="text-[10.5px] font-medium text-slate-600">
                        {formatRelativeTime(notif.created_at)}
                      </span>
                    </div>

                    <h5
                      className={`text-xs leading-snug line-clamp-1 ${
                        !notif.is_read
                          ? "font-bold text-slate-900"
                          : "font-semibold text-slate-700"
                      }`}
                    >
                      {notif.title}
                    </h5>

                    <p className="text-[11.5px] text-slate-600 mt-0.5 line-clamp-2 leading-relaxed">
                      {notif.message}
                    </p>

                    {notif.data?.url && (
                      <div className="inline-flex items-center gap-1 mt-1 text-[11px] font-semibold text-blue-700 group-hover:underline">
                        <span>Buka rincian</span>
                        <ExternalLink className="w-3 h-3" aria-hidden="true" />
                      </div>
                    )}
                  </div>
                </button>

                {/* Right Action Column: Unread Dot & Delete Button */}
                <div className="flex flex-col items-center gap-1 flex-shrink-0 pt-0.5">
                  {!notif.is_read && (
                    <span
                      className="w-2 h-2 rounded-full bg-blue-600 ring-2 ring-white"
                      title="Belum dibaca"
                      aria-label="Belum dibaca"
                    />
                  )}
                  <button
                    type="button"
                    onClick={(e) =>
                      handleDeleteNotification(
                        e,
                        notif.id_notifications,
                        !notif.is_read
                      )
                    }
                    aria-label="Hapus notifikasi"
                    title="Hapus notifikasi ini"
                    className="min-w-[44px] min-h-[44px] sm:min-w-[36px] sm:min-h-[36px] flex items-center justify-center text-slate-600 hover:text-rose-700 hover:bg-rose-50 rounded-lg transition-all cursor-pointer opacity-100 sm:opacity-75 sm:group-hover:opacity-100 sm:focus-visible:opacity-100 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-rose-600 active:scale-90"
                  >
                    <Trash2 className="w-4 h-4 sm:w-3.5 sm:h-3.5" aria-hidden="true" />
                  </button>
                </div>
              </div>
            );
          })}
      </div>

      {/* Footer Bar */}
      <div className="p-2.5 border-t border-slate-100 bg-slate-50/70 text-center flex-shrink-0">
        <span className="text-[11px] text-slate-600 font-medium">
          Notifikasi operasional terpusat SPINDO
        </span>
      </div>
    </>
  );

  return (
    <div className="relative" ref={containerRef}>
      <button
        ref={triggerRef}
        type="button"
        onClick={() => setIsOpen((prev) => !prev)}
        aria-expanded={isOpen}
        aria-haspopup="dialog"
        aria-label={`Pemberitahuan notifikasi${
          unreadCount > 0 ? `, ${unreadCount} belum dibaca` : ""
        }`}
        className="relative p-2 rounded-xl border border-slate-200/80 bg-white text-slate-600 hover:text-slate-900 hover:bg-slate-50 active:scale-95 transition-all shadow-2xs focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-emerald-600 cursor-pointer min-w-[44px] min-h-[44px] flex items-center justify-center"
      >
        <Bell className="w-4 h-4" aria-hidden="true" />

        {unreadCount > 0 && (
          <span className="absolute -top-1 -right-1 flex h-4 min-w-[16px] px-1 items-center justify-center rounded-full bg-rose-600 text-[9.5px] font-extrabold text-white ring-2 ring-white shadow-xs animate-in zoom-in-50 duration-200">
            {unreadCount > 99 ? "99+" : unreadCount}
          </span>
        )}
      </button>

      {/* 1. Desktop Dropdown Popover (>= sm) */}
      {isOpen && (
        <div
          role="dialog"
          aria-label="Pemberitahuan Notifikasi"
          className="hidden sm:block absolute right-0 mt-2 w-96 max-w-sm rounded-2xl bg-white/98 backdrop-blur-2xl border border-slate-200/80 shadow-[0_12px_32px_-4px_rgba(11,37,69,0.15),0_2px_8px_rgba(0,0,0,0.04)] text-sm z-50 overflow-hidden animate-fade-in-up"
        >
          <div className="p-3.5 border-b border-slate-100 flex items-center justify-between gap-2 bg-slate-50/70">
            <div className="flex items-center gap-2">
              <span className="font-bold text-[#0B2545] text-sm tracking-tight">
                Notifikasi
              </span>
              {unreadCount > 0 && (
                <span className="px-2 py-0.5 text-[10px] font-bold rounded-full bg-rose-100 text-rose-700 border border-rose-200/80">
                  {unreadCount} Baru
                </span>
              )}
            </div>

            {unreadCount > 0 && (
              <button
                type="button"
                onClick={handleMarkAllAsRead}
                disabled={isMarkingAll}
                className="inline-flex items-center gap-1.5 min-h-[36px] text-xs font-semibold text-emerald-700 hover:text-emerald-800 disabled:opacity-50 transition-colors focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-emerald-600 rounded-lg px-2 py-1 hover:bg-emerald-50 cursor-pointer"
                title="Tandai semua notifikasi telah dibaca"
              >
                <CheckCheck className="w-3.5 h-3.5" aria-hidden="true" />
                <span>Tandai Semua Dibaca</span>
              </button>
            )}
          </div>

          {renderNotificationBody(false)}
        </div>
      )}

      {/* 2. Mobile Bottom Sheet & Backdrop (< sm) */}
      {isOpen && isMounted && typeof document !== "undefined" && createPortal(
        <div className="sm:hidden fixed inset-0 z-[100] animate-fade-in" aria-modal="true" role="dialog">
          <div
            className="fixed inset-0 bg-slate-950/40 backdrop-blur-xs transition-opacity"
            onClick={() => setIsOpen(false)}
            aria-hidden="true"
          />

          <div
            ref={mobileSheetRef}
            role="document"
            aria-label="Pemberitahuan Notifikasi"
            className="fixed inset-x-0 bottom-0 z-50 max-h-[85dvh] rounded-t-3xl bg-white border-t border-slate-200/90 shadow-[0_-16px_40px_-8px_rgba(11,37,69,0.25)] flex flex-col overflow-hidden animate-slide-up"
            style={{ paddingBottom: "max(1.25rem, env(safe-area-inset-bottom))" }}
          >
            <div className="w-full pt-3 pb-1 flex justify-center flex-shrink-0">
              <div className="w-10 h-1.5 rounded-full bg-slate-300" />
            </div>

            <div className="px-4 py-3 border-b border-slate-100 flex items-center justify-between gap-2 bg-slate-50/70 flex-shrink-0">
              <div className="flex items-center gap-2">
                <span className="font-extrabold text-[#0B2545] text-base tracking-tight">
                  Notifikasi
                </span>
                {unreadCount > 0 && (
                  <span className="px-2 py-0.5 text-[10px] font-bold rounded-full bg-rose-100 text-rose-700 border border-rose-200/80">
                    {unreadCount} Baru
                  </span>
                )}
              </div>

              <div className="flex items-center gap-1.5">
                {unreadCount > 0 && (
                  <button
                    type="button"
                    onClick={handleMarkAllAsRead}
                    disabled={isMarkingAll}
                    className="inline-flex items-center gap-1.5 text-xs font-semibold text-emerald-700 hover:text-emerald-800 disabled:opacity-50 transition-colors px-2.5 py-2 rounded-xl hover:bg-emerald-50 active:scale-95 cursor-pointer min-h-[44px] focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-emerald-600"
                  >
                    <CheckCheck className="w-3.5 h-3.5" aria-hidden="true" />
                    <span>Tandai Semua</span>
                  </button>
                )}
                <button
                  type="button"
                  onClick={() => setIsOpen(false)}
                  className="min-w-[44px] min-h-[44px] w-11 h-11 rounded-full bg-slate-200/70 hover:bg-slate-200 flex items-center justify-center text-slate-700 active:scale-90 transition-all cursor-pointer focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-emerald-600"
                  aria-label="Tutup notifikasi"
                >
                  <X className="w-4 h-4" aria-hidden="true" />
                </button>
              </div>
            </div>

            {renderNotificationBody(true)}
          </div>
        </div>,
        document.body
      )}
    </div>
  );
}
