import type { Metadata } from "next";
import { Inter } from "next/font/google";
import "./globals.css";
import Sidebar from "@/components/Sidebar";

const inter = Inter({ subsets: ["latin"] });

export const metadata: Metadata = {
  title: "Ummu Admin Dashboard",
  description: "Next.js admin panel for the Ummu app.",
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="en" className="h-full bg-slate-50 dark:bg-slate-900">
      <body className={`${inter.className} h-full antialiased`}>
        <div className="flex h-full">
          <aside className="w-72 flex-none hidden lg:block">
            <Sidebar />
          </aside>
          <main className="flex-1 overflow-y-auto px-4 py-8 sm:px-6 lg:px-8">
            {children}
          </main>
        </div>
      </body>
    </html>
  );
}
