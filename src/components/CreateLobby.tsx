import React, { useState } from 'react';
import { useGameStore } from '../store/gameStore';
import { ArrowLeft, Users, Map, Lock, Play } from 'lucide-react';
import Button from './ui/Button';
import Card from './ui/Card';
import Input from './ui/Input';

const CreateLobby: React.FC = () => {
  const { 
    setCurrentScreen,
    createLobby,
    connectionStatus,
    playerName
  } = useGameStore();

  const [lobbyName, setLobbyName] = useState(`${playerName}'s Game`);
  const [maxPlayers, setMaxPlayers] = useState(4);
  const [selectedMap, setSelectedMap] = useState('usa');
  const [password, setPassword] = useState('');
  const [usePassword, setUsePassword] = useState(false);
  const [creating, setCreating] = useState(false);

  const availableMaps = [
    { id: 'usa', name: 'USA', description: 'The original Power Grid map' },
    { id: 'germany', name: 'Germany', description: 'European variant with different regions' },
    { id: 'china', name: 'China', description: 'Asian expansion with unique mechanics' }
  ];

  const playerCounts = [2, 3, 4, 5, 6];

  const handleCreateLobby = async () => {
    if (!lobbyName.trim() || creating) return;
    
    setCreating(true);
    
    try {
      createLobby(
        lobbyName.trim(),
        maxPlayers,
        selectedMap,
        usePassword ? password : undefined
      );
    } catch (error) {
      console.error('Failed to create lobby:', error);
      setCreating(false);
    }
    
    // Note: setCreating(false) will be handled by the store when we receive the lobby created response
  };

  const handleBack = () => {
    setCurrentScreen('lobby-browser');
  };

  return (
    <div className="min-h-screen bg-game-background p-4">
      <div className="max-w-2xl mx-auto space-y-6">
        {/* Header */}
        <div className="flex items-center justify-between">
          <Button
            variant="outline"
            onClick={handleBack}
            className="touch-target"
          >
            <ArrowLeft className="w-5 h-5 mr-2" />
            Back
          </Button>
          
          <h1 className="text-2xl font-bold text-white">
            Create Lobby
          </h1>
          
          <div></div> {/* Spacer */}
        </div>

        {/* Lobby Settings */}
        <Card className="p-6 space-y-6">
          <h2 className="text-xl font-semibold text-white">Lobby Settings</h2>
          
          {/* Lobby Name */}
          <div className="space-y-2">
            <Input
              label="Lobby Name"
              placeholder="Enter lobby name"
              value={lobbyName}
              onChange={(e) => setLobbyName(e.target.value)}
              disabled={creating}
            />
          </div>

          {/* Max Players */}
          <div className="space-y-2">
            <label className="block text-sm font-medium text-white">
              Maximum Players
            </label>
            <div className="grid grid-cols-5 gap-2">
              {playerCounts.map((count) => (
                <button
                  key={count}
                  className={`
                    p-3 rounded-lg border-2 transition-all touch-target
                    ${maxPlayers === count 
                      ? 'border-blue-500 bg-blue-500/20 text-blue-400' 
                      : 'border-slate-600 bg-game-surface text-slate-300 hover:border-slate-400'
                    }
                  `}
                  onClick={() => setMaxPlayers(count)}
                  disabled={creating}
                >
                  <Users className="w-5 h-5 mx-auto mb-1" />
                  <div className="text-sm font-medium">{count}</div>
                </button>
              ))}
            </div>
          </div>

          {/* Map Selection */}
          <div className="space-y-2">
            <label className="block text-sm font-medium text-white">
              Game Map
            </label>
            <div className="space-y-2">
              {availableMaps.map((map) => (
                <button
                  key={map.id}
                  className={`
                    w-full p-4 rounded-lg border-2 transition-all text-left touch-target
                    ${selectedMap === map.id 
                      ? 'border-blue-500 bg-blue-500/20' 
                      : 'border-slate-600 bg-game-surface hover:border-slate-400'
                    }
                  `}
                  onClick={() => setSelectedMap(map.id)}
                  disabled={creating}
                >
                  <div className="flex items-center gap-3">
                    <Map className="w-5 h-5 text-blue-400" />
                    <div>
                      <div className="text-white font-medium">{map.name}</div>
                      <div className="text-sm text-slate-400">{map.description}</div>
                    </div>
                  </div>
                </button>
              ))}
            </div>
          </div>

          {/* Password Protection */}
          <div className="space-y-3">
            <div className="flex items-center gap-3">
              <input
                type="checkbox"
                id="usePassword"
                checked={usePassword}
                onChange={(e) => setUsePassword(e.target.checked)}
                disabled={creating}
                className="w-4 h-4 text-blue-600 bg-gray-100 border-gray-300 rounded focus:ring-blue-500"
              />
              <label htmlFor="usePassword" className="text-white font-medium">
                Password Protection
              </label>
            </div>
            
            {usePassword && (
              <Input
                type="password"
                label="Lobby Password"
                placeholder="Enter password"
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                disabled={creating}
              />
            )}
          </div>
        </Card>

        {/* Host Info */}
        <Card className="p-4 bg-blue-900/20 border-blue-600">
          <div className="flex items-center gap-2 text-blue-400">
            <Users className="w-5 h-5" />
            <span className="font-medium">Host: {playerName}</span>
          </div>
          <p className="text-sm text-blue-300 mt-1">
            As the host, you can start the game when ready and control lobby settings.
          </p>
        </Card>

        {/* Connection Status */}
        {connectionStatus !== 'connected' && (
          <Card className="p-4 bg-red-900/20 border-red-600">
            <div className="text-center text-red-400">
              <p className="font-medium">Not Connected</p>
              <p className="text-sm">You must be connected to create a lobby</p>
            </div>
          </Card>
        )}

        {/* Create Button */}
        <div className="space-y-3">
          <Button
            className="w-full touch-target"
            onClick={handleCreateLobby}
            disabled={
              !lobbyName.trim() || 
              creating || 
              connectionStatus !== 'connected' ||
              (usePassword && !password.trim())
            }
          >
            {creating ? (
              <>
                <div className="w-5 h-5 border-2 border-white border-t-transparent rounded-full animate-spin mr-2" />
                Creating Lobby...
              </>
            ) : (
              <>
                <Play className="w-5 h-5 mr-2" />
                Create Lobby
              </>
            )}
          </Button>
          
          {creating && (
            <p className="text-center text-sm text-slate-400">
              Setting up your lobby on the server...
            </p>
          )}
        </div>
      </div>
    </div>
  );
};

export default CreateLobby;