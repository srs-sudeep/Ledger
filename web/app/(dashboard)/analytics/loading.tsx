import { Skeleton } from "@/components/ui/skeleton";

export default function AnalyticsLoading() {
  return (
    <div className="space-y-8 animate-in fade-in duration-300">
      <div className="space-y-2">
        <Skeleton className="h-7 w-36" />
        <Skeleton className="h-4 w-56" />
      </div>

      <div className="flex gap-4">
        <Skeleton className="h-20 w-40 rounded-xl" />
        <Skeleton className="h-20 w-40 rounded-xl" />
        <Skeleton className="h-10 w-48 rounded-xl" />
      </div>

      <div className="grid grid-cols-12 gap-8">
        <Skeleton className="col-span-12 lg:col-span-5 h-72 rounded-xl" />
        <Skeleton className="col-span-12 lg:col-span-7 h-72 rounded-xl" />
      </div>

      <Skeleton className="h-64 rounded-xl" />
    </div>
  );
}
