"use client";

import * as React from "react";
import Image from "next/image";
import { cn, getInitials } from "@/lib/utils";

interface AvatarProps extends React.HTMLAttributes<HTMLDivElement> {
  src?: string | null;
  alt?: string;
  fallback?: string;
  size?: "sm" | "md" | "lg";
}

const sizeClasses = {
  sm: "w-8 h-8 text-xs",
  md: "w-10 h-10 text-sm",
  lg: "w-12 h-12 text-base",
};

const sizePx = { sm: 32, md: 40, lg: 48 } as const;

export function Avatar({
  src,
  alt,
  fallback = "?",
  size = "md",
  className,
  ...props
}: AvatarProps) {
  const [imgError, setImgError] = React.useState(false);

  return (
    <div
      className={cn(
        "rounded-full overflow-hidden flex items-center justify-center font-bold bg-surface-container-high text-on-surface-variant ring-2 ring-surface-tint/10",
        sizeClasses[size],
        className
      )}
      {...props}
    >
      {src && !imgError ? (
        <Image
          src={src}
          alt={alt || "Avatar"}
          width={sizePx[size]}
          height={sizePx[size]}
          className="w-full h-full object-cover"
          unoptimized
          onError={() => setImgError(true)}
        />
      ) : (
        <span>{getInitials(fallback)}</span>
      )}
    </div>
  );
}
