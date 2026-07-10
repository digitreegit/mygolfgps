import type { Metadata } from "next";
import "./globals.css";

export const metadata: Metadata = {
  title: "MyGolfGPS",
  description: "Golf GPS for Apple Watch — yards to the green, powered by OpenStreetMap",
};

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="en">
      <body>{children}</body>
    </html>
  );
}
