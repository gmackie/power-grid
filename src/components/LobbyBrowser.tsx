import React, { useEffect, useState } from 'react';
import { useGameStore } from '../store/gameStore';
import { 
  ArrowLeft, 
  RefreshCw, 
  Plus, 
  Users, 
  Lock, 
  Play,
  Search,
  Filter
} from 'lucide-react';
import Button from './ui/Button';
import Card from './ui/Card';
import Input from './ui/Input';
import type { LobbyListItem } from '../types/game';

const LobbyBrowser: React.FC = () => {
  const { 
    lobbies,
    connectionStatus,
    setCurrentScreen,
    listLobbies,
    joinLobby,
    playerName
  } = useGameStore();

  const [searchTerm, setSearchTerm] = useState('');
  const [showPasswordPrompt, setShowPasswordPrompt] = useState<string | null>(null);
  const [password, setPassword] = useState('');
  const [loading, setLoading] = useState(false);

  // Auto-refresh lobbies when component mounts and every 10 seconds
  useEffect(() => {
    if (connectionStatus === 'connected') {
      listLobbies();
      const interval = setInterval(listLobbies, 10000);
      return () => clearInterval(interval);
    }
  }, [connectionStatus, listLobbies]);

  const filteredLobbies = (lobbies || []).filter(lobby => 
    lobby?.name?.toLowerCase().includes(searchTerm.toLowerCase()) ||
    lobby?.map_id?.toLowerCase().includes(searchTerm.toLowerCase())
  );

  const handleRefresh = () => {
    setLoading(true);
    listLobbies();
    setTimeout(() => setLoading(false), 1000);
  };

  const handleJoinLobby = (lobbyId: string, hasPassword: boolean) => {
    if (hasPassword) {
      setShowPasswordPrompt(lobbyId);
    } else {
      joinLobby(lobbyId);
    }
  };

  const handlePasswordSubmit = () => {
    if (showPasswordPrompt) {
      joinLobby(showPasswordPrompt, password);
      setShowPasswordPrompt(null);
      setPassword('');
    }
  };

  const handleCreateNew = () => {
    setCurrentScreen('lobby');
  };

  const handleBack = () => {
    setCurrentScreen('menu');
  };

  const getStatusColor = (status: string) => {
    switch (status) {
      case 'waiting': return 'text-green-400';
      case 'starting': return 'text-yellow-400';
      case 'in_progress': return 'text-blue-400';
      case 'finished': return 'text-gray-400';
      default: return 'text-gray-400';
    }
  };

  const getStatusText = (status: string) => {
    switch (status) {
      case 'waiting': return 'Waiting for players';
      case 'starting': return 'Starting soon';
      case 'in_progress': return 'Game in progress';
      case 'finished': return 'Game finished';
      default: return status;
    }
  };

  const formatTimeAgo = (dateString: string) => {
    const date = new Date(dateString);
    const now = new Date();
    const diff = Math.floor((now.getTime() - date.getTime()) / 1000);
    
    if (diff < 60) return 'Just now';
    if (diff < 3600) return `${Math.floor(diff / 60)}m ago`;
    if (diff < 86400) return `${Math.floor(diff / 3600)}h ago`;
    return `${Math.floor(diff / 86400)}d ago`;
  };

  return (
    <div className="min-h-screen bg-game-background p-4">
      <div className="max-w-4xl mx-auto space-y-6">
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
            Browse Lobbies
          </h1>
          
          <Button
            onClick={handleCreateNew}
            className="touch-target"
          >
            <Plus className="w-5 h-5 mr-2" />
            Create
          </Button>
        </div>

        {/* Search and Controls */}
        <Card className="p-4">
          <div className="flex gap-3">
            <div className="flex-1 relative">
              <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 w-4 h-4 text-slate-400" />
              <Input
                placeholder="Search lobbies..."
                value={searchTerm}
                onChange={(e) => setSearchTerm(e.target.value)}
                className="pl-10"
              />
            </div>
            
            <Button
              variant="outline"
              onClick={handleRefresh}
              disabled={loading || connectionStatus !== 'connected'}
              className="touch-target"
            >
              <RefreshCw className={`w-5 h-5 ${loading ? 'animate-spin' : ''}`} />
            </Button>
          </div>
        </Card>

        {/* Connection Status */}
        {connectionStatus !== 'connected' && (
          <Card className="p-4 bg-yellow-900/20 border-yellow-600">
            <div className="text-center text-yellow-400">
              {connectionStatus === 'connecting' ? 'Connecting...' : 'Not connected to server'}
            </div>
          </Card>
        )}

        {/* Lobby List */}
        <div className="space-y-3">
          {filteredLobbies.length === 0 ? (
            <Card className="p-8 text-center">
              <div className="text-slate-400 space-y-2">
                <Users className="w-12 h-12 mx-auto opacity-50" />
                <p className="text-lg">No lobbies found</p>
                <p className="text-sm">
                  {searchTerm ? 'Try adjusting your search terms' : 'Be the first to create a lobby!'}
                </p>
              </div>
            </Card>
          ) : (
            filteredLobbies.map((lobby) => (
              <Card key={lobby.id} className="p-4" data-testid="lobby-card">
                <div className="flex items-center justify-between">
                  <div className="flex-1">
                    <div className="flex items-center gap-3 mb-2">
                      <h3 className="text-lg font-semibold text-white">
                        {lobby.name}
                      </h3>
                      
                      {lobby.has_password && (
                        <Lock className="w-4 h-4 text-yellow-400" />
                      )}
                      
                      <span className={`text-sm font-medium ${getStatusColor(lobby.status)}`}>
                        {getStatusText(lobby.status)}
                      </span>
                    </div>
                    
                    <div className="flex items-center gap-4 text-sm text-slate-400">
                      <div className="flex items-center gap-1">
                        <Users className="w-4 h-4" />
                        <span>{lobby.player_count || 0}/{lobby.max_players} players</span>
                      </div>
                      
                      <div>
                        Map: <span className="text-white capitalize">{lobby.map_id}</span>
                      </div>
                      
                      <div>
                        Created {formatTimeAgo(lobby.created_at)}
                      </div>
                    </div>
                    
                    {/* Player List - Note: Server only sends player_count, not individual players */}
                    {(lobby.player_count || 0) > 0 && (
                      <div className="mt-2 flex gap-1">
                        {/* Show placeholder dots for players since server doesn't send player details in lobby list */}
                        {Array.from({ length: Math.min(lobby.player_count || 0, 4) }).map((_, index) => (
                          <div
                            key={index}
                            className="w-6 h-6 rounded-full border border-slate-600 bg-slate-600"
                            title={`Player ${index + 1}`}
                          />
                        ))}
                        {(lobby.player_count || 0) > 4 && (
                          <div className="w-6 h-6 rounded-full bg-slate-700 border border-slate-600 flex items-center justify-center text-xs text-slate-300">
                            +{(lobby.player_count || 0) - 4}
                          </div>
                        )}
                      </div>
                    )}
                  </div>
                  
                  <div className="ml-4">
                    <Button
                      onClick={() => handleJoinLobby(lobby.id, lobby.has_password)}
                      disabled={
                        connectionStatus !== 'connected' ||
                        lobby.status !== 'waiting' ||
                        (lobby.player_count || 0) >= lobby.max_players
                        // Note: Can't check if player is already in lobby since server doesn't send player list
                      }
                      className="touch-target"
                    >
                      Join
                    </Button>
                  </div>
                </div>
              </Card>
            ))
          )}
        </div>

        {/* Password Prompt Modal */}
        {showPasswordPrompt && (
          <div className="fixed inset-0 bg-black/50 flex items-center justify-center p-4 z-50">
            <Card className="w-full max-w-md p-6 space-y-4">
              <h3 className="text-lg font-semibold text-white">
                Password Required
              </h3>
              
              <Input
                type="password"
                label="Enter lobby password"
                placeholder="Password"
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                onKeyPress={(e) => e.key === 'Enter' && handlePasswordSubmit()}
              />
              
              <div className="flex gap-3">
                <Button
                  onClick={handlePasswordSubmit}
                  disabled={!password.trim()}
                  className="flex-1 touch-target"
                >
                  Join Lobby
                </Button>
                
                <Button
                  variant="outline"
                  onClick={() => {
                    setShowPasswordPrompt(null);
                    setPassword('');
                  }}
                  className="touch-target"
                >
                  Cancel
                </Button>
              </div>
            </Card>
          </div>
        )}
      </div>
    </div>
  );
};

export default LobbyBrowser;