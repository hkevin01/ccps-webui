import React, { useEffect, useRef } from 'react';
import Map from 'ol/Map';
import View from 'ol/View';
import TileLayer from 'ol/layer/Tile';
import OSM from 'ol/source/OSM';
import XYZ from 'ol/source/XYZ';
import VectorLayer from 'ol/layer/Vector';
import VectorSource from 'ol/source/Vector';
import { LineString } from 'ol/geom';
import Feature from 'ol/Feature';
import { fromLonLat } from 'ol/proj';
import { Style, Stroke } from 'ol/style';
// Import the CSS file we created
import '../styles/map-styles.css';

const eastCoastCoordinates = [
    [-66.9647, 44.8101], // Maine
    [-71.3824, 42.4072], // Massachusetts
    [-74.0060, 40.7128], // New York
    [-76.6122, 39.2904], // Maryland
    [-77.0369, 38.9072], // DC
    [-76.2859, 36.8508], // Virginia
    [-77.9447, 34.2257], // North Carolina
    [-81.0998, 32.0835], // Georgia
    [-80.1918, 25.7617], // Miami, FL
];

interface OpenLayersMapProps {
    height?: string;
    usgsLayerVisible?: boolean;
}

export const OpenLayersMap: React.FC<OpenLayersMapProps> = ({
    height = '400px',
    usgsLayerVisible = true
}) => {
    const mapRef = useRef<HTMLDivElement>(null);
    const mapInstanceRef = useRef<Map | null>(null);

    useEffect(() => {
        if (!mapRef.current) return;

        // Create coastline feature
        const coastLineFeature = new Feature({
            geometry: new LineString(eastCoastCoordinates.map(coord => fromLonLat(coord)))
        });

        coastLineFeature.setStyle(
            new Style({
                stroke: new Stroke({
                    color: '#0d6efd',
                    width: 4
                })
            })
        );

        const vectorSource = new VectorSource({
            features: [coastLineFeature]
        });

        const vectorLayer = new VectorLayer({
            source: vectorSource,
            properties: {
                title: 'East Coast Line'
            }
        });

        // Base layers
        const osmLayer = new TileLayer({
            source: new OSM(),
            properties: {
                title: 'OpenStreetMap',
                type: 'base'
            }
        });

        // USGS Coastal Erosion layer (from USGS services)
        const usgsCoastalLayer = new TileLayer({
            source: new XYZ({
                url: 'https://coastalmap.marine.usgs.gov/cmgp/rest/services/CoastalChangeHazardsPortal/ShorelineChangeRates/MapServer/tile/{z}/{y}/{x}',
                attributions: 'USGS Coastal Change Hazards Portal'
            }),
            visible: usgsLayerVisible,
            properties: {
                title: 'USGS Coastal Change'
            }
        });

        // Create map
        const map = new Map({
            target: mapRef.current,
            layers: [
                osmLayer,
                usgsCoastalLayer,
                vectorLayer
            ],
            view: new View({
                center: fromLonLat([-76.2859, 36.8508]), // Centered on Virginia
                zoom: 5
            })
        });

        mapInstanceRef.current = map;

        return () => {
            if (mapInstanceRef.current) {
                mapInstanceRef.current.setTarget(undefined);
                mapInstanceRef.current = null;
            }
        };
    }, [usgsLayerVisible]);

    return (
        <div
            ref={mapRef}
            style={{
                width: '100%',
                height: height,
                border: '1px solid #ddd',
                borderRadius: '4px'
            }}
        />
    );
};
