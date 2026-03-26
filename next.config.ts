import type { NextConfig } from "next";

const nextConfig: NextConfig = {
  output: "standalone",
  images: {
    remotePatterns: [
      {
        protocol: "https",
        hostname: "czjhwhfqohpmwprhasve.supabase.co",
        pathname: "/storage/v1/object/public/**",
      },
      {
        protocol: "https",
        hostname: "mmo.aiircdn.com",
      },
      {
        protocol: "https",
        hostname: "donate.kpfk.org",
        pathname: "/api/**",
      },
      {
        protocol: "https",
        hostname: "events.kpfk.org",
      },
    ],
  },
};

export default nextConfig;
