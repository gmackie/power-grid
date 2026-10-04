// Converts the server's snake_case GAME_STATE payload into the client GameState.

import type {
  GameState,
  GamePhase,
  Player,
  PowerPlant,
  ResourceMarket,
  ResourceType,
  City,
  AuctionState,
} from '../types/game';

export interface ServerPlant {
  id: number;
  cost: number;
  capacity: number;
  resource_type: string;
  resource_cost: number;
}

export interface ServerPlayer {
  id: string;
  name: string;
  color: string;
  money: number;
  cities: string[];
  power_plants: ServerPlant[] | null;
  resources: { Coal?: number; Oil?: number; Garbage?: number; Uranium?: number };
  powered_cities?: number;
  connected?: boolean;
  has_passed?: boolean;
}

export interface ServerGameState {
  game_id: string;
  name?: string;
  status: 'LOBBY' | 'PLAYING' | 'FINISHED';
  current_phase: string;
  current_turn: string;
  current_round: number;
  step: number;
  turn_order: string[];
  winner_id: string | null;
  players: Record<string, ServerPlayer>;
  map?: {
    name?: string;
    cities: Record<string, { id: string; name: string; region: string; position: [number, number]; slots: string[] }>;
    connections: { city_a: string; city_b: string; cost: number }[];
  };
  market?: { resources: Record<'Coal' | 'Oil' | 'Garbage' | 'Uranium', number[]> };
  power_plants?: ServerPlant[];
  plant_market?: { current: ServerPlant[]; future: ServerPlant[]; deck_remaining?: number };
  auction: null | {
    plant_id: number;
    current_bid: number;
    current_bidder: string;
    nominated_by?: string;
    participants: string[];
    passed: string[];
  };
  active_regions?: string[];
  map_id?: string;
}

const PHASE_MAP: Record<string, GamePhase> = {
  PLAYER_ORDER: 'auction',
  AUCTION: 'auction',
  BUY_RESOURCES: 'resource',
  BUILD_CITIES: 'building',
  BUREAUCRACY: 'bureaucracy',
  GAME_END: 'bureaucracy',
};

function toResourceType(t: string | undefined): ResourceType {
  const lower = (t || '').toLowerCase();
  if (lower === 'coal' || lower === 'oil' || lower === 'garbage' || lower === 'uranium' || lower === 'hybrid') {
    return lower;
  }
  return 'eco'; // Wind / no-resource plants
}

export function adaptPlant(p: ServerPlant): PowerPlant {
  return {
    id: p.id,
    number: p.id,
    cost: p.cost,
    citiesPowered: p.capacity,
    resourceType: toResourceType(p.resource_type),
    resourceCount: p.resource_cost,
  };
}

function marketEntry(prices: number[] | undefined): { count: number; price: number } {
  if (!prices) return { count: 0, price: 0 };
  let count = 0;
  let price = 0;
  prices.forEach((n, idx) => {
    if (n > 0) {
      count += n;
      if (price === 0) price = idx;
    }
  });
  return { count, price };
}

function adaptMarket(market: ServerGameState['market']): ResourceMarket {
  const coal = marketEntry(market?.resources?.Coal);
  const oil = marketEntry(market?.resources?.Oil);
  const garbage = marketEntry(market?.resources?.Garbage);
  const uranium = marketEntry(market?.resources?.Uranium);
  return {
    coal: coal.count,
    oil: oil.count,
    garbage: garbage.count,
    uranium: uranium.count,
    hybrid: 0,
    eco: 0,
    coalPrice: coal.price,
    oilPrice: oil.price,
    garbagePrice: garbage.price,
    uraniumPrice: uranium.price,
    hybridPrice: 0,
    ecoPrice: 0,
  };
}

export function adaptGameState(s: ServerGameState): GameState {
  const ids = Object.keys(s.players || {});
  const order = (s.turn_order || []).filter((id) => s.players[id]);
  const orderedIds = [...order, ...ids.filter((id) => !order.includes(id))];

  const players: Player[] = orderedIds.map((id) => {
    const p = s.players[id];
    return {
      id: p.id,
      name: p.name,
      color: p.color,
      money: p.money,
      cities: p.cities || [],
      powerPlants: (p.power_plants || []).map(adaptPlant),
      resources: {
        coal: p.resources?.Coal ?? 0,
        oil: p.resources?.Oil ?? 0,
        garbage: p.resources?.Garbage ?? 0,
        uranium: p.resources?.Uranium ?? 0,
        hybrid: 0,
        eco: 0,
      },
      hasPassed: p.has_passed ?? false,
      poweredCities: p.powered_cities ?? 0,
      connected: p.connected ?? true,
    };
  });

  const colorOf = (id: string) => s.players[id]?.color ?? '#888888';

  const cityMap = s.map?.cities ?? {};
  const cities: City[] = Object.values(cityMap).map((c) => ({
    id: c.id,
    name: c.name,
    region: c.region,
    x: c.position?.[0] ?? 0,
    y: c.position?.[1] ?? 0,
    connections: [],
    houses: (c.slots || []).map((pid) => ({ playerColor: colorOf(pid), cost: 0, playerId: pid })),
  }));
  const cityById = new Map(cities.map((c) => [c.id, c]));
  for (const conn of s.map?.connections ?? []) {
    cityById.get(conn.city_a)?.connections.push({ to: conn.city_b, cost: conn.cost });
    cityById.get(conn.city_b)?.connections.push({ to: conn.city_a, cost: conn.cost });
  }

  const current = (s.plant_market?.current ?? s.power_plants ?? []).map(adaptPlant);
  const future = (s.plant_market?.future ?? []).map(adaptPlant);

  let auctionState: AuctionState | undefined;
  if (s.auction) {
    const all = [
      ...(s.plant_market?.current ?? []),
      ...(s.plant_market?.future ?? []),
      ...(s.power_plants ?? []),
    ];
    const raw = all.find((p) => p.id === s.auction!.plant_id);
    auctionState = {
      currentPlant: raw ? adaptPlant(raw) : undefined,
      currentBid: s.auction.current_bid,
      currentBidder: s.auction.current_bidder || undefined,
      biddingOrder: s.auction.participants || [],
      passedPlayers: s.auction.passed || [],
      plantsWon: {},
      nominatedBy: s.auction.nominated_by,
    };
  }

  const currentTurn = s.current_turn || '';
  const currentPlayer = Math.max(0, players.findIndex((p) => p.id === currentTurn));

  return {
    id: s.game_id,
    players,
    currentPlayer,
    currentRound: s.current_round,
    phase: PHASE_MAP[s.current_phase] ?? 'auction',
    powerPlantMarket: current,
    resourceMarket: adaptMarket(s.market),
    cities,
    turnOrder: s.turn_order || [],
    auctionState,
    status: s.status,
    step: s.step,
    currentTurn,
    futureMarket: future,
    winnerId: s.winner_id,
    activeRegions: s.active_regions ?? [],
    mapId: s.map_id,
    serverPhase: s.current_phase,
    resourceLadders: {
      coal: s.market?.resources?.Coal ?? [],
      oil: s.market?.resources?.Oil ?? [],
      garbage: s.market?.resources?.Garbage ?? [],
      uranium: s.market?.resources?.Uranium ?? [],
    },
    deckRemaining: s.plant_market?.deck_remaining,
  };
}
