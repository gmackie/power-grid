import { useGameStore } from '../store/gameStore';

/** Current game, "me", and whose move it is. */
export function useGameView() {
  const gameState = useGameStore((s) => s.gameState);
  const myId = useGameStore((s) => s.gamePlayerId ?? s.playerId);
  const me = gameState?.players.find((p) => p.id === myId);
  const actingId = gameState?.currentTurn || undefined;
  const acting = gameState?.players.find((p) => p.id === actingId);
  const isMyTurn = !!myId && actingId === myId && gameState?.status === 'PLAYING';
  return { gameState, myId, me, actingId, acting, isMyTurn };
}
