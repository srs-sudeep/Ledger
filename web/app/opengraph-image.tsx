import { ImageResponse } from "next/og";
import { SITE_NAME, SITE_TAGLINE } from "@/lib/site";

export const runtime = "edge";

export const alt = `${SITE_NAME} — ${SITE_TAGLINE}`;
export const size = { width: 1200, height: 630 };
export const contentType = "image/png";

/** Open Graph / social preview card. */
export default function OpenGraphImage() {
  return new ImageResponse(
    (
      <div
        style={{
          width: "100%",
          height: "100%",
          display: "flex",
          flexDirection: "column",
          justifyContent: "center",
          padding: 72,
          background: "linear-gradient(125deg, #faf8ff 0%, #eaedff 45%, #dae2fd 100%)",
        }}
      >
        <div
          style={{
            display: "flex",
            alignItems: "center",
            gap: 24,
            marginBottom: 36,
          }}
        >
          <div
            style={{
              width: 88,
              height: 88,
              borderRadius: 22,
              display: "flex",
              alignItems: "center",
              justifyContent: "center",
              background: "linear-gradient(135deg, #00174b 0%, #0053db 100%)",
              color: "white",
              fontSize: 52,
              fontWeight: 800,
              fontFamily: "system-ui, sans-serif",
            }}
          >
            L
          </div>
          <div style={{ display: "flex", flexDirection: "column", gap: 6 }}>
            <span
              style={{
                fontSize: 56,
                fontWeight: 800,
                color: "#131b2e",
                fontFamily: "system-ui, sans-serif",
                letterSpacing: "-0.03em",
                lineHeight: 1.1,
              }}
            >
              {SITE_NAME}
            </span>
            <span
              style={{
                fontSize: 22,
                fontWeight: 600,
                color: "#0053db",
                fontFamily: "system-ui, sans-serif",
              }}
            >
              Personal · Groups · Settle up
            </span>
          </div>
        </div>
        <p
          style={{
            fontSize: 28,
            color: "#515f74",
            lineHeight: 1.45,
            maxWidth: 980,
            fontFamily: "system-ui, sans-serif",
            fontWeight: 500,
            margin: 0,
          }}
        >
          {SITE_TAGLINE}
        </p>
      </div>
    ),
    { ...size }
  );
}
