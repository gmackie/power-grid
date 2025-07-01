import React, { useState } from 'react';
import { useGameStore, useDeviceStore } from '../../store/gameStore';
import { ResourceType, ResourcePhaseState, ResourceMarket } from '../../types/game';
import { Fuel, Minus, Plus, ShoppingCart, Check } from 'lucide-react';
import Button from '../ui/Button';
import Card from '../ui/Card';

interface ResourcePhaseProps {
  resourcePhaseState: ResourcePhaseState;
  resourceMarket: ResourceMarket;
}

const ResourcePhase: React.FC<ResourcePhaseProps> = ({ resourcePhaseState, resourceMarket }) => {
  const { 
    getCurrentPlayer, 
    isCurrentPlayerTurn,
    buyResources,
    pass,
    playerId
  } = useGameStore();
  
  const { isMobile } = useDeviceStore();
  
  const [resourcesToBuy, setResourcesToBuy] = useState<Record<ResourceType, number>>({
    coal: 0,
    oil: 0,
    garbage: 0,
    uranium: 0
  });
  
  const currentPlayer = getCurrentPlayer();
  const isMyTurn = isCurrentPlayerTurn();
  const myPurchases = resourcePhaseState.resourcesPurchased[playerId || ''] || {};
  
  // Calculate resource capacities based on power plants
  const getResourceCapacity = (type: ResourceType): number => {
    if (!currentPlayer) return 0;
    
    return currentPlayer.powerPlants.reduce((capacity, plant) => {
      if (plant.resourceType === type || plant.resourceType === 'hybrid') {
        return capacity + plant.resourceCount * 2; // Plants can store 2x their requirement
      }
      return capacity;
    }, 0);
  };
  
  // Calculate current resources including purchases
  const getCurrentResources = (type: ResourceType): number => {
    if (!currentPlayer) return 0;
    return currentPlayer.resources[type] + (myPurchases[type] || 0);
  };
  
  // Calculate price for buying resources
  const getResourcePrice = (type: ResourceType, amount: number): number => {
    const prices: Record<ResourceType, number> = {
      coal: resourceMarket.coalPrice,
      oil: resourceMarket.oilPrice,
      garbage: resourceMarket.garbagePrice,
      uranium: resourceMarket.uraniumPrice
    };
    
    // Simple pricing: fixed price per unit (in real game, prices increase as supply decreases)
    return prices[type] * amount;
  };
  
  const getTotalCost = (): number => {
    return Object.entries(resourcesToBuy).reduce((total, [type, amount]) => {
      return total + getResourcePrice(type as ResourceType, amount);
    }, 0);
  };
  
  const canAffordPurchase = (): boolean => {
    if (!currentPlayer) return false;
    return getTotalCost() <= currentPlayer.money;
  };
  
  const handleResourceChange = (type: ResourceType, delta: number) => {
    const currentAmount = resourcesToBuy[type];
    const newAmount = Math.max(0, currentAmount + delta);
    const currentResources = getCurrentResources(type);
    const capacity = getResourceCapacity(type);
    const maxCanBuy = capacity - currentResources;
    const available = resourceMarket[type as keyof typeof resourceMarket];
    
    // Check constraints
    if (newAmount > maxCanBuy) return; // Can't exceed capacity
    if (newAmount > available) return; // Can't exceed market supply
    
    setResourcesToBuy({
      ...resourcesToBuy,
      [type]: newAmount
    });
  };
  
  const handleBuyResources = () => {
    const hasResources = Object.values(resourcesToBuy).some(amount => amount > 0);
    if (hasResources && canAffordPurchase()) {
      buyResources(resourcesToBuy);
      setResourcesToBuy({ coal: 0, oil: 0, garbage: 0, uranium: 0 });
    }
  };
  
  const handlePass = () => {
    pass();
    setResourcesToBuy({ coal: 0, oil: 0, garbage: 0, uranium: 0 });
  };
  
  const renderResourceRow = (type: ResourceType, icon: string, color: string) => {
    const capacity = getResourceCapacity(type);
    const current = getCurrentResources(type);
    const toBuy = resourcesToBuy[type];
    const available = resourceMarket[type as keyof typeof resourceMarket];
    const price = getResourcePrice(type, 1);
    
    if (capacity === 0) return null; // Don't show resources player can't use
    
    return (
      <div key={type} className="p-4 bg-game-surface rounded-lg">
        <div className="flex items-center justify-between mb-3">
          <div className="flex items-center gap-3">
            <div className={`w-10 h-10 ${color} rounded-full flex items-center justify-center text-white`}>
              {icon}
            </div>
            <div>
              <h4 className="text-white font-medium capitalize">{type}</h4>
              <p className="text-xs text-slate-400">${price} each</p>
            </div>
          </div>
          
          <div className="text-right">
            <p className="text-sm text-slate-400">Available</p>
            <p className="text-lg font-semibold text-white">{available}</p>
          </div>
        </div>
        
        {/* Resource capacity bar */}
        <div className="mb-3">
          <div className="flex justify-between text-xs text-slate-400 mb-1">
            <span>Storage: {current + toBuy}/{capacity}</span>
            <span>{Math.round(((current + toBuy) / capacity) * 100)}%</span>
          </div>
          <div className="h-2 bg-slate-700 rounded-full overflow-hidden">
            <div className="h-full flex">
              <div 
                className={`${color} transition-all duration-300`}
                style={{ width: `${(current / capacity) * 100}%` }}
              />
              <div 
                className={`${color} opacity-50 transition-all duration-300`}
                style={{ width: `${(toBuy / capacity) * 100}%` }}
              />
            </div>
          </div>
        </div>
        
        {/* Buy controls */}
        <div className="flex items-center justify-between">
          <Button
            variant="outline"
            size="sm"
            onClick={() => handleResourceChange(type, -1)}
            disabled={toBuy === 0 || !isMyTurn}
            className="w-10 h-10 p-0"
          >
            <Minus className="w-4 h-4" />
          </Button>
          
          <div className="text-center">
            <p className="text-2xl font-bold text-white">{toBuy}</p>
            {toBuy > 0 && (
              <p className="text-sm text-yellow-400">${getResourcePrice(type, toBuy)}</p>
            )}
          </div>
          
          <Button
            variant="outline"
            size="sm"
            onClick={() => handleResourceChange(type, 1)}
            disabled={
              !isMyTurn ||
              toBuy >= available ||
              current + toBuy >= capacity
            }
            className="w-10 h-10 p-0"
          >
            <Plus className="w-4 h-4" />
          </Button>
        </div>
      </div>
    );
  };
  
  return (
    <div className="space-y-6">
      {/* Phase Header */}
      <Card className="p-4 bg-green-900/20 border-green-600">
        <div className="flex items-center justify-between">
          <div className="flex items-center gap-3">
            <Fuel className="w-6 h-6 text-green-400" />
            <div>
              <h2 className="text-xl font-bold text-white">Resource Phase</h2>
              <p className="text-sm text-slate-400">
                Buy resources to power your plants
              </p>
            </div>
          </div>
          
          <div className="text-right">
            <p className="text-sm text-slate-400">Turn Order</p>
            <p className="text-lg font-semibold text-white">
              {resourcePhaseState.buyingOrder.indexOf(playerId || '') + 1} / {resourcePhaseState.buyingOrder.length}
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
            
            {getTotalCost() > 0 && (
              <div className="text-right">
                <p className="text-sm text-slate-400">Total Cost</p>
                <p className={`text-2xl font-bold ${
                  canAffordPurchase() ? 'text-green-400' : 'text-red-400'
                }`}>
                  ${getTotalCost()}
                </p>
              </div>
            )}
          </div>
        </Card>
      )}
      
      {/* Resource Market */}
      <Card className="p-6">
        <h3 className="text-lg font-semibold text-white mb-4">
          Resource Market
        </h3>
        
        <div className={`
          grid gap-4
          ${isMobile ? 'grid-cols-1' : 'grid-cols-2'}
        `}>
          {renderResourceRow('coal', '⚫', 'bg-gray-700')}
          {renderResourceRow('oil', '🛢️', 'bg-amber-700')}
          {renderResourceRow('garbage', '🗑️', 'bg-yellow-700')}
          {renderResourceRow('uranium', '☢️', 'bg-green-700')}
        </div>
      </Card>
      
      {/* Action Buttons */}
      {isMyTurn && (
        <Card className="p-6">
          <div className="flex gap-3">
            <Button
              className="flex-1 touch-target"
              onClick={handleBuyResources}
              disabled={getTotalCost() === 0 || !canAffordPurchase()}
            >
              <ShoppingCart className="w-5 h-5 mr-2" />
              Buy Resources (${getTotalCost()})
            </Button>
            
            <Button
              variant="outline"
              className="touch-target"
              onClick={handlePass}
            >
              Pass
            </Button>
          </div>
        </Card>
      )}
      
      {!isMyTurn && (
        <Card className="p-4">
          <div className="text-center text-slate-400">
            <p>Waiting for other players...</p>
            {resourcePhaseState.currentBuyer && (
              <p className="mt-2">
                Current buyer: {resourcePhaseState.currentBuyer}
              </p>
            )}
          </div>
        </Card>
      )}
      
      {/* Purchase History */}
      {Object.keys(resourcePhaseState.resourcesPurchased).length > 0 && (
        <Card className="p-6">
          <h3 className="text-lg font-semibold text-white mb-4">
            Resources Purchased
          </h3>
          
          <div className="space-y-2">
            {Object.entries(resourcePhaseState.resourcesPurchased).map(([buyerId, resources]) => {
              const hasResources = Object.values(resources).some(amount => amount > 0);
              if (!hasResources) return null;
              
              return (
                <div key={buyerId} className="flex items-center justify-between p-3 bg-game-surface rounded-lg">
                  <span className="text-white">
                    {buyerId === playerId ? 'You' : `Player ${buyerId}`}
                  </span>
                  <div className="flex items-center gap-3">
                    {Object.entries(resources).map(([type, amount]) => 
                      amount > 0 && (
                        <span key={type} className="text-sm text-slate-400">
                          {amount}× {type}
                        </span>
                      )
                    )}
                    <Check className="w-4 h-4 text-green-400" />
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

export default ResourcePhase;