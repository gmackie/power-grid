import React, { useState, useEffect } from 'react';
import Card from '../ui/Card';
import Button from '../ui/Button';
import { SimulatedGamesList } from './SimulatedGamesList';
import { CreateSimulatedGame } from './CreateSimulatedGame';
import { GameMonitor } from './GameMonitor';
import { SimulatedGame } from '../../types/admin';

export const SimulatedGames: React.FC = () => {
  const [activeView, setActiveView] = useState<'list' | 'create' | 'monitor'>('list');
  const [selectedGame, setSelectedGame] = useState<SimulatedGame | null>(null);
  const [games, setGames] = useState<SimulatedGame[]>([]);

  const handleCreateGame = () => {
    setActiveView('create');
  };

  const handleViewGame = (game: SimulatedGame) => {
    setSelectedGame(game);
    setActiveView('monitor');
  };

  const handleGameCreated = (game: SimulatedGame) => {
    setGames([...games, game]);
    setSelectedGame(game);
    setActiveView('monitor');
  };

  const handleBackToList = () => {
    setActiveView('list');
    setSelectedGame(null);
  };

  return (
    <div className="space-y-6">
      <div className="flex justify-between items-center">
        <div>
          <h2 className="text-2xl font-bold text-gray-900 mb-2">Simulated Games</h2>
          <p className="text-gray-600">Create and monitor AI-powered game simulations</p>
        </div>
        {activeView === 'list' && (
          <Button onClick={handleCreateGame}>
            Create Simulated Game
          </Button>
        )}
        {activeView !== 'list' && (
          <Button variant="outline" onClick={handleBackToList}>
            Back to Games List
          </Button>
        )}
      </div>

      {activeView === 'list' && (
        <SimulatedGamesList 
          games={games}
          onViewGame={handleViewGame}
          onRefresh={() => {
            // Refresh games list
            console.log('Refreshing games list');
          }}
        />
      )}

      {activeView === 'create' && (
        <CreateSimulatedGame 
          onGameCreated={handleGameCreated}
          onCancel={handleBackToList}
        />
      )}

      {activeView === 'monitor' && selectedGame && (
        <GameMonitor 
          game={selectedGame}
          onBack={handleBackToList}
        />
      )}
    </div>
  );
};