import React, { useState } from 'react';
import Card from '../ui/Card';
import Button from '../ui/Button';
import Input from '../ui/Input';
import { CreateSimulatedGameRequest, SimulatedGame } from '../../types/admin';
import { simulatedGamesApi } from '../../services/simulatedGamesApi';
import { Brain, Zap, Shield, Shuffle } from 'lucide-react';

interface CreateSimulatedGameProps {
  onGameCreated: (game: SimulatedGame) => void;
  onCancel: () => void;
}

export const CreateSimulatedGame: React.FC<CreateSimulatedGameProps> = ({
  onGameCreated,
  onCancel
}) => {
  const [formData, setFormData] = useState<CreateSimulatedGameRequest>({
    name: '',
    aiPlayerCount: 4,
    aiDifficulty: 'medium',
    mapId: 'usa',
    gameSpeed: 'normal',
    aiConfigurations: []
  });
  const [useAdvancedSettings, setUseAdvancedSettings] = useState(false);
  const [creating, setCreating] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [launchProgress, setLaunchProgress] = useState<string[]>([]);

  const aiPersonalities = [
    { value: 'aggressive', label: 'Aggressive', icon: Zap },
    { value: 'conservative', label: 'Conservative', icon: Shield },
    { value: 'balanced', label: 'Balanced', icon: Brain },
    { value: 'random', label: 'Random', icon: Shuffle }
  ];

  const aiStrategies = [
    { value: 'power_plant_focused', label: 'Power Plant Focused' },
    { value: 'city_expansion', label: 'City Expansion' },
    { value: 'resource_hoarding', label: 'Resource Hoarding' },
    { value: 'balanced', label: 'Balanced Strategy' }
  ];

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setCreating(true);
    setError(null);
    setLaunchProgress([]);

    try {
      // Step 1: Create the game lobby
      setLaunchProgress(prev => [...prev, '🎮 Creating game lobby...']);
      
      // Create the lobby using the API
      const lobby = await simulatedGamesApi.createLobby(
        formData.name,
        formData.aiPlayerCount,
        formData.mapId
      );
      
      setLaunchProgress(prev => [...prev, `✅ Lobby created: ${lobby.id}`]);

      // Step 2: Launch AI clients
      setLaunchProgress(prev => [...prev, `🤖 Launching ${formData.aiPlayerCount} AI clients...`]);
      
      const aiClients = [];
      for (let i = 0; i < formData.aiPlayerCount; i++) {
        const config = formData.aiConfigurations?.[i] || {
          personality: 'balanced',
          strategy: 'balanced'
        };

        setLaunchProgress(prev => [...prev, `  → Starting AI Player ${i + 1}...`]);
        
        // Launch an AI client process
        const client = await simulatedGamesApi.launchAIClient({
          lobbyId: lobby.id,
          playerName: `AI_${config.personality}_${i + 1}`,
          difficulty: formData.aiDifficulty,
          personality: config.personality,
          strategy: config.strategy,
          gameSpeed: formData.gameSpeed
        });
        aiClients.push(client);
        
        setLaunchProgress(prev => [...prev, `  ✅ AI Player ${i + 1} connected`]);
      }

      // Step 3: Wait for all clients to be ready
      setLaunchProgress(prev => [...prev, '⏳ Waiting for all AI players to be ready...']);
      
      // Poll for ready status
      await new Promise(resolve => setTimeout(resolve, 2000));
      
      setLaunchProgress(prev => [...prev, '✅ All AI players ready']);

      // Step 4: Start the game
      setLaunchProgress(prev => [...prev, '🚀 Starting game...']);
      
      await simulatedGamesApi.startGame(lobby.id);
      
      setLaunchProgress(prev => [...prev, '✅ Game started successfully!']);

      // Create the simulated game object
      const simulatedGame: SimulatedGame = {
        id: lobby.id,
        name: formData.name,
        status: 'running',
        aiPlayerCount: formData.aiPlayerCount,
        aiDifficulty: formData.aiDifficulty,
        mapId: formData.mapId,
        currentRound: 1,
        currentPhase: 'auction',
        gameSpeed: formData.gameSpeed,
        startedAt: new Date().toISOString(),
        duration: 0,
        aiPlayers: aiClients.map((client, i) => ({
          id: client.id,
          name: client.name,
          personality: formData.aiConfigurations?.[i]?.personality || 'balanced',
          strategy: formData.aiConfigurations?.[i]?.strategy || 'balanced',
          currentMoney: 50,
          citiesOwned: 0,
          powerPlants: [],
          score: 0
        }))
      };

      setTimeout(() => {
        onGameCreated(simulatedGame);
      }, 1000);

    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to create simulated game');
      setLaunchProgress(prev => [...prev, `❌ Error: ${err instanceof Error ? err.message : 'Unknown error'}`]);
    } finally {
      setCreating(false);
    }
  };

  const updateAIConfig = (index: number, field: 'personality' | 'strategy', value: string) => {
    const configs = [...(formData.aiConfigurations || [])];
    if (!configs[index]) {
      configs[index] = { personality: 'balanced', strategy: 'balanced' };
    }
    configs[index][field] = value;
    setFormData({ ...formData, aiConfigurations: configs });
  };

  return (
    <form onSubmit={handleSubmit} className="space-y-6">
      {/* Basic Settings */}
      <Card>
        <div className="p-6 space-y-4">
          <h3 className="text-lg font-semibold">Game Configuration</h3>
          
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div>
              <Input
                label="Game Name"
                placeholder="AI Test Game"
                value={formData.name}
                onChange={(e) => setFormData({ ...formData, name: e.target.value })}
                required
              />
            </div>
            
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">
                Number of AI Players
              </label>
              <select
                name="aiPlayerCount"
                value={formData.aiPlayerCount}
                onChange={(e) => setFormData({ ...formData, aiPlayerCount: parseInt(e.target.value) })}
                className="w-full px-3 py-2 border border-gray-300 rounded-md"
              >
                {[2, 3, 4, 5, 6].map(num => (
                  <option key={num} value={num}>{num} Players</option>
                ))}
              </select>
            </div>
            
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">
                AI Difficulty
              </label>
              <select
                name="aiDifficulty"
                value={formData.aiDifficulty}
                onChange={(e) => setFormData({ ...formData, aiDifficulty: e.target.value as any })}
                className="w-full px-3 py-2 border border-gray-300 rounded-md"
              >
                <option value="easy">Easy</option>
                <option value="medium">Medium</option>
                <option value="hard">Hard</option>
                <option value="adaptive">Adaptive</option>
              </select>
            </div>
            
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">
                Map
              </label>
              <select
                name="mapId"
                value={formData.mapId}
                onChange={(e) => setFormData({ ...formData, mapId: e.target.value })}
                className="w-full px-3 py-2 border border-gray-300 rounded-md"
              >
                <option value="usa">USA</option>
                <option value="germany">Germany</option>
                <option value="france">France</option>
                <option value="italy">Italy</option>
                <option value="japan">Japan</option>
              </select>
            </div>
            
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">
                Game Speed
              </label>
              <select
                name="gameSpeed"
                value={formData.gameSpeed}
                onChange={(e) => setFormData({ ...formData, gameSpeed: e.target.value as any })}
                className="w-full px-3 py-2 border border-gray-300 rounded-md"
              >
                <option value="slow">Slow (5s per decision)</option>
                <option value="normal">Normal (2s per decision)</option>
                <option value="fast">Fast (500ms per decision)</option>
                <option value="instant">Instant (No delay)</option>
              </select>
            </div>
          </div>
        </div>
      </Card>

      {/* Advanced AI Settings */}
      <Card>
        <div className="p-6">
          <div className="flex items-center justify-between mb-4">
            <h3 className="text-lg font-semibold">AI Player Configuration</h3>
            <Button
              type="button"
              variant="outline"
              size="sm"
              onClick={() => setUseAdvancedSettings(!useAdvancedSettings)}
            >
              {useAdvancedSettings ? 'Hide' : 'Show'} Advanced Settings
            </Button>
          </div>

          {useAdvancedSettings ? (
            <div className="space-y-4">
              {Array.from({ length: formData.aiPlayerCount }, (_, i) => (
                <div key={i} className="p-4 bg-gray-50 rounded-lg">
                  <h4 className="font-medium mb-3">AI Player {i + 1}</h4>
                  <div className="grid grid-cols-1 md:grid-cols-2 gap-3">
                    <div>
                      <label className="block text-sm font-medium text-gray-700 mb-1">
                        Personality
                      </label>
                      <select
                        name={`ai${i}_personality`}
                        value={formData.aiConfigurations?.[i]?.personality || 'balanced'}
                        onChange={(e) => updateAIConfig(i, 'personality', e.target.value)}
                        className="w-full px-3 py-2 border border-gray-300 rounded-md"
                      >
                        {aiPersonalities.map(p => (
                          <option key={p.value} value={p.value}>{p.label}</option>
                        ))}
                      </select>
                    </div>
                    <div>
                      <label className="block text-sm font-medium text-gray-700 mb-1">
                        Strategy
                      </label>
                      <select
                        name={`ai${i}_strategy`}
                        value={formData.aiConfigurations?.[i]?.strategy || 'balanced'}
                        onChange={(e) => updateAIConfig(i, 'strategy', e.target.value)}
                        className="w-full px-3 py-2 border border-gray-300 rounded-md"
                      >
                        {aiStrategies.map(s => (
                          <option key={s.value} value={s.value}>{s.label}</option>
                        ))}
                      </select>
                    </div>
                  </div>
                </div>
              ))}
            </div>
          ) : (
            <p className="text-sm text-gray-600">
              All AI players will use {formData.aiDifficulty} difficulty with balanced personality and strategy.
            </p>
          )}
        </div>
      </Card>

      {/* Launch Progress */}
      {launchProgress.length > 0 && (
        <Card>
          <div className="p-6">
            <h3 className="text-lg font-semibold mb-4">Launch Progress</h3>
            <div className="bg-gray-900 text-gray-300 p-4 rounded-lg max-h-64 overflow-y-auto font-mono text-sm">
              {launchProgress.map((message, i) => (
                <div key={i} className="mb-1">{message}</div>
              ))}
            </div>
          </div>
        </Card>
      )}

      {/* Error Display */}
      {error && (
        <div className="bg-red-50 border border-red-200 text-red-700 px-4 py-3 rounded">
          {error}
        </div>
      )}

      {/* Action Buttons */}
      <div className="flex justify-end gap-3">
        <Button
          type="button"
          variant="outline"
          onClick={onCancel}
          disabled={creating}
        >
          Cancel
        </Button>
        <Button
          type="submit"
          disabled={creating || !formData.name}
        >
          {creating ? 'Creating Game...' : 'Create Game'}
        </Button>
      </div>
    </form>
  );
};