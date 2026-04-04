import Link from "next/link";
import {
  ArrowRight,
  PieChart,
  Scale,
  Users,
  Wallet,
} from "lucide-react";
import { createClient } from "@/lib/supabase/server";
import { Button } from "@/components/ui/button";
import {
  Card,
  CardDescription,
  CardHeader,
  CardTitle,
} from "@/components/ui/card";

const features = [
  {
    icon: Wallet,
    title: "Personal ledger",
    description:
      "Track spending by category, set budgets, and keep private transactions in one place.",
  },
  {
    icon: Users,
    title: "Group splits",
    description:
      "Share trips and household costs with Splitwise-style groups and fair splits.",
  },
  {
    icon: PieChart,
    title: "Analytics",
    description:
      "See trends, burn rate, and how personal spend compares to group activity.",
  },
  {
    icon: Scale,
    title: "Settle up",
    description:
      "Simplify who owes whom with debt simplification—fewer transfers, same balances.",
  },
] as const;

export default async function Home() {
  const supabase = createClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();

  return (
    <div className="relative min-h-screen overflow-hidden">
      <div
        className="pointer-events-none absolute inset-0 -z-10"
        aria-hidden
      >
        <div className="absolute -left-32 top-0 h-96 w-96 rounded-full bg-surface-tint/15 blur-3xl" />
        <div className="absolute -right-24 top-1/3 h-80 w-80 rounded-full bg-primary-container/20 blur-3xl" />
        <div className="absolute bottom-0 left-1/3 h-64 w-64 rounded-full bg-secondary-container/30 blur-3xl" />
      </div>

      <header className="mx-auto flex max-w-6xl items-center justify-between px-6 py-6 md:px-8">
        <Link
          href="/"
          className="font-headline text-xl font-extrabold tracking-tight text-on-surface"
        >
          The Ledger
        </Link>
        <nav className="flex items-center gap-3">
          {user ? (
            <Link href="/dashboard">
              <Button variant="gradient" size="sm">
                Dashboard
                <ArrowRight className="ml-1.5 h-4 w-4" aria-hidden />
              </Button>
            </Link>
          ) : (
            <>
              <Link href="/login">
                <Button variant="ghost" size="sm">
                  Sign in
                </Button>
              </Link>
              <Link href="/register">
                <Button variant="gradient" size="sm">
                  Get started
                </Button>
              </Link>
            </>
          )}
        </nav>
      </header>

      <main>
        <section className="mx-auto max-w-6xl px-6 pb-20 pt-8 md:px-8 md:pb-28 md:pt-12">
          <div className="mx-auto max-w-3xl text-center">
            <p className="mb-4 inline-flex items-center rounded-full border border-outline/20 bg-surface-container-lowest/80 px-3 py-1 text-xs font-medium text-secondary shadow-ambient backdrop-blur-sm">
              Personal finance · Group expense sharing
            </p>
            <h1 className="font-headline text-4xl font-extrabold leading-[1.1] tracking-tight text-on-surface md:text-5xl lg:text-6xl">
              One ledger for{" "}
              <span className="text-surface-tint">you</span> and your{" "}
              <span className="text-surface-tint">crew</span>
            </h1>
            <p className="mx-auto mt-6 max-w-xl text-base leading-relaxed text-secondary md:text-lg">
              Track personal expenses, split bills with groups, and settle balances
              without spreadsheets—built on a modern stack you can run yourself.
            </p>
            <div className="mt-10 flex flex-wrap items-center justify-center gap-4">
              {user ? (
                <Link href="/dashboard">
                  <Button variant="gradient" size="lg" className="gap-2">
                    Open dashboard
                    <ArrowRight className="h-5 w-5" aria-hidden />
                  </Button>
                </Link>
              ) : (
                <>
                  <Link href="/register">
                    <Button variant="gradient" size="lg" className="gap-2">
                      Create free account
                      <ArrowRight className="h-5 w-5" aria-hidden />
                    </Button>
                  </Link>
                  <Link href="/login">
                    <Button variant="outline" size="lg">
                      I already have an account
                    </Button>
                  </Link>
                </>
              )}
            </div>
          </div>
        </section>

        <section className="border-t border-outline/10 bg-surface-container-low/40 py-16 md:py-20">
          <div className="mx-auto max-w-6xl px-6 md:px-8">
            <h2 className="text-center font-headline text-2xl font-bold tracking-tight text-on-surface md:text-3xl">
              Everything you need to stay balanced
            </h2>
            <p className="mx-auto mt-3 max-w-2xl text-center text-sm text-secondary md:text-base">
              From daily spend to weekend trips with friends—same app, clear numbers.
            </p>
            <ul className="mt-12 grid gap-6 sm:grid-cols-2 lg:grid-cols-4">
              {features.map(({ icon: Icon, title, description }) => (
                <li key={title}>
                  <Card className="h-full border border-outline/10 p-6 shadow-ambient">
                    <CardHeader className="mb-0 space-y-3 p-0">
                      <div className="flex h-11 w-11 items-center justify-center rounded-lg bg-surface-container text-surface-tint">
                        <Icon className="h-5 w-5" strokeWidth={2} aria-hidden />
                      </div>
                      <CardTitle className="text-base">{title}</CardTitle>
                      <CardDescription className="text-sm leading-relaxed text-secondary">
                        {description}
                      </CardDescription>
                    </CardHeader>
                  </Card>
                </li>
              ))}
            </ul>
          </div>
        </section>

        <section className="mx-auto max-w-6xl px-6 py-16 md:px-8 md:py-24">
          <div className="glass ghost-border relative overflow-hidden rounded-2xl border border-white/40 px-8 py-12 text-center shadow-ambient-lg md:px-16">
            <div
              className="pointer-events-none absolute inset-0 -z-10 bg-gradient-to-br from-surface-container-lowest/90 via-surface-container-low/80 to-surface-container/60"
              aria-hidden
            />
            <h2 className="font-headline text-2xl font-bold text-on-surface md:text-3xl">
              Ready to simplify your money?
            </h2>
            <p className="mx-auto mt-3 max-w-lg text-secondary">
              Sign up in seconds and connect your Supabase project—your data stays yours.
            </p>
            <div className="mt-8 flex flex-wrap justify-center gap-4">
              {user ? (
                <Link href="/dashboard">
                  <Button variant="gradient" size="lg">
                    Go to dashboard
                  </Button>
                </Link>
              ) : (
                <>
                  <Link href="/register">
                    <Button variant="gradient" size="lg">
                      Get started free
                    </Button>
                  </Link>
                  <Link href="/login">
                    <Button variant="secondary" size="lg">
                      Sign in
                    </Button>
                  </Link>
                </>
              )}
            </div>
          </div>
        </section>
      </main>

      <footer className="border-t border-outline/10 py-8 text-center text-xs text-on-surface-variant">
        <p>© {new Date().getFullYear()} The Ledger. Built for clarity, not clutter.</p>
      </footer>
    </div>
  );
}
