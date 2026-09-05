import { cn } from "@/lib/utils";

export function SectionHeader({
  eyebrow,
  title,
  description,
  actions,
  className,
}: {
  eyebrow?: string;
  title: string;
  description?: string;
  actions?: React.ReactNode;
  className?: string;
}) {
  return (
    <div className={cn("flex items-end justify-between gap-4", className)}>
      <div>
        {eyebrow && (
          <p className="text-[11px] uppercase tracking-[0.2em] text-secondary mb-2">{eyebrow}</p>
        )}
        <h2 className="text-2xl font-headline font-bold">{title}</h2>
        {description && <p className="text-sm text-secondary mt-1">{description}</p>}
      </div>
      {actions}
    </div>
  );
}
