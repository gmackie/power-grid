import React, { useState, useEffect } from 'react';
import { useGameStore, useDeviceStore } from '../../store/gameStore';
import { PowerPlant, AuctionState } from '../../types/game';
import { Gavel, DollarSign, Zap, X, Check } from 'lucide-react';
import Button from '../ui/Button';
import Card from '../ui/Card';
import Input from '../ui/Input';

interface AuctionPhaseProps {
  auctionState: AuctionState;
  powerPlantMarket: PowerPlant[];
}

const AuctionPhase: React.FC<AuctionPhaseProps> = ({ auctionState, powerPlantMarket }) => {
  const { 
    gameState,
    getCurrentPlayer, 
    isCurrentPlayerTurn,
    bid,
    pass,
    playerId
  } = useGameStore();
  
  const { isMobile } = useDeviceStore();
  
  const [bidAmount, setBidAmount] = useState<string>('');
  const [selectedPlant, setSelectedPlant] = useState<PowerPlant | null>(null);
  
  const currentPlayer = getCurrentPlayer();
  const isMyTurn = isCurrentPlayerTurn();
  const hasPassedThisRound = auctionState.passedPlayers.includes(playerId || '');
  const currentAuctionPlant = auctionState.currentPlant;
  
  useEffect(() => {
    // Set initial bid amount to current bid + 1 or minimum
    if (currentAuctionPlant && isMyTurn && !hasPassedThisRound) {
      const minBid = auctionState.currentBid > 0 ? auctionState.currentBid + 1 : currentAuctionPlant.cost;
      setBidAmount(minBid.toString());
    }
  }, [currentAuctionPlant, auctionState.currentBid, isMyTurn, hasPassedThisRound]);

  const handleSelectPlant = (plant: PowerPlant) => {
    if (!currentAuctionPlant && !hasPassedThisRound) {
      setSelectedPlant(plant);
      setBidAmount(plant.cost.toString());
    }
  };

  const handleBid = () => {
    const amount = parseInt(bidAmount);
    if (!isNaN(amount) && amount > 0) {
      if (currentAuctionPlant) {
        // Bid on current auction
        bid(amount);
      } else if (selectedPlant) {
        // Start new auction
        bid(selectedPlant.cost);
      }
    }
  };

  const handlePass = () => {
    pass();
    setSelectedPlant(null);
    setBidAmount('');
  };

  const validateBid = (value: string): boolean => {
    const amount = parseInt(value);
    if (isNaN(amount) || amount <= 0) return false;
    
    if (currentAuctionPlant) {
      return amount > auctionState.currentBid;
    } else if (selectedPlant) {
      return amount >= selectedPlant.cost;
    }
    
    return false;
  };

  const renderPowerPlant = (plant: PowerPlant, isAvailable: boolean = true) => {
    const isCurrentAuction = currentAuctionPlant?.id === plant.id;
    const isSelected = selectedPlant?.id === plant.id;
    const resourceColors: Record<string, string> = {
      coal: 'bg-gray-700',
      oil: 'bg-amber-700',
      garbage: 'bg-yellow-700',
      uranium: 'bg-green-700',
      hybrid: 'bg-purple-700',
      eco: 'bg-blue-700'
    };

    return (
      <div
        key={plant.id}
        className={`
          relative p-4 rounded-lg border-2 transition-all cursor-pointer
          ${isCurrentAuction 
            ? 'border-yellow-500 bg-yellow-900/20 scale-105' 
            : isSelected
              ? 'border-blue-500 bg-blue-900/20'
              : isAvailable
                ? 'border-slate-600 bg-game-surface hover:border-slate-500'
                : 'border-slate-700 bg-slate-800 opacity-50 cursor-not-allowed'
          }
        `}
        onClick={() => isAvailable && !isCurrentAuction && handleSelectPlant(plant)}
      >
        {/* Plant Number */}
        <div className="text-center mb-3">
          <div className="text-3xl font-bold text-white">
            {plant.number}
          </div>
          <div className="text-sm text-slate-400">
            Min: ${plant.cost}
          </div>
        </div>

        {/* Resource Type */}
        <div className={`
          inline-flex items-center gap-1 px-2 py-1 rounded-full text-xs text-white
          ${resourceColors[plant.resourceType] || 'bg-slate-700'}
        `}>
          {plant.resourceType !== 'eco' && (
            <span>{plant.resourceCount}×</span>
          )}
          <span className="capitalize">{plant.resourceType}</span>
        </div>

        {/* Power Output */}
        <div className="mt-3 flex items-center justify-center gap-1 text-yellow-400">
          <Zap className="w-4 h-4" />
          <span className="font-medium">
            Powers {plant.citiesPowered} {plant.citiesPowered === 1 ? 'city' : 'cities'}
          </span>
        </div>

        {/* Current Bid (if being auctioned) */}
        {isCurrentAuction && auctionState.currentBid > 0 && (
          <div className="absolute -top-2 -right-2 bg-yellow-500 text-black px-2 py-1 rounded-full text-sm font-bold">
            ${auctionState.currentBid}
          </div>
        )}
      </div>
    );
  };

  const renderBiddingControls = () => {
    if (hasPassedThisRound) {
      return (
        <Card className="p-4 bg-red-900/20 border-red-700">
          <div className="text-center text-red-400">
            <X className="w-6 h-6 mx-auto mb-2" />
            <p>You have passed this auction round</p>
          </div>
        </Card>
      );
    }

    if (!isMyTurn) {
      return (
        <Card className="p-4">
          <div className="text-center text-slate-400">
            <p>Waiting for other players...</p>
            {auctionState.currentBidder && (
              <p className="mt-2">
                Current bidder: {gameState?.players.find(p => p.id === auctionState.currentBidder)?.name}
              </p>
            )}
          </div>
        </Card>
      );
    }

    const minBid = currentAuctionPlant 
      ? auctionState.currentBid + 1 
      : selectedPlant?.cost || 0;
    
    const maxBid = currentPlayer?.money || 0;

    return (
      <Card className="p-6 space-y-4">
        <h3 className="text-lg font-semibold text-white">
          {currentAuctionPlant ? 'Place Your Bid' : 'Start Auction'}
        </h3>

        {currentAuctionPlant && (
          <div className="text-center p-3 bg-game-surface rounded-lg">
            <p className="text-sm text-slate-400">Current Plant</p>
            <p className="text-xl font-bold text-white">#{currentAuctionPlant.number}</p>
            <p className="text-sm text-yellow-400">Current Bid: ${auctionState.currentBid}</p>
          </div>
        )}

        {selectedPlant && !currentAuctionPlant && (
          <div className="text-center p-3 bg-game-surface rounded-lg">
            <p className="text-sm text-slate-400">Selected Plant</p>
            <p className="text-xl font-bold text-white">#{selectedPlant.number}</p>
          </div>
        )}

        <div className="space-y-3">
          <Input
            type="number"
            label="Bid Amount"
            value={bidAmount}
            onChange={(e) => setBidAmount(e.target.value)}
            min={minBid}
            max={maxBid}
            placeholder={`Min: $${minBid}`}
            error={bidAmount && !validateBid(bidAmount) ? 'Invalid bid amount' : undefined}
          />

          <div className="flex items-center justify-between text-sm">
            <span className="text-slate-400">Your Money:</span>
            <span className="text-yellow-400 font-medium">${currentPlayer?.money || 0}</span>
          </div>

          {/* Quick bid buttons */}
          {currentAuctionPlant && (
            <div className="flex gap-2">
              {[1, 5, 10].map(increment => {
                const quickBid = auctionState.currentBid + increment;
                return quickBid <= maxBid && (
                  <Button
                    key={increment}
                    variant="outline"
                    size="sm"
                    onClick={() => setBidAmount(quickBid.toString())}
                    className="flex-1"
                  >
                    +${increment}
                  </Button>
                );
              })}
            </div>
          )}
        </div>

        <div className="flex gap-3">
          <Button
            className="flex-1 touch-target"
            onClick={handleBid}
            disabled={!validateBid(bidAmount) || (!currentAuctionPlant && !selectedPlant)}
          >
            <Gavel className="w-5 h-5 mr-2" />
            {currentAuctionPlant ? 'Place Bid' : 'Start Auction'}
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
    );
  };

  return (
    <div className="space-y-6">
      {/* Phase Header */}
      <Card className="p-4 bg-game-primary/20 border-game-primary">
        <div className="flex items-center justify-between">
          <div className="flex items-center gap-3">
            <Gavel className="w-6 h-6 text-blue-400" />
            <div>
              <h2 className="text-xl font-bold text-white">Auction Phase</h2>
              <p className="text-sm text-slate-400">
                {currentAuctionPlant 
                  ? `Bidding on Plant #${currentAuctionPlant.number}` 
                  : 'Select a power plant to auction'}
              </p>
            </div>
          </div>
          
          {/* Auction progress */}
          <div className="text-right">
            <p className="text-sm text-slate-400">Active Bidders</p>
            <p className="text-lg font-semibold text-white">
              {auctionState.biddingOrder.length - auctionState.passedPlayers.length}
            </p>
          </div>
        </div>
      </Card>

      {/* Power Plant Market */}
      <Card className="p-6">
        <h3 className="text-lg font-semibold text-white mb-4">
          Power Plant Market
        </h3>
        
        <div className={`
          grid gap-4
          ${isMobile ? 'grid-cols-2' : 'grid-cols-3 lg:grid-cols-4'}
        `}>
          {powerPlantMarket.map((plant) => {
            const isAvailable = !Object.values(auctionState.plantsWon).some(p => p.id === plant.id);
            return renderPowerPlant(plant, isAvailable);
          })}
        </div>
      </Card>

      {/* Bidding Controls */}
      {renderBiddingControls()}

      {/* Auction History */}
      {Object.keys(auctionState.plantsWon).length > 0 && (
        <Card className="p-6">
          <h3 className="text-lg font-semibold text-white mb-4">
            Plants Won This Round
          </h3>
          
          <div className="space-y-2">
            {Object.entries(auctionState.plantsWon).map(([playerId, plant]) => {
              const player = gameState?.players.find(p => p.id === playerId);
              return (
                <div key={playerId} className="flex items-center justify-between p-3 bg-game-surface rounded-lg">
                  <div className="flex items-center gap-3">
                    <div
                      className="w-6 h-6 rounded-full border-2 border-white"
                      style={{ backgroundColor: player?.color }}
                    />
                    <span className="text-white">{player?.name}</span>
                  </div>
                  <div className="flex items-center gap-2">
                    <span className="text-slate-400">Plant #{plant.number}</span>
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

export default AuctionPhase;