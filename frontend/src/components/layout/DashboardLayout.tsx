import { Outlet } from "react-router-dom";
import { Sidebar } from "@/components/layout/sidebar";
import { Header } from "@/components/layout/header";

export function DashboardLayout() {
  return (
    <div className="min-h-screen bg-surface">
      <Sidebar />
      <main className="md:ml-60 min-h-screen">
        <Header />
        <div className="p-4 md:p-8 max-w-[1520px] mx-auto">
          <Outlet />
        </div>
      </main>
    </div>
  );
}
