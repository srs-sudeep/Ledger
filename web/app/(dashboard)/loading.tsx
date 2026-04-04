import { Skeleton } from "@/components/ui/skeleton";

export default function DashboardRouteLoading() {
  return (
    <div className="space-y-8 animate-in fade-in duration-300">
      <div className="flex items-center justify-between">
        <div className="space-y-2">
          <Skeleton className="h-7 w-48" />
          <Skeleton className="h-4 w-32" />
        </div>
        <Skeleton className="h-10 w-32 rounded-xl" />
      </div>

      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
        {Array.from({ length: 4 }).map((_, i) => (
          <Skeleton key={i} className="h-28 rounded-xl" />
        ))}
      </div>

      <div className="grid grid-cols-12 gap-8">
        <Skeleton className="col-span-12 lg:col-span-7 h-64 rounded-xl" />
        <Skeleton className="col-span-12 lg:col-span-5 h-64 rounded-xl" />
      </div>
    </div>
  );
}
