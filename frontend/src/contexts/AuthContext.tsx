import { createContext, useContext, useEffect, useState, type ReactNode } from "react";
import { authApi, setToken } from "@/api/client";
import type { Profile } from "@/lib/types";

type AuthUser = Profile & { email: string };

interface AuthContextValue {
  user: AuthUser | null;
  loading: boolean;
  login: (email: string, password: string) => Promise<void>;
  register: (
    email: string,
    password: string,
    fullName?: string,
    phonePrimary?: string,
    phoneSecondary?: string
  ) => Promise<void>;
  loginWithGoogle: (idToken: string) => Promise<void>;
  logout: () => void;
  refreshUser: () => Promise<void>;
}

const AuthContext = createContext<AuthContextValue | null>(null);

export function AuthProvider({ children }: { children: ReactNode }) {
  const [user, setUser] = useState<AuthUser | null>(null);
  const [loading, setLoading] = useState(true);

  const refreshUser = async () => {
    try {
      const me = await authApi.me();
      setUser(me);
    } catch {
      setUser(null);
      setToken(null);
    }
  };

  useEffect(() => {
    refreshUser().finally(() => setLoading(false));
  }, []);

  const login = async (email: string, password: string) => {
    const { access_token } = await authApi.login(email, password);
    setToken(access_token);
    await refreshUser();
  };

  const register = async (
    email: string,
    password: string,
    fullName?: string,
    phonePrimary?: string,
    phoneSecondary?: string
  ) => {
    const { access_token } = await authApi.register(
      email,
      password,
      fullName,
      phonePrimary,
      phoneSecondary
    );
    setToken(access_token);
    await refreshUser();
  };

  const loginWithGoogle = async (idToken: string) => {
    const { access_token } = await authApi.loginWithGoogle(idToken);
    setToken(access_token);
    await refreshUser();
  };

  const logout = () => {
    setToken(null);
    setUser(null);
  };

  return (
    <AuthContext.Provider value={{ user, loading, login, register, loginWithGoogle, logout, refreshUser }}>
      {children}
    </AuthContext.Provider>
  );
}

export function useAuth() {
  const ctx = useContext(AuthContext);
  if (!ctx) throw new Error("useAuth must be used within AuthProvider");
  return ctx;
}
