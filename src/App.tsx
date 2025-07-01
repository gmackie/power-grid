import React, { useEffect } from 'react';
import { useGameStore, useDeviceStore } from './store/gameStore';
import MainMenu from './components/MainMenu';
import LobbyScreen from './components/screens/LobbyScreen';
import GameScreen from './components/GameScreen';
import ConnectionStatus from './components/ConnectionStatus';
import ErrorNotification from './components/ErrorNotification';
import './App.css';

function App() {
  const { currentScreen, connectionStatus, connect } = useGameStore();
  const { updateDeviceInfo } = useDeviceStore();

  useEffect(() => {
    // Initialize device info
    updateDeviceInfo();

    // Auto-connect to server on app start
    if (connectionStatus === 'disconnected') {
      connect().catch(console.error);
    }

    // Handle visibility change for mobile optimization
    const handleVisibilityChange = () => {
      if (document.hidden) {
        // App went to background - could pause some features
        console.log('App backgrounded');
      } else {
        // App came to foreground - resume
        console.log('App foregrounded');
        if (connectionStatus === 'disconnected') {
          connect().catch(console.error);
        }
      }
    };

    document.addEventListener('visibilitychange', handleVisibilityChange);

    return () => {
      document.removeEventListener('visibilitychange', handleVisibilityChange);
    };
  }, [connectionStatus, connect, updateDeviceInfo]);

  const renderCurrentScreen = () => {
    switch (currentScreen) {
      case 'menu':
        return <MainMenu />;
      case 'lobby':
        return <LobbyScreen />;
      case 'game':
        return <GameScreen />;
      default:
        return <MainMenu />;
    }
  };

  return (
    <div className="app">
      {/* Connection status indicator */}
      <ConnectionStatus />
      
      {/* Error notifications */}
      <ErrorNotification />
      
      {/* Main content */}
      <main className="min-h-screen">
        {renderCurrentScreen()}
      </main>
    </div>
  );
}

export default App;