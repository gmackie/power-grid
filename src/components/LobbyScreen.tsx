import React, { useEffect } from 'react';
import { useGameStore } from '../store/gameStore';
import { Users, Play, ArrowLeft, Copy, Check, Crown, Settings } from 'lucide-react';
import Button from './ui/Button';
import Card from './ui/Card';
import { lobbyActions } from '../services/websocket';

const LobbyScreen: React.FC = () => {
  const { 
    currentLobby,
    playerName,
    connectionStatus,
    setCurrentScreen,
    leaveLobby,
    setReady
  } = useGameStore();

  const [gameIdCopied, setGameIdCopied] = React.useState(false);
  const [isReady, setIsReady] = React.useState(false);

  // Redirect if no lobby
  useEffect(() => {
    if (!currentLobby) {
      setCurrentScreen('lobby-browser');
    }
  }, [currentLobby, setCurrentScreen]);

  if (!currentLobby) {
    return (
      <div className="min-h-screen bg-game-background flex items-center justify-center">
        <div className="text-white">Loading...</div>
      </div>
    );
  }

  const currentPlayer = currentLobby.players.find(p => p.name === playerName);
  const isHost = currentPlayer?.is_host || false;

  const handleCopyGameId = async () => {
    try {
      await navigator.clipboard.writeText(currentLobby.id);
      setGameIdCopied(true);
      setTimeout(() => setGameIdCopied(false), 2000);
    } catch (error) {
      console.error('Failed to copy game ID:', error);
    }
  };

  const handleStartGame = () => {
    if (isHost && currentLobby.players.length >= 2) {
      lobbyActions.startGame();
    }
  };

  const handleLeave = () => {
    leaveLobby();
  };
  
  const handleToggleReady = () => {
    const newReadyState = !isReady;
    setIsReady(newReadyState);
    setReady(newReadyState);
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
            {currentLobby.name}
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
              {currentLobby.id}
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
              Players ({currentLobby.players.length}/{currentLobby.max_players})
            </h2>
          </div>
          
          <div className="space-y-3">
            {currentLobby.players.map((player) => (
              <div
                key={player.id}
                className="flex items-center justify-between p-3 bg-game-surface rounded-lg"
              >
                <div className="flex items-center gap-3">
                  <div
                    className="w-6 h-6 rounded-full border-2 border-white"
                    style={{ backgroundColor: player.color }}
                  />
                  <span className="text-white font-medium flex items-center gap-2">
                    {player.name}
                    {player.name === playerName && ' (You)'}
                    {player.is_host && <Crown className="w-4 h-4 text-yellow-400" />}
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
            {Array.from({ length: currentLobby.max_players - currentLobby.players.length }).map((_, index) => (
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
        {isHost && (
          <Card className="p-6">
            <div className="space-y-4">
              <div className="flex items-center gap-2">
                <Crown className="w-5 h-5 text-yellow-400" />
                <h3 className="text-lg font-semibold text-white">
                  Host Controls
                </h3>
              </div>
              
              <div className="flex gap-3">
                <Button
                  className="flex-1 touch-target"
                  onClick={handleStartGame}
                  disabled={currentLobby.players.length < 2 || !currentLobby.players.every(p => p.ready)}
                >
                  <Play className="w-5 h-5 mr-2" />
                  Start Game
                </Button>
              </div>
              
              {currentLobby.players.length < 2 && (
                <p className="text-sm text-yellow-400">
                  Need at least 2 players to start
                </p>
              )}
              
              {!currentLobby.players.every(p => p.ready) && currentLobby.players.length >= 2 && (
                <p className="text-sm text-yellow-400">
                  All players must be ready to start
                </p>
              )}
            </div>
          </Card>
        )}

        {/* Ready Status */}
        {!isHost && (
          <Card className="p-6">
            <div className="text-center space-y-4">
              <p className="text-slate-400">
                {currentLobby.players.every(p => p.ready) ? 
                  'Waiting for the host to start the game...' :
                  'Mark yourself as ready when you\'re prepared to play'
                }
              </p>
              
              <Button
                variant={isReady ? "secondary" : "outline"}
                className="touch-target"
                onClick={handleToggleReady}
                disabled={connectionStatus !== 'connected'}
              >
                {isReady ? 'Ready ✓' : 'Not Ready'}
              </Button>
            </div>
          </Card>
        )}
        
        {/* Lobby Info */}
        <Card className="p-4 bg-slate-900/50">
          <div className="flex items-center justify-between text-sm text-slate-400">
            <span>Map: <span className="text-white capitalize">{currentLobby.map_id}</span></span>
            <span>Status: <span className="text-white capitalize">{currentLobby.status}</span></span>
          </div>
        </Card>
      </div>
    </div>
  );
};

export default LobbyScreen;