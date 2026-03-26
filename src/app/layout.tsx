import type { Metadata } from "next";
import "./globals.css";

export const metadata: Metadata = {
  title: "KPFK 90.7 FM",
  description:
    "KPFK 90.7 FM — Pacifica Foundation community radio in Los Angeles",
  icons: {
    icon: "/favicon.svg",
  },
  alternates: {
    types: {
      "application/rss+xml": "/feed",
    },
  },
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="en">
      <body>
        {/* Persistent root layout — future audio player mounts here */}
        {children}
      </body>
    </html>
  );
}
