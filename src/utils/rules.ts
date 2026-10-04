// Client-side mirror of the server rules (cf_server/src/domain), used to preview
// costs and disable impossible moves. The server stays authoritative.

import type { City, GameState, Player, PowerPlant } from '../types/game';

export type Fuel = 'coal' | 'oil' | 'garbage' | 'uranium';
export const FUELS: readonly Fuel[] = ['coal', 'oil', 'garbage', 'uranium'];

/** House cost by how many houses the city already has (domain/rules.ts CITY_SLOT_COST). */
export const CITY_SLOT_COST = [10, 15, 20] as const;
export const slotsOpenInStep = (step: number | undefined): number => Math.min(Math.max(step ?? 1, 1), 3);

export const INCOME_TABLE = [10, 22, 33, 44, 54, 64, 73, 82, 90, 98, 105, 112, 118, 124, 129, 134, 138, 142, 145, 148, 150];
export const incomeFor = (powered: number): number =>
  INCOME_TABLE[Math.min(Math.max(powered, 0), INCOME_TABLE.length - 1)];

/** Cities needed to end the game, by player count. */
export const END_GAME_CITIES: Record<number, number> = { 2: 21, 3: 17, 4: 17, 5: 15, 6: 14 };

// --- resources -----------------------------------------------------------------

/** Cost of buying `amount` tokens cheapest-first, or undefined if the market runs out. */
export function purchaseCost(ladder: readonly number[] | undefined, amount: number): number | undefined {
  if (amount <= 0) return 0;
  if (!ladder) return undefined;
  let remaining = amount;
  let cost = 0;
  for (let price = 1; price < ladder.length && remaining > 0; price++) {
    const take = Math.min(ladder[price] ?? 0, remaining);
    cost += take * price;
    remaining -= take;
  }
  return remaining > 0 ? undefined : cost;
}

export const tokensAvailable = (ladder: readonly number[] | undefined): number =>
  (ladder ?? []).reduce((a, b) => a + b, 0);

/** Next token price (cheapest available), or undefined if sold out. */
export function nextPrice(ladder: readonly number[] | undefined): number | undefined {
  if (!ladder) return undefined;
  for (let price = 1; price < ladder.length; price++) if ((ladder[price] ?? 0) > 0) return price;
  return undefined;
}

export function storageCapacity(plants: readonly PowerPlant[]): { own: Record<Fuel, number>; hybrid: number } {
  const own: Record<Fuel, number> = { coal: 0, oil: 0, garbage: 0, uranium: 0 };
  let hybrid = 0;
  for (const p of plants) {
    if (p.resourceType === 'hybrid') hybrid += 2 * p.resourceCount;
    else if (p.resourceType !== 'eco') own[p.resourceType as Fuel] += 2 * p.resourceCount;
  }
  return { own, hybrid };
}

export function fitsStorage(plants: readonly PowerPlant[], store: Record<Fuel, number>): boolean {
  const cap = storageCapacity(plants);
  if (store.garbage > cap.own.garbage || store.uranium > cap.own.uranium) return false;
  const overflow = Math.max(0, store.coal - cap.own.coal) + Math.max(0, store.oil - cap.own.oil);
  return overflow <= cap.hybrid;
}

/** Fuels this player's plants can burn at all. */
export function usableFuels(plants: readonly PowerPlant[]): Fuel[] {
  const cap = storageCapacity(plants);
  return FUELS.filter((f) => cap.own[f] > 0 || (cap.hybrid > 0 && (f === 'coal' || f === 'oil')));
}

export const playerStore = (p: Player): Record<Fuel, number> => ({
  coal: p.resources.coal,
  oil: p.resources.oil,
  garbage: p.resources.garbage,
  uranium: p.resources.uranium,
});

// --- building ------------------------------------------------------------------

/** Cheapest connection cost from any owned city to `target` (Dijkstra over map edges). */
export function connectionCost(cities: readonly City[], owned: readonly string[], target: string): number | undefined {
  if (owned.length === 0 || owned.includes(target)) return 0;
  const byId = new Map(cities.map((c) => [c.id, c]));
  const dist = new Map<string, number>(owned.map((id) => [id, 0]));
  const visited = new Set<string>();
  for (;;) {
    let best: string | undefined;
    let bestD = Infinity;
    for (const [id, d] of dist) if (!visited.has(id) && d < bestD) { best = id; bestD = d; }
    if (best === undefined) return undefined;
    if (best === target) return bestD;
    visited.add(best);
    for (const edge of byId.get(best)?.connections ?? []) {
      const nd = bestD + edge.cost;
      if (nd < (dist.get(edge.to) ?? Infinity)) dist.set(edge.to, nd);
    }
  }
}

export type BuildCheck =
  | { ok: true; cost: number; houseCost: number; connection: number; reason?: undefined }
  | { ok: false; reason: string; cost?: number };

export function checkBuild(state: GameState, player: Player, city: City): BuildCheck {
  const regions = state.activeRegions ?? [];
  if (regions.length > 0 && !regions.includes(city.region)) return { ok: false, reason: 'Region not in play' };
  if (city.houses.some((h) => h.playerId === player.id)) return { ok: false, reason: 'You are already here' };
  const taken = city.houses.length;
  if (taken >= CITY_SLOT_COST.length) return { ok: false, reason: 'City is full' };
  if (taken >= slotsOpenInStep(state.step)) return { ok: false, reason: `Full for step ${state.step ?? 1}` };
  const connection = connectionCost(state.cities, player.cities, city.id);
  if (connection === undefined) return { ok: false, reason: 'Not connected' };
  const houseCost = CITY_SLOT_COST[taken];
  const cost = houseCost + connection;
  if (cost > player.money) return { ok: false, reason: `Costs $${cost}`, cost };
  return { ok: true, cost, houseCost, connection };
}

// --- bureaucracy ---------------------------------------------------------------

/** Mirrors engine powerCities: which plants can run with the player's fuel, in the given order. */
export function powerPlan(player: Player, plantIds: readonly number[]): { capacity: number; used: Record<Fuel, number>; ok: boolean } {
  const store = playerStore(player);
  const used: Record<Fuel, number> = { coal: 0, oil: 0, garbage: 0, uranium: 0 };
  let capacity = 0;
  for (const id of plantIds) {
    const plant = player.powerPlants.find((p) => p.id === id);
    if (!plant) return { capacity, used, ok: false };
    if (plant.resourceType === 'eco') { capacity += plant.citiesPowered; continue; }
    if (plant.resourceType === 'hybrid') {
      let need = plant.resourceCount;
      const coal = Math.min(store.coal, need); store.coal -= coal; need -= coal;
      const oil = Math.min(store.oil, need); store.oil -= oil; need -= oil;
      if (need > 0) return { capacity, used, ok: false };
      used.coal += coal; used.oil += oil;
    } else {
      const fuel = plant.resourceType as Fuel;
      if (store[fuel] < plant.resourceCount) return { capacity, used, ok: false };
      store[fuel] -= plant.resourceCount;
      used[fuel] += plant.resourceCount;
    }
    capacity += plant.citiesPowered;
  }
  return { capacity, used, ok: true };
}

export const playerName = (state: GameState | undefined, id: string | undefined): string =>
  state?.players.find((p) => p.id === id)?.name ?? 'Someone';
