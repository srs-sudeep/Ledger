import { useEffect } from "react";
import { X } from "lucide-react";

export function ModalShell({
  open,
  title,
  description,
  onClose,
  children,
  size = "md",
}: {
  open: boolean;
  title: string;
  description?: string;
  onClose: () => void;
  children: React.ReactNode;
  size?: "sm" | "md" | "lg" | "xl";
}) {
  useEffect(() => {
    if (!open) return;
    const onKeyDown = (event: KeyboardEvent) => {
      if (event.key === "Escape") onClose();
    };
    window.addEventListener("keydown", onKeyDown);
    return () => window.removeEventListener("keydown", onKeyDown);
  }, [open, onClose]);

  if (!open) return null;

  const maxWidth =
    size === "sm"
      ? "max-w-lg"
      : size === "md"
        ? "max-w-2xl"
        : size === "lg"
          ? "max-w-4xl"
          : "max-w-6xl";

  return (
    <div className="fixed inset-0 z-[120] flex items-center justify-center bg-black/40 px-4 py-8">
      <button type="button" className="absolute inset-0" aria-label="Close modal" onClick={onClose} />
      <div className={`relative z-[121] w-full ${maxWidth} rounded-[28px] border border-white/40 bg-white shadow-ambient-lg`}>
        <div className="flex items-start justify-between gap-4 border-b border-outline/10 px-6 py-5">
          <div>
            <h3 className="text-2xl font-headline font-bold">{title}</h3>
            {description && <p className="text-sm text-secondary mt-1">{description}</p>}
          </div>
          <button
            type="button"
            aria-label="Close"
            onClick={onClose}
            className="rounded-full bg-surface-container-low p-2 text-secondary hover:text-on-surface"
          >
            <X size={18} />
          </button>
        </div>
        <div className="max-h-[80vh] overflow-auto px-6 py-5">{children}</div>
      </div>
    </div>
  );
}
