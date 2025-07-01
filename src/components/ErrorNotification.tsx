import React, { useEffect } from 'react';
import { useGameStore } from '../store/gameStore';
import { X, AlertCircle } from 'lucide-react';
import Button from './ui/Button';

const ErrorNotification: React.FC = () => {
  const { errorMessage, clearError } = useGameStore();

  useEffect(() => {
    if (errorMessage) {
      // Auto-clear error after 5 seconds
      const timer = setTimeout(() => {
        clearError();
      }, 5000);

      return () => clearTimeout(timer);
    }
  }, [errorMessage, clearError]);

  if (!errorMessage) {
    return null;
  }

  return (
    <div className="fixed top-20 left-1/2 transform -translate-x-1/2 z-50 max-w-sm w-full mx-4">
      <div className="
        bg-red-600 border border-red-500 text-red-100
        rounded-lg shadow-lg p-4
        animate-slide-up
      ">
        <div className="flex items-start gap-3">
          <AlertCircle className="w-5 h-5 flex-shrink-0 mt-0.5" />
          
          <div className="flex-1 min-w-0">
            <p className="text-sm font-medium">
              Error
            </p>
            <p className="text-sm opacity-90 mt-1">
              {errorMessage}
            </p>
          </div>
          
          <Button
            variant="outline"
            size="sm"
            onClick={clearError}
            className="
              border-red-400 text-red-100 hover:bg-red-500 
              w-8 h-8 p-0 flex-shrink-0
            "
          >
            <X className="w-4 h-4" />
          </Button>
        </div>
      </div>
    </div>
  );
};

export default ErrorNotification;