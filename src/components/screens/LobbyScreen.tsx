import React, { useState, useEffect } from 'react';
import { useGameStore } from '../../store/gameStore';
import { wsManager, lobbyActions } from '../../services/websocket';
import type { MapInfo, LobbyInfo } from '../../types/game';
import { Settings, Users, Crown, Check, X, Plus, RefreshCw } from 'lucide-react';

interface LobbyPlayer {
  id: string;
  name: string;
  is_host: boolean;
  is_ready: boolean;
  joined_at: string;
}

interface LobbyMessage {
  id: string;
  player_id: string;
  player_name: string;
  content: string;
  created_at: string;
}

interface LobbyData {
  id: string;
  name: string;
  status: string;
  players: Record<string, LobbyPlayer>;
  messages: LobbyMessage[];
  max_players: number;
  map_id: string;
  created_at: string;
  updated_at: string;
}

const LobbyScreen: React.FC = () => {
  const { playerName, setCurrentScreen } = useGameStore();
  const [availableMaps, setAvailableMaps] = useState<MapInfo[]>([]);
  const [availableLobbies, setAvailableLobbies] = useState<LobbyInfo[]>([]);
  const [currentLobby, setCurrentLobby] = useState<LobbyData | null>(null);
  const [playerId, setPlayerId] = useState<string>('');
  const [isConnected, setIsConnected] = useState(false);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string>('');

  // Create lobby form state
  const [showCreateForm, setShowCreateForm] = useState(false);
  const [newLobbyName, setNewLobbyName] = useState('');
  const [selectedMapId, setSelectedMapId] = useState('usa');
  const [maxPlayers, setMaxPlayers] = useState(4);
  const [lobbyPassword, setLobbyPassword] = useState('');

  // Chat state
  const [chatMessage, setChatMessage] = useState('');

  useEffect(() => {
    if (!playerName) {
      setCurrentScreen('menu');
      return;
    }

    // Set up WebSocket handlers
    wsManager.setOnConnectionChange((status) => {
      setIsConnected(status === 'connected');
      if (status === 'connected') {
        // Connect as player
        lobbyActions.connect(playerName);
      }
    });

    wsManager.setOnError((errorMsg) => {
      setError(errorMsg);
    });

    wsManager.setOnMessage((message) => {
      console.log('Received message:', message.type, message.data);
      
      switch (message.type) {
        case 'CONNECTED':
          if (message.data?.player_id) {
            setPlayerId(message.data.player_id);
            // Load maps and lobbies
            lobbyActions.listMaps();
            lobbyActions.listLobbies();
          }
          break;

        case 'MAPS_LISTED':
          if (message.data?.maps) {
            setAvailableMaps(message.data.maps);
          }
          break;

        case 'LOBBIES_LISTED':
          if (message.data?.lobbies) {
            setAvailableLobbies(message.data.lobbies);
          }
          break;

        case 'LOBBY_CREATED':
        case 'LOBBY_JOINED':
        case 'LOBBY_UPDATED':
          if (message.data?.lobby) {
            setCurrentLobby(message.data.lobby);
          }
          break;

        case 'LOBBY_LEFT':
          setCurrentLobby(null);
          lobbyActions.listLobbies();
          break;

        case 'GAME_STARTING':
          if (message.data?.lobby) {
            // Transition to game
            setCurrentScreen('game');
          }
          break;

        case 'ERROR':
          setError(message.data?.message || 'Unknown error');
          break;
      }
    });

    // Connect to WebSocket
    if (!wsManager.isConnected()) {
      wsManager.connect().catch((err) => {
        setError('Failed to connect to server');
        console.error('Connection failed:', err);
      });
    }

    return () => {
      // Cleanup WebSocket handlers
      wsManager.setOnConnectionChange(() => {});
      wsManager.setOnError(() => {});
      wsManager.setOnMessage(() => {});
    };
  }, [playerName, setCurrentScreen]);

  const handleCreateLobby = () => {
    if (!newLobbyName.trim()) {
      setError('Lobby name is required');
      return;
    }

    setLoading(true);
    lobbyActions.createLobby(newLobbyName, playerName, maxPlayers, selectedMapId, lobbyPassword);
    setShowCreateForm(false);
    setNewLobbyName('');
    setLobbyPassword('');
    setLoading(false);
  };

  const handleJoinLobby = (lobby: LobbyInfo) => {
    setLoading(true);
    const password = lobby.has_password ? prompt('Enter lobby password:') : '';
    if (lobby.has_password && !password) {
      setLoading(false);
      return;
    }
    lobbyActions.joinLobby(lobby.id, playerName, password || '');
    setLoading(false);
  };

  const handleLeaveLobby = () => {
    lobbyActions.leaveLobby();
  };

  const handleToggleReady = () => {
    if (currentLobby && playerId) {
      const currentPlayer = currentLobby.players[playerId];
      if (currentPlayer) {
        lobbyActions.setReady(!currentPlayer.is_ready);
      }
    }
  };

  const handleStartGame = () => {
    lobbyActions.startGame();
  };

  const handleSendMessage = () => {
    if (chatMessage.trim()) {
      lobbyActions.sendChatMessage(chatMessage);
      setChatMessage('');
    }
  };

  const refreshLobbies = () => {
    lobbyActions.listLobbies();
  };

  if (!isConnected) {
    return (
      <div className="min-h-screen bg-gray-900 text-white flex items-center justify-center">
        <div className="text-center">
          <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-blue-500 mx-auto mb-4"></div>
          <p>Connecting to server...</p>
          {error && <p className="text-red-400 mt-2">{error}</p>}
        </div>
      </div>
    );
  }

  // If in a lobby, show lobby view
  if (currentLobby) {
    const currentPlayer = currentLobby.players[playerId];
    const isHost = currentPlayer?.is_host || false;
    const playersList = Object.values(currentLobby.players);
    const selectedMap = availableMaps.find(m => m.id === currentLobby.map_id);
    const allReady = playersList.every(p => p.is_ready);
    const canStart = isHost && allReady && playersList.length >= 2;

    return (
      <div className="min-h-screen bg-gray-900 text-white p-4">
        <div className="max-w-6xl mx-auto">
          {/* Header */}
          <div className="flex items-center justify-between mb-6">
            <div>
              <h1 className="text-3xl font-bold text-blue-400">{currentLobby.name}</h1>
              <p className="text-gray-400">
                Map: {selectedMap?.name || currentLobby.map_id} • 
                {playersList.length}/{currentLobby.max_players} players
              </p>
            </div>
            <button
              onClick={handleLeaveLobby}
              className="px-4 py-2 bg-red-600 hover:bg-red-700 rounded-lg transition-colors"
            >
              Leave Lobby
            </button>
          </div>

          <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
            {/* Players List */}
            <div className="lg:col-span-1">
              <div className="bg-gray-800 rounded-lg p-4">
                <h2 className="text-xl font-semibold mb-4 flex items-center">
                  <Users className="mr-2" size={20} />
                  Players
                </h2>
                <div className="space-y-2">
                  {playersList.map((player) => (
                    <div key={player.id} className="flex items-center justify-between p-2 bg-gray-700 rounded">
                      <div className="flex items-center">
                        {player.is_host && <Crown className="mr-2 text-yellow-400" size={16} />}
                        <span>{player.name}</span>
                      </div>
                      <div className="flex items-center">
                        {player.is_ready ? (
                          <Check className="text-green-400" size={16} />
                        ) : (
                          <X className="text-red-400" size={16} />
                        )}
                      </div>
                    </div>
                  ))}
                </div>
                
                {/* Ready Button */}
                <div className="mt-4 space-y-2">
                  <button
                    onClick={handleToggleReady}
                    className={`w-full px-4 py-2 rounded-lg transition-colors ${
                      currentPlayer?.is_ready 
                        ? 'bg-green-600 hover:bg-green-700' 
                        : 'bg-gray-600 hover:bg-gray-700'
                    }`}
                  >
                    {currentPlayer?.is_ready ? 'Ready' : 'Not Ready'}
                  </button>
                  
                  {isHost && (
                    <button
                      onClick={handleStartGame}
                      disabled={!canStart}
                      className={`w-full px-4 py-2 rounded-lg transition-colors ${
                        canStart 
                          ? 'bg-blue-600 hover:bg-blue-700' 
                          : 'bg-gray-600 cursor-not-allowed'
                      }`}
                    >
                      Start Game
                    </button>
                  )}
                </div>
              </div>
            </div>

            {/* Map Info & Chat */}
            <div className="lg:col-span-2 space-y-6">
              {/* Map Info */}
              {selectedMap && (
                <div className="bg-gray-800 rounded-lg p-4">
                  <h2 className="text-xl font-semibold mb-2">{selectedMap.name}</h2>
                  <p className="text-gray-400 mb-2">{selectedMap.description}</p>
                  <div className="flex space-x-4 text-sm text-gray-300">
                    <span>{selectedMap.cityCount} cities</span>
                    <span>{selectedMap.regionCount} regions</span>
                    <span>{selectedMap.playerCount.min}-{selectedMap.playerCount.max} players</span>
                  </div>
                </div>
              )}

              {/* Chat */}
              <div className="bg-gray-800 rounded-lg p-4">
                <h2 className="text-xl font-semibold mb-4">Chat</h2>
                <div className="h-64 overflow-y-auto bg-gray-700 rounded p-3 mb-4">
                  {currentLobby.messages.map((message) => (
                    <div key={message.id} className="mb-2">
                      <span className="font-medium text-blue-400">{message.player_name}:</span>
                      <span className="ml-2">{message.content}</span>
                    </div>
                  ))}
                </div>
                <div className="flex">
                  <input
                    type="text"
                    value={chatMessage}
                    onChange={(e) => setChatMessage(e.target.value)}
                    onKeyPress={(e) => e.key === 'Enter' && handleSendMessage()}
                    placeholder="Type a message..."
                    className="flex-1 px-3 py-2 bg-gray-700 border border-gray-600 rounded-l-lg focus:outline-none focus:border-blue-500"
                  />
                  <button
                    onClick={handleSendMessage}
                    className="px-4 py-2 bg-blue-600 hover:bg-blue-700 rounded-r-lg transition-colors"
                  >
                    Send
                  </button>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    );
  }

  // Lobby browser view
  return (
    <div className="min-h-screen bg-gray-900 text-white p-4">
      <div className="max-w-6xl mx-auto">
        {/* Header */}
        <div className="flex items-center justify-between mb-6">
          <div>
            <h1 className="text-3xl font-bold text-blue-400">Lobby Browser</h1>
            <p className="text-gray-400">Welcome, {playerName}!</p>
          </div>
          <div className="flex space-x-4">
            <button
              onClick={refreshLobbies}
              className="px-4 py-2 bg-gray-600 hover:bg-gray-700 rounded-lg transition-colors flex items-center"
            >
              <RefreshCw size={16} className="mr-2" />
              Refresh
            </button>
            <button
              onClick={() => setShowCreateForm(true)}
              className="px-4 py-2 bg-blue-600 hover:bg-blue-700 rounded-lg transition-colors flex items-center"
            >
              <Plus size={16} className="mr-2" />
              Create Lobby
            </button>
            <button
              onClick={() => setCurrentScreen('menu')}
              className="px-4 py-2 bg-gray-600 hover:bg-gray-700 rounded-lg transition-colors"
            >
              Back to Menu
            </button>
          </div>
        </div>

        {error && (
          <div className="bg-red-900 border border-red-700 text-red-100 px-4 py-3 rounded mb-6">
            {error}
            <button onClick={() => setError('')} className="float-right text-red-200 hover:text-white">×</button>
          </div>
        )}

        <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
          {/* Available Lobbies */}
          <div className="lg:col-span-2">
            <h2 className="text-xl font-semibold mb-4">Available Lobbies</h2>
            <div className="space-y-3">
              {availableLobbies.length === 0 ? (
                <div className="bg-gray-800 rounded-lg p-6 text-center text-gray-400">
                  No lobbies available. Create one to get started!
                </div>
              ) : (
                availableLobbies.map((lobby) => {
                  const mapInfo = availableMaps.find(m => m.id === lobby.map_id);
                  return (
                    <div key={lobby.id} className="bg-gray-800 rounded-lg p-4">
                      <div className="flex items-center justify-between">
                        <div>
                          <h3 className="font-semibold text-lg">{lobby.name}</h3>
                          <p className="text-gray-400">
                            Map: {mapInfo?.name || lobby.map_id} • 
                            {lobby.player_count}/{lobby.max_players} players
                            {lobby.has_password && ' • 🔒'}
                          </p>
                        </div>
                        <button
                          onClick={() => handleJoinLobby(lobby)}
                          disabled={lobby.player_count >= lobby.max_players || loading}
                          className={`px-4 py-2 rounded-lg transition-colors ${
                            lobby.player_count >= lobby.max_players 
                              ? 'bg-gray-600 cursor-not-allowed' 
                              : 'bg-blue-600 hover:bg-blue-700'
                          }`}
                        >
                          {lobby.player_count >= lobby.max_players ? 'Full' : 'Join'}
                        </button>
                      </div>
                    </div>
                  );
                })
              )}
            </div>
          </div>

          {/* Available Maps */}
          <div className="lg:col-span-1">
            <h2 className="text-xl font-semibold mb-4">Available Maps</h2>
            <div className="space-y-3">
              {availableMaps.map((map) => (
                <div key={map.id} className="bg-gray-800 rounded-lg p-3">
                  <h3 className="font-medium">{map.name}</h3>
                  <p className="text-sm text-gray-400">{map.description}</p>
                  <div className="text-xs text-gray-500 mt-1">
                    {map.cityCount} cities • {map.playerCount.min}-{map.playerCount.max} players
                  </div>
                </div>
              ))}
            </div>
          </div>
        </div>

        {/* Create Lobby Modal */}
        {showCreateForm && (
          <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50">
            <div className="bg-gray-800 rounded-lg p-6 w-full max-w-md">
              <h2 className="text-xl font-semibold mb-4">Create New Lobby</h2>
              
              <div className="space-y-4">
                <div>
                  <label className="block text-sm font-medium mb-1">Lobby Name</label>
                  <input
                    type="text"
                    value={newLobbyName}
                    onChange={(e) => setNewLobbyName(e.target.value)}
                    className="w-full px-3 py-2 bg-gray-700 border border-gray-600 rounded-lg focus:outline-none focus:border-blue-500"
                    placeholder="Enter lobby name"
                  />
                </div>

                <div>
                  <label className="block text-sm font-medium mb-1">Map</label>
                  <select
                    value={selectedMapId}
                    onChange={(e) => setSelectedMapId(e.target.value)}
                    className="w-full px-3 py-2 bg-gray-700 border border-gray-600 rounded-lg focus:outline-none focus:border-blue-500"
                  >
                    {availableMaps.map((map) => (
                      <option key={map.id} value={map.id}>
                        {map.name} ({map.cityCount} cities)
                      </option>
                    ))}
                  </select>
                </div>

                <div>
                  <label className="block text-sm font-medium mb-1">Max Players</label>
                  <select
                    value={maxPlayers}
                    onChange={(e) => setMaxPlayers(parseInt(e.target.value))}
                    className="w-full px-3 py-2 bg-gray-700 border border-gray-600 rounded-lg focus:outline-none focus:border-blue-500"
                  >
                    {[2, 3, 4, 5, 6].map((num) => (
                      <option key={num} value={num}>{num} players</option>
                    ))}
                  </select>
                </div>

                <div>
                  <label className="block text-sm font-medium mb-1">Password (optional)</label>
                  <input
                    type="password"
                    value={lobbyPassword}
                    onChange={(e) => setLobbyPassword(e.target.value)}
                    className="w-full px-3 py-2 bg-gray-700 border border-gray-600 rounded-lg focus:outline-none focus:border-blue-500"
                    placeholder="Leave empty for public lobby"
                  />
                </div>
              </div>

              <div className="flex justify-end space-x-3 mt-6">
                <button
                  onClick={() => setShowCreateForm(false)}
                  className="px-4 py-2 bg-gray-600 hover:bg-gray-700 rounded-lg transition-colors"
                >
                  Cancel
                </button>
                <button
                  onClick={handleCreateLobby}
                  disabled={!newLobbyName.trim() || loading}
                  className="px-4 py-2 bg-blue-600 hover:bg-blue-700 rounded-lg transition-colors disabled:bg-gray-600 disabled:cursor-not-allowed"
                >
                  Create
                </button>
              </div>
            </div>
          </div>
        )}
      </div>
    </div>
  );
};

export default LobbyScreen;