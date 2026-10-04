import React, { useMemo, useState } from 'react';
import { Building2, MapPin, ZoomIn, ZoomOut } from 'lucide-react';
import { useGameStore } from '../../store/gameStore';
import type { City } from '../../types/game';
import Button from '../ui/Button';
import GameBoard from '../GameBoard';
import { ActionBar, ColorDot, Section } from '../game/GameChrome';
import { useGameView } from '../../hooks/useGameView';
import { cn } from '../../utils/cn';
import { checkBuild, type BuildCheck } from '../../utils/rules';

const BuildingPhase: React.FC = () => {
  const { gameState, me, isMyTurn } = useGameView();
  const buildCity = useGameStore((s) => s.buildCity);
  const endTurn = useGameStore((s) => s.endTurn);
  const [selectedId, setSelectedId] = useState<string | null>(null);
  const [zoom, setZoom] = useState(1);
  const [showAll, setShowAll] = useState(false);

  const cities = useMemo(() => gameState?.cities ?? [], [gameState?.cities]);
  const checks = useMemo(() => {
    const out = new Map<string, BuildCheck>();
    if (gameState && me) for (const c of cities) out.set(c.id, checkBuild(gameState, me, c));
    return out;
  }, [gameState, me, cities]);

  const outOfPlay = useMemo(() => {
    const regions = gameState?.activeRegions ?? [];
    return new Set(cities.filter((c) => regions.length > 0 && !regions.includes(c.region)).map((c) => c.id));
  }, [cities, gameState?.activeRegions]);
  const buildable = useMemo(
    () => new Set(isMyTurn ? [...checks].filter(([, r]) => r.ok).map(([id]) => id) : []),
    [checks, isMyTurn]
  );

  if (!gameState || !me) return null;

  const selected = cities.find((c) => c.id === selectedId);
  const selectedCheck = selected ? checks.get(selected.id) : undefined;
  const mine = cities.filter((c) => me.cities.includes(c.id));

  const rows = cities
    .filter((c) => !outOfPlay.has(c.id) && !me.cities.includes(c.id))
    .map((c) => ({ city: c, check: checks.get(c.id)! }))
    .filter((r) => showAll || r.check.ok)
    .sort((a, b) => Number(b.check.ok) - Number(a.check.ok) || (a.check.cost ?? 999) - (b.check.cost ?? 999) || a.city.name.localeCompare(b.city.name));

  const select = (c: City) => setSelectedId(c.id === selectedId ? null : c.id);
  const build = () => {
    if (!selected || !selectedCheck?.ok) return;
    buildCity(selected.id);
    setSelectedId(null);
  };

  return (
    <div className="space-y-3">
      <Section
        title="Map"
        right={
          <div className="flex gap-1">
            <button aria-label="Zoom out" className="flex h-9 w-9 items-center justify-center rounded-lg border border-slate-600 text-white disabled:opacity-30" disabled={zoom <= 1} onClick={() => setZoom((z) => Math.max(1, z - 0.5))}><ZoomOut className="h-4 w-4" /></button>
            <button aria-label="Zoom in" className="flex h-9 w-9 items-center justify-center rounded-lg border border-slate-600 text-white disabled:opacity-30" disabled={zoom >= 3} onClick={() => setZoom((z) => Math.min(3, z + 0.5))}><ZoomIn className="h-4 w-4" /></button>
          </div>
        }
      >
        <div className="-mx-1 overflow-auto overscroll-contain rounded-lg">
          <div style={{ width: `${zoom * 100}%` }}>
            <GameBoard
              cities={cities}
              mapId={gameState.mapId}
              selectedId={selectedId}
              buildable={buildable}
              outOfPlay={outOfPlay}
              onSelect={select}
            />
          </div>
        </div>
        <p className="mt-2 text-xs text-slate-400">
          {isMyTurn ? 'Green rings: you can build there. Tap a city to select it.' : 'Tap a city for details.'}
          {zoom === 1 ? ' Zoom in for names and costs.' : ''}
        </p>
      </Section>

      {selected && (
        <Section title={selected.name} right={<span className="text-xs capitalize text-slate-400">{selected.region.replace(/_/g, ' ')}</span>}>
          <div className="flex items-center gap-2 text-sm text-slate-300">
            {selected.houses.length === 0 ? 'No houses yet' : selected.houses.map((h, i) => (
              <span key={i} className="flex items-center gap-1"><ColorDot color={h.playerColor} />{gameState.players.find((p) => p.id === h.playerId)?.name}</span>
            ))}
          </div>
          {selectedCheck && (
            <p className={cn('mt-2 text-sm', selectedCheck.ok ? 'text-green-400' : 'text-red-400')}>
              {selectedCheck.ok
                ? `House $${selectedCheck.houseCost} + connection $${selectedCheck.connection} = $${selectedCheck.cost}`
                : selectedCheck.reason}
            </p>
          )}
        </Section>
      )}

      <Section
        title={showAll ? 'All cities' : 'You can build in'}
        right={<button className="text-sm text-blue-400" onClick={() => setShowAll((v) => !v)}>{showAll ? 'Only buildable' : 'Show all'}</button>}
      >
        {rows.length === 0 ? (
          <p className="text-sm text-slate-400">{me.money < 10 ? 'Not enough money to build.' : 'Nowhere to build right now.'}</p>
        ) : (
          <ul className="divide-y divide-slate-700">
            {rows.map(({ city, check }) => (
              <li key={city.id}>
                <button
                  data-testid="city-item"
                  onClick={() => select(city)}
                  className={cn('flex min-h-[48px] w-full items-center gap-3 px-1 py-2 text-left', city.id === selectedId && 'bg-blue-500/15')}
                >
                  <MapPin className={cn('h-4 w-4 shrink-0', check.ok ? 'text-green-400' : 'text-slate-500')} />
                  <span className="min-w-0 flex-1">
                    <span className="block truncate text-white">{city.name}</span>
                    <span className="block text-xs text-slate-400">{check.ok ? `${city.houses.length}/3 houses` : check.reason}</span>
                  </span>
                  <span className="flex gap-1">{city.houses.map((h, i) => <ColorDot key={i} color={h.playerColor} />)}</span>
                  {check.ok && <span className="w-12 text-right font-semibold tabular-nums text-yellow-400">${check.cost}</span>}
                </button>
              </li>
            ))}
          </ul>
        )}
      </Section>

      {mine.length > 0 && (
        <Section title={`Your network (${mine.length})`}>
          <p className="text-sm text-slate-300">{mine.map((c) => c.name).join(', ')}</p>
        </Section>
      )}

      {isMyTurn && (
        <ActionBar>
          <div className="flex gap-2">
            <Button className="flex-1" onClick={build} disabled={!selectedCheck?.ok}>
              <Building2 className="mr-2 h-5 w-5" />
              {selected ? (selectedCheck?.ok ? `Build ${selected.name} $${selectedCheck.cost}` : `Can't build ${selected.name}`) : 'Select a city'}
            </Button>
            <Button variant="outline" onClick={() => { setSelectedId(null); endTurn(); }}>Done</Button>
          </div>
        </ActionBar>
      )}
    </div>
  );
};

export default BuildingPhase;
