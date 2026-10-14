"use client";

import { useState, useEffect, useRef, useCallback } from "react";
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
  const [unreadCount, setUnreadCount] = useState<number>(0);
  const [isLoading, setIsLoading] = useState(false);
  const [isMarkingAll, setIsMarkingAll] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const containerRef = useRef<HTMLDivElement>(null);
  const triggerRef = useRef<HTMLButtonElement>(null);

  // Fetch unread count for badge (called on mount and periodically)
  const fetchUnreadCount = useCallback(async () => {
    try {
      const res = await apiClient.get<ApiResponse<NotificationUnreadCountResponse>>(
        "/notifications/unread-count"
      );
      if (res.data?.success && res.data?.data) {
        setUnreadCount(res.data.data.unread_count);
      }
    } catch {
      // Quietly ignore polling failure to prevent noisy UI interruption
    }
  }, []);

  // Fetch full notification list
  const fetchNotifications = useCallback(async () => {
    setIsLoading(true);
    setError(null);
    try {
      const res = await apiClient.get<ApiResponse<NotificationListResponse>>(
        "/notifications",
        {
          params: { per_page: 30 },
        }
      );
      if (res.data?.success && res.data?.data) {
        setNotifications(res.data.data.notifications || []);
        setUnreadCount(res.data.data.unread_count || 0);
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

  // Mount effect: fetch unread count & setup polling
  useEffect(() => {
    fetchUnreadCount();
    const interval = setInterval(fetchUnreadCount, 30000); // Poll every 30s
    return () => clearInterval(interval);
  }, [fetchUnreadCount]);

  // When dropdown opens, fetch notification list
  useEffect(() => {
    if (isOpen) {
      fetchNotifications();
    }
  }, [isOpen, fetchNotifications]);

  // Handle click outside to close dropdown
  useEffect(() => {
    const handleClickOutside = (event: MouseEvent) => {
      if (
        containerRef.current &&
        !containerRef.current.contains(event.target as Node)
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

  // Handle ESC key to close
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

  // Mark all notifications as read
  const handleMarkAllAsRead = async () => {
    if (unreadCount === 0 || isMarkingAll) return;
    setIsMarkingAll(true);
    try {
      const res = await apiClient.put<ApiResponse<{ marked_count: number; unread_count: number }>>(
        "/notifications/read-all"
      );
      if (res.data?.success) {
        setNotifications((prev) =>
          prev.map((notif) => ({
            ...notif,
            is_read: true,
            read_at: notif.read_at || new Date().toISOString(),
          }))
        );
        setUnreadCount(0);
      }
    } catch {
      // Keep state resilient
    } finally {
      setIsMarkingAll(false);
    }
  };

  // Mark single notification as read & navigate to target URL
  const handleNotificationClick = async (notif: NotificationItem) => {
    if (!notif.is_read) {
      // Optimistic update
      setNotifications((prev) =>
        prev.map((item) =>
          item.id_notifications === notif.id_notifications
            ? { ...item, is_read: true, read_at: new Date().toISOString() }
            : item
        )
      );
      setUnreadCount((prev) => Math.max(0, prev - 1));

      // Network request in background
      try {
        await apiClient.put(`/notifications/${notif.id_notifications}/read`);
      } catch {
        // Ignored
      }
    }

    setIsOpen(false);

    // Deep link routing if URL is provided
    const targetUrl = notif.data?.url;
    if (targetUrl && typeof targetUrl === "string") {
      router.push(targetUrl);
    }
  };

  // Delete notification
  const handleDeleteNotification = async (
    e: React.MouseEvent,
    id: number,
    wasUnread: boolean
  ) => {
    e.stopPropagation();
    setNotifications((prev) =>
      prev.filter((item) => item.id_notifications !== id)
    );
    if (wasUnread) {
      setUnreadCount((prev) => Math.max(0, prev - 1));
    }
    try {
      await apiClient.delete(`/notifications/${id}`);
    } catch {
      // Non-blocking
    }
  };

  // Get type icon and styling
  const getTypeConfig = (type: NotificationType) => {
    switch (type) {
      case "leave":
        return {
          icon: <Calendar className="w-4 h-4 text-emerald-600" aria-hidden="true" />,
          bg: "bg-emerald-50 border-emerald-200/70 text-emerald-700",
          label: "Cuti",
        };
      case "overtime":
        return {
          icon: <Clock className="w-4 h-4 text-amber-600" aria-hidden="true" />,
          bg: "bg-amber-50 border-amber-200/70 text-amber-700",
          label: "Lembur",
        };
      case "payroll":
        return {
          icon: <Banknote className="w-4 h-4 text-blue-600" aria-hidden="true" />,
          bg: "bg-blue-50 border-blue-200/70 text-blue-700",
          label: "Penggajian",
        };
      case "attendance":
        return {
          icon: <UserCheck className="w-4 h-4 text-purple-600" aria-hidden="true" />,
          bg: "bg-purple-50 border-purple-200/70 text-purple-700",
          label: "Presensi",
        };
      case "performance":
        return {
          icon: <Award className="w-4 h-4 text-indigo-600" aria-hidden="true" />,
          bg: "bg-indigo-50 border-indigo-200/70 text-indigo-700",
          label: "Kinerja",
        };
      default:
        return {
          icon: <Info className="w-4 h-4 text-slate-600" aria-hidden="true" />,
          bg: "bg-slate-100 border-slate-200 text-slate-700",
          label: "Sistem",
        };
    }
  };

  // Filtered notifications
  const displayedNotifications =
    activeTab === "unread"
      ? notifications.filter((item) => !item.is_read)
      : notifications;

  return (
    <div className="relative" ref={containerRef}>
      {/* Trigger Button with Accessible Hit Area & Badge */}
      <button
        ref={triggerRef}
        type="button"
        onClick={() => setIsOpen((prev) => !prev)}
        aria-expanded={isOpen}
        aria-haspopup="dialog"
        aria-label={`Pemberitahuan notifikasi${
          unreadCount > 0 ? `, ${unreadCount} belum dibaca` : ""
        }`}
        className="relative p-2 rounded-xl border border-slate-200/80 bg-white text-slate-600 hover:text-slate-900 hover:bg-slate-50 active:scale-95 transition-all shadow-2xs focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-emerald-600 cursor-pointer min-w-[40px] min-h-[40px] flex items-center justify-center"
      >
        <Bell className="w-4 h-4" aria-hidden="true" />

        {/* Unread Indicator Badge */}
        {unreadCount > 0 && (
          <span className="absolute -top-1 -right-1 flex h-4 min-w-[16px] px-1 items-center justify-center rounded-full bg-rose-600 text-[9.5px] font-extrabold text-white ring-2 ring-white shadow-xs animate-in zoom-in-50 duration-200">
            {unreadCount > 99 ? "99+" : unreadCount}
          </span>
        )}
      </button>

      {/* Dropdown Popover */}
      {isOpen && (
        <div
          role="dialog"
          aria-label="Pemberitahuan Notifikasi"
          className="absolute right-0 mt-2 w-[calc(100vw-2rem)] sm:w-96 max-w-sm rounded-2xl bg-white/98 backdrop-blur-2xl border border-slate-200/80 shadow-[0_12px_32px_-4px_rgba(11,37,69,0.15),0_2px_8px_rgba(0,0,0,0.04)] text-sm z-50 overflow-hidden animate-fade-in-up"
        >
          {/* Popover Header */}
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
                className="inline-flex items-center gap-1.5 text-xs font-semibold text-emerald-700 hover:text-emerald-800 disabled:opacity-50 transition-colors focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-emerald-600 rounded-lg px-2 py-1 hover:bg-emerald-50 cursor-pointer"
                title="Tandai semua notifikasi telah dibaca"
              >
                <CheckCheck className="w-3.5 h-3.5" aria-hidden="true" />
                <span>Tandai Semua Dibaca</span>
              </button>
            )}
          </div>

          {/* Filter Tabs: Semua / Belum Dibaca */}
          <div className="px-3.5 pt-2.5 pb-2 flex items-center gap-2 border-b border-slate-100 bg-white">
            <button
              type="button"
              onClick={() => setActiveTab("all")}
              className={`px-3 py-1 rounded-lg text-xs font-semibold transition-all cursor-pointer ${
                activeTab === "all"
                  ? "bg-[#0B2545] text-white shadow-2xs"
                  : "text-slate-600 hover:bg-slate-100 hover:text-slate-900"
              }`}
            >
              Semua ({notifications.length})
            </button>
            <button
              type="button"
              onClick={() => setActiveTab("unread")}
              className={`px-3 py-1 rounded-lg text-xs font-semibold transition-all cursor-pointer ${
                activeTab === "unread"
                  ? "bg-[#0B2545] text-white shadow-2xs"
                  : "text-slate-600 hover:bg-slate-100 hover:text-slate-900"
              }`}
            >
              Belum Dibaca ({unreadCount})
            </button>
          </div>

          {/* Content Area with Anti-Slop States */}
          <div className="max-h-96 overflow-y-auto divide-y divide-slate-100 overscroll-contain">
            {/* 1. Loading State */}
            {isLoading && notifications.length === 0 && (
              <div className="p-4 space-y-3">
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

            {/* 2. Error State with Retry Button */}
            {!isLoading && error && (
              <div className="p-6 text-center space-y-3">
                <div className="w-10 h-10 mx-auto rounded-xl bg-rose-50 border border-rose-200 flex items-center justify-center text-rose-600">
                  <Info className="w-5 h-5" aria-hidden="true" />
                </div>
                <div>
                  <h4 className="text-xs font-bold text-slate-900">
                    Gagal Memuat Notifikasi
                  </h4>
                  <p className="text-[11px] text-slate-500 mt-0.5">{error}</p>
                </div>
                <button
                  type="button"
                  onClick={fetchNotifications}
                  className="inline-flex items-center gap-1.5 px-3 py-1.5 text-xs font-medium rounded-lg bg-slate-100 hover:bg-slate-200 text-slate-800 transition-colors cursor-pointer"
                >
                  <RotateCcw className="w-3.5 h-3.5" aria-hidden="true" />
                  <span>Coba Lagi</span>
                </button>
              </div>
            )}

            {/* 3. Empty State */}
            {!isLoading && !error && displayedNotifications.length === 0 && (
              <div className="p-8 text-center space-y-2">
                <div className="w-12 h-12 mx-auto rounded-2xl bg-slate-50 border border-slate-200/80 flex items-center justify-center text-slate-400">
                  <Bell className="w-5 h-5" aria-hidden="true" />
                </div>
                <h4 className="text-xs font-bold text-slate-900">
                  {activeTab === "unread"
                    ? "Tidak Ada Notifikasi Baru"
                    : "Belum Ada Notifikasi"}
                </h4>
                <p className="text-[11px] text-slate-500 max-w-xs mx-auto leading-relaxed">
                  {activeTab === "unread"
                    ? "Seluruh pemberitahuan operasional telah Anda baca."
                    : "Pemberitahuan terkait cuti, lembur, dan slip gaji akan muncul di sini."}
                </p>
              </div>
            )}

            {/* 4. Notification Item List */}
            {!error &&
              displayedNotifications.map((notif) => {
                const config = getTypeConfig(notif.type);
                return (
                  <div
                    key={notif.id_notifications}
                    onClick={() => handleNotificationClick(notif)}
                    role="button"
                    tabIndex={0}
                    onKeyDown={(e) => {
                      if (e.key === "Enter" || e.key === " ") {
                        e.preventDefault();
                        handleNotificationClick(notif);
                      }
                    }}
                    className={`group relative p-3 sm:p-3.5 flex items-start gap-3 transition-colors cursor-pointer text-left focus-visible:outline-none focus-visible:bg-slate-50 ${
                      !notif.is_read
                        ? "bg-blue-50/40 hover:bg-blue-50/70"
                        : "bg-white hover:bg-slate-50/80"
                    }`}
                  >
                    {/* Squircle Type Icon */}
                    <div
                      className={`w-9 h-9 rounded-xl border flex items-center justify-center flex-shrink-0 shadow-2xs ${config.bg}`}
                    >
                      {config.icon}
                    </div>

                    {/* Content Details */}
                    <div className="flex-1 min-w-0 pr-4">
                      <div className="flex items-center gap-1.5 mb-0.5">
                        <span className="text-[9.5px] font-bold uppercase tracking-wider text-slate-400">
                          {config.label}
                        </span>
                        <span className="text-slate-300 font-bold text-[8px]">
                          •
                        </span>
                        <span className="text-[10px] text-slate-400">
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

                      <p className="text-[11px] text-slate-600 mt-0.5 line-clamp-2 leading-relaxed">
                        {notif.message}
                      </p>

                      {notif.data?.url && (
                        <div className="inline-flex items-center gap-1 mt-1.5 text-[10.5px] font-semibold text-blue-700 group-hover:underline">
                          <span>Buka rincian</span>
                          <ExternalLink className="w-2.5 h-2.5" aria-hidden="true" />
                        </div>
                      )}
                    </div>

                    {/* Right Action Icons: Unread Indicator Dot & Delete Button */}
                    <div className="flex flex-col items-end gap-1.5 flex-shrink-0">
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
                        className="opacity-0 group-hover:opacity-100 p-1 text-slate-400 hover:text-rose-600 hover:bg-rose-50 rounded-lg transition-all cursor-pointer"
                      >
                        <Trash2 className="w-3.5 h-3.5" aria-hidden="true" />
                      </button>
                    </div>
                  </div>
                );
              })}
          </div>

          {/* Footer Bar */}
          <div className="p-2.5 border-t border-slate-100 bg-slate-50/70 text-center">
            <span className="text-[10.5px] text-slate-500 font-medium">
              Notifikasi operasional terpusat SPKINDO
            </span>
          </div>
        </div>
      )}
    </div>
  );
}
