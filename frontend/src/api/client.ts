const API_BASE = import.meta.env.VITE_API_URL ?? "";

export class ApiError extends Error {
  constructor(
    message: string,
    public status: number
  ) {
    super(message);
  }
}

function getToken(): string | null {
  return localStorage.getItem("ledger_token");
}

export function setToken(token: string | null) {
  if (token) localStorage.setItem("ledger_token", token);
  else localStorage.removeItem("ledger_token");
}

export async function api<T>(
  path: string,
  options: RequestInit = {}
): Promise<T> {
  const token = getToken();
  const headers: Record<string, string> = {
    "Content-Type": "application/json",
    ...(options.headers as Record<string, string>),
  };
  if (token) headers.Authorization = `Bearer ${token}`;

  const res = await fetch(`${API_BASE}${path}`, { ...options, headers });
  if (!res.ok) {
    let msg = res.statusText;
    try {
      const body = await res.json();
      if (body.detail) msg = typeof body.detail === "string" ? body.detail : JSON.stringify(body.detail);
    } catch {
      /* ignore */
    }
    throw new ApiError(msg, res.status);
  }
  if (res.status === 204) return undefined as T;
  return res.json() as Promise<T>;
}

export const authApi = {
  register: (email: string, password: string, full_name?: string) =>
    api<{ access_token: string }>("/api/auth/register", {
      method: "POST",
      body: JSON.stringify({ email, password, full_name }),
    }),
  login: (email: string, password: string) =>
    api<{ access_token: string }>("/api/auth/login", {
      method: "POST",
      body: JSON.stringify({ email, password }),
    }),
  loginWithGoogle: (id_token: string) =>
    api<{ access_token: string }>("/api/auth/google", {
      method: "POST",
      body: JSON.stringify({ id_token }),
    }),
  me: () => api<import("@/lib/types").Profile & { email: string }>("/api/auth/me"),
  updateMe: (data: { full_name?: string; default_currency?: string }) =>
    api<import("@/lib/types").Profile & { email: string }>("/api/auth/me", {
      method: "PATCH",
      body: JSON.stringify(data),
    }),
};
