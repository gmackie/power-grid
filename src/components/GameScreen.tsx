import React from 'react';
import { ArrowLeft, Coins, Trophy, WifiOff } from 'lucide-react';
import { useGameStore } from '../store/gameStore';
import AuctionPhase from './phases/AuctionPhase';
import ResourcePhase from './phases/ResourcePhase';
import BuildingPhase from './phases/BuildingPhase';
import BureaucracyPhase from './phases/BureaucracyPhase';
import Button from './ui/Button';
import { ActionBar, PlayerStrip, Section } from './game/GameChrome';
import { useGameView } from '../hooks/useGameView';
import { END_GAME_CITIES } from '../utils/rules';

const PHASE_LABEL: Record<string, string> = {
  PLAYER_ORDER: 'Player order',
  AUCTION: 'Auction',
  BUY_RESOURCES: 'Buy resources',
  BUILD_CITIES: 'Build',
  BUREAUCRACY: 'Bureaucracy',
  GAME_END: 'Game over',
};

/** What the acting player is being asked to do, for the turn banner. */
function promptFor(phase: string | undefined, auction: boolean): string {
  switch (phase) {
    case 'AUCTION': return auction ? 'raise the bid or pass' : 'pick a plant to auction';
    case 'BUY_RESOURCES': return 'buy fuel for your plants';
    case 'BUILD_CITIES': return 'build in cities';
    case 'BUREAUCRACY': return 'power your cities';
    default: return 'make a move';
  }
}

const GameScreen: React.FC = () => {
  const leaveGame = useGameStore((s) => s.leaveGame);
  const gameConnection = useGameStore((s) => s.gameConnection);
  const { gameState, myId, me, acting, actingId, isMyTurn } = useGameView();

  const handleLeave = () => {
    if (gameState?.status === 'PLAYING' && !window.confirm('Leave this game? You can rejoin from this device later.')) return;
    leaveGame();
  };

  if (!gameState) {
    return (
      <div className="flex min-h-[100dvh] flex-col items-center justify-center gap-4 bg-game-background p-6 text-center">
        <div className="h-10 w-10 animate-spin rounded-full border-4 border-slate-700 border-l-blue-500" />
        <p className="text-slate-300">{gameConnection === 'error' ? 'Could not reach the game.' : 'Joining game…'}</p>
        <Button variant="outline" onClick={leaveGame}>Back to menu</Button>
      </div>
    );
  }

  const phase = gameState.serverPhase;
  const finished = gameState.status === 'FINISHED';
  const winner = gameState.players.find((p) => p.id === gameState.winnerId);
  const target = END_GAME_CITIES[gameState.players.length];

  const renderPhase = () => {
    if (finished) return null;
    switch (gameState.phase) {
      case 'auction': return <AuctionPhase />;
      case 'resource': return <ResourcePhase />;
      case 'building': return <BuildingPhase />;
      case 'bureaucracy': return <BureaucracyPhase />;
    }
  };

  return (
    <div className="min-h-[100dvh] bg-game-background">
      {/* Sticky header */}
      <header className="sticky top-0 z-30 border-b border-slate-700 bg-game-surface pt-[env(safe-area-inset-top)]">
        <div className="mx-auto flex max-w-3xl items-center gap-2 px-3 py-2 short:py-1 pl-[max(0.75rem,env(safe-area-inset-left))] pr-[max(0.75rem,env(safe-area-inset-right))]">
          <button
            onClick={handleLeave}
            aria-label="Leave game"
            className="flex h-11 w-11 shrink-0 items-center justify-center rounded-lg border border-slate-600 text-white active:bg-slate-700"
          >
            <ArrowLeft className="h-5 w-5" />
          </button>
          <div className="min-w-0 flex-1 text-center">
            <p className="truncate text-sm font-semibold text-white">{PHASE_LABEL[phase ?? ''] ?? 'Power Grid'}</p>
            <p className="truncate text-xs text-slate-400 short:hidden">
              Round {gameState.currentRound} · Step {gameState.step ?? 1}
              {target ? ` · ${target} cities ends it` : ''}
            </p>
          </div>
          <div className="flex h-11 shrink-0 items-center gap-1 rounded-lg bg-yellow-400/10 px-3 font-bold text-yellow-400">
            <Coins className="h-4 w-4" />${me?.money ?? 0}
          </div>
        </div>
        {/* Turn banner */}
        {!finished && (
          <div className={isMyTurn ? 'bg-green-600 text-white' : 'bg-slate-800 text-slate-300'}>
            <p className="mx-auto max-w-3xl px-3 py-1.5 text-center text-sm font-medium short:py-0.5 short:text-xs">
              {isMyTurn
                ? `Your turn: ${promptFor(phase, !!gameState.auctionState)}`
                : acting
                  ? `Waiting for ${acting.name} to ${promptFor(phase, !!gameState.auctionState)}…`
                  : 'Waiting…'}
            </p>
          </div>
        )}
        {gameConnection && gameConnection !== 'connected' && (
          <div className="flex items-center justify-center gap-2 bg-red-700 px-3 py-1 text-xs text-white">
            <WifiOff className="h-3.5 w-3.5" /> Reconnecting to the game…
          </div>
        )}
      </header>

      <main className="mx-auto max-w-3xl space-y-3 px-3 pb-44 pt-3 short:pb-28 pl-[max(0.75rem,env(safe-area-inset-left))] pr-[max(0.75rem,env(safe-area-inset-right))]">
        <PlayerStrip state={gameState} myId={myId} actingId={finished ? undefined : actingId} />

        {finished && (
          <Section>
            <div className="flex flex-col items-center gap-2 py-4 text-center">
              <Trophy className="h-10 w-10 text-yellow-400" />
              <p className="text-xl font-bold text-white">{winner ? `${winner.name} wins!` : 'Game over'}</p>
              <p className="text-sm text-slate-400">
                {[...gameState.players]
                  .sort((a, b) => (b.poweredCities ?? 0) - (a.poweredCities ?? 0) || b.money - a.money)
                  .map((p) => `${p.name}: ${p.poweredCities ?? 0} powered, $${p.money}`)
                  .join(' · ')}
              </p>
            </div>
          </Section>
        )}

        {renderPhase()}
      </main>

      {finished && (
        <ActionBar>
          <Button className="w-full" onClick={leaveGame}>Back to menu</Button>
        </ActionBar>
      )}
    </div>
  );
};

export default GameScreen;
