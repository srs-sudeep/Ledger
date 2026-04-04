"use client";

import {
  createContext,
  useContext,
  type ReactNode,
} from "react";
import { DEFAULT_CURRENCY } from "@/lib/currencies";

const CurrencyContext = createContext<string>(DEFAULT_CURRENCY);

export function CurrencyProvider({
  currency,
  children,
}: {
  currency: string;
  children: ReactNode;
}) {
  return (
    <CurrencyContext.Provider value={currency || DEFAULT_CURRENCY}>
      {children}
    </CurrencyContext.Provider>
  );
}

export function useCurrency(): string {
  return useContext(CurrencyContext);
}
