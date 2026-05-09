import { ImageResponse } from "next/og";

export const runtime = "edge";

export const size = { width: 32, height: 32 };
export const contentType = "image/png";

/** App icon — gradient “L” mark for Lyari. */
export default function Icon() {
  return new ImageResponse(
    (
      <div
        style={{
          width: "100%",
          height: "100%",
          display: "flex",
          alignItems: "center",
          justifyContent: "center",
          background: "linear-gradient(135deg, #00174b 0%, #0053db 100%)",
          borderRadius: 8,
        }}
      >
        <span
          style={{
            color: "white",
            fontSize: 20,
            fontWeight: 800,
            fontFamily: "system-ui, sans-serif",
            letterSpacing: "-0.05em",
          }}
        >
          L
        </span>
      </div>
    ),
    { ...size }
  );
}
