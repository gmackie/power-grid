import React, { useEffect, useMemo, useState } from 'react';
import { ShoppingCart } from 'lucide-react';
import { useGameStore } from '../../store/gameStore';
import Button from '../ui/Button';
import { ResourceIcon } from '../ui/Art';
import { ActionBar, PlantSummary, Section, Stepper } from '../game/GameChrome';
import { useGameView } from '../../hooks/useGameView';
import {
  FUELS, type Fuel, fitsStorage, nextPrice, playerStore, purchaseCost, storageCapacity, tokensAvailable, usableFuels,
} from '../../utils/rules';

const EMPTY: Record<Fuel, number> = { coal: 0, oil: 0, garbage: 0, uranium: 0 };

/** Price ladder as small chips: "$3×2 $4×3 …". */
function Ladder({ ladder }: { ladder: number[] }) {
  const rungs = ladder.map((n, price) => ({ n, price })).filter((r) => r.price > 0 && r.n > 0);
  if (rungs.length === 0) return <span className="text-xs text-red-400">Sold out</span>;
  return (
    <div className="flex flex-wrap gap-1">
      {rungs.map((r) => (
        <span key={r.price} className="rounded bg-slate-800 px-1.5 py-0.5 text-[11px] tabular-nums text-slate-300">
          ${r.price}×{r.n}
        </span>
      ))}
    </div>
  );
}

const ResourcePhase: React.FC = () => {
  const { gameState, me, isMyTurn } = useGameView();
  const buyResources = useGameStore((s) => s.buyResources);
  const endTurn = useGameStore((s) => s.endTurn);
  const [cart, setCart] = useState<Record<Fuel, number>>(EMPTY);

  const ladders = gameState?.resourceLadders;
  const plants = me?.powerPlants ?? [];
  const owned = me ? playerStore(me) : EMPTY;
  const usable = usableFuels(plants);
  const cap = storageCapacity(plants);

  // A new turn or a market change invalidates the cart.
  const ladderKey = JSON.stringify(ladders);
  useEffect(() => { setCart(EMPTY); }, [isMyTurn, ladderKey]);

  const costOf = (f: Fuel, n: number) => purchaseCost(ladders?.[f], n);
  const total = useMemo(
    () => FUELS.reduce((sum, f) => sum + (costOf(f, cart[f]) ?? Infinity), 0),
    // eslint-disable-next-line react-hooks/exhaustive-deps
    [cart, ladderKey]
  );

  /** Most of `fuel` we could add given storage, supply and money. */
  const maxFor = (f: Fuel): number => {
    let n = cart[f];
    for (;;) {
      const next = { ...cart, [f]: n + 1 };
      const after = FUELS.reduce((acc, x) => ({ ...acc, [x]: owned[x] + next[x] }), {} as Record<Fuel, number>);
      const cost = FUELS.reduce((sum, x) => sum + (costOf(x, next[x]) ?? Infinity), 0);
      if (!fitsStorage(plants, after) || cost > (me?.money ?? 0)) return n;
      n += 1;
    }
  };

  if (!gameState || !me) return null;

  const nothing = FUELS.every((f) => cart[f] === 0);
  const buyAndEnd = () => {
    if (!nothing) buyResources({ ...cart, hybrid: 0, eco: 0 });
    endTurn();
    setCart(EMPTY);
  };

  return (
    <div className="space-y-3">
      {plants.length > 0 && (
        <Section title="Your plants">
          <div className="flex flex-wrap gap-x-4 gap-y-1 text-sm">
            {plants.map((p) => <PlantSummary key={p.id} plant={p} />)}
          </div>
        </Section>
      )}

      <Section title="Resource market" right={isMyTurn ? <span className="text-xs text-slate-400">Cheapest first</span> : undefined}>
        <div className="space-y-2">
          {FUELS.map((f) => {
            const canUse = usable.includes(f);
            const storage = cap.own[f] + (f === 'coal' || f === 'oil' ? cap.hybrid : 0);
            const lineCost = costOf(f, cart[f]);
            return (
              <div key={f} className="rounded-lg bg-game-surface p-3">
                <div className="flex items-center gap-3">
                  <ResourceIcon type={f} size={36} />
                  <div className="min-w-0 flex-1">
                    <div className="flex items-baseline justify-between gap-2">
                      <p className="font-medium capitalize text-white">{f}</p>
                      <p className="text-xs text-slate-400">
                        {tokensAvailable(ladders?.[f])} left · next ${nextPrice(ladders?.[f]) ?? '–'}
                      </p>
                    </div>
                    <p className="text-xs text-slate-400">
                      {canUse ? `You hold ${owned[f]} / ${storage}` : `You hold ${owned[f]} · no plant uses ${f}`}
                    </p>
                  </div>
                </div>
                <div className="mt-2"><Ladder ladder={ladders?.[f] ?? []} /></div>
                {isMyTurn && canUse && (
                  <div className="mt-2 flex items-center justify-between">
                    <span className="text-sm tabular-nums text-yellow-400">{cart[f] > 0 ? `$${lineCost ?? '–'}` : ''}</span>
                    <Stepper label={f} value={cart[f]} max={maxFor(f)} onChange={(v) => setCart({ ...cart, [f]: Math.max(0, v) })} />
                  </div>
                )}
              </div>
            );
          })}
        </div>
      </Section>

      {isMyTurn && (
        <ActionBar>
          <div className="flex items-center justify-between text-sm short:hidden">
            <span className="text-slate-400">{nothing ? 'Nothing in cart' : `Cart: ${FUELS.filter((f) => cart[f]).map((f) => `${cart[f]} ${f}`).join(', ')}`}</span>
            <span className="font-bold tabular-nums text-yellow-400">${nothing ? 0 : total} / ${me.money}</span>
          </div>
          <div className="flex gap-2">
            <Button className="flex-1" onClick={buyAndEnd} disabled={!nothing && total > me.money}>
              <ShoppingCart className="mr-2 h-5 w-5" />
              {nothing ? 'Buy nothing & end turn' : `Buy for $${total} & end turn`}
            </Button>
            {!nothing && <Button variant="outline" onClick={() => setCart(EMPTY)}>Clear</Button>}
          </div>
        </ActionBar>
      )}
    </div>
  );
};

export default ResourcePhase;
