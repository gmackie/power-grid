import React, { useState, useEffect } from 'react';
import Card from '../ui/Card';
import Button from '../ui/Button';
import { adminApi } from '../../services/adminApi';
import { LeaderboardEntry } from '@power-grid/api-client';

export const LeaderboardView: React.FC = () => {
  const [entries, setEntries] = useState<LeaderboardEntry[]>([]);
  const [leaderboardType, setLeaderboardType] = useState<'global' | 'weekly' | 'monthly' | 'alltime'>('global');
  const [mapFilter, setMapFilter] = useState<string>('all');
  const [loading, setLoading] = useState(true);
  const [availableMaps] = useState([
    { id: 'all', name: 'All Maps' },
    { id: 'usa', name: 'USA' },
    { id: 'germany', name: 'Germany' },
    { id: 'france', name: 'France' },
    { id: 'italy', name: 'Italy' },
    { id: 'japan', name: 'Japan' }
  ]);

  useEffect(() => {
    fetchLeaderboard();
  }, [leaderboardType, mapFilter]);

  const fetchLeaderboard = async () => {
    try {
      setLoading(true);
      const data = await adminApi.getLeaderboard(50); // Top 50 players
      setEntries(data);
    } catch (error) {
      console.error('Failed to fetch leaderboard:', error);
    } finally {
      setLoading(false);
    }
  };

  const getLeaderboardTitle = () => {
    const typeTitle = {
      global: 'Global',
      weekly: 'Weekly',
      monthly: 'Monthly',
      alltime: 'All Time'
    }[leaderboardType];

    const mapTitle = mapFilter === 'all' ? '' : ` - ${availableMaps.find(m => m.id === mapFilter)?.name} Map`;
    
    return `${typeTitle} Leaderboard${mapTitle}`;
  };

  const getTrendIcon = (trend: string) => {
    if (trend === 'up') return '↑';
    if (trend === 'down') return '↓';
    return '—';
  };

  const getTrendColor = (trend: string) => {
    if (trend === 'up') return 'text-green-600';
    if (trend === 'down') return 'text-red-600';
    return 'text-gray-400';
  };

  return (
    <div className="space-y-6">
      <div>
        <h2 className="text-2xl font-bold text-gray-900 mb-4">Leaderboards</h2>
        <p className="text-gray-600">View player rankings and competitive standings</p>
      </div>

      {/* Leaderboard Controls */}
      <Card>
        <div className="p-4">
          <div className="flex flex-wrap gap-2 mb-4">
            <Button
              variant={leaderboardType === 'global' ? 'primary' : 'outline'}
              size="sm"
              onClick={() => setLeaderboardType('global')}
            >
              Global
            </Button>
            <Button
              variant={leaderboardType === 'weekly' ? 'primary' : 'outline'}
              size="sm"
              onClick={() => setLeaderboardType('weekly')}
            >
              Weekly
            </Button>
            <Button
              variant={leaderboardType === 'monthly' ? 'primary' : 'outline'}
              size="sm"
              onClick={() => setLeaderboardType('monthly')}
            >
              Monthly
            </Button>
            <Button
              variant={leaderboardType === 'alltime' ? 'primary' : 'outline'}
              size="sm"
              onClick={() => setLeaderboardType('alltime')}
            >
              All Time
            </Button>
          </div>

          <div className="flex items-center gap-4">
            <label className="text-sm font-medium text-gray-700">Filter by Map:</label>
            <select
              name="mapFilter"
              value={mapFilter}
              onChange={(e) => setMapFilter(e.target.value)}
              className="px-3 py-2 border border-gray-300 rounded-md"
            >
              {availableMaps.map(map => (
                <option key={map.id} value={map.id}>{map.name}</option>
              ))}
            </select>
          </div>
        </div>
      </Card>

      {/* Leaderboard Table */}
      <Card>
        <div className="p-6">
          <h3 className="text-lg font-semibold mb-4">{getLeaderboardTitle()}</h3>
          
          {loading ? (
            <div className="text-center py-8">
              <div className="text-gray-500">Loading leaderboard...</div>
            </div>
          ) : entries.length > 0 ? (
            <div className="overflow-x-auto">
              <table className="min-w-full divide-y divide-gray-200">
                <thead className="bg-gray-50">
                  <tr>
                    <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                      Rank
                    </th>
                    <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                      Player
                    </th>
                    <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                      Rating
                    </th>
                    <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                      Games
                    </th>
                    <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                      Win %
                    </th>
                    <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                      Trend
                    </th>
                  </tr>
                </thead>
                <tbody className="bg-white divide-y divide-gray-200">
                  {entries.map((entry) => (
                    <tr key={entry.player_id} className="hover:bg-gray-50">
                      <td className="px-6 py-4 whitespace-nowrap text-sm font-medium text-gray-900">
                        {entry.rank}
                        {entry.rank <= 3 && (
                          <span className="ml-2">
                            {entry.rank === 1 && '🥇'}
                            {entry.rank === 2 && '🥈'}
                            {entry.rank === 3 && '🥉'}
                          </span>
                        )}
                      </td>
                      <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-900">
                        {entry.player_name}
                      </td>
                      <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                        {entry.rating}
                      </td>
                      <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                        {entry.games_played}
                      </td>
                      <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                        {(entry.win_rate * 100).toFixed(1)}%
                      </td>
                      <td className="px-6 py-4 whitespace-nowrap text-sm">
                        <span className={getTrendColor(entry.trend)}>
                          {getTrendIcon(entry.trend)}
                        </span>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          ) : (
            <div className="text-center py-8 text-gray-500">
              No leaderboard data available
            </div>
          )}
        </div>
      </Card>

      {/* Achievement Leaderboard */}
      <Card>
        <div className="p-6">
          <h3 className="text-lg font-semibold mb-4">Achievement Leaderboard</h3>
          <div className="text-center py-8 text-gray-500">
            Achievement leaderboard would be displayed here
          </div>
        </div>
      </Card>
    </div>
  );
};