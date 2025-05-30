import React from 'react';

type MapProvider = 'google' | 'openlayers';

interface MapSelectorProps {
    activeProvider: MapProvider;
    onProviderChange: (provider: MapProvider) => void;
}

export const MapSelector: React.FC<MapSelectorProps> = ({
    activeProvider,
    onProviderChange
}) => {
    return (
        <div className="btn-group mb-3" role="group" aria-label="Map provider selector">
            <button
                type="button"
                className={`btn ${activeProvider === 'google' ? 'btn-primary' : 'btn-outline-primary'}`}
                onClick={() => onProviderChange('google')}
            >
                Google Maps
            </button>
            <button
                type="button"
                className={`btn ${activeProvider === 'openlayers' ? 'btn-primary' : 'btn-outline-primary'}`}
                onClick={() => onProviderChange('openlayers')}
            >
                OpenLayers
            </button>
        </div>
    );
};
