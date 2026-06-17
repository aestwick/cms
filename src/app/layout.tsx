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

// Runs before paint to set the theme with no flash of the wrong mode.
const themeInitScript = `(function(){try{var t=localStorage.getItem('kpfk-theme');if(!t){t=window.matchMedia('(prefers-color-scheme: dark)').matches?'dark':'light';}document.documentElement.dataset.mode=t;}catch(e){}})();`;

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="en" suppressHydrationWarning>
      <head>
        <script dangerouslySetInnerHTML={{ __html: themeInitScript }} />
      </head>
      <body>
        {/* Persistent root layout — future audio player mounts here */}
        {children}
      </body>
    </html>
  );
}
