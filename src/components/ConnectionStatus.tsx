import React from 'react';
import { useGameStore } from '../store/gameStore';
import { Wifi, WifiOff, Loader2, AlertTriangle } from 'lucide-react';

const ConnectionStatus: React.FC = () => {
  const { connectionStatus } = useGameStore();

  if (connectionStatus === 'connected') {
    return null; // Don't show when connected
  }

  const getStatusIcon = () => {
    switch (connectionStatus) {
      case 'connecting':
        return <Loader2 className="w-4 h-4 animate-spin" />;
      case 'error':
        return <AlertTriangle className="w-4 h-4" />;
      case 'disconnected':
      default:
        return <WifiOff className="w-4 h-4" />;
    }
  };

  const getStatusColor = () => {
    switch (connectionStatus) {
      case 'connecting':
        return 'bg-yellow-600 border-yellow-500 text-yellow-100';
      case 'error':
        return 'bg-red-600 border-red-500 text-red-100';
      case 'disconnected':
      default:
        return 'bg-gray-600 border-gray-500 text-gray-100';
    }
  };

  const getStatusText = () => {
    switch (connectionStatus) {
      case 'connecting':
        return 'Connecting to server...';
      case 'error':
        return 'Connection error';
      case 'disconnected':
      default:
        return 'Disconnected from server';
    }
  };

  return (
    <div className="fixed top-4 left-1/2 transform -translate-x-1/2 z-50">
      <div 
        data-testid="connection-status"
        className={`
        flex items-center gap-2 px-4 py-2 rounded-lg border
        ${getStatusColor()}
        shadow-lg backdrop-blur-sm
        animate-slide-up
      `}>
        {getStatusIcon()}
        <span className="text-sm font-medium">
          {getStatusText()}
        </span>
      </div>
    </div>
  );
};

export default ConnectionStatus;