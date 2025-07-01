import React, { useState, useMemo } from 'react';
import { useGameStore, useDeviceStore } from '../../store/gameStore';
import { BuildingPhaseState, City } from '../../types/game';
import { Building2, MapPin, DollarSign, Check, X } from 'lucide-react';
import Button from '../ui/Button';
import Card from '../ui/Card';
import GameBoard from '../GameBoard';

interface BuildingPhaseProps {
  buildingPhaseState: BuildingPhaseState;
  cities: City[];
}

const BuildingPhase: React.FC<BuildingPhaseProps> = ({ buildingPhaseState, cities }) => {
  const { 
    getCurrentPlayer, 
    isCurrentPlayerTurn,
    buildCity,
    pass,
    playerId,
    gameState
  } = useGameStore();
  
  const { isMobile } = useDeviceStore();
  
  const [selectedCity, setSelectedCity] = useState<City | null>(null);
  const [hoveredCity, setHoveredCity] = useState<City | null>(null);
  
  const currentPlayer = getCurrentPlayer();
  const isMyTurn = isCurrentPlayerTurn();
  const myBuiltCities = buildingPhaseState.citiesBuilt[playerId || ''] || [];
  
  // Calculate building cost for a city
  const calculateBuildingCost = (city: City): number => {
    if (!currentPlayer) return 0;
    
    const housesInCity = city.houses.length;
    const houseCost = 10 + (housesInCity * 5); // Base 10, +5 per existing house
    
    // Connection cost (find cheapest path to player's network)
    let connectionCost = 0;
    if (currentPlayer.cities.length > 0) {
      connectionCost = findCheapestConnection(city, currentPlayer.cities);
    }
    
    return houseCost + connectionCost;
  };
  
  // Find cheapest connection to player's network (simplified)
  const findCheapestConnection = (targetCity: City, playerCities: string[]): number => {
    // In a real implementation, this would use Dijkstra's algorithm
    // For now, return a simple calculation
    let minCost = Infinity;
    
    cities.forEach(city => {
      if (playerCities.includes(city.id)) {
        const connection = city.connections.find(c => c.to === targetCity.id);
        if (connection && connection.cost < minCost) {
          minCost = connection.cost;
        }
      }
    });
    
    return minCost === Infinity ? 20 : minCost; // Default connection cost
  };
  
  // Check if player can build in city
  const canBuildInCity = (city: City): { canBuild: boolean; reason?: string } => {
    if (!currentPlayer) return { canBuild: false, reason: 'No current player' };
    
    // Check if already built this turn
    if (myBuiltCities.includes(city.id)) {
      return { canBuild: false, reason: 'Already built here this turn' };
    }
    
    // Check if player already has a house in this city
    if (city.houses.some(h => h.playerColor === currentPlayer.color)) {
      return { canBuild: false, reason: 'You already own this city' };
    }
    
    // Check if city is full (max 3 houses)
    if (city.houses.length >= 3) {
      return { canBuild: false, reason: 'City is full' };
    }
    
    // Check if player has enough money
    const cost = calculateBuildingCost(city);
    if (cost > currentPlayer.money) {
      return { canBuild: false, reason: `Need $${cost} (you have $${currentPlayer.money})` };
    }
    
    // Check step restrictions (simplified - in real game, depends on current step)
    const currentStep = gameState?.currentRound || 1;
    if (currentStep === 1 && city.houses.length > 0) {
      return { canBuild: false, reason: 'Step 1: Can only build in empty cities' };
    }
    
    return { canBuild: true };
  };
  
  const handleCitySelect = (city: City) => {
    const { canBuild } = canBuildInCity(city);
    if (canBuild && isMyTurn) {
      setSelectedCity(city);
    }
  };
  
  const handleBuildCity = () => {
    if (selectedCity && isMyTurn) {
      buildCity(selectedCity.id);
      setSelectedCity(null);
    }
  };
  
  const handlePass = () => {
    pass();
    setSelectedCity(null);
  };
  
  // Group cities by region for display
  const citiesByRegion = useMemo(() => {
    const grouped: Record<string, City[]> = {};
    cities.forEach(city => {
      if (!grouped[city.region]) {
        grouped[city.region] = [];
      }
      grouped[city.region].push(city);
    });
    return grouped;
  }, [cities]);
  
  return (
    <div className="space-y-6">
      {/* Phase Header */}
      <Card className="p-4 bg-purple-900/20 border-purple-600">
        <div className="flex items-center justify-between">
          <div className="flex items-center gap-3">
            <Building2 className="w-6 h-6 text-purple-400" />
            <div>
              <h2 className="text-xl font-bold text-white">Building Phase</h2>
              <p className="text-sm text-slate-400">
                Expand your network by building in cities
              </p>
            </div>
          </div>
          
          <div className="text-right">
            <p className="text-sm text-slate-400">Cities Built</p>
            <p className="text-lg font-semibold text-white">
              {myBuiltCities.length}
            </p>
          </div>
        </div>
      </Card>
      
      {/* Player Status */}
      {currentPlayer && (
        <Card className="p-4">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-sm text-slate-400">Your Money</p>
              <p className="text-2xl font-bold text-yellow-400">${currentPlayer.money}</p>
            </div>
            
            <div className="text-center">
              <p className="text-sm text-slate-400">Your Cities</p>
              <p className="text-2xl font-bold text-blue-400">{currentPlayer.cities.length}</p>
            </div>
            
            {selectedCity && (
              <div className="text-right">
                <p className="text-sm text-slate-400">Build Cost</p>
                <p className="text-2xl font-bold text-green-400">
                  ${calculateBuildingCost(selectedCity)}
                </p>
              </div>
            )}
          </div>
        </Card>
      )}
      
      {/* Game Board */}
      <Card className="p-6">
        <h3 className="text-lg font-semibold text-white mb-4">
          Game Board
        </h3>
        
        {/* Full game board would go here - simplified for now */}
        <GameBoard
          cities={cities}
          selectedCity={selectedCity}
          hoveredCity={hoveredCity}
          onCityClick={handleCitySelect}
          onCityHover={setHoveredCity}
          currentPlayer={currentPlayer}
        />
      </Card>
      
      {/* City List (Mobile-friendly alternative view) */}
      {isMobile && (
        <Card className="p-6">
          <h3 className="text-lg font-semibold text-white mb-4">
            Available Cities
          </h3>
          
          <div className="space-y-4">
            {Object.entries(citiesByRegion).map(([region, regionCities]) => (
              <div key={region}>
                <h4 className="text-sm font-medium text-slate-400 mb-2">{region}</h4>
                <div className="space-y-2">
                  {regionCities.map(city => {
                    const { canBuild, reason } = canBuildInCity(city);
                    const isSelected = selectedCity?.id === city.id;
                    
                    return (
                      <button
                        key={city.id}
                        className={`
                          w-full p-3 rounded-lg text-left transition-all
                          ${isSelected 
                            ? 'bg-blue-900/50 border-2 border-blue-500' 
                            : canBuild && isMyTurn
                              ? 'bg-game-surface hover:bg-slate-700 border-2 border-transparent'
                              : 'bg-slate-800 opacity-50 cursor-not-allowed border-2 border-transparent'
                          }
                        `}
                        onClick={() => canBuild && isMyTurn && handleCitySelect(city)}
                        disabled={!canBuild || !isMyTurn}
                      >
                        <div className="flex items-center justify-between">
                          <div className="flex items-center gap-3">
                            <MapPin className="w-5 h-5 text-slate-400" />
                            <div>
                              <p className="text-white font-medium">{city.name}</p>
                              <p className="text-xs text-slate-400">
                                {city.houses.length}/3 houses • Cost: ${calculateBuildingCost(city)}
                              </p>
                            </div>
                          </div>
                          
                          <div className="flex items-center gap-1">
                            {city.houses.map((house, idx) => (
                              <div
                                key={idx}
                                className="w-4 h-4 rounded-full border border-white"
                                style={{ backgroundColor: house.playerColor }}
                              />
                            ))}
                          </div>
                        </div>
                        
                        {!canBuild && reason && (
                          <p className="text-xs text-red-400 mt-1">{reason}</p>
                        )}
                      </button>
                    );
                  })}
                </div>
              </div>
            ))}
          </div>
        </Card>
      )}
      
      {/* Action Buttons */}
      {isMyTurn && (
        <Card className="p-6">
          <div className="flex gap-3">
            <Button
              className="flex-1 touch-target"
              onClick={handleBuildCity}
              disabled={!selectedCity}
            >
              <Building2 className="w-5 h-5 mr-2" />
              Build in {selectedCity?.name || 'Selected City'}
            </Button>
            
            <Button
              variant="outline"
              className="touch-target"
              onClick={handlePass}
            >
              Done Building
            </Button>
          </div>
          
          {selectedCity && (
            <div className="mt-4 p-3 bg-game-surface rounded-lg">
              <div className="flex items-center justify-between text-sm">
                <span className="text-slate-400">House Cost:</span>
                <span className="text-white">${10 + (selectedCity.houses.length * 5)}</span>
              </div>
              <div className="flex items-center justify-between text-sm mt-1">
                <span className="text-slate-400">Connection Cost:</span>
                <span className="text-white">
                  ${calculateBuildingCost(selectedCity) - (10 + (selectedCity.houses.length * 5))}
                </span>
              </div>
              <div className="border-t border-slate-600 mt-2 pt-2 flex items-center justify-between">
                <span className="text-slate-400 font-medium">Total:</span>
                <span className="text-green-400 font-bold">${calculateBuildingCost(selectedCity)}</span>
              </div>
            </div>
          )}
        </Card>
      )}
      
      {!isMyTurn && (
        <Card className="p-4">
          <div className="text-center text-slate-400">
            <p>Waiting for other players...</p>
            {buildingPhaseState.currentBuilder && (
              <p className="mt-2">
                Current builder: {buildingPhaseState.currentBuilder}
              </p>
            )}
          </div>
        </Card>
      )}
      
      {/* Building History */}
      {Object.keys(buildingPhaseState.citiesBuilt).length > 0 && (
        <Card className="p-6">
          <h3 className="text-lg font-semibold text-white mb-4">
            Cities Built This Turn
          </h3>
          
          <div className="space-y-2">
            {Object.entries(buildingPhaseState.citiesBuilt).map(([builderId, cityIds]) => {
              if (cityIds.length === 0) return null;
              
              return (
                <div key={builderId} className="p-3 bg-game-surface rounded-lg">
                  <div className="flex items-center justify-between">
                    <span className="text-white">
                      {builderId === playerId ? 'You' : `Player ${builderId}`}
                    </span>
                    <div className="flex items-center gap-2">
                      <span className="text-slate-400">{cityIds.length} cities</span>
                      <Check className="w-4 h-4 text-green-400" />
                    </div>
                  </div>
                  <div className="mt-1 text-xs text-slate-400">
                    {cityIds.map(id => cities.find(c => c.id === id)?.name).join(', ')}
                  </div>
                </div>
              );
            })}
          </div>
        </Card>
      )}
    </div>
  );
};

export default BuildingPhase;