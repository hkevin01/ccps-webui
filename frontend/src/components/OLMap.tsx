import React, { useEffect, useRef, useState } from 'react';
import Map from 'ol/Map';
import View from 'ol/View';
import TileLayer from 'ol/layer/Tile';
import VectorLayer from 'ol/layer/Vector';
import VectorSource from 'ol/source/Vector';
import OSM from 'ol/source/OSM';
import XYZ from 'ol/source/XYZ';
import { fromLonLat } from 'ol/proj';
import { LineString } from 'ol/geom';
import Feature from 'ol/Feature';
import { Style, Stroke } from 'ol/style';
import LayerSwitcher from 'ol-layerswitcher';
import 'ol/ol.css';
import 'ol-layerswitcher/dist/ol-layerswitcher.css';
import { Control, defaults as defaultControls } from 'ol/control';

// East Coast coordinates
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

// Google Maps API key
const GOOGLE_MAPS_API_KEY = process.env.REACT_APP_GOOGLE_MAPS_API_KEY || '';

// Custom Control for Google Maps attribution
class GoogleMapsAttribution extends Control {
    constructor() {
        const element = document.createElement('div');
        element.className = 'ol-control ol-attribution google-attribution';
        element.innerHTML = '©2024 Google';

        super({
            element: element,
            target: undefined
        });
    }
}

interface OLMapProps {
    height?: string;
    usgsLayerVisible?: boolean;
}

const OLMap: React.FC<OLMapProps> = ({
    height = '500px',
    usgsLayerVisible = true
}) => {
    const mapRef = useRef<HTMLDivElement>(null);
    const mapInstanceRef = useRef<Map | null>(null);
    const [mapLoaded, setMapLoaded] = useState(false);

    useEffect(() => {
        if (!mapRef.current || mapInstanceRef.current) return;

        // Create OpenStreetMap layer
        const osmLayer = new TileLayer({
            source: new OSM(),
            visible: true,
            properties: {
                title: 'OpenStreetMap',
                type: 'base'
            }
        });

        // Create Google Maps layer
        const googleMapsLayer = new TileLayer({
            source: new XYZ({
                url: `https://mt1.google.com/vt/lyrs=m&x={x}&y={y}&z={z}&key=${GOOGLE_MAPS_API_KEY}`,
                attributions: '©2024 Google Maps'
            }),
            visible: false,
            properties: {
                title: 'Google Maps',
                type: 'base'
            }
        });

        // Google Satellite layer
        const googleSatelliteLayer = new TileLayer({
            source: new XYZ({
                url: `https://mt1.google.com/vt/lyrs=s&x={x}&y={y}&z={z}&key=${GOOGLE_MAPS_API_KEY}`,
                attributions: '©2024 Google Satellite'
            }),
            visible: false,
            properties: {
                title: 'Google Satellite',
                type: 'base'
            }
        });

        // USGS Coastal Change layer
        const usgsCoastalLayer = new TileLayer({
            source: new XYZ({
                url: 'https://coastalmap.marine.usgs.gov/cmgp/rest/services/CoastalChangeHazardsPortal/ShorelineChangeRates/MapServer/tile/{z}/{y}/{x}',
                attributions: 'USGS Coastal Change Hazards Portal'
            }),
            visible: usgsLayerVisible,
            properties: {
                title: 'USGS Coastal Change',
                type: 'overlay'
            }
        });

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
                title: 'East Coast Line',
                type: 'overlay'
            }
        });

        // Create map
        const map = new Map({
            target: mapRef.current,
            layers: [
                osmLayer,
                googleMapsLayer,
                googleSatelliteLayer,
                usgsCoastalLayer,
                vectorLayer
            ],
            view: new View({
                center: fromLonLat([-76.2859, 36.8508]), // Centered on Virginia
                zoom: 5
            }),
            controls: defaultControls().extend([
                new GoogleMapsAttribution()
            ])
        });

        // Add layer switcher control
        const layerSwitcher = new LayerSwitcher({
            tipLabel: 'Layer switcher', // Optional label for button
            groupSelectStyle: 'children', // Optional: Select all child layers when parent is selected
            reverse: true, // Optional: display layers in reverse order
            collapseTipLabel: 'Hide layer switcher', // Optional: tooltip for collapse button
        });
        map.addControl(layerSwitcher);

        mapInstanceRef.current = map;
        setMapLoaded(true);

        return () => {
            if (mapInstanceRef.current) {
                mapInstanceRef.current.setTarget(undefined);
                mapInstanceRef.current = null;
            }
        };
    }, [usgsLayerVisible]);

    // Update USGS layer visibility when the prop changes
    useEffect(() => {
        if (mapInstanceRef.current && mapLoaded) {
            const layers = mapInstanceRef.current.getLayers().getArray();
            const usgsLayer = layers.find(layer =>
                layer.get('title') === 'USGS Coastal Change'
            );

            if (usgsLayer) {
                usgsLayer.setVisible(usgsLayerVisible);
            }
        }
    }, [usgsLayerVisible, mapLoaded]);

    return (
        <div className="map-container">
            <div
                ref={mapRef}
                style={{
                    width: '100%',
                    height,
                    border: '1px solid #ddd',
                    borderRadius: '4px'
                }}
            />
            <div className="map-attribution">
                Data sources: OpenStreetMap, Google Maps, USGS Coastal Change Hazards Portal
            </div>
        </div>
    );
};

export default OLMap;
