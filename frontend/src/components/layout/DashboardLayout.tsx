import { Outlet } from "react-router-dom";
import { Sidebar } from "@/components/layout/sidebar";
import { Header } from "@/components/layout/header";

export function DashboardLayout() {
  return (
    <div className="min-h-screen bg-surface">
      <Sidebar />
      <main className="min-h-screen md:ml-72">
        <Header />
        <div className="p-4 md:p-8 max-w-[1520px] mx-auto">
          <Outlet />
        </div>
      </main>
    </div>
  );
}
