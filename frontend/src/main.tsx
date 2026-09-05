import React from "react";
import ReactDOM from "react-dom/client";
import { BrowserRouter } from "react-router-dom";
// Google sign-in temporarily disabled
// import { GoogleOAuthProvider } from "@react-oauth/google";
import App from "./App";
import "./index.css";

// const googleClientId = import.meta.env.VITE_GOOGLE_CLIENT_ID as string | undefined;

const app = (
  <BrowserRouter>
    <App />
  </BrowserRouter>
);

ReactDOM.createRoot(document.getElementById("root")!).render(
  <React.StrictMode>
    {/* Google sign-in temporarily disabled
    {googleClientId ? (
      <GoogleOAuthProvider clientId={googleClientId}>{app}</GoogleOAuthProvider>
    ) : (
      app
    )}
    */}
    {app}
  </React.StrictMode>
);
