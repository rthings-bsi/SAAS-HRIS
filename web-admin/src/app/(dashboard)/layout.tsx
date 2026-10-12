"use client";

import { useEffect, useState, type ReactNode } from "react";
import { useRouter } from "next/navigation";
import { Sidebar } from "@/components/layout/Sidebar";
import { Header } from "@/components/layout/Header";
import { MobileBottomNav } from "@/components/layout/MobileBottomNav";

export default function DashboardLayout({
  children,
}: {
  children: ReactNode;
}) {
  const router = useRouter();
  const [sidebarOpen, setSidebarOpen] = useState(false);
  const [isClient, setIsClient] = useState(false);

  useEffect(() => {
    setIsClient(true);
    if (!localStorage.getItem("hris_token")) {
      router.replace("/login");
    }
  }, [router]);

  const isAuthenticated = isClient ? Boolean(localStorage.getItem("hris_token")) : null;

  if (isAuthenticated === null) {
    return (
      <div className="flex h-screen items-center justify-center bg-[#F8FAFC]">
        <div className="flex items-center gap-2 text-sm text-[#475569]">
          <span className="inline-block w-4 h-4 border-2 border-orange-600 border-t-transparent rounded-full animate-spin" />
          <span>Memeriksa sesi...</span>
        </div>
      </div>
    );
  }

  if (!isAuthenticated) {
    return null;
  }

  return (
    <div className="flex h-screen overflow-hidden bg-[#F2F2F7]">
      {/* Keyboard Accessibility Skip Link (R-32) */}
      <a
        href="#main-content"
        className="sr-only focus:not-sr-only focus:absolute focus:top-3 focus:left-3 focus:z-50 focus:px-4 focus:py-2 focus:bg-orange-600 focus:text-white focus:rounded-md focus:text-sm focus:font-medium focus:shadow-md"
      >
        Lewati ke konten utama
      </a>

      {/* Main Sidebar (Desktop sidebar or mobile slide-out for Admin 'Menu') */}
      <Sidebar
        isOpen={sidebarOpen}
        onClose={() => setSidebarOpen(false)}
      />

      {/* Main Content Area */}
      <div className="flex flex-col flex-1 min-w-0 overflow-hidden">
        {/* Top Header on Mobile (< lg) */}
        <div className="lg:hidden">
          <Header onOpenSidebar={() => setSidebarOpen(true)} />
        </div>

        <main
          id="main-content"
          tabIndex={-1}
          className="flex-1 overflow-y-auto p-3.5 sm:p-6 lg:p-8 pb-24 sm:pb-8 lg:pb-8 outline-none bg-[#F2F2F7]"
        >
          {children}
        </main>

        {/* Mobile Bottom Navigation Bar (< lg) */}
        <MobileBottomNav onOpenMenu={() => setSidebarOpen(true)} />
      </div>
    </div>
  );
}
