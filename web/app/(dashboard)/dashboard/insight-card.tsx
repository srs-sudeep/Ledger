import { ArrowRight } from "lucide-react";

export function InsightCard() {
  return (
    <div className="cta-gradient text-white p-8 rounded-xl relative overflow-hidden">
      <div className="relative z-10">
        <h4 className="text-[10px] font-bold opacity-70 uppercase tracking-widest mb-4">
          Savvy Spender Pro
        </h4>
        <p className="text-xl font-headline font-bold leading-tight mb-6">
          Split expenses with friends and simplify debts automatically.
        </p>
        <button className="flex items-center gap-2 text-xs font-bold group">
          View Groups
          <ArrowRight
            size={14}
            className="group-hover:translate-x-1 transition-transform"
          />
        </button>
      </div>
      <div className="absolute -bottom-10 -right-10 w-40 h-40 bg-white/10 rounded-full blur-2xl" />
      <div className="absolute -top-10 -left-10 w-32 h-32 bg-white/5 rounded-full blur-xl" />
    </div>
  );
}
