import React, { useState, useEffect } from 'react';
import Card from '../ui/Card';
import Button from '../ui/Button';
import { adminApi } from '../../services/adminApi';
import { ServerInfo, HealthStatus, GameAnalytics } from '@power-grid/api-client';
import { PlayerManagement } from './PlayerManagement';
import { GameAnalyticsView } from './GameAnalyticsView';
import { LeaderboardView } from './LeaderboardView';
import { SystemStatus } from './SystemStatus';
import { SimulatedGames } from './SimulatedGames';

type AdminSection = 'overview' | 'players' | 'analytics' | 'leaderboards' | 'system' | 'simulated';

export const AdminDashboard: React.FC = () => {
  const [activeSection, setActiveSection] = useState<AdminSection>('overview');
  const [serverInfo, setServerInfo] = useState<ServerInfo | null>(null);
  const [health, setHealth] = useState<HealthStatus | null>(null);
  const [gameAnalytics, setGameAnalytics] = useState<GameAnalytics | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    const fetchOverviewData = async () => {
      try {
        setLoading(true);
        setError(null);
        
        const [serverInfoData, healthData, analyticsData] = await Promise.all([
          adminApi.getServerInfo(),
          adminApi.getHealth(),
          adminApi.getGameAnalytics({ days: 7 })
        ]);

        setServerInfo(serverInfoData);
        setHealth(healthData);
        setGameAnalytics(analyticsData);
      } catch (err) {
        setError(err instanceof Error ? err.message : 'Failed to fetch data');
      } finally {
        setLoading(false);
      }
    };

    fetchOverviewData();
  }, []);

  const renderNavigation = () => (
    <div className="flex space-x-2 mb-6">
      {[
        { id: 'overview', label: 'Overview' },
        { id: 'players', label: 'Players' },
        { id: 'analytics', label: 'Analytics' },
        { id: 'leaderboards', label: 'Leaderboards' },
        { id: 'simulated', label: 'Simulated Games' },
        { id: 'system', label: 'System' }
      ].map(section => (
        <Button
          key={section.id}
          variant={activeSection === section.id ? 'primary' : 'secondary'}
          onClick={() => setActiveSection(section.id as AdminSection)}
        >
          {section.label}
        </Button>
      ))}
    </div>
  );

  const renderOverview = () => (
    <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
      <Card>
        <h3 className="text-lg font-semibold mb-4">Server Status</h3>
        {loading ? (
          <div className="text-gray-500">Loading...</div>
        ) : error ? (
          <div className="text-red-500">{error}</div>
        ) : (
          <div className="space-y-2">
            <div className="flex justify-between">
              <span>Status:</span>
              <span className={`font-semibold ${
                health?.status === 'healthy' ? 'text-green-600' : 'text-red-600'
              }`}>
                {health?.status || 'Unknown'}
              </span>
            </div>
            <div className="flex justify-between">
              <span>Version:</span>
              <span>{serverInfo?.version || 'Unknown'}</span>
            </div>
            <div className="flex justify-between">
              <span>Uptime:</span>
              <span>{serverInfo?.uptime ? `${Math.floor(serverInfo.uptime / 3600)}h ${Math.floor((serverInfo.uptime % 3600) / 60)}m` : 'Unknown'}</span>
            </div>
          </div>
        )}
      </Card>

      <Card>
        <h3 className="text-lg font-semibold mb-4">Game Activity (7 days)</h3>
        {loading ? (
          <div className="text-gray-500">Loading...</div>
        ) : error ? (
          <div className="text-red-500">{error}</div>
        ) : (
          <div className="space-y-2">
            <div className="flex justify-between">
              <span>Total Games:</span>
              <span className="font-semibold">{gameAnalytics?.total_games || 0}</span>
            </div>
            <div className="flex justify-between">
              <span>Unique Players:</span>
              <span className="font-semibold">{gameAnalytics?.unique_players || 0}</span>
            </div>
            <div className="flex justify-between">
              <span>Avg Duration:</span>
              <span className="font-semibold">
                {gameAnalytics?.average_game_duration ? `${Math.round(gameAnalytics.average_game_duration)}min` : 'N/A'}
              </span>
            </div>
          </div>
        )}
      </Card>

      <Card>
        <h3 className="text-lg font-semibold mb-4">Quick Actions</h3>
        <div className="space-y-2">
          <Button
            variant="outline"
            className="w-full justify-start"
            onClick={() => setActiveSection('players')}
          >
            Manage Players
          </Button>
          <Button
            variant="outline"
            className="w-full justify-start"
            onClick={() => setActiveSection('analytics')}
          >
            View Analytics
          </Button>
          <Button
            variant="outline"
            className="w-full justify-start"
            onClick={() => setActiveSection('simulated')}
          >
            Simulated Games
          </Button>
          <Button
            variant="outline"
            className="w-full justify-start"
            onClick={() => setActiveSection('system')}
          >
            System Status
          </Button>
        </div>
      </Card>
    </div>
  );

  const renderContent = () => {
    switch (activeSection) {
      case 'overview':
        return renderOverview();
      case 'players':
        return <PlayerManagement />;
      case 'analytics':
        return <GameAnalyticsView />;
      case 'leaderboards':
        return <LeaderboardView />;
      case 'simulated':
        return <SimulatedGames />;
      case 'system':
        return <SystemStatus />;
      default:
        return renderOverview();
    }
  };

  return (
    <div className="min-h-screen bg-gray-50 p-6">
      <div className="max-w-7xl mx-auto">
        <div className="mb-8">
          <h1 className="text-3xl font-bold text-gray-900 mb-2">Admin Dashboard</h1>
          <p className="text-gray-600">Manage your Power Grid game server</p>
        </div>

        {renderNavigation()}
        {renderContent()}
      </div>
    </div>
  );
};