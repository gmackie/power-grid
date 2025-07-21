import React, { useState } from 'react';
import { useGameStore, useDeviceStore } from '../store/gameStore';
import { Play, Users, Settings, Wifi, WifiOff, Smartphone, Monitor, Shield } from 'lucide-react';
import Button from './ui/Button';
import Input from './ui/Input';
import Card from './ui/Card';

const MainMenu: React.FC = () => {
  const { 
    connectionStatus, 
    createGame, 
    joinGame, 
    connect, 
    disconnect,
    setCurrentScreen,
    setPlayerName: setGlobalPlayerName,
    registerPlayer,
    isPlayerRegistered
  } = useGameStore();
  
  const { isMobile, isTablet, orientation } = useDeviceStore();
  
  const [playerName, setPlayerName] = useState('');
  const [gameId, setGameId] = useState('');
  const [selectedColor, setSelectedColor] = useState('#ff0000');
  const [showJoinForm, setShowJoinForm] = useState(false);

  const colors = [
    { value: '#ff0000', name: 'Red' },
    { value: '#0000ff', name: 'Blue' },
    { value: '#00ff00', name: 'Green' },
    { value: '#ffff00', name: 'Yellow' },
    { value: '#ff8000', name: 'Orange' },
    { value: '#8000ff', name: 'Purple' }
  ];


  const handleJoinGame = () => {
    if (playerName.trim() && gameId.trim()) {
      joinGame(gameId.trim(), playerName.trim(), selectedColor);
    }
  };

  const toggleConnection = () => {
    if (connectionStatus === 'connected') {
      disconnect();
    } else {
      connect();
    }
  };

  const handleJoinLobby = () => {
    if (playerName.trim()) {
      setGlobalPlayerName(playerName.trim());
      if (connectionStatus === 'connected' && !isPlayerRegistered) {
        registerPlayer(playerName.trim());
      }
      setCurrentScreen('lobby-browser');
    }
  };

  return (
    <div className="min-h-screen bg-game-background flex items-center justify-center p-4">
      <div className="w-full max-w-md mx-auto space-y-6">
        {/* Header */}
        <div className="text-center space-y-2">
          <h1 className="text-4xl font-bold text-white">
            Power Grid
          </h1>
          <p className="text-slate-400 text-lg">
            Digital Board Game
          </p>
          
          {/* Platform indicator */}
          <div className="flex items-center justify-center gap-2 text-sm text-slate-500">
            {isMobile ? <Smartphone className="w-4 h-4" /> : <Monitor className="w-4 h-4" />}
            <span>
              {isMobile ? 'Mobile' : isTablet ? 'Tablet' : 'Desktop'} • {orientation}
            </span>
          </div>
        </div>

        {/* Connection Status */}
        <Card className="p-4">
          <div className="flex items-center justify-between">
            <div className="flex items-center gap-2">
              {connectionStatus === 'connected' ? (
                <Wifi className="w-5 h-5 text-green-500" />
              ) : (
                <WifiOff className="w-5 h-5 text-red-500" />
              )}
              <span className={`text-sm font-medium ${
                connectionStatus === 'connected' ? 'text-green-500' : 'text-red-500'
              }`}>
                {connectionStatus === 'connected' ? 'Connected' : 
                 connectionStatus === 'connecting' ? 'Connecting...' : 
                 connectionStatus === 'error' ? 'Connection Error' : 'Disconnected'}
              </span>
            </div>
            <Button
              variant="outline"
              size="sm"
              onClick={toggleConnection}
              disabled={connectionStatus === 'connecting'}
            >
              {connectionStatus === 'connected' ? 'Disconnect' : 'Connect'}
            </Button>
          </div>
        </Card>

        {/* Player Setup */}
        <Card className="p-6 space-y-4">
          <h2 className="text-xl font-semibold text-white">Player Setup</h2>
          
          <div className="space-y-3">
            <Input
              label="Player Name"
              placeholder="Enter your name"
              value={playerName}
              onChange={(e) => setPlayerName(e.target.value)}
              disabled={connectionStatus !== 'connected'}
            />
            
            {/* Color Selection */}
            <div className="space-y-2">
              <label className="block text-sm font-medium text-white">
                Player Color
              </label>
              <div className="grid grid-cols-6 gap-2">
                {colors.map((color) => (
                  <button
                    key={color.value}
                    className={`
                      w-10 h-10 rounded-full border-2 transition-all touch-target
                      ${selectedColor === color.value 
                        ? 'border-white scale-110' 
                        : 'border-slate-600 hover:border-slate-400'
                      }
                    `}
                    style={{ backgroundColor: color.value }}
                    onClick={() => setSelectedColor(color.value)}
                    title={color.name}
                  />
                ))}
              </div>
            </div>
          </div>
        </Card>

        {/* Game Options */}
        <Card className="p-6 space-y-4">
          <h2 className="text-xl font-semibold text-white">Game Options</h2>
          
          <div className="space-y-3">
            {!showJoinForm ? (
              <>
                <Button
                  className="w-full touch-target"
                  onClick={handleJoinLobby}
                  disabled={!playerName.trim()}
                >
                  <Users className="w-5 h-5 mr-2" />
                  Browse Lobbies
                </Button>

                <Button
                  variant="outline"
                  className="w-full touch-target"
                  onClick={() => {
                    if (playerName.trim()) {
                      setGlobalPlayerName(playerName.trim());
                      if (connectionStatus === 'connected' && !isPlayerRegistered) {
                        registerPlayer(playerName.trim());
                      }
                      setCurrentScreen('lobby');
                    }
                  }}
                  disabled={!playerName.trim()}
                >
                  <Play className="w-5 h-5 mr-2" />
                  Create New Lobby
                </Button>
                
                <Button
                  variant="outline"
                  className="w-full touch-target"
                  onClick={() => setShowJoinForm(true)}
                  disabled={connectionStatus !== 'connected'}
                >
                  <Users className="w-5 h-5 mr-2" />
                  Join Game by ID
                </Button>
              </>
            ) : (
              <div className="space-y-3">
                <Input
                  label="Game ID"
                  placeholder="Enter game ID"
                  value={gameId}
                  onChange={(e) => setGameId(e.target.value)}
                />
                
                <div className="flex gap-2">
                  <Button
                    className="flex-1 touch-target"
                    onClick={handleJoinGame}
                    disabled={!playerName.trim() || !gameId.trim() || connectionStatus !== 'connected'}
                  >
                    Join Game
                  </Button>
                  
                  <Button
                    variant="outline"
                    className="touch-target"
                    onClick={() => {
                      setShowJoinForm(false);
                      setGameId('');
                    }}
                  >
                    Cancel
                  </Button>
                </div>
              </div>
            )}
          </div>
        </Card>

        {/* Settings */}
        <Card className="p-4 space-y-2">
          <button className="w-full flex items-center justify-center gap-2 text-slate-400 hover:text-white transition-colors touch-target">
            <Settings className="w-5 h-5" />
            <span>Settings</span>
          </button>
          <button 
            className="w-full flex items-center justify-center gap-2 text-slate-400 hover:text-white transition-colors touch-target"
            onClick={() => setCurrentScreen('admin')}
          >
            <Shield className="w-5 h-5" />
            <span>Admin Dashboard</span>
          </button>
        </Card>

        {/* Version Info */}
        <div className="text-center text-xs text-slate-500">
          Power Grid Digital v1.0.0 - Web Edition
        </div>
      </div>
    </div>
  );
};

export default MainMenu;