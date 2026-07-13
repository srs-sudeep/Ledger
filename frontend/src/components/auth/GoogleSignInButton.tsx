import { GoogleLogin } from "@react-oauth/google";
import { useAuth } from "@/contexts/AuthContext";
import { useState } from "react";

const GOOGLE_CLIENT_ID = import.meta.env.VITE_GOOGLE_CLIENT_ID as string | undefined;

export function GoogleSignInButton() {
  const { loginWithGoogle } = useAuth();
  const [error, setError] = useState("");

  if (!GOOGLE_CLIENT_ID) return null;

  return (
    <div className="space-y-2">
      <div className="relative my-4">
        <div className="absolute inset-0 flex items-center">
          <div className="w-full border-t border-outline-variant/40" />
        </div>
        <p className="relative text-center text-xs text-secondary bg-surface-container-lowest px-2 mx-auto w-fit">
          or continue with
        </p>
      </div>
      <div className="flex justify-center">
        <GoogleLogin
          onSuccess={async (res) => {
            if (!res.credential) return;
            setError("");
            try {
              await loginWithGoogle(res.credential);
            } catch (e) {
              setError(e instanceof Error ? e.message : "Google sign-in failed");
            }
          }}
          onError={() => setError("Google sign-in was cancelled or failed")}
          useOneTap={false}
          theme="outline"
          size="large"
          text="continue_with"
          shape="rectangular"
        />
      </div>
      {error && <p className="text-xs text-error text-center">{error}</p>}
    </div>
  );
}

export function GoogleSignInHint() {
  if (GOOGLE_CLIENT_ID) return null;
  return (
    <p className="text-[11px] text-secondary text-center mt-3">
      Google sign-in: set <code className="text-xs">VITE_GOOGLE_CLIENT_ID</code> and{" "}
      <code className="text-xs">GOOGLE_CLIENT_ID</code> in <code className="text-xs">.env</code>
    </p>
  );
}
