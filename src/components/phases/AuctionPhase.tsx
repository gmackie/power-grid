import React, { useEffect, useMemo, useState } from 'react';
import { Gavel } from 'lucide-react';
import { useGameStore } from '../../store/gameStore';
import type { PowerPlant } from '../../types/game';
import Button from '../ui/Button';
import { PlantCard } from '../ui/Art';
import { ActionBar, PlantSummary, Section, Stepper } from '../game/GameChrome';
import { useGameView } from '../../hooks/useGameView';
import { cn } from '../../utils/cn';
import { playerName } from '../../utils/rules';

function PlantTile({ plant, selected, disabled, onSelect, badge }: {
  plant: PowerPlant; selected?: boolean; disabled?: boolean; onSelect?: () => void; badge?: string;
}) {
  return (
    <button
      type="button"
      data-testid="power-plant"
      disabled={disabled || !onSelect}
      onClick={onSelect}
      className={cn(
        'relative rounded-xl border-2 p-1.5 text-left transition-colors',
        selected ? 'border-blue-400 bg-blue-500/20 ring-4 ring-blue-400/40' : 'border-slate-700 bg-game-surface',
        onSelect && !disabled && 'active:border-blue-300',
        disabled && 'opacity-50'
      )}
    >
      <PlantCard type={plant.resourceType} number={plant.number} className="h-auto w-full rounded-lg" width={undefined} height={undefined} />
      <div className="mt-1 flex items-center justify-between px-0.5 text-xs">
        <PlantSummary plant={plant} />
      </div>
      {badge && <span className="absolute -right-1 -top-1 rounded-full bg-yellow-400 px-2 py-0.5 text-xs font-bold text-black">{badge}</span>}
    </button>
  );
}

const AuctionPhase: React.FC = () => {
  const { gameState, myId, me, isMyTurn } = useGameView();
  const bid = useGameStore((s) => s.bid);
  const pass = useGameStore((s) => s.pass);
  const [selectedId, setSelectedId] = useState<number | null>(null);
  const [amount, setAmount] = useState(0);

  const auction = gameState?.auctionState;
  const live = auction?.currentPlant;
  const market = useMemo(() => gameState?.powerPlantMarket ?? [], [gameState?.powerPlantMarket]);
  const future = gameState?.futureMarket ?? [];
  const selected = live ?? market.find((p) => p.id === selectedId);
  const money = me?.money ?? 0;
  const minBid = live ? (auction?.currentBid ?? 0) + 1 : selected?.number ?? 0;
  const firstRound = (gameState?.currentRound ?? 1) === 1;
  const iAmDone = !live && !!me?.hasPassed;
  const nominating = isMyTurn && !live && !iAmDone;

  // Reset the bid whenever the thing being bid on (or its price) changes.
  useEffect(() => { setAmount(Math.min(minBid, money)); }, [minBid, money, live?.id, selectedId]);
  // Drop a selection that left the market.
  useEffect(() => { if (selectedId !== null && !market.some((p) => p.id === selectedId)) setSelectedId(null); }, [market, selectedId]);

  if (!gameState) return null;

  // High bidder is whoever acted before the current bidder in the participant ring.
  const parts = auction?.biddingOrder ?? [];
  const highBidder = live && parts.length
    ? parts[(parts.indexOf(auction!.currentBidder ?? '') - 1 + parts.length) % parts.length]
    : undefined;

  const canAfford = amount >= minBid && amount <= money;
  const submit = () => {
    if (!selected || !canAfford) return;
    bid(amount, live ? undefined : selected.id);
    setSelectedId(null);
  };

  return (
    <div className="space-y-3">
      {live && (
        <Section title={<span className="flex items-center gap-2"><Gavel className="h-4 w-4 text-blue-400" />Up for auction</span>}>
          <div className="grid grid-cols-[minmax(0,9rem)_1fr] items-center gap-3">
            <PlantTile plant={live} badge={`$${auction!.currentBid}`} />
            <div className="space-y-1 text-sm">
              <p className="text-2xl font-bold text-yellow-400">${auction!.currentBid}</p>
              <p className="text-slate-300">High bid: {highBidder === myId ? 'you' : playerName(gameState, highBidder)}</p>
              <p className="text-slate-400">Next to act: {auction!.currentBidder === myId ? 'you' : playerName(gameState, auction!.currentBidder)}</p>
              <p className="text-slate-500">Still in: {parts.map((id) => (id === myId ? 'you' : playerName(gameState, id))).join(', ')}</p>
            </div>
          </div>
        </Section>
      )}

      <Section title="Current market" right={<span className="text-xs text-slate-400">{nominating ? 'Tap a plant' : 'Buyable now'}</span>}>
        <div className="grid grid-cols-2 gap-2 sm:grid-cols-4">
          {market.map((p) => (
            <PlantTile
              key={p.id}
              plant={p}
              selected={selected?.id === p.id}
              disabled={!!live && live.id !== p.id}
              onSelect={nominating ? () => setSelectedId(p.id) : undefined}
            />
          ))}
        </div>
      </Section>

      {future.length > 0 && (
        <Section title="Future market" right={<span className="text-xs text-slate-400">{gameState.deckRemaining ?? ''} left in deck</span>}>
          <div className="grid grid-cols-4 gap-2 opacity-70">
            {future.map((p) => (
              <div key={p.id} className="rounded-lg border border-slate-700 bg-game-surface p-1">
                <PlantCard type={p.resourceType} number={p.number} className="h-auto w-full rounded" width={undefined} height={undefined} />
              </div>
            ))}
          </div>
        </Section>
      )}

      {me && me.powerPlants.length > 0 && (
        <Section title="Your plants">
          <div className="flex flex-wrap gap-x-4 gap-y-1 text-sm">
            {me.powerPlants.map((p) => <PlantSummary key={p.id} plant={p} />)}
          </div>
        </Section>
      )}

      {isMyTurn && (
        <ActionBar>
          {selected ? (
            <>
              <div className="flex items-center justify-between gap-2">
                <div className="min-w-0 text-sm">
                  <p className="truncate text-slate-300"><PlantSummary plant={selected} /></p>
                  <p className="text-xs text-slate-500">Min ${minBid} · you have ${money}</p>
                </div>
                <Stepper label="bid" value={amount} onChange={setAmount} min={minBid} max={money} />
              </div>
              {live && (
                <div className="flex gap-2">
                  {[1, 5, 10].map((inc) => (
                    <Button key={inc} size="sm" variant="outline" className="flex-1" disabled={auction!.currentBid + inc > money}
                      onClick={() => setAmount(auction!.currentBid + inc)}>
                      ${auction!.currentBid + inc}
                    </Button>
                  ))}
                </div>
              )}
              <div className="flex gap-2">
                <Button className="flex-1" onClick={submit} disabled={!canAfford}>
                  <Gavel className="mr-2 h-5 w-5" />
                  {money < minBid ? "Can't afford" : live ? `Bid $${amount}` : `Open at $${amount}`}
                </Button>
                {live ? (
                  <Button variant="outline" onClick={pass}>Pass</Button>
                ) : (
                  <Button variant="outline" onClick={() => setSelectedId(null)}>Back</Button>
                )}
              </div>
            </>
          ) : (
            <div className="flex items-center gap-2">
              <p className="flex-1 text-sm text-slate-300">Tap a plant in the current market to put it up for auction.</p>
              <Button variant="outline" onClick={pass} disabled={firstRound}>
                {firstRound ? 'Must buy in round 1' : 'Pass'}
              </Button>
            </div>
          )}
        </ActionBar>
      )}

      {iAmDone && (
        <p className="text-center text-sm text-slate-400">You're done with the auction this round.</p>
      )}
    </div>
  );
};

export default AuctionPhase;
