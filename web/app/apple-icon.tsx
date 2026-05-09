import { ImageResponse } from "next/og";

export const runtime = "edge";

export const size = { width: 180, height: 180 };
export const contentType = "image/png";

/** Apple touch icon — home-screen bookmark. */
export default function AppleIcon() {
  return new ImageResponse(
    (
      <div
        style={{
          width: "100%",
          height: "100%",
          display: "flex",
          flexDirection: "column",
          alignItems: "center",
          justifyContent: "center",
          background: "linear-gradient(145deg, #00174b 0%, #0053db 55%, #131b2e 100%)",
          borderRadius: 36,
        }}
      >
        <span
          style={{
            color: "white",
            fontSize: 96,
            fontWeight: 800,
            fontFamily: "system-ui, sans-serif",
            letterSpacing: "-0.06em",
            lineHeight: 1,
          }}
        >
          L
        </span>
        <span
          style={{
            color: "rgba(255,255,255,0.85)",
            fontSize: 18,
            fontWeight: 600,
            fontFamily: "system-ui, sans-serif",
            marginTop: 8,
            letterSpacing: "0.02em",
          }}
        >
          Lyari
        </span>
      </div>
    ),
    { ...size }
  );
}
