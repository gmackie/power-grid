import React from 'react';
import { useGameStore, useDeviceStore } from '../store/gameStore';
import { ArrowLeft, Users, Coins, Zap, Factory } from 'lucide-react';
import Button from './ui/Button';
import Card from './ui/Card';
import AuctionPhase from './phases/AuctionPhase';
import ResourcePhase from './phases/ResourcePhase';
import BuildingPhase from './phases/BuildingPhase';
import BureaucracyPhase from './phases/BureaucracyPhase';

const GameScreen: React.FC = () => {
  const { 
    gameState, 
    getCurrentPlayer,
    isCurrentPlayerTurn,
    setCurrentScreen 
  } = useGameStore();
  
  const { isMobile, orientation } = useDeviceStore();
  
  const currentPlayer = getCurrentPlayer();
  const isMyTurn = isCurrentPlayerTurn();

  // Mock game state for now
  const mockGameState = {
    currentRound: 1,
    phase: 'auction' as const,
    currentPlayer: 0,
    players: [
      {
        id: '1',
        name: 'Player 1',
        color: '#ff0000',
        money: 50,
        cities: ['Berlin', 'Hamburg'],
        powerPlants: [
          { id: 1, number: 3, cost: 10, resourceType: 'oil' as const, resourceCount: 2, citiesPowered: 1 }
        ],
        resources: { coal: 0, oil: 2, garbage: 0, uranium: 0 }
      },
      {
        id: '2',
        name: 'Player 2',
        color: '#0000ff',
        money: 45,
        cities: ['Munich'],
        powerPlants: [],
        resources: { coal: 0, oil: 0, garbage: 0, uranium: 0 }
      }
    ],
    powerPlantMarket: [
      { id: 2, number: 4, cost: 15, resourceType: 'coal' as const, resourceCount: 2, citiesPowered: 1 },
      { id: 3, number: 5, cost: 20, resourceType: 'hybrid' as const, resourceCount: 2, citiesPowered: 1 },
      { id: 4, number: 6, cost: 25, resourceType: 'garbage' as const, resourceCount: 1, citiesPowered: 1 }
    ]
  };

  const handleLeaveGame = () => {
    setCurrentScreen('menu');
  };

  const renderPhaseContent = () => {
    // Use real game state if available, otherwise use mock
    const currentGameState = gameState || mockGameState;
    
    switch (currentGameState.phase) {
      case 'auction':
        return (
          <AuctionPhase
            auctionState={currentGameState.auctionState || {
              currentPlant: undefined,
              currentBid: 0,
              currentBidder: undefined,
              biddingOrder: currentGameState.players.map(p => p.id),
              passedPlayers: [],
              plantsWon: {}
            }}
            powerPlantMarket={currentGameState.powerPlantMarket}
          />
        );
        
      case 'resource':
        return (
          <ResourcePhase
            resourcePhaseState={currentGameState.resourcePhaseState || {
              buyingOrder: currentGameState.players.map(p => p.id).reverse(), // Reverse turn order
              currentBuyer: undefined,
              resourcesPurchased: {}
            }}
            resourceMarket={currentGameState.resourceMarket || {
              coal: 24,
              oil: 18,
              garbage: 6,
              uranium: 2,
              coalPrice: 1,
              oilPrice: 2,
              garbagePrice: 3,
              uraniumPrice: 8
            }}
          />
        );
        
      case 'building':
        return (
          <BuildingPhase
            buildingPhaseState={currentGameState.buildingPhaseState || {
              buildingOrder: currentGameState.players.map(p => p.id).reverse(), // Reverse turn order
              currentBuilder: undefined,
              citiesBuilt: {}
            }}
            cities={currentGameState.cities || mockCities}
          />
        );
        
      case 'bureaucracy':
        return (
          <BureaucracyPhase
            bureaucracyState={currentGameState.bureaucracyState || {
              poweringOrder: currentGameState.players.map(p => p.id),
              currentPowerer: undefined,
              citiesPowered: {},
              earnings: {}
            }}
          />
        );
        
      default:
        return (
          <Card className="p-6">
            <h3 className="text-lg font-semibold text-white mb-4">
              Unknown Phase
            </h3>
            <p className="text-slate-400">
              Invalid game phase: {currentGameState.phase}
            </p>
          </Card>
        );
    }
  };
  
  // Mock cities data for testing
  const mockCities = [
    {
      id: 'berlin',
      name: 'Berlin',
      x: 0.5,
      y: 0.3,
      region: 'North',
      houses: [],
      connections: [
        { to: 'hamburg', cost: 10 },
        { to: 'munich', cost: 15 }
      ]
    },
    {
      id: 'hamburg',
      name: 'Hamburg',
      x: 0.4,
      y: 0.2,
      region: 'North',
      houses: [],
      connections: [
        { to: 'berlin', cost: 10 },
        { to: 'cologne', cost: 12 }
      ]
    },
    {
      id: 'munich',
      name: 'Munich',
      x: 0.6,
      y: 0.5,
      region: 'South',
      houses: [],
      connections: [
        { to: 'berlin', cost: 15 },
        { to: 'frankfurt', cost: 8 }
      ]
    },
    {
      id: 'cologne',
      name: 'Cologne',
      x: 0.3,
      y: 0.4,
      region: 'West',
      houses: [],
      connections: [
        { to: 'hamburg', cost: 12 },
        { to: 'frankfurt', cost: 6 }
      ]
    },
    {
      id: 'frankfurt',
      name: 'Frankfurt',
      x: 0.5,
      y: 0.4,
      region: 'Central',
      houses: [],
      connections: [
        { to: 'munich', cost: 8 },
        { to: 'cologne', cost: 6 }
      ]
    }
  ];

  return (
    <div className="min-h-screen bg-game-background">
      {/* Header */}
      <div className="bg-game-surface border-b border-slate-600 p-4">
        <div className="max-w-7xl mx-auto flex items-center justify-between">
          <Button
            variant="outline"
            onClick={handleLeaveGame}
            className="touch-target"
          >
            <ArrowLeft className="w-5 h-5 mr-2" />
            Leave
          </Button>
          
          <div className="text-center">
            <h1 className="text-xl font-bold text-white">
              Power Grid
            </h1>
            <p className="text-sm text-slate-400">
              Round {mockGameState.currentRound} • {mockGameState.phase} Phase
            </p>
          </div>
          
          <div className="flex items-center gap-2">
            <Users className="w-5 h-5 text-slate-400" />
            <span className="text-sm text-slate-400">
              {mockGameState.players.length}
            </span>
          </div>
        </div>
      </div>

      <div className={`
        max-w-7xl mx-auto p-4 space-y-6
        ${isMobile && orientation === 'portrait' ? 'space-y-4' : ''}
      `}>
        {/* Turn Indicator */}
        {isMyTurn && (
          <Card className="p-4 bg-green-600 border-green-500">
            <div className="text-center">
              <p className="text-green-100 font-medium">
                It's your turn!
              </p>
            </div>
          </Card>
        )}

        {/* Current Player Info */}
        {currentPlayer && (
          <Card className="p-4">
            <div className="flex items-center justify-between">
              <div className="flex items-center gap-3">
                <div
                  className="w-8 h-8 rounded-full border-2 border-white"
                  style={{ backgroundColor: currentPlayer.color }}
                />
                <div>
                  <h2 className="text-lg font-semibold text-white">
                    {currentPlayer.name}
                  </h2>
                  <p className="text-sm text-slate-400">
                    Cities: {currentPlayer.cities.length} • Plants: {currentPlayer.powerPlants.length}
                  </p>
                </div>
              </div>
              
              <div className="flex items-center gap-2 text-yellow-400">
                <Coins className="w-5 h-5" />
                <span className="font-semibold">
                  ${currentPlayer.money}
                </span>
              </div>
            </div>
          </Card>
        )}

        {/* Phase Content */}
        {renderPhaseContent()}

        {/* Players Overview */}
        <Card className="p-6">
          <h3 className="text-lg font-semibold text-white mb-4">
            Players
          </h3>
          
          <div className={`
            grid gap-4
            ${isMobile ? 'grid-cols-1' : 'grid-cols-2 lg:grid-cols-3'}
          `}>
            {mockGameState.players.map((player, index) => (
              <div
                key={player.id}
                className={`
                  bg-game-surface rounded-lg p-4 border
                  ${index === mockGameState.currentPlayer 
                    ? 'border-yellow-500 bg-yellow-900/20' 
                    : 'border-slate-600'
                  }
                `}
              >
                <div className="space-y-2">
                  <div className="flex items-center gap-2">
                    <div
                      className="w-6 h-6 rounded-full border-2 border-white"
                      style={{ backgroundColor: player.color }}
                    />
                    <span className="text-white font-medium">
                      {player.name}
                      {player.id === currentPlayer?.id && ' (You)'}
                    </span>
                  </div>
                  
                  <div className="grid grid-cols-2 gap-2 text-sm">
                    <div className="flex items-center gap-1 text-yellow-400">
                      <Coins className="w-4 h-4" />
                      <span>${player.money}</span>
                    </div>
                    
                    <div className="flex items-center gap-1 text-blue-400">
                      <Factory className="w-4 h-4" />
                      <span>{player.powerPlants.length}</span>
                    </div>
                    
                    <div className="flex items-center gap-1 text-green-400">
                      <Zap className="w-4 h-4" />
                      <span>{player.cities.length}</span>
                    </div>
                    
                    <div className="text-slate-400">
                      Resources: {Object.values(player.resources).reduce((a, b) => a + b, 0)}
                    </div>
                  </div>
                </div>
              </div>
            ))}
          </div>
        </Card>
      </div>
    </div>
  );
};

export default GameScreen;