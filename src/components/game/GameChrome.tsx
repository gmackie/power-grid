// Shared mobile-first building blocks for the in-game screens.
import React from 'react';
import { Coins, Factory, Home, Zap } from 'lucide-react';
import type { GameState, Player } from '../../types/game';
import { cn } from '../../utils/cn';

/** Fixed bottom bar for the primary actions; content scrolls underneath. */
export function ActionBar({ children, className }: { children: React.ReactNode; className?: string }) {
  return (
    <div
      className={cn(
        'fixed inset-x-0 bottom-0 z-30 border-t border-slate-700 bg-game-surface/95 backdrop-blur',
        'px-3 pt-3 pb-[max(0.75rem,env(safe-area-inset-bottom))] short:pt-2 short:pb-[max(0.5rem,env(safe-area-inset-bottom))]',
        'pl-[max(0.75rem,env(safe-area-inset-left))] pr-[max(0.75rem,env(safe-area-inset-right))]',
        className
      )}
    >
      <div className="mx-auto w-full max-w-3xl space-y-2 short:flex short:max-w-none short:items-center short:gap-3 short:space-y-0 short:[&>*]:min-w-0 short:[&>*]:flex-1">{children}</div>
    </div>
  );
}

export function Section({ title, right, children, className }: { title?: React.ReactNode; right?: React.ReactNode; children: React.ReactNode; className?: string }) {
  return (
    <section className={cn('rounded-xl border border-slate-700 bg-game-card/60 p-3 sm:p-4', className)}>
      {(title || right) && (
        <div className="mb-3 flex items-center justify-between gap-2">
          {title && <h3 className="text-base font-semibold text-white">{title}</h3>}
          {right}
        </div>
      )}
      {children}
    </section>
  );
}

export function ColorDot({ color, className }: { color: string; className?: string }) {
  return <span className={cn('inline-block h-3.5 w-3.5 shrink-0 rounded-full ring-2 ring-white/80', className)} style={{ backgroundColor: color }} />;
}

/** Horizontally scrolling player chips in turn order. */
export function PlayerStrip({ state, myId, actingId }: { state: GameState; myId?: string; actingId?: string }) {
  const order = state.turnOrder.length ? state.turnOrder : state.players.map((p) => p.id);
  const players = order.map((id) => state.players.find((p) => p.id === id)).filter((p): p is Player => !!p);
  return (
    <div className="-mx-3 overflow-x-auto px-3 pb-1 [scrollbar-width:none]">
      <div className="flex gap-2">
        {players.map((p, i) => (
          <div
            key={p.id}
            className={cn(
              'min-w-[9.5rem] shrink-0 rounded-xl border px-3 py-2',
              p.id === actingId ? 'border-yellow-400 bg-yellow-400/10' : 'border-slate-700 bg-game-surface'
            )}
          >
            <div className="flex items-center gap-2">
              <span className="text-xs text-slate-500">{i + 1}</span>
              <ColorDot color={p.color} />
              <span className="truncate text-sm font-medium text-white">
                {p.name}
                {p.id === myId && <span className="text-slate-400"> (you)</span>}
              </span>
              {p.connected === false && <span className="text-[10px] uppercase text-red-400">offline</span>}
            </div>
            <div className="mt-1 flex items-center gap-3 text-xs text-slate-300">
              <span className="flex items-center gap-1 text-yellow-400"><Coins className="h-3.5 w-3.5" />{p.money}</span>
              <span className="flex items-center gap-1"><Home className="h-3.5 w-3.5" />{p.cities.length}</span>
              <span className="flex items-center gap-1"><Factory className="h-3.5 w-3.5" />{p.powerPlants.map((pp) => `#${pp.number}`).join(' ') || '–'}</span>
            </div>
          </div>
        ))}
      </div>
    </div>
  );
}

/** One-line plant summary: number, fuel, output. */
export function PlantSummary({ plant }: { plant: { number: number; resourceType: string; resourceCount: number; citiesPowered: number } }) {
  const fuel = plant.resourceType === 'eco' ? 'wind' : plant.resourceType;
  return (
    <span className="inline-flex items-center gap-1.5">
      <span className="font-bold text-white">#{plant.number}</span>
      <span className="text-slate-400">
        {plant.resourceType === 'eco' ? 'free' : `${plant.resourceCount} ${fuel}`}
      </span>
      <span className="inline-flex items-center text-yellow-400"><Zap className="h-3.5 w-3.5" />{plant.citiesPowered}</span>
    </span>
  );
}

/** Large +/- stepper with 44px targets. */
export function Stepper({ value, onChange, min = 0, max, disabled, label }: {
  value: number; onChange: (v: number) => void; min?: number; max: number; disabled?: boolean; label: string;
}) {
  const btn = 'flex h-11 w-11 items-center justify-center rounded-lg border border-slate-600 text-xl text-white active:bg-slate-700 disabled:opacity-30';
  return (
    <div className="flex items-center gap-2">
      <button type="button" aria-label={`Less ${label}`} className={btn} disabled={disabled || value <= min} onClick={() => onChange(value - 1)}>−</button>
      <span className="w-8 text-center text-xl font-bold tabular-nums text-white">{value}</span>
      <button type="button" aria-label={`More ${label}`} className={btn} disabled={disabled || value >= max} onClick={() => onChange(value + 1)}>+</button>
    </div>
  );
}
