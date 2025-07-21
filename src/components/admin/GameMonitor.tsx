import React, { useState, useEffect } from 'react';
import Card from '../ui/Card';
import Button from '../ui/Button';
import { SimulatedGame, AIPlayer, AIDecision } from '../../types/admin';
import { Play, Pause, Square, SkipForward, Eye, Brain, TrendingUp } from 'lucide-react';

interface GameMonitorProps {
  game: SimulatedGame;
  onBack: () => void;
}

export const GameMonitor: React.FC<GameMonitorProps> = ({ game, onBack }) => {
  const [gameState, setGameState] = useState<SimulatedGame>(game);
  const [decisions, setDecisions] = useState<AIDecision[]>([]);
  const [selectedPlayer, setSelectedPlayer] = useState<string | null>(null);
  const [showDecisions, setShowDecisions] = useState(true);
  const [autoScroll, setAutoScroll] = useState(true);
  const [gameSpeed, setGameSpeed] = useState(game.gameSpeed);
  const decisionsEndRef = React.useRef<HTMLDivElement>(null);

  useEffect(() => {
    // Connect to WebSocket for real-time updates
    const ws = new WebSocket(`ws://localhost:5080/ws/admin/game/${game.id}`);
    
    ws.onmessage = (event) => {
      const message = JSON.parse(event.data);
      
      switch (message.type) {
        case 'game_update':
          setGameState(message.data);
          break;
          
        case 'ai_decision':
          const decision: AIDecision = message.data;
          setDecisions(prev => [...prev.slice(-99), decision]); // Keep last 100 decisions
          break;
          
        case 'game_completed':
          setGameState(prev => ({ ...prev, status: 'completed' }));
          break;
      }
    };

    ws.onerror = (error) => {
      console.error('WebSocket error:', error);
    };

    return () => {
      ws.close();
    };
  }, [game.id]);

  useEffect(() => {
    // Auto-scroll to bottom when new decisions arrive
    if (autoScroll && decisionsEndRef.current) {
      decisionsEndRef.current.scrollIntoView({ behavior: 'smooth' });
    }
  }, [decisions, autoScroll]);

  const handlePauseResume = async () => {
    try {
      const action = gameState.status === 'running' ? 'pause' : 'resume';
      const response = await fetch(`/api/admin/simulated/control/${game.id}`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ action })
      });
      
      if (response.ok) {
        setGameState(prev => ({
          ...prev,
          status: action === 'pause' ? 'paused' : 'running'
        }));
      }
    } catch (error) {
      console.error('Failed to control game:', error);
    }
  };

  const handleStop = async () => {
    if (!confirm('Are you sure you want to stop this game?')) return;
    
    try {
      const response = await fetch(`/api/admin/simulated/control/${game.id}`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ action: 'stop' })
      });
      
      if (response.ok) {
        setGameState(prev => ({ ...prev, status: 'stopped' }));
      }
    } catch (error) {
      console.error('Failed to stop game:', error);
    }
  };

  const handleSpeedChange = async (newSpeed: string) => {
    try {
      const response = await fetch(`/api/admin/simulated/control/${game.id}`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ action: 'speed', speed: newSpeed })
      });
      
      if (response.ok) {
        setGameSpeed(newSpeed as any);
      }
    } catch (error) {
      console.error('Failed to change game speed:', error);
    }
  };

  const getPhaseColor = (phase: string) => {
    const colors = {
      auction: 'bg-purple-100 text-purple-800',
      resource: 'bg-green-100 text-green-800',
      building: 'bg-blue-100 text-blue-800',
      bureaucracy: 'bg-orange-100 text-orange-800'
    };
    return colors[phase as keyof typeof colors] || 'bg-gray-100 text-gray-800';
  };

  const filteredDecisions = selectedPlayer
    ? decisions.filter(d => d.playerId === selectedPlayer)
    : decisions;

  return (
    <div className="space-y-6">
      {/* Game Header */}
      <Card>
        <div className="p-6">
          <div className="flex justify-between items-start mb-4">
            <div>
              <h2 className="text-2xl font-bold mb-2">{gameState.name}</h2>
              <div className="flex items-center gap-4 text-sm text-gray-600">
                <span>Game ID: {gameState.id}</span>
                <span className={`px-2 py-1 rounded-full text-xs font-semibold ${
                  gameState.status === 'running' ? 'bg-green-100 text-green-800' :
                  gameState.status === 'paused' ? 'bg-yellow-100 text-yellow-800' :
                  gameState.status === 'completed' ? 'bg-blue-100 text-blue-800' :
                  'bg-gray-100 text-gray-800'
                }`}>
                  Status: {gameState.status}
                </span>
              </div>
            </div>
            
            <div className="flex items-center gap-2">
              {gameState.status === 'running' && (
                <Button
                  size="sm"
                  variant="outline"
                  onClick={handlePauseResume}
                >
                  <Pause className="w-4 h-4 mr-1" />
                  Pause
                </Button>
              )}
              {gameState.status === 'paused' && (
                <Button
                  size="sm"
                  variant="outline"
                  onClick={handlePauseResume}
                >
                  <Play className="w-4 h-4 mr-1" />
                  Resume
                </Button>
              )}
              {(gameState.status === 'running' || gameState.status === 'paused') && (
                <Button
                  size="sm"
                  variant="outline"
                  onClick={handleStop}
                  className="text-red-600 hover:text-red-700"
                >
                  <Square className="w-4 h-4 mr-1" />
                  Stop Game
                </Button>
              )}
            </div>
          </div>

          {/* Game Info */}
          <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
            <div>
              <div className="text-sm text-gray-500">Current Round</div>
              <div className="text-xl font-semibold">{gameState.currentRound}</div>
            </div>
            <div>
              <div className="text-sm text-gray-500">Current Phase</div>
              <div className={`inline-block px-2 py-1 rounded text-sm font-semibold ${getPhaseColor(gameState.currentPhase)}`}>
                {gameState.currentPhase}
              </div>
            </div>
            <div>
              <div className="text-sm text-gray-500">Duration</div>
              <div className="text-xl font-semibold">
                {Math.floor(gameState.duration / 60)}:{(gameState.duration % 60).toString().padStart(2, '0')}
              </div>
            </div>
            <div>
              <div className="text-sm text-gray-500">Game Speed</div>
              <select
                value={gameSpeed}
                onChange={(e) => handleSpeedChange(e.target.value)}
                className="mt-1 px-2 py-1 border border-gray-300 rounded text-sm"
                disabled={gameState.status !== 'running'}
              >
                <option value="slow">Slow</option>
                <option value="normal">Normal</option>
                <option value="fast">Fast</option>
                <option value="instant">Instant</option>
              </select>
            </div>
          </div>
        </div>
      </Card>

      {/* AI Players */}
      <Card>
        <div className="p-6">
          <h3 className="text-lg font-semibold mb-4">AI Players</h3>
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
            {gameState.aiPlayers.map((player) => (
              <div
                key={player.id}
                className={`p-4 border rounded-lg cursor-pointer transition-all ${
                  selectedPlayer === player.id
                    ? 'border-blue-500 bg-blue-50'
                    : 'border-gray-200 hover:border-gray-300'
                }`}
                onClick={() => setSelectedPlayer(selectedPlayer === player.id ? null : player.id)}
              >
                <div className="flex justify-between items-start mb-2">
                  <div>
                    <h4 className="font-medium">{player.name}</h4>
                    <div className="text-sm text-gray-600">
                      {player.personality} • {player.strategy}
                    </div>
                  </div>
                  <Eye className={`w-4 h-4 ${selectedPlayer === player.id ? 'text-blue-500' : 'text-gray-400'}`} />
                </div>
                
                <div className="grid grid-cols-2 gap-2 text-sm">
                  <div>
                    <span className="text-gray-500">Money:</span>
                    <span className="ml-1 font-medium">${player.currentMoney}</span>
                  </div>
                  <div>
                    <span className="text-gray-500">Cities:</span>
                    <span className="ml-1 font-medium">{player.citiesOwned}</span>
                  </div>
                  <div>
                    <span className="text-gray-500">Plants:</span>
                    <span className="ml-1 font-medium">{player.powerPlants.length}</span>
                  </div>
                  <div>
                    <span className="text-gray-500">Score:</span>
                    <span className="ml-1 font-medium">{player.score}</span>
                  </div>
                </div>
              </div>
            ))}
          </div>
        </div>
      </Card>

      {/* AI Decisions Log */}
      {showDecisions && (
        <Card>
          <div className="p-6">
            <div className="flex justify-between items-center mb-4">
              <h3 className="text-lg font-semibold">
                AI Decision Log
                {selectedPlayer && ` - ${gameState.aiPlayers.find(p => p.id === selectedPlayer)?.name}`}
              </h3>
              <div className="flex items-center gap-2">
                <label className="flex items-center gap-2 text-sm">
                  <input
                    type="checkbox"
                    checked={autoScroll}
                    onChange={(e) => setAutoScroll(e.target.checked)}
                    className="rounded"
                  />
                  Auto-scroll
                </label>
                <Button
                  size="sm"
                  variant="outline"
                  onClick={() => setShowDecisions(false)}
                >
                  Hide
                </Button>
              </div>
            </div>
            
            <div className="bg-gray-900 text-gray-300 p-4 rounded-lg h-96 overflow-y-auto font-mono text-xs">
              {filteredDecisions.length === 0 ? (
                <div className="text-center text-gray-500">
                  Waiting for AI decisions...
                </div>
              ) : (
                filteredDecisions.map((decision, i) => (
                  <div key={decision.id} className="mb-3 pb-3 border-b border-gray-800 last:border-0">
                    <div className="flex items-start gap-2">
                      <span className="text-gray-500">[{new Date(decision.timestamp).toLocaleTimeString()}]</span>
                      <Brain className="w-3 h-3 text-blue-400 mt-0.5" />
                      <div className="flex-1">
                        <div className="text-blue-400 font-semibold">
                          {decision.playerName} ({decision.phase})
                        </div>
                        <div className="text-green-400 mt-1">
                          Decision: {decision.decision}
                        </div>
                        <div className="text-gray-400 mt-1">
                          Reasoning: {decision.reasoning}
                        </div>
                        {decision.factors && Object.keys(decision.factors).length > 0 && (
                          <div className="text-gray-500 mt-1 text-xs">
                            Factors: {JSON.stringify(decision.factors)}
                          </div>
                        )}
                        {decision.outcome && (
                          <div className="text-yellow-400 mt-1">
                            Outcome: {decision.outcome}
                          </div>
                        )}
                      </div>
                    </div>
                  </div>
                ))
              )}
              <div ref={decisionsEndRef} />
            </div>
          </div>
        </Card>
      )}

      {/* Action Buttons */}
      <div className="flex justify-between">
        <Button variant="outline" onClick={onBack}>
          Back to Games List
        </Button>
        <div className="flex gap-2">
          <Button variant="outline">
            <TrendingUp className="w-4 h-4 mr-2" />
            View Analytics
          </Button>
          <Button variant="outline">
            Export Game Data
          </Button>
        </div>
      </div>
    </div>
  );
};