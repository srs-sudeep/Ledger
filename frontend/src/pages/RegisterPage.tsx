import { useState } from "react";
import { Link, useNavigate } from "react-router-dom";
import { useAuth } from "@/contexts/AuthContext";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { PasswordInput } from "@/components/ui/password-input";
import { BrandLogo } from "@/components/BrandLogo";
import { SITE_NAME } from "@/lib/site";
import { Info } from "lucide-react";
// Google sign-in temporarily disabled
// import { GoogleSignInButton, GoogleSignInHint } from "@/components/auth/GoogleSignInButton";

export function RegisterPage() {
  const { register } = useAuth();
  const navigate = useNavigate();
  const [fullName, setFullName] = useState("");
  const [phonePrimary, setPhonePrimary] = useState("");
  const [phoneSecondary, setPhoneSecondary] = useState("");
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [confirmPassword, setConfirmPassword] = useState("");
  const [error, setError] = useState("");
  const [loading, setLoading] = useState(false);

  const onSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setError("");

    if (password.length < 6) {
      setError("Password must be at least 6 characters");
      return;
    }
    if (!fullName.trim()) {
      setError("Full name is required");
      return;
    }
    if (password !== confirmPassword) {
      setError("Passwords do not match");
      return;
    }

    setLoading(true);
    try {
      await register(
        email,
        password,
        fullName || undefined,
        phonePrimary || undefined,
        phoneSecondary || undefined
      );
      navigate("/dashboard");
    } catch (err) {
      setError(err instanceof Error ? err.message : "Registration failed");
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="min-h-screen flex items-center justify-center bg-surface p-4">
      <div className="w-full max-w-md bg-surface-container-lowest rounded-2xl shadow-ambient p-8">
        <BrandLogo size={56} showWordmark wordmarkClassName="text-2xl" className="mb-2" />
        <h1 className="text-lg font-headline font-semibold mb-2 text-on-surface">Create account</h1>
        <div className="flex gap-2 items-start rounded-xl bg-surface-container-low p-3 mb-6 text-xs text-secondary">
          <Info size={16} className="shrink-0 mt-0.5 text-surface-tint" />
          <p>
            Self-hosted {SITE_NAME} does <strong className="text-on-surface">not</strong> send verification
            emails. Your account is active immediately — we only check that the email format is valid.
          </p>
        </div>
        <form onSubmit={onSubmit} className="space-y-4">
          <Input
            id="name"
            label="Full name"
            required
            autoComplete="name"
            value={fullName}
            onChange={(e) => setFullName(e.target.value)}
          />
          <Input
            id="email"
            label="Email"
            type="email"
            autoComplete="email"
            value={email}
            onChange={(e) => setEmail(e.target.value)}
            required
          />
          <Input
            id="phonePrimary"
            label="Primary phone"
            autoComplete="tel"
            value={phonePrimary}
            onChange={(e) => setPhonePrimary(e.target.value)}
          />
          <Input
            id="phoneSecondary"
            label="Secondary phone"
            autoComplete="tel-national"
            value={phoneSecondary}
            onChange={(e) => setPhoneSecondary(e.target.value)}
          />
          <PasswordInput
            id="password"
            label="Password"
            autoComplete="new-password"
            value={password}
            onChange={(e) => setPassword(e.target.value)}
            required
            minLength={6}
          />
          <PasswordInput
            id="confirmPassword"
            label="Confirm password"
            autoComplete="new-password"
            value={confirmPassword}
            onChange={(e) => setConfirmPassword(e.target.value)}
            required
            minLength={6}
          />
          {error && <p className="text-xs text-error">{error}</p>}
          <Button type="submit" className="w-full" disabled={loading}>
            {loading ? "Creating..." : "Register"}
          </Button>
        </form>
        {/* Google sign-in temporarily disabled
        <GoogleSignInButton />
        <GoogleSignInHint />
        */}
        <p className="text-sm text-secondary mt-4 text-center">
          Already have an account?{" "}
          <Link to="/login" className="text-surface-tint font-medium">
            Sign in
          </Link>
        </p>
      </div>
    </div>
  );
}
