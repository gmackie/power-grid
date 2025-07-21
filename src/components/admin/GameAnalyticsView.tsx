import React, { useState, useEffect } from 'react';
import Card from '../ui/Card';
import Button from '../ui/Button';
import { adminApi } from '../../services/adminApi';
import { GameAnalytics } from '@power-grid/api-client';

export const GameAnalyticsView: React.FC = () => {
  const [analytics, setAnalytics] = useState<GameAnalytics | null>(null);
  const [timeRange, setTimeRange] = useState<string>('7days');
  const [loading, setLoading] = useState(true);
  const [startDate, setStartDate] = useState('');
  const [endDate, setEndDate] = useState('');

  useEffect(() => {
    fetchAnalytics();
  }, [timeRange, startDate, endDate]);

  const fetchAnalytics = async () => {
    try {
      setLoading(true);
      let params: any = {};
      
      if (timeRange === 'custom' && startDate && endDate) {
        params.start = startDate;
        params.end = endDate;
      } else if (timeRange === '7days') {
        params.days = 7;
      } else if (timeRange === '30days') {
        params.days = 30;
      }

      const data = await adminApi.getGameAnalytics(params);
      setAnalytics(data);
    } catch (error) {
      console.error('Failed to fetch analytics:', error);
    } finally {
      setLoading(false);
    }
  };

  const handleTimeRangeChange = (value: string) => {
    setTimeRange(value);
    if (value !== 'custom') {
      setStartDate('');
      setEndDate('');
    }
  };

  const getTimeRangeLabel = () => {
    if (timeRange === '7days') return 'Last 7 Days';
    if (timeRange === '30days') return 'Last 30 Days';
    if (timeRange === 'custom' && startDate && endDate) {
      return `${new Date(startDate).toLocaleDateString()} - ${new Date(endDate).toLocaleDateString()}`;
    }
    return 'Select Time Range';
  };

  return (
    <div className="space-y-6">
      <div>
        <h2 className="text-2xl font-bold text-gray-900 mb-4">Game Analytics</h2>
        <p className="text-gray-600">View detailed analytics and insights about your games</p>
      </div>

      {/* Time Range Selector */}
      <Card>
        <div className="p-4">
          <div className="flex items-center gap-4">
            <label className="text-sm font-medium text-gray-700">Time Range:</label>
            <select
              name="timeRange"
              value={timeRange}
              onChange={(e) => handleTimeRangeChange(e.target.value)}
              className="px-3 py-2 border border-gray-300 rounded-md"
            >
              <option value="7days">Last 7 Days</option>
              <option value="30days">Last 30 Days</option>
              <option value="custom">Custom Range</option>
            </select>
            
            {timeRange === 'custom' && (
              <>
                <input
                  type="date"
                  name="startDate"
                  value={startDate}
                  onChange={(e) => setStartDate(e.target.value)}
                  className="px-3 py-2 border border-gray-300 rounded-md"
                  aria-label="Start Date"
                />
                <input
                  type="date"
                  name="endDate"
                  value={endDate}
                  onChange={(e) => setEndDate(e.target.value)}
                  className="px-3 py-2 border border-gray-300 rounded-md"
                  aria-label="End Date"
                />
                <Button
                  size="sm"
                  onClick={fetchAnalytics}
                  disabled={!startDate || !endDate}
                >
                  Apply
                </Button>
              </>
            )}
          </div>
          {analytics && (
            <div className="mt-2 text-sm text-gray-600">
              Showing data for: {getTimeRangeLabel()}
            </div>
          )}
        </div>
      </Card>

      {loading ? (
        <div className="text-center py-8">
          <div className="text-gray-500">Loading analytics...</div>
        </div>
      ) : analytics ? (
        <>
          {/* Key Metrics */}
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
            <Card>
              <div className="p-6">
                <h3 className="text-sm font-medium text-gray-500">Total Games Played</h3>
                <p className="mt-2 text-3xl font-semibold text-gray-900">
                  {analytics.total_games || 0}
                </p>
              </div>
            </Card>
            
            <Card>
              <div className="p-6">
                <h3 className="text-sm font-medium text-gray-500">Active Players</h3>
                <p className="mt-2 text-3xl font-semibold text-gray-900">
                  {analytics.unique_players || 0}
                </p>
              </div>
            </Card>
            
            <Card>
              <div className="p-6">
                <h3 className="text-sm font-medium text-gray-500">Average Game Duration</h3>
                <p className="mt-2 text-3xl font-semibold text-gray-900">
                  {analytics.average_game_duration ? `${Math.round(analytics.average_game_duration)}min` : 'N/A'}
                </p>
              </div>
            </Card>
            
            <Card>
              <div className="p-6">
                <h3 className="text-sm font-medium text-gray-500">Games In Progress</h3>
                <p className="mt-2 text-3xl font-semibold text-gray-900">
                  {analytics.games_in_progress || 0}
                </p>
              </div>
            </Card>
          </div>

          {/* Phase Distribution */}
          <Card>
            <div className="p-6">
              <h3 className="text-lg font-semibold mb-4">Game Phase Distribution</h3>
              <div className="phase-distribution-chart">
                {/* Placeholder for chart */}
                <div className="bg-gray-100 rounded-lg p-8 text-center text-gray-500">
                  Phase distribution chart would be displayed here
                </div>
              </div>
              <div className="mt-4 grid grid-cols-2 md:grid-cols-4 gap-4">
                <div className="text-center">
                  <div className="text-sm text-gray-500">Auction Phase</div>
                  <div className="text-lg font-semibold">{analytics.phase_breakdown?.auction || 0}%</div>
                </div>
                <div className="text-center">
                  <div className="text-sm text-gray-500">Resource Phase</div>
                  <div className="text-lg font-semibold">{analytics.phase_breakdown?.resource || 0}%</div>
                </div>
                <div className="text-center">
                  <div className="text-sm text-gray-500">Building Phase</div>
                  <div className="text-lg font-semibold">{analytics.phase_breakdown?.building || 0}%</div>
                </div>
                <div className="text-center">
                  <div className="text-sm text-gray-500">Bureaucracy Phase</div>
                  <div className="text-lg font-semibold">{analytics.phase_breakdown?.bureaucracy || 0}%</div>
                </div>
              </div>
            </div>
          </Card>

          {/* Player Statistics Tab */}
          <Card>
            <div className="p-6">
              <div className="mb-4">
                <Button
                  variant="outline"
                  size="sm"
                >
                  Player Statistics
                </Button>
                <Button
                  variant="outline"
                  size="sm"
                  className="ml-2"
                >
                  Resource Analytics
                </Button>
              </div>
              
              <div className="space-y-4">
                <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
                  <div>
                    <div className="text-sm text-gray-500">New Players</div>
                    <div className="text-2xl font-semibold">{analytics.new_players || 0}</div>
                  </div>
                  <div>
                    <div className="text-sm text-gray-500">Returning Players</div>
                    <div className="text-2xl font-semibold">{analytics.returning_players || 0}</div>
                  </div>
                  <div>
                    <div className="text-sm text-gray-500">Average Games per Player</div>
                    <div className="text-2xl font-semibold">{analytics.avg_games_per_player?.toFixed(1) || 0}</div>
                  </div>
                  <div>
                    <div className="text-sm text-gray-500">Player Retention Rate</div>
                    <div className="text-2xl font-semibold">{analytics.retention_rate ? `${(analytics.retention_rate * 100).toFixed(1)}%` : 'N/A'}</div>
                  </div>
                </div>
                
                <div className="player-activity-chart mt-6">
                  <h4 className="text-md font-medium mb-2">Player Activity</h4>
                  <div className="bg-gray-100 rounded-lg p-8 text-center text-gray-500">
                    Player activity chart would be displayed here
                  </div>
                </div>
              </div>
            </div>
          </Card>

          {/* Export Button */}
          <div className="flex justify-end">
            <Button
              variant="outline"
              onClick={() => {
                // Export functionality would be implemented here
                console.log('Export analytics');
              }}
            >
              Export Analytics
            </Button>
          </div>
        </>
      ) : (
        <Card>
          <div className="p-6 text-center text-gray-500">
            No analytics data available
          </div>
        </Card>
      )}
    </div>
  );
};