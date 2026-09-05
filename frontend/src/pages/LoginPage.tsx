import { useState } from "react";
import { Link, useNavigate } from "react-router-dom";
import { useAuth } from "@/contexts/AuthContext";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { PasswordInput } from "@/components/ui/password-input";
import { BrandLogo } from "@/components/BrandLogo";
import { SITE_NAME } from "@/lib/site";
// Google sign-in temporarily disabled
// import { GoogleSignInButton, GoogleSignInHint } from "@/components/auth/GoogleSignInButton";

export function LoginPage() {
  const { login } = useAuth();
  const navigate = useNavigate();
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [error, setError] = useState("");
  const [loading, setLoading] = useState(false);

  const onSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setLoading(true);
    setError("");
    try {
      await login(email, password);
      navigate("/dashboard");
    } catch (err) {
      setError(err instanceof Error ? err.message : "Login failed");
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="min-h-screen flex items-center justify-center bg-surface p-4">
      <div className="w-full max-w-md bg-surface-container-lowest rounded-2xl shadow-ambient p-8">
        <BrandLogo size={56} showWordmark wordmarkClassName="text-2xl" className="mb-1" />
        <p className="text-secondary text-sm mb-6">Sign in to your {SITE_NAME.toLowerCase()}</p>
        <form onSubmit={onSubmit} className="space-y-4">
          <Input
            id="email"
            label="Email"
            type="email"
            autoComplete="email"
            value={email}
            onChange={(e) => setEmail(e.target.value)}
            required
          />
          <PasswordInput
            id="password"
            label="Password"
            autoComplete="current-password"
            value={password}
            onChange={(e) => setPassword(e.target.value)}
            required
          />
          {error && <p className="text-xs text-error">{error}</p>}
          <Button type="submit" className="w-full" disabled={loading}>
            {loading ? "Signing in..." : "Sign in"}
          </Button>
        </form>
        {/* Google sign-in temporarily disabled
        <GoogleSignInButton />
        <GoogleSignInHint />
        */}
        <p className="text-sm text-secondary mt-4 text-center">
          No account?{" "}
          <Link to="/register" className="text-surface-tint font-medium">
            Register
          </Link>
        </p>
      </div>
    </div>
  );
}
