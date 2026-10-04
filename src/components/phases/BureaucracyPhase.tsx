import React, { useEffect, useMemo, useState } from 'react';
import { Check, Zap } from 'lucide-react';
import { useGameStore } from '../../store/gameStore';
import type { Player } from '../../types/game';
import Button from '../ui/Button';
import { PlantCard } from '../ui/Art';
import { ActionBar, PlantSummary, Section } from '../game/GameChrome';
import { useGameView } from '../../hooks/useGameView';
import { cn } from '../../utils/cn';
import { FUELS, incomeFor, powerPlan } from '../../utils/rules';

/** Greedy default: biggest plants first, keep each one the fuel still covers. */
function bestSelection(me: Player): number[] {
  const chosen: number[] = [];
  for (const p of [...me.powerPlants].sort((a, b) => b.citiesPowered - a.citiesPowered)) {
    if (powerPlan(me, [...chosen, p.id]).ok) chosen.push(p.id);
    if (powerPlan(me, chosen).capacity >= me.cities.length) break;
  }
  return chosen;
}

const BureaucracyPhase: React.FC = () => {
  const { gameState, me, isMyTurn } = useGameView();
  const powerCities = useGameStore((s) => s.powerCities);
  const endTurn = useGameStore((s) => s.endTurn);
  const [chosen, setChosen] = useState<number[]>([]);

  const meKey = me ? JSON.stringify([me.powerPlants.map((p) => p.id), me.resources, me.cities.length]) : '';
  // eslint-disable-next-line react-hooks/exhaustive-deps
  useEffect(() => { if (me) setChosen(bestSelection(me)); }, [meKey, isMyTurn]);

  const plan = useMemo(() => (me ? powerPlan(me, chosen) : undefined), [me, chosen]);
  if (!gameState || !me || !plan) return null;

  const powered = Math.min(plan.capacity, me.cities.length);
  const income = incomeFor(powered);

  const toggle = (id: number) => {
    const next = chosen.includes(id) ? chosen.filter((x) => x !== id) : [...chosen, id];
    if (powerPlan(me, next).ok) setChosen(next);
  };
  const runnable = (id: number) => chosen.includes(id) || powerPlan(me, [...chosen, id]).ok;

  const submit = () => {
    if (chosen.length) powerCities(chosen);
    endTurn(); // collects $10 base income if nothing was powered
  };

  return (
    <div className="space-y-3">
      <Section title="Power your cities" right={<span className="text-xs text-slate-400">{me.cities.length} {me.cities.length === 1 ? 'city' : 'cities'} owned</span>}>
        {me.powerPlants.length === 0 ? (
          <p className="text-sm text-slate-400">You have no power plants yet.</p>
        ) : (
          <div className="grid grid-cols-2 gap-2 sm:grid-cols-3">
            {me.powerPlants.map((p) => {
              const on = chosen.includes(p.id);
              const can = runnable(p.id);
              return (
                <button
                  key={p.id}
                  type="button"
                  disabled={!isMyTurn || !can}
                  onClick={() => toggle(p.id)}
                  className={cn(
                    'relative rounded-xl border-2 p-1.5 text-left',
                    on ? 'border-green-400 bg-green-500/15' : 'border-slate-700 bg-game-surface',
                    !can && 'opacity-50'
                  )}
                >
                  <PlantCard type={p.resourceType} number={p.number} className="h-auto w-full rounded-lg" width={undefined} height={undefined} />
                  <div className="mt-1 px-0.5 text-xs"><PlantSummary plant={p} /></div>
                  <p className="px-0.5 text-[11px] text-slate-400">{on ? 'Running' : can ? 'Tap to run' : 'Not enough fuel'}</p>
                  {on && <Check className="absolute right-2 top-2 h-5 w-5 rounded-full bg-green-500 p-0.5 text-white" />}
                </button>
              );
            })}
          </div>
        )}
        <p className="mt-3 text-xs text-slate-400">
          Fuel: {FUELS.filter((f) => me.resources[f] > 0).map((f) => `${me.resources[f]} ${f}`).join(', ') || 'none'}
          {FUELS.some((f) => plan.used[f] > 0) && ` · burning ${FUELS.filter((f) => plan.used[f]).map((f) => `${plan.used[f]} ${f}`).join(', ')}`}
        </p>
      </Section>

      <Section>
        <div className="grid grid-cols-3 text-center">
          <div><p className="text-xs text-slate-400">Capacity</p><p className="text-xl font-bold text-white">{plan.capacity}</p></div>
          <div><p className="text-xs text-slate-400">Powered</p><p className="text-xl font-bold text-white">{powered}/{me.cities.length}</p></div>
          <div><p className="text-xs text-slate-400">Income</p><p className="text-xl font-bold text-green-400">${income}</p></div>
        </div>
      </Section>

      {isMyTurn && (
        <ActionBar>
          <Button className="w-full" onClick={submit}>
            <Zap className="mr-2 h-5 w-5" />
            {powered > 0 ? `Power ${powered} ${powered === 1 ? 'city' : 'cities'} & collect $${income}` : `Collect $${income} & end turn`}
          </Button>
        </ActionBar>
      )}
    </div>
  );
};

export default BureaucracyPhase;
