import { useEffect } from 'react';
import { useGameStore, useDeviceStore } from './store/gameStore';
import MainMenu from './components/MainMenu';
import LobbyScreen from './components/LobbyScreen';
import LobbyBrowser from './components/LobbyBrowser';
import CreateLobby from './components/CreateLobby';
import GameScreen from './components/GameScreen';
import ConnectionStatus from './components/ConnectionStatus';
import ErrorNotification from './components/ErrorNotification';
import { AdminDashboard } from './components/admin/AdminDashboard';
import './App.css';

function App() {
  const { currentScreen, connectionStatus, connect, currentLobby } = useGameStore();
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

  // Handle URL-based navigation
  useEffect(() => {
    const handlePopState = () => {
      const url = new URL(window.location.href);
      const path = url.pathname;
      const params = new URLSearchParams(url.search);
      
      if (path === '/lobby' && params.get('id')) {
        // If we have a lobby ID in URL, try to rejoin
        const lobbyId = params.get('id');
        if (lobbyId && connectionStatus === 'connected') {
          // This would typically trigger a rejoin attempt
          console.log('Attempting to rejoin lobby:', lobbyId);
        }
      }
    };

    window.addEventListener('popstate', handlePopState);
    handlePopState(); // Handle initial load

    return () => {
      window.removeEventListener('popstate', handlePopState);
    };
  }, [connectionStatus]);

  // Update URL when screen changes
  useEffect(() => {
    const url = new URL(window.location.href);
    
    switch (currentScreen) {
      case 'lobby-browser':
        url.pathname = '/lobbies';
        url.search = '';
        break;
      case 'lobby':
        url.pathname = '/lobby';
        if (currentLobby) {
          url.searchParams.set('id', currentLobby.id);
        }
        break;
      case 'game':
        url.pathname = '/game';
        break;
      case 'admin':
        url.pathname = '/admin';
        break;
      default:
        url.pathname = '/';
        url.search = '';
    }
    
    window.history.replaceState({}, '', url.toString());
  }, [currentScreen, currentLobby]);

  const renderCurrentScreen = () => {
    switch (currentScreen) {
      case 'menu':
        return <MainMenu />;
      case 'lobby-browser':
        return <LobbyBrowser />;
      case 'lobby':
        return currentLobby ? <LobbyScreen /> : <CreateLobby />;
      case 'game':
        return <GameScreen />;
      case 'admin':
        return <AdminDashboard />;
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