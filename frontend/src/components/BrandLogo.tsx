import { SITE_NAME, SITE_LOGO_SRC } from "@/lib/site";
import { cn } from "@/lib/utils";

type BrandLogoProps = {
  size?: number;
  showWordmark?: boolean;
  wordmarkClassName?: string;
  className?: string;
};

export function BrandLogo({
  size = 40,
  showWordmark = false,
  wordmarkClassName,
  className,
}: BrandLogoProps) {
  return (
    <div className={cn("flex items-center gap-3", className)}>
      <img
        src={SITE_LOGO_SRC}
        alt={showWordmark ? "" : SITE_NAME}
        width={size}
        height={size}
        className="shrink-0 rounded-[22%] shadow-sm"
        decoding="async"
      />
      {showWordmark && (
        <span
          className={cn(
            "font-headline font-bold tracking-tight text-on-surface",
            wordmarkClassName
          )}
        >
          {SITE_NAME}
        </span>
      )}
    </div>
  );
}
