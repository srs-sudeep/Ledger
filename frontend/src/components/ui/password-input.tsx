import * as React from "react";
import { Eye, EyeOff } from "lucide-react";
import { cn } from "@/lib/utils";

export interface PasswordInputProps
  extends Omit<React.InputHTMLAttributes<HTMLInputElement>, "type"> {
  label?: string;
}

export const PasswordInput = React.forwardRef<HTMLInputElement, PasswordInputProps>(
  ({ className, label, id, ...props }, ref) => {
    const [visible, setVisible] = React.useState(false);

    return (
      <div className="space-y-1.5">
        {label && (
          <label
            htmlFor={id}
            className="block text-xs font-medium text-on-surface-variant font-label"
          >
            {label}
          </label>
        )}
        <div className="relative">
          <input
            type={visible ? "text" : "password"}
            id={id}
            className={cn(
              "flex h-11 w-full rounded-xl bg-surface-container-low px-4 py-2 pr-11 text-sm text-on-surface font-body",
              "placeholder:text-outline transition-all duration-200",
              "focus:bg-surface-container-lowest focus:outline-none focus:ring-1 focus:ring-surface-tint/20",
              "disabled:cursor-not-allowed disabled:opacity-50",
              className
            )}
            ref={ref}
            {...props}
          />
          <button
            type="button"
            tabIndex={-1}
            aria-label={visible ? "Hide password" : "Show password"}
            onClick={() => setVisible((v) => !v)}
            className="absolute right-3 top-1/2 -translate-y-1/2 text-secondary hover:text-on-surface transition-colors"
          >
            {visible ? <EyeOff size={18} /> : <Eye size={18} />}
          </button>
        </div>
      </div>
    );
  }
);
PasswordInput.displayName = "PasswordInput";
