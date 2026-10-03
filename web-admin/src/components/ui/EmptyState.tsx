"use client";

import { type ReactNode } from "react";
import { Inbox } from "lucide-react";
import { Button } from "./Button";
import { cn } from "@/lib/utils";

export interface EmptyStateProps {
  title: string;
  description: string;
  actionLabel?: string;
  onAction?: () => void;
  icon?: ReactNode;
  className?: string;
}

export function EmptyState({
  title,
  description,
  actionLabel,
  onAction,
  icon,
  className,
}: EmptyStateProps) {
  return (
    <div
      role="region"
      aria-label={title}
      className={cn(
        "flex flex-col items-center justify-center p-8 sm:p-12 text-center rounded-2xl border border-slate-200/80 bg-white/95 backdrop-blur-md shadow-[0_1px_3px_rgba(0,0,0,0.03),0_1px_2px_rgba(0,0,0,0.02)]",
        className
      )}
    >
      <div className="w-14 h-14 mb-4 flex items-center justify-center rounded-2xl bg-slate-50/90 border border-slate-200/80 text-slate-500 shadow-2xs">
        {icon || <Inbox className="w-6 h-6" aria-hidden="true" />}
      </div>

      <h3 className="text-base font-semibold text-slate-900 mb-1 tracking-tight">
        {title}
      </h3>

      <p className="text-sm text-slate-600 max-w-md mb-5 leading-relaxed">
        {description}
      </p>

      {actionLabel && onAction && (
        <Button variant="primary" size="md" onClick={onAction}>
          {actionLabel}
        </Button>
      )}
    </div>
  );
}
