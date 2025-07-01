import React from 'react';
import { useGameStore } from '../store/gameStore';
import { Users, Play, ArrowLeft, Copy, Check } from 'lucide-react';
import Button from './ui/Button';
import Card from './ui/Card';

const LobbyScreen: React.FC = () => {
  const { 
    gameState, 
    startGame, 
    setCurrentScreen,
    playerId 
  } = useGameStore();

  const [gameIdCopied, setGameIdCopied] = React.useState(false);

  // Mock lobby data for now - replace with actual lobby state
  const mockLobby = {
    gameId: 'GAME123',
    players: [
      { id: '1', name: 'Player 1', color: '#ff0000', ready: true },
      { id: '2', name: 'Player 2', color: '#0000ff', ready: false },
    ],
    isHost: playerId === '1',
    gameStarted: false
  };

  const handleCopyGameId = async () => {
    try {
      await navigator.clipboard.writeText(mockLobby.gameId);
      setGameIdCopied(true);
      setTimeout(() => setGameIdCopied(false), 2000);
    } catch (error) {
      console.error('Failed to copy game ID:', error);
    }
  };

  const handleStartGame = () => {
    if (mockLobby.isHost && mockLobby.players.length >= 2) {
      startGame();
    }
  };

  const handleLeave = () => {
    setCurrentScreen('menu');
  };

  return (
    <div className="min-h-screen bg-game-background p-4">
      <div className="max-w-2xl mx-auto space-y-6">
        {/* Header */}
        <div className="flex items-center justify-between">
          <Button
            variant="outline"
            onClick={handleLeave}
            className="touch-target"
          >
            <ArrowLeft className="w-5 h-5 mr-2" />
            Leave
          </Button>
          
          <h1 className="text-2xl font-bold text-white">
            Game Lobby
          </h1>
          
          <div></div> {/* Spacer */}
        </div>

        {/* Game Info */}
        <Card className="p-6">
          <div className="flex items-center justify-between mb-4">
            <h2 className="text-xl font-semibold text-white">
              Game ID
            </h2>
            
            <Button
              variant="outline"
              size="sm"
              onClick={handleCopyGameId}
              className="touch-target"
            >
              {gameIdCopied ? (
                <Check className="w-4 h-4 mr-2" />
              ) : (
                <Copy className="w-4 h-4 mr-2" />
              )}
              {gameIdCopied ? 'Copied!' : 'Copy'}
            </Button>
          </div>
          
          <div className="text-center">
            <div className="text-3xl font-mono text-blue-400 bg-game-surface rounded-lg py-4 px-6">
              {mockLobby.gameId}
            </div>
            <p className="text-slate-400 text-sm mt-2">
              Share this ID with friends to let them join
            </p>
          </div>
        </Card>

        {/* Players List */}
        <Card className="p-6">
          <div className="flex items-center gap-2 mb-4">
            <Users className="w-5 h-5 text-white" />
            <h2 className="text-xl font-semibold text-white">
              Players ({mockLobby.players.length}/6)
            </h2>
          </div>
          
          <div className="space-y-3">
            {mockLobby.players.map((player, index) => (
              <div
                key={player.id}
                className="flex items-center justify-between p-3 bg-game-surface rounded-lg"
              >
                <div className="flex items-center gap-3">
                  <div
                    className="w-6 h-6 rounded-full border-2 border-white"
                    style={{ backgroundColor: player.color }}
                  />
                  <span className="text-white font-medium">
                    {player.name}
                    {player.id === playerId && ' (You)'}
                    {index === 0 && ' (Host)'}
                  </span>
                </div>
                
                <div className={`
                  px-3 py-1 rounded-full text-xs font-medium
                  ${player.ready 
                    ? 'bg-green-600 text-green-100' 
                    : 'bg-yellow-600 text-yellow-100'
                  }
                `}>
                  {player.ready ? 'Ready' : 'Not Ready'}
                </div>
              </div>
            ))}
            
            {/* Empty slots */}
            {Array.from({ length: 6 - mockLobby.players.length }).map((_, index) => (
              <div
                key={`empty-${index}`}
                className="flex items-center p-3 bg-game-surface rounded-lg opacity-50"
              >
                <div className="flex items-center gap-3">
                  <div className="w-6 h-6 rounded-full border-2 border-dashed border-slate-500" />
                  <span className="text-slate-500">
                    Waiting for player...
                  </span>
                </div>
              </div>
            ))}
          </div>
        </Card>

        {/* Game Controls */}
        {mockLobby.isHost && (
          <Card className="p-6">
            <div className="space-y-4">
              <h3 className="text-lg font-semibold text-white">
                Host Controls
              </h3>
              
              <div className="flex gap-3">
                <Button
                  className="flex-1 touch-target"
                  onClick={handleStartGame}
                  disabled={mockLobby.players.length < 2 || !mockLobby.players.every(p => p.ready)}
                >
                  <Play className="w-5 h-5 mr-2" />
                  Start Game
                </Button>
              </div>
              
              {mockLobby.players.length < 2 && (
                <p className="text-sm text-yellow-400">
                  Need at least 2 players to start
                </p>
              )}
              
              {!mockLobby.players.every(p => p.ready) && mockLobby.players.length >= 2 && (
                <p className="text-sm text-yellow-400">
                  All players must be ready to start
                </p>
              )}
            </div>
          </Card>
        )}

        {/* Ready Status */}
        {!mockLobby.isHost && (
          <Card className="p-6">
            <div className="text-center space-y-4">
              <p className="text-slate-400">
                Waiting for the host to start the game...
              </p>
              
              <Button
                variant="secondary"
                className="touch-target"
                disabled
              >
                Ready ✓
              </Button>
            </div>
          </Card>
        )}
      </div>
    </div>
  );
};

export default LobbyScreen;