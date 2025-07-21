import React, { useState, useEffect } from 'react';
import Card from '../ui/Card';
import Button from '../ui/Button';
import { adminApi } from '../../services/adminApi';
import { HealthStatus, ServerInfo } from '@power-grid/api-client';

export const SystemStatus: React.FC = () => {
  const [health, setHealth] = useState<HealthStatus | null>(null);
  const [serverInfo, setServerInfo] = useState<ServerInfo | null>(null);
  const [activeTab, setActiveTab] = useState<'overview' | 'logs' | 'config'>('overview');
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    fetchSystemData();
    const interval = setInterval(fetchSystemData, 30000); // Refresh every 30 seconds
    return () => clearInterval(interval);
  }, []);

  const fetchSystemData = async () => {
    try {
      setLoading(true);
      const [healthData, serverData] = await Promise.all([
        adminApi.getHealth(),
        adminApi.getServerInfo()
      ]);
      setHealth(healthData);
      setServerInfo(serverData);
    } catch (error) {
      console.error('Failed to fetch system data:', error);
    } finally {
      setLoading(false);
    }
  };

  const formatUptime = (seconds: number) => {
    const days = Math.floor(seconds / 86400);
    const hours = Math.floor((seconds % 86400) / 3600);
    const minutes = Math.floor((seconds % 3600) / 60);
    
    if (days > 0) {
      return `${days}d ${hours}h ${minutes}m`;
    } else if (hours > 0) {
      return `${hours}h ${minutes}m`;
    } else {
      return `${minutes}m`;
    }
  };

  const renderSystemOverview = () => (
    <>
      {/* Server Health */}
      <Card>
        <div className="p-6">
          <h3 className="text-lg font-semibold mb-4">Server Health</h3>
          
          {loading ? (
            <div className="text-gray-500">Loading health status...</div>
          ) : health ? (
            <div className="space-y-4">
              <div className="flex items-center justify-between">
                <span className="text-gray-600">Overall Status</span>
                <span className={`font-semibold ${
                  health.status === 'healthy' ? 'text-green-600' : 
                  health.status === 'degraded' ? 'text-yellow-600' : 'text-red-600'
                }`}>
                  {health.status.toUpperCase()}
                </span>
              </div>
              
              <div className="space-y-2">
                <div className="flex items-center justify-between">
                  <span className="text-gray-600">Database</span>
                  <span className={health.database ? 'text-green-600' : 'text-red-600'}>
                    {health.database ? '✓ Connected' : '✗ Disconnected'}
                  </span>
                </div>
                <div className="flex items-center justify-between">
                  <span className="text-gray-600">WebSocket Server</span>
                  <span className={health.websocket ? 'text-green-600' : 'text-red-600'}>
                    {health.websocket ? '✓ Running' : '✗ Not Running'}
                  </span>
                </div>
                <div className="flex items-center justify-between">
                  <span className="text-gray-600">Cache</span>
                  <span className={health.cache ? 'text-green-600' : 'text-red-600'}>
                    {health.cache ? '✓ Available' : '✗ Unavailable'}
                  </span>
                </div>
              </div>
              
              <div className="pt-2 border-t">
                <div className="text-sm text-gray-500">
                  Last Updated: {new Date(health.timestamp).toLocaleString()}
                </div>
              </div>
            </div>
          ) : (
            <div className="text-red-500">Failed to load health status</div>
          )}
        </div>
      </Card>

      {/* System Metrics */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
        <Card>
          <div className="p-6">
            <h4 className="text-sm font-medium text-gray-500">CPU Usage</h4>
            <p className="mt-2 text-2xl font-semibold">45%</p>
            <p className="text-sm text-gray-500">4 cores</p>
          </div>
        </Card>
        
        <Card>
          <div className="p-6">
            <h4 className="text-sm font-medium text-gray-500">Memory Usage</h4>
            <p className="mt-2 text-2xl font-semibold">2.1 GB</p>
            <p className="text-sm text-gray-500">of 8 GB (26%)</p>
          </div>
        </Card>
        
        <Card>
          <div className="p-6">
            <h4 className="text-sm font-medium text-gray-500">Disk Usage</h4>
            <p className="mt-2 text-2xl font-semibold">15 GB</p>
            <p className="text-sm text-gray-500">of 100 GB (15%)</p>
          </div>
        </Card>
        
        <Card>
          <div className="p-6">
            <h4 className="text-sm font-medium text-gray-500">Network I/O</h4>
            <p className="mt-2 text-2xl font-semibold">125 KB/s</p>
            <p className="text-sm text-gray-500">↓ 100 KB/s ↑ 25 KB/s</p>
          </div>
        </Card>
      </div>

      {/* Server Info */}
      <Card>
        <div className="p-6">
          <h3 className="text-lg font-semibold mb-4">Server Information</h3>
          
          {loading ? (
            <div className="text-gray-500">Loading server info...</div>
          ) : serverInfo ? (
            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
              <div>
                <div className="text-sm text-gray-500">Version</div>
                <div className="font-medium">{serverInfo.version}</div>
              </div>
              <div>
                <div className="text-sm text-gray-500">Uptime</div>
                <div className="font-medium">{formatUptime(serverInfo.uptime)}</div>
              </div>
              <div>
                <div className="text-sm text-gray-500">Start Time</div>
                <div className="font-medium">{new Date(serverInfo.start_time).toLocaleString()}</div>
              </div>
              <div>
                <div className="text-sm text-gray-500">Environment</div>
                <div className="font-medium">{serverInfo.environment}</div>
              </div>
            </div>
          ) : (
            <div className="text-gray-500">No server information available</div>
          )}
        </div>
      </Card>

      {/* WebSocket Connections */}
      <Card>
        <div className="p-6">
          <h3 className="text-lg font-semibold mb-4">WebSocket Connections</h3>
          <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
            <div>
              <div className="text-sm text-gray-500">Active Connections:</div>
              <div className="text-2xl font-semibold">42</div>
            </div>
            <div>
              <div className="text-sm text-gray-500">Peak Connections:</div>
              <div className="text-2xl font-semibold">156</div>
            </div>
            <div>
              <div className="text-sm text-gray-500">Messages/sec:</div>
              <div className="text-2xl font-semibold">89</div>
            </div>
          </div>
        </div>
      </Card>

      {/* System Actions */}
      <Card>
        <div className="p-6">
          <h3 className="text-lg font-semibold mb-4">System Actions</h3>
          <div className="space-y-2">
            <Button
              variant="outline"
              className="w-full justify-start"
              onClick={() => console.log('Restart server')}
            >
              Restart Server
            </Button>
            <Button
              variant="outline"
              className="w-full justify-start"
              onClick={() => console.log('Clear cache')}
            >
              Clear Cache
            </Button>
            <Button
              variant="outline"
              className="w-full justify-start"
              onClick={() => console.log('Backup data')}
            >
              Backup Data
            </Button>
            <Button
              variant="outline"
              className="w-full justify-start"
              onClick={() => setActiveTab('config')}
            >
              Configuration
            </Button>
          </div>
        </div>
      </Card>
    </>
  );

  const renderSystemLogs = () => (
    <Card>
      <div className="p-6">
        <div className="mb-4 flex justify-between items-center">
          <h3 className="text-lg font-semibold">System Logs</h3>
          <div className="flex gap-2">
            <select
              name="logLevel"
              className="px-3 py-2 border border-gray-300 rounded-md"
              defaultValue="all"
            >
              <option value="all">All Levels</option>
              <option value="debug">Debug</option>
              <option value="info">Info</option>
              <option value="warn">Warning</option>
              <option value="error">Error</option>
            </select>
            <input
              type="text"
              placeholder="Search logs..."
              className="px-3 py-2 border border-gray-300 rounded-md"
            />
          </div>
        </div>
        
        <div className="bg-gray-900 text-gray-300 p-4 rounded-lg h-96 overflow-y-auto font-mono text-sm">
          <div className="log-entry space-y-1">
            <div className="text-blue-400">[2025-01-20 12:34:56] INFO: Server started on port 4080</div>
            <div className="text-green-400">[2025-01-20 12:34:57] DEBUG: WebSocket server initialized</div>
            <div className="text-yellow-400">[2025-01-20 12:35:12] WARN: High memory usage detected (78%)</div>
            <div className="text-blue-400">[2025-01-20 12:35:45] INFO: New player connected: Player123</div>
            <div className="text-red-400">[2025-01-20 12:36:03] ERROR: Failed to save game state: Database timeout</div>
            <div className="text-blue-400">[2025-01-20 12:36:05] INFO: Retrying database operation...</div>
            <div className="text-green-400">[2025-01-20 12:36:06] DEBUG: Database operation successful</div>
          </div>
        </div>
      </div>
    </Card>
  );

  const renderConfiguration = () => (
    <Card>
      <div className="p-6">
        <h3 className="text-lg font-semibold mb-4">Server Configuration</h3>
        <div className="space-y-4">
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">
              Max Players per Game
            </label>
            <input
              type="number"
              defaultValue="6"
              className="w-full px-3 py-2 border border-gray-300 rounded-md"
            />
          </div>
          
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">
              Game Timeout (minutes)
            </label>
            <input
              type="number"
              defaultValue="120"
              className="w-full px-3 py-2 border border-gray-300 rounded-md"
            />
          </div>
          
          <div>
            <label className="flex items-center space-x-2">
              <input type="checkbox" defaultChecked className="rounded" />
              <span className="text-sm font-medium text-gray-700">Enable AI Players</span>
            </label>
          </div>
          
          <div>
            <label className="flex items-center space-x-2">
              <input type="checkbox" className="rounded" />
              <span className="text-sm font-medium text-gray-700">Debug Mode</span>
            </label>
          </div>
          
          <div className="pt-4">
            <Button>Save Configuration</Button>
          </div>
        </div>
      </div>
    </Card>
  );

  return (
    <div className="space-y-6">
      <div>
        <h2 className="text-2xl font-bold text-gray-900 mb-4">System Status</h2>
        <p className="text-gray-600">Monitor server health and system performance</p>
      </div>

      {/* Tab Navigation */}
      <div className="flex space-x-4 border-b">
        <button
          className={`pb-2 px-1 ${activeTab === 'overview' ? 'border-b-2 border-blue-500 text-blue-600' : 'text-gray-600'}`}
          onClick={() => setActiveTab('overview')}
        >
          Overview
        </button>
        <button
          className={`pb-2 px-1 ${activeTab === 'logs' ? 'border-b-2 border-blue-500 text-blue-600' : 'text-gray-600'}`}
          onClick={() => setActiveTab('logs')}
        >
          System Logs
        </button>
        <button
          className={`pb-2 px-1 ${activeTab === 'config' ? 'border-b-2 border-blue-500 text-blue-600' : 'text-gray-600'}`}
          onClick={() => setActiveTab('config')}
        >
          Configuration
        </button>
      </div>

      {/* Tab Content */}
      <div>
        {activeTab === 'overview' && renderSystemOverview()}
        {activeTab === 'logs' && renderSystemLogs()}
        {activeTab === 'config' && renderConfiguration()}
      </div>
    </div>
  );
};