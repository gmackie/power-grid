import React, { useState, useEffect } from 'react';
import Card from '../ui/Card';
import Input from '../ui/Input';
import Button from '../ui/Button';
import { adminApi } from '../../services/adminApi';
import { PlayerSummary } from '@power-grid/api-client';

export const PlayerManagement: React.FC = () => {
  const [players, setPlayers] = useState<PlayerSummary[]>([]);
  const [searchTerm, setSearchTerm] = useState('');
  const [statusFilter, setStatusFilter] = useState<'all' | 'active' | 'inactive'>('all');
  const [activityFilter, setActivityFilter] = useState<string>('all');
  const [loading, setLoading] = useState(true);
  const [selectedPlayer, setSelectedPlayer] = useState<PlayerSummary | null>(null);

  useEffect(() => {
    fetchPlayers();
  }, []);

  const fetchPlayers = async () => {
    try {
      setLoading(true);
      const data = await adminApi.getPlayers();
      setPlayers(data);
    } catch (error) {
      console.error('Failed to fetch players:', error);
    } finally {
      setLoading(false);
    }
  };

  const filteredPlayers = players.filter(player => {
    const matchesSearch = player.name.toLowerCase().includes(searchTerm.toLowerCase());
    const matchesStatus = statusFilter === 'all' || player.status === statusFilter;
    return matchesSearch && matchesStatus;
  });

  return (
    <div className="space-y-6">
      <div>
        <h2 className="text-2xl font-bold text-gray-900 mb-4">Player Management</h2>
        <p className="text-gray-600">Manage and view player statistics</p>
      </div>

      <Card>
        <div className="p-6">
          <div className="mb-6 flex gap-4">
            <Input
              type="text"
              placeholder="Search players..."
              value={searchTerm}
              onChange={(e) => setSearchTerm(e.target.value)}
              className="flex-1 max-w-md"
            />
            <select
              name="statusFilter"
              value={statusFilter}
              onChange={(e) => setStatusFilter(e.target.value as any)}
              className="px-3 py-2 border border-gray-300 rounded-md"
            >
              <option value="all">All Status</option>
              <option value="active">Active</option>
              <option value="inactive">Inactive</option>
            </select>
            <select
              name="activityFilter"
              value={activityFilter}
              onChange={(e) => setActivityFilter(e.target.value)}
              className="px-3 py-2 border border-gray-300 rounded-md"
            >
              <option value="all">All Time</option>
              <option value="last7days">Last 7 Days</option>
              <option value="last30days">Last 30 Days</option>
            </select>
          </div>

          {loading ? (
            <div className="text-center py-8">
              <div className="text-gray-500">Loading players...</div>
            </div>
          ) : (
            <div className="overflow-x-auto">
              <table className="min-w-full divide-y divide-gray-200">
                <thead className="bg-gray-50">
                  <tr>
                    <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                      Player Name
                    </th>
                    <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                      Games Played
                    </th>
                    <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                      Win Rate
                    </th>
                    <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                      Last Active
                    </th>
                    <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                      Status
                    </th>
                    <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                      Actions
                    </th>
                  </tr>
                </thead>
                <tbody className="bg-white divide-y divide-gray-200">
                  {filteredPlayers.map((player) => (
                    <tr key={player.id} data-player-id={player.id} className="hover:bg-gray-50 cursor-pointer" onClick={() => setSelectedPlayer(player)}>
                      <td className="px-6 py-4 whitespace-nowrap text-sm font-medium text-gray-900">
                        {player.name}
                      </td>
                      <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                        {player.games_played}
                      </td>
                      <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                        {(player.win_rate * 100).toFixed(1)}%
                      </td>
                      <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                        {new Date(player.last_active).toLocaleDateString()}
                      </td>
                      <td className="px-6 py-4 whitespace-nowrap">
                        <span className={`px-2 inline-flex text-xs leading-5 font-semibold rounded-full ${
                          player.status === 'active' 
                            ? 'bg-green-100 text-green-800' 
                            : 'bg-gray-100 text-gray-800'
                        }`}>
                          {player.status}
                        </span>
                      </td>
                      <td className="px-6 py-4 whitespace-nowrap text-sm font-medium">
                        <Button
                          size="sm"
                          variant="outline"
                          onClick={(e) => {
                            e.stopPropagation();
                            setSelectedPlayer(player);
                          }}
                        >
                          View Details
                        </Button>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          )}
        </div>
      </Card>

      {/* Player Details Modal */}
      {selectedPlayer && (
        <div className="fixed inset-0 bg-gray-500 bg-opacity-75 flex items-center justify-center p-4 z-50">
          <div className="bg-white rounded-lg p-6 max-w-2xl w-full max-h-[90vh] overflow-y-auto">
            <h3 className="text-lg font-semibold mb-4">Player Details</h3>
            <div className="space-y-4">
              <div>
                <h4 className="font-medium text-gray-700">Basic Information</h4>
                <div className="mt-2 space-y-2">
                  <div className="flex justify-between">
                    <span className="text-gray-500">Name:</span>
                    <span className="font-medium">{selectedPlayer.name}</span>
                  </div>
                  <div className="flex justify-between">
                    <span className="text-gray-500">Total Games:</span>
                    <span className="font-medium">{selectedPlayer.games_played}</span>
                  </div>
                  <div className="flex justify-between">
                    <span className="text-gray-500">Wins:</span>
                    <span className="font-medium">{selectedPlayer.wins}</span>
                  </div>
                  <div className="flex justify-between">
                    <span className="text-gray-500">Win Rate:</span>
                    <span className="font-medium">{(selectedPlayer.win_rate * 100).toFixed(1)}%</span>
                  </div>
                  <div className="flex justify-between">
                    <span className="text-gray-500">Average Score:</span>
                    <span className="font-medium">{selectedPlayer.average_score.toFixed(0)}</span>
                  </div>
                  <div className="flex justify-between">
                    <span className="text-gray-500">Favorite Map:</span>
                    <span className="font-medium">{selectedPlayer.favorite_map || 'N/A'}</span>
                  </div>
                </div>
              </div>

              <div>
                <h4 className="font-medium text-gray-700">Recent Games</h4>
                <p className="text-sm text-gray-500 mt-2">Game history would be displayed here</p>
              </div>

              <div>
                <h4 className="font-medium text-gray-700">Achievements</h4>
                <p className="text-sm text-gray-500 mt-2">Player achievements would be displayed here</p>
              </div>
            </div>
            
            <div className="mt-6 flex justify-end">
              <Button
                variant="outline"
                onClick={() => setSelectedPlayer(null)}
              >
                Close
              </Button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};