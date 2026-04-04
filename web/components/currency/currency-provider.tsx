"use client";

import {
  createContext,
  useContext,
  type ReactNode,
} from "react";

const CurrencyContext = createContext<string>("USD");

export function CurrencyProvider({
  currency,
  children,
}: {
  currency: string;
  children: ReactNode;
}) {
  return (
    <CurrencyContext.Provider value={currency || "USD"}>
      {children}
    </CurrencyContext.Provider>
  );
}

export function useCurrency(): string {
  return useContext(CurrencyContext);
}
