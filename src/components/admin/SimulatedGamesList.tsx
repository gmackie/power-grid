import React, { useState, useEffect } from 'react';
import Card from '../ui/Card';
import Button from '../ui/Button';
import { SimulatedGame } from '../../types/admin';
import { RefreshCw, Play, Pause, Eye, Trash2 } from 'lucide-react';

interface SimulatedGamesListProps {
  games: SimulatedGame[];
  onViewGame: (game: SimulatedGame) => void;
  onRefresh: () => void;
}

export const SimulatedGamesList: React.FC<SimulatedGamesListProps> = ({
  games,
  onViewGame,
  onRefresh
}) => {
  const [statusFilter, setStatusFilter] = useState<string>('all');
  const [loading, setLoading] = useState(false);

  const filteredGames = games.filter(game => {
    if (statusFilter === 'all') return true;
    return game.status === statusFilter;
  });

  const getStatusColor = (status: string) => {
    switch (status) {
      case 'running':
        return 'text-green-600 bg-green-100';
      case 'paused':
        return 'text-yellow-600 bg-yellow-100';
      case 'completed':
        return 'text-blue-600 bg-blue-100';
      case 'stopped':
        return 'text-gray-600 bg-gray-100';
      default:
        return 'text-gray-600 bg-gray-100';
    }
  };

  const formatDuration = (seconds: number) => {
    const hours = Math.floor(seconds / 3600);
    const minutes = Math.floor((seconds % 3600) / 60);
    const secs = seconds % 60;
    
    if (hours > 0) {
      return `${hours}h ${minutes}m`;
    } else if (minutes > 0) {
      return `${minutes}m ${secs}s`;
    }
    return `${secs}s`;
  };

  const handleRefresh = async () => {
    setLoading(true);
    await onRefresh();
    setTimeout(() => setLoading(false), 500);
  };

  return (
    <div className="space-y-4">
      {/* Filters and Actions */}
      <Card>
        <div className="p-4 flex justify-between items-center">
          <div className="flex items-center gap-4">
            <select
              name="statusFilter"
              value={statusFilter}
              onChange={(e) => setStatusFilter(e.target.value)}
              className="px-3 py-2 border border-gray-300 rounded-md"
            >
              <option value="all">All Status</option>
              <option value="running">Running</option>
              <option value="paused">Paused</option>
              <option value="completed">Completed</option>
              <option value="stopped">Stopped</option>
            </select>
            <div className="text-sm text-gray-600">
              {filteredGames.length} game{filteredGames.length !== 1 ? 's' : ''}
            </div>
          </div>
          <Button
            variant="outline"
            size="sm"
            onClick={handleRefresh}
            disabled={loading}
          >
            <RefreshCw className={`w-4 h-4 mr-2 ${loading ? 'animate-spin' : ''}`} />
            Refresh
          </Button>
        </div>
      </Card>

      {/* Games List */}
      <Card>
        <div className="overflow-x-auto">
          <table className="min-w-full divide-y divide-gray-200">
            <thead className="bg-gray-50">
              <tr>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Game ID
                </th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Name
                </th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Status
                </th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  AI Players
                </th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Difficulty
                </th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Duration
                </th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Actions
                </th>
              </tr>
            </thead>
            <tbody className="bg-white divide-y divide-gray-200">
              {filteredGames.length === 0 ? (
                <tr>
                  <td colSpan={7} className="px-6 py-12 text-center text-gray-500">
                    {statusFilter === 'all' 
                      ? 'No simulated games found. Create one to get started.'
                      : `No ${statusFilter} games found.`
                    }
                  </td>
                </tr>
              ) : (
                filteredGames.map((game) => (
                  <tr key={game.id} className="hover:bg-gray-50">
                    <td className="px-6 py-4 whitespace-nowrap text-sm font-mono text-gray-900">
                      {game.id.slice(0, 8)}...
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-900">
                      {game.name}
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap">
                      <span className={`px-2 py-1 inline-flex text-xs leading-5 font-semibold rounded-full ${getStatusColor(game.status)}`}>
                        {game.status}
                      </span>
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                      {game.aiPlayerCount} players
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                      {game.aiDifficulty}
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                      {formatDuration(game.duration)}
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap text-sm font-medium">
                      <div className="flex items-center gap-2">
                        <Button
                          size="sm"
                          variant="outline"
                          onClick={() => onViewGame(game)}
                          title="View Game"
                        >
                          <Eye className="w-4 h-4" />
                        </Button>
                        {game.status === 'running' && (
                          <Button
                            size="sm"
                            variant="outline"
                            onClick={() => console.log('Pause game', game.id)}
                            title="Pause Game"
                          >
                            <Pause className="w-4 h-4" />
                          </Button>
                        )}
                        {game.status === 'paused' && (
                          <Button
                            size="sm"
                            variant="outline"
                            onClick={() => console.log('Resume game', game.id)}
                            title="Resume Game"
                          >
                            <Play className="w-4 h-4" />
                          </Button>
                        )}
                        {(game.status === 'completed' || game.status === 'stopped') && (
                          <Button
                            size="sm"
                            variant="outline"
                            onClick={() => console.log('Delete game', game.id)}
                            title="Delete Game"
                          >
                            <Trash2 className="w-4 h-4" />
                          </Button>
                        )}
                      </div>
                    </td>
                  </tr>
                ))
              )}
            </tbody>
          </table>
        </div>
      </Card>

      {/* Summary Stats */}
      <div className="grid grid-cols-1 md:grid-cols-4 gap-4">
        <Card>
          <div className="p-4">
            <div className="text-sm text-gray-500">Running Games</div>
            <div className="text-2xl font-semibold">
              {games.filter(g => g.status === 'running').length}
            </div>
          </div>
        </Card>
        <Card>
          <div className="p-4">
            <div className="text-sm text-gray-500">Completed Today</div>
            <div className="text-2xl font-semibold">
              {games.filter(g => 
                g.status === 'completed' && 
                new Date(g.startedAt).toDateString() === new Date().toDateString()
              ).length}
            </div>
          </div>
        </Card>
        <Card>
          <div className="p-4">
            <div className="text-sm text-gray-500">Total AI Players</div>
            <div className="text-2xl font-semibold">
              {games.reduce((sum, g) => sum + g.aiPlayerCount, 0)}
            </div>
          </div>
        </Card>
        <Card>
          <div className="p-4">
            <div className="text-sm text-gray-500">Avg Game Duration</div>
            <div className="text-2xl font-semibold">
              {games.length > 0 
                ? formatDuration(Math.floor(
                    games.reduce((sum, g) => sum + g.duration, 0) / games.length
                  ))
                : 'N/A'
              }
            </div>
          </div>
        </Card>
      </div>
    </div>
  );
};