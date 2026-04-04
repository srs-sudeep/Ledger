import * as React from "react";
import { cva, type VariantProps } from "class-variance-authority";
import { cn } from "@/lib/utils";

const buttonVariants = cva(
  "inline-flex items-center justify-center whitespace-nowrap rounded-md text-sm font-semibold transition-all duration-150 active:scale-[0.97] disabled:pointer-events-none disabled:opacity-50 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-primary/40 focus-visible:ring-offset-2",
  {
    variants: {
      variant: {
        default:
          "bg-surface-tint text-on-primary hover:bg-surface-tint/85 shadow-sm hover:shadow-md",
        gradient: "cta-gradient text-white shadow-lg hover:opacity-90",
        secondary:
          "bg-surface-container-low text-on-surface hover:bg-surface-container",
        outline:
          "border border-outline/30 text-on-surface hover:bg-surface-container-low",
        ghost:
          "hover:bg-surface-container-low text-on-surface-variant hover:text-on-surface",
        destructive: "bg-error text-on-error hover:bg-error/90",
        link: "text-surface-tint underline-offset-4 hover:underline",
      },
      size: {
        default: "h-10 px-5 py-2",
        sm: "h-8 px-3 text-xs",
        lg: "h-12 px-8 text-base",
        icon: "h-10 w-10",
      },
    },
    defaultVariants: {
      variant: "default",
      size: "default",
    },
  }
);

export interface ButtonProps
  extends React.ButtonHTMLAttributes<HTMLButtonElement>,
    VariantProps<typeof buttonVariants> {}

const Button = React.forwardRef<HTMLButtonElement, ButtonProps>(
  ({ className, variant, size, ...props }, ref) => {
    return (
      <button
        className={cn(buttonVariants({ variant, size, className }))}
        ref={ref}
        {...props}
      />
    );
  }
);
Button.displayName = "Button";

export { Button, buttonVariants };
