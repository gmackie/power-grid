import React, { useState, useMemo } from 'react';
import { useGameStore } from '../../store/gameStore';
import { BureaucracyState, PowerPlant, ResourceType } from '../../types/game';
import { Zap, DollarSign, Fuel, TrendingUp, Check, X } from 'lucide-react';
import Button from '../ui/Button';
import Card from '../ui/Card';

interface BureaucracyPhaseProps {
  bureaucracyState: BureaucracyState;
}

const BureaucracyPhase: React.FC<BureaucracyPhaseProps> = ({ bureaucracyState }) => {
  const { 
    getCurrentPlayer, 
    isCurrentPlayerTurn,
    powerCities,
    playerId
  } = useGameStore();
  
  const [plantsToPower, setPlantsToPower] = useState<Set<number>>(new Set());
  const [resourcesUsed, setResourcesUsed] = useState<Record<ResourceType, number>>({
    coal: 0,
    oil: 0,
    garbage: 0,
    uranium: 0
  });
  
  const currentPlayer = getCurrentPlayer();
  const isMyTurn = isCurrentPlayerTurn();
  const hasPowered = bureaucracyState.citiesPowered[playerId || ''] !== undefined;
  
  // Calculate maximum cities that can be powered
  const calculateMaxPower = useMemo(() => {
    if (!currentPlayer) return { maxCities: 0, byPlant: [] };
    
    const plantDetails = currentPlayer.powerPlants.map(plant => {
      const hasResources = checkPlantResources(plant);
      return {
        plant,
        canPower: hasResources,
        citiesPowered: hasResources ? plant.citiesPowered : 0
      };
    });
    
    const maxCities = Math.min(
      currentPlayer.cities.length,
      plantDetails.reduce((sum, p) => sum + p.citiesPowered, 0)
    );
    
    return { maxCities, byPlant: plantDetails };
  }, [currentPlayer]);
  
  // Check if plant has required resources
  function checkPlantResources(plant: PowerPlant): boolean {
    if (!currentPlayer) return false;
    
    if (plant.resourceType === 'eco') return true; // Eco plants don't need resources
    
    const available = { ...currentPlayer.resources };
    
    // Subtract already allocated resources
    Object.entries(resourcesUsed).forEach(([type, amount]) => {
      available[type as ResourceType] -= amount;
    });
    
    if (plant.resourceType === 'hybrid') {
      // Hybrid plants can use coal OR oil
      return (available.coal >= plant.resourceCount || available.oil >= plant.resourceCount);
    }
    
    return available[plant.resourceType] >= plant.resourceCount;
  }
  
  // Toggle plant power status
  const togglePlant = (plant: PowerPlant) => {
    const newPlantsToPower = new Set(plantsToPower);
    const newResourcesUsed = { ...resourcesUsed };
    
    if (plantsToPower.has(plant.id)) {
      // Unpowering plant
      newPlantsToPower.delete(plant.id);
      
      // Return resources
      if (plant.resourceType !== 'eco') {
        if (plant.resourceType === 'hybrid') {
          // Determine which resource was used
          if (newResourcesUsed.coal >= plant.resourceCount) {
            newResourcesUsed.coal -= plant.resourceCount;
          } else {
            newResourcesUsed.oil -= plant.resourceCount;
          }
        } else {
          newResourcesUsed[plant.resourceType] -= plant.resourceCount;
        }
      }
    } else {
      // Powering plant
      if (!checkPlantResources(plant)) return;
      
      newPlantsToPower.add(plant.id);
      
      // Consume resources
      if (plant.resourceType !== 'eco') {
        if (plant.resourceType === 'hybrid') {
          // Use coal if available, otherwise oil
          if (currentPlayer!.resources.coal - newResourcesUsed.coal >= plant.resourceCount) {
            newResourcesUsed.coal += plant.resourceCount;
          } else {
            newResourcesUsed.oil += plant.resourceCount;
          }
        } else {
          newResourcesUsed[plant.resourceType] += plant.resourceCount;
        }
      }
    }
    
    setPlantsToPower(newPlantsToPower);
    setResourcesUsed(newResourcesUsed);
  };
  
  // Calculate cities powered and earnings
  const calculateEarnings = () => {
    let citiesPowered = 0;
    
    currentPlayer?.powerPlants.forEach(plant => {
      if (plantsToPower.has(plant.id)) {
        citiesPowered += plant.citiesPowered;
      }
    });
    
    // Cap at actual city count
    citiesPowered = Math.min(citiesPowered, currentPlayer?.cities.length || 0);
    
    // Earnings table (simplified)
    const earningsTable: Record<number, number> = {
      0: 10, 1: 22, 2: 33, 3: 44, 4: 54, 5: 64, 6: 73, 7: 82, 8: 90,
      9: 98, 10: 105, 11: 112, 12: 118, 13: 124, 14: 129, 15: 134,
      16: 138, 17: 142, 18: 145, 19: 148, 20: 150
    };
    
    const earnings = earningsTable[citiesPowered] || 150;
    
    return { citiesPowered, earnings };
  };
  
  const handlePowerCities = () => {
    const { citiesPowered } = calculateEarnings();
    powerCities(citiesPowered);
  };
  
  const { citiesPowered, earnings } = calculateEarnings();
  
  return (
    <div className="space-y-6">
      {/* Phase Header */}
      <Card className="p-4 bg-orange-900/20 border-orange-600">
        <div className="flex items-center justify-between">
          <div className="flex items-center gap-3">
            <Zap className="w-6 h-6 text-orange-400" />
            <div>
              <h2 className="text-xl font-bold text-white">Bureaucracy Phase</h2>
              <p className="text-sm text-slate-400">
                Power cities and earn money
              </p>
            </div>
          </div>
          
          <div className="text-right">
            <p className="text-sm text-slate-400">Round</p>
            <p className="text-lg font-semibold text-white">
              {bureaucracyState.poweringOrder.indexOf(playerId || '') + 1} / {bureaucracyState.poweringOrder.length}
            </p>
          </div>
        </div>
      </Card>
      
      {/* Player Status */}
      {currentPlayer && !hasPowered && (
        <>
          <Card className="p-6">
            <h3 className="text-lg font-semibold text-white mb-4">
              Your Power Plants
            </h3>
            
            <div className="space-y-3">
              {currentPlayer.powerPlants.map(plant => {
                const canPower = checkPlantResources(plant);
                const isPowered = plantsToPower.has(plant.id);
                
                return (
                  <div
                    key={plant.id}
                    className={`
                      p-4 rounded-lg border-2 transition-all cursor-pointer
                      ${isPowered 
                        ? 'border-green-500 bg-green-900/20' 
                        : canPower && isMyTurn
                          ? 'border-slate-600 bg-game-surface hover:border-slate-500'
                          : 'border-slate-700 bg-slate-800 opacity-50 cursor-not-allowed'
                      }
                    `}
                    onClick={() => isMyTurn && canPower && togglePlant(plant)}
                  >
                    <div className="flex items-center justify-between">
                      <div className="flex items-center gap-3">
                        <div className="text-2xl font-bold text-white">
                          #{plant.number}
                        </div>
                        <div>
                          <p className="text-sm text-slate-400">
                            {plant.resourceType !== 'eco' && `${plant.resourceCount}× `}
                            {plant.resourceType}
                          </p>
                          <p className="text-sm text-yellow-400">
                            Powers {plant.citiesPowered} {plant.citiesPowered === 1 ? 'city' : 'cities'}
                          </p>
                        </div>
                      </div>
                      
                      <div className="flex items-center gap-2">
                        {isPowered && <Check className="w-5 h-5 text-green-400" />}
                        {!canPower && !isPowered && <X className="w-5 h-5 text-red-400" />}
                      </div>
                    </div>
                  </div>
                );
              })}
              
              {currentPlayer.powerPlants.length === 0 && (
                <p className="text-center text-slate-400 py-8">
                  You have no power plants
                </p>
              )}
            </div>
          </Card>
          
          {/* Resources Used */}
          {Object.values(resourcesUsed).some(v => v > 0) && (
            <Card className="p-4">
              <h4 className="text-sm font-medium text-slate-400 mb-2">Resources Being Used</h4>
              <div className="flex items-center gap-4">
                {Object.entries(resourcesUsed).map(([type, amount]) => 
                  amount > 0 && (
                    <div key={type} className="flex items-center gap-1">
                      <Fuel className="w-4 h-4 text-slate-400" />
                      <span className="text-white">{amount}× {type}</span>
                    </div>
                  )
                )}
              </div>
            </Card>
          )}
          
          {/* Earnings Preview */}
          <Card className="p-6 bg-green-900/20 border-green-600">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm text-slate-400">Cities Powered</p>
                <p className="text-3xl font-bold text-white">
                  {citiesPowered} / {currentPlayer.cities.length}
                </p>
              </div>
              
              <div className="text-center">
                <TrendingUp className="w-8 h-8 text-green-400 mx-auto mb-1" />
                <p className="text-sm text-slate-400">Earnings</p>
                <p className="text-3xl font-bold text-green-400">${earnings}</p>
              </div>
              
              <div className="text-right">
                <p className="text-sm text-slate-400">Max Possible</p>
                <p className="text-xl text-slate-500">{calculateMaxPower.maxCities} cities</p>
              </div>
            </div>
          </Card>
          
          {/* Action Buttons */}
          {isMyTurn && (
            <Card className="p-6">
              <Button
                className="w-full touch-target"
                onClick={handlePowerCities}
              >
                <DollarSign className="w-5 h-5 mr-2" />
                Power {citiesPowered} Cities & Earn ${earnings}
              </Button>
            </Card>
          )}
        </>
      )}
      
      {/* Already Powered */}
      {hasPowered && (
        <Card className="p-6">
          <div className="text-center">
            <Check className="w-12 h-12 text-green-400 mx-auto mb-3" />
            <h3 className="text-xl font-semibold text-white mb-2">
              Cities Powered
            </h3>
            <p className="text-slate-400">
              You powered {bureaucracyState.citiesPowered[playerId!]} cities 
              and earned ${bureaucracyState.earnings[playerId!]}
            </p>
          </div>
        </Card>
      )}
      
      {/* Waiting for Others */}
      {!isMyTurn && !hasPowered && (
        <Card className="p-4">
          <div className="text-center text-slate-400">
            <p>Waiting for other players...</p>
            {bureaucracyState.currentPowerer && (
              <p className="mt-2">
                Current player: {bureaucracyState.currentPowerer}
              </p>
            )}
          </div>
        </Card>
      )}
      
      {/* Phase Results */}
      {Object.keys(bureaucracyState.citiesPowered).length > 0 && (
        <Card className="p-6">
          <h3 className="text-lg font-semibold text-white mb-4">
            Phase Results
          </h3>
          
          <div className="space-y-2">
            {Object.entries(bureaucracyState.citiesPowered).map(([powerId, cities]) => {
              const earnings = bureaucracyState.earnings[powerId] || 0;
              
              return (
                <div key={powerId} className="flex items-center justify-between p-3 bg-game-surface rounded-lg">
                  <span className="text-white">
                    {powerId === playerId ? 'You' : `Player ${powerId}`}
                  </span>
                  <div className="flex items-center gap-4">
                    <div className="flex items-center gap-1">
                      <Zap className="w-4 h-4 text-yellow-400" />
                      <span className="text-slate-400">{cities} cities</span>
                    </div>
                    <div className="flex items-center gap-1">
                      <DollarSign className="w-4 h-4 text-green-400" />
                      <span className="text-green-400 font-medium">${earnings}</span>
                    </div>
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

export default BureaucracyPhase;