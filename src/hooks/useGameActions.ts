import { useGameStore } from '../store/gameStore';
import type { ResourceType } from '../types/game';

export interface GameActions {
  bid: (amount: number, plantId?: number) => void;
  pass: () => void;
  buyResources: (resources: Record<ResourceType, number>) => void;
  buildCity: (cityId: string) => void;
  powerCities: (citiesPowered: number) => void;
}

/**
 * Custom hook that provides game actions based on the current mode
 * @param localMode - Whether to use local simulation or server synchronization
 */
export function useGameActions(localMode: boolean = false): GameActions {
  const store = useGameStore();

  if (localMode) {
    // Use local simulation methods
    return {
      bid: store.simulateBid,
      pass: store.simulatePass,
      buyResources: store.simulateBuyResources,
      buildCity: store.simulateBuildCity,
      powerCities: store.simulatePowerCities
    };
  } else {
    // Use server synchronization methods
    return {
      bid: store.bid,
      pass: store.pass,
      buyResources: store.buyResources,
      buildCity: store.buildCity,
      powerCities: store.powerCities
    };
  }
}

export default useGameActions;