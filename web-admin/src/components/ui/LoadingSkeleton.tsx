import { cn } from "@/lib/utils";

interface SkeletonProps {
  className?: string;
  width?: string | number;
  height?: string | number;
}

export function Skeleton({ className, width, height }: SkeletonProps) {
  return (
    <div
      aria-hidden="true"
      style={{
        width: typeof width === "number" ? `${width}px` : width,
        height: typeof height === "number" ? `${height}px` : height,
      }}
      className={cn(
        "animate-pulse bg-slate-200/80 rounded-lg",
        className
      )}
    />
  );
}

interface TableSkeletonProps {
  rows?: number;
  columns?: number;
  className?: string;
}

export function TableSkeleton({
  rows = 5,
  columns = 4,
  className,
}: TableSkeletonProps) {
  return (
    <div
      role="status"
      aria-label="Memuat tabel data"
      className={cn(
        "w-full rounded-2xl border border-slate-200/80 bg-white/95 backdrop-blur-md overflow-hidden shadow-[0_1px_3px_rgba(0,0,0,0.03),0_1px_2px_rgba(0,0,0,0.02)]",
        className
      )}
    >
      {/* Table Header Skeleton */}
      <div className="flex items-center gap-4 px-5 py-3.5 bg-slate-50/80 backdrop-blur-xs border-b border-slate-200/70">
        {Array.from({ length: columns }).map((_, i) => (
          <Skeleton key={`th-${i}`} className="h-4 flex-1" />
        ))}
      </div>

      {/* Table Rows Skeleton */}
      <div className="divide-y divide-slate-100">
        {Array.from({ length: rows }).map((_, rIdx) => (
          <div
            key={`row-${rIdx}`}
            className="flex items-center gap-4 px-5 py-3.5"
          >
            {Array.from({ length: columns }).map((_, cIdx) => (
              <Skeleton
                key={`cell-${rIdx}-${cIdx}`}
                className={cn(
                  "h-4 flex-1",
                  cIdx === 0 ? "w-1/3 flex-none" : ""
                )}
              />
            ))}
          </div>
        ))}
      </div>
      <span className="sr-only">Sedang memuat data...</span>
    </div>
  );
}

interface CardSkeletonProps {
  count?: number;
  className?: string;
}

export function CardSkeleton({ count = 3, className }: CardSkeletonProps) {
  return (
    <div
      role="status"
      aria-label="Memuat ringkasan data"
      className={cn("grid grid-cols-1 md:grid-cols-3 gap-4", className)}
    >
      {Array.from({ length: count }).map((_, i) => (
        <div
          key={`card-skel-${i}`}
          className="p-5 rounded-2xl border border-slate-200/80 bg-white/95 backdrop-blur-md shadow-[0_1px_3px_rgba(0,0,0,0.03),0_1px_2px_rgba(0,0,0,0.02)] space-y-3"
        >
          <div className="flex items-center justify-between">
            <Skeleton className="h-4 w-28" />
            <Skeleton className="h-8 w-8 rounded-xl" />
          </div>
          <Skeleton className="h-7 w-20" />
          <Skeleton className="h-3 w-36" />
        </div>
      ))}
      <span className="sr-only">Sedang memuat ringkasan...</span>
    </div>
  );
}
