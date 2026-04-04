import { Skeleton } from "@/components/ui/skeleton";

export default function PersonalLoading() {
  return (
    <div className="space-y-8 animate-in fade-in duration-300">
      <div className="flex items-center justify-between">
        <div className="space-y-2">
          <Skeleton className="h-7 w-48" />
          <Skeleton className="h-4 w-64" />
        </div>
        <Skeleton className="h-10 w-36 rounded-xl" />
      </div>

      <Skeleton className="h-24 rounded-xl" />

      <div className="space-y-3">
        <Skeleton className="h-12 rounded-xl" />
        {Array.from({ length: 6 }).map((_, i) => (
          <Skeleton key={i} className="h-14 rounded-xl" />
        ))}
      </div>
    </div>
  );
}
