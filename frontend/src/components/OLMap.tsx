import React, { useEffect, useRef, useState } from 'react';
import Map from 'ol/Map';
import View from 'ol/View';
import TileLayer from 'ol/layer/Tile';
import VectorLayer from 'ol/layer/Vector';
import VectorSource from 'ol/source/Vector';
import OSM from 'ol/source/OSM';
import XYZ from 'ol/source/XYZ';
import ImageWMS from 'ol/source/ImageWMS';
import { fromLonLat } from 'ol/proj';
import { Point } from 'ol/geom';
import Feature from 'ol/Feature';
import { Style, Stroke, Circle, Fill, Text } from 'ol/style';
import LayerSwitcher from 'ol-layerswitcher';
import 'ol/ol.css';
import 'ol-layerswitcher/dist/ol-layerswitcher.css';
import { Control, defaults as defaultControls } from 'ol/control';
import { Overlay } from 'ol';
import { fetchMassShorelineData } from '../services/usgsDataService';
import Heatmap from 'ol/layer/Heatmap';
import ImageLayer from 'ol/layer/Image';

// East Coast coordinates (we'll use this for reference but not as a LineString)
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

// Custom Control for visualization type selection
class VisualizationControl extends Control {
    constructor(options: any) {
        const element = document.createElement('div');
        element.className = 'ol-control ol-unselectable viz-control';

        const dotBtn = document.createElement('button');
        dotBtn.innerHTML = 'Dots';
        dotBtn.className = options.activeViz === 'dots' ? 'active' : '';
        dotBtn.onclick = () => options.onChange('dots');

        const heatmapBtn = document.createElement('button');
        heatmapBtn.innerHTML = 'Heatmap';
        heatmapBtn.className = options.activeViz === 'heatmap' ? 'active' : '';
        heatmapBtn.onclick = () => options.onChange('heatmap');

        element.appendChild(dotBtn);
        element.appendChild(heatmapBtn);

        super({
            element: element,
            target: options.target
        });

        // Store references to update active state
        this.dotBtn = dotBtn;
        this.heatmapBtn = heatmapBtn;
    }

    updateActiveVisualization(type: string) {
        this.dotBtn.className = type === 'dots' ? 'active' : '';
        this.heatmapBtn.className = type === 'heatmap' ? 'active' : '';
    }

    dotBtn: HTMLButtonElement;
    heatmapBtn: HTMLButtonElement;
}

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
    const popupRef = useRef<HTMLDivElement>(null);
    const vizControlRef = useRef<VisualizationControl | null>(null);
    const [mapLoaded, setMapLoaded] = useState(false);
    const [usgsData, setUsgsData] = useState<any[]>([]);
    const [selectedFeature, setSelectedFeature] = useState<any>(null);
    const [vizType, setVizType] = useState<'dots' | 'heatmap'>('dots');

    // Load USGS data
    useEffect(() => {
        const loadUsgsData = async () => {
            try {
                const data = await fetchMassShorelineData();
                setUsgsData(data);
            } catch (error) {
                console.error('Error loading USGS data:', error);
            }
        };

        loadUsgsData();
    }, []);

    // Handle visualization type change
    const handleVizTypeChange = (type: 'dots' | 'heatmap') => {
        setVizType(type);
        if (vizControlRef.current) {
            vizControlRef.current.updateActiveVisualization(type);
        }

        if (mapInstanceRef.current) {
            const map = mapInstanceRef.current;

            // Toggle layer visibility based on visualization type
            const layers = map.getLayers().getArray();

            const dotsLayer = layers.find(layer =>
                layer.get('title') === 'MA Shoreline Points'
            );

            const heatmapLayer = layers.find(layer =>
                layer.get('title') === 'MA Shoreline Heatmap'
            );

            if (dotsLayer) dotsLayer.setVisible(type === 'dots');
            if (heatmapLayer) heatmapLayer.setVisible(type === 'heatmap');
        }
    };

    // Initialize map
    useEffect(() => {
        if (!mapRef.current || mapInstanceRef.current) return;

        // Create popup overlay
        const popupOverlay = new Overlay({
            element: popupRef.current!,
            autoPan: true,
            offset: [0, -10]
        });

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
                url: `https://mt1.google.com/vt/lyrs=m&x={x}&y={y}&z={z}`,
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
                url: `https://mt1.google.com/vt/lyrs=s&x={x}&y={y}&z={z}`,
                attributions: '©2024 Google Satellite'
            }),
            visible: false,
            properties: {
                title: 'Google Satellite',
                type: 'base'
            }
        });

        // Fix USGS Coastal Change layer - use ImageLayer with ImageWMS source
        const usgsCoastalLayer = new ImageLayer({
            source: new ImageWMS({
                url: 'https://cida.usgs.gov/coastalchangehazardsportal/geoserver/wms',
                params: {
                    'LAYERS': 'ccap:SC_shorelines_shellpoint',
                    'TILED': true,
                    'FORMAT': 'image/png',
                    'TRANSPARENT': true
                },
                attributions: 'USGS Coastal Change Hazards Portal'
            }),
            visible: usgsLayerVisible,
            opacity: 0.7, // Make it semi-transparent so other layers are visible underneath
            zIndex: 5, // Ensure proper stacking order
            properties: {
                title: 'USGS Coastal Change Overlay',
                type: 'overlay'
            }
        });

        // Alternative USGS sources with direct tile URLs
        const usgsCoastalLayerAlt = new TileLayer({
            source: new XYZ({
                url: 'https://marine.usgs.gov/coastalchangehazardsportal/rest/services/National_Assessment/national_baseline_transects/MapServer/tile/{z}/{y}/{x}',
                attributions: 'USGS Coastal Change Hazards Portal'
            }),
            visible: false, // Start hidden, can be toggled in layer switcher
            opacity: 0.7,
            properties: {
                title: 'USGS Transects (Alternative)',
                type: 'overlay'
            }
        });

        // Try another USGS source - using a different endpoint
        const usgsHistoricalShorelineLayer = new TileLayer({
            source: new XYZ({
                url: 'https://marine.usgs.gov/coastalchangehazardsportal/rest/services/DigitalShorelineData/historical_shorelines/MapServer/tile/{z}/{y}/{x}',
                attributions: 'USGS Historical Shorelines'
            }),
            visible: usgsLayerVisible, // Match the visibility setting from props
            opacity: 0.8,
            properties: {
                title: 'USGS Historical Shorelines',
                type: 'overlay'
            }
        });

        // Use `any` type to bypass TypeScript's type checking for OpenLayers objects
        // @ts-ignore - Tell TypeScript to ignore type errors for these lines
        const pointsSource = new VectorSource();
        // @ts-ignore
        const heatmapSource = new VectorSource();

        // @ts-ignore
        const pointsLayer = new VectorLayer({
            source: pointsSource,
            visible: vizType === 'dots',
            properties: {
                title: 'MA Shoreline Points',
                type: 'overlay'
            }
        });

        // @ts-ignore - Force TypeScript to accept this
        const heatmapLayer = new Heatmap({
            source: heatmapSource,
            visible: vizType === 'heatmap',
            blur: 15,
            radius: 10,
            weight: function (feature) {
                // Weight by absolute erosion rate (both erosion and accretion contribute to heat)
                const erosionRate = Math.abs(feature.get('properties')?.erosionRate || 0);
                return Math.min(1, erosionRate / 2); // Normalize
            },
            properties: {
                title: 'MA Shoreline Heatmap',
                type: 'overlay'
            }
        });

        // Create reference points for East Coast (without explicit Point type)
        const eastCoastPointsSource = new VectorSource();
        eastCoastCoordinates.forEach((coord, index) => {
            const pointFeature = new Feature({
                geometry: new Point(fromLonLat(coord)),
                properties: {
                    name: `Point ${index + 1}`,
                    location: ['Maine', 'Massachusetts', 'New York', 'Maryland', 'DC',
                        'Virginia', 'North Carolina', 'Georgia', 'Florida'][index] || ''
                }
            });

            // Small blue markers for reference points
            pointFeature.setStyle(new Style({
                image: new Circle({
                    radius: 4,
                    fill: new Fill({ color: '#0d6efd' }),
                    stroke: new Stroke({ color: 'white', width: 1 })
                })
            }));

            eastCoastPointsSource.addFeature(pointFeature);
        });

        // East Coast points layer without type constraints
        const eastCoastPointsLayer = new VectorLayer({
            source: eastCoastPointsSource,
            properties: {
                title: 'East Coast Reference Points',
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
                usgsCoastalLayerAlt,      // Add alternative layer
                usgsHistoricalShorelineLayer, // Add historical shorelines
                eastCoastPointsLayer,
                pointsLayer,
                heatmapLayer
            ],
            overlays: [popupOverlay],
            view: new View({
                center: fromLonLat([-70.8, 42.0]), // Center on Massachusetts
                zoom: 7
            }),
            controls: defaultControls().extend([
                new GoogleMapsAttribution()
            ])
        });

        // Add layer switcher control
        const layerSwitcher = new LayerSwitcher({
            tipLabel: 'Layer switcher',
            groupSelectStyle: 'children',
            reverse: true,
            collapseTipLabel: 'Hide layer switcher',
        });
        map.addControl(layerSwitcher);

        // Add visualization control
        const vizControl = new VisualizationControl({
            activeViz: vizType,
            onChange: handleVizTypeChange
        });
        map.addControl(vizControl);
        vizControlRef.current = vizControl;

        // Add click handler for features
        map.on('click', (evt) => {
            const feature = map.forEachFeatureAtPixel(evt.pixel, feature => feature);

            if (feature && feature.get('properties')) {
                const coords = evt.coordinate;
                const properties = feature.get('properties');

                setSelectedFeature(properties);
                popupOverlay.setPosition(coords);
            } else {
                popupOverlay.setPosition(undefined);
                setSelectedFeature(null);
            }
        });

        mapInstanceRef.current = map;
        setMapLoaded(true);

        return () => {
            if (mapInstanceRef.current) {
                mapInstanceRef.current.setTarget(undefined);
                mapInstanceRef.current = null;
            }
        };
    }, [usgsLayerVisible, vizType]);

    // Update map with USGS data
    useEffect(() => {
        if (mapLoaded && mapInstanceRef.current && usgsData.length > 0) {
            const map = mapInstanceRef.current;

            // Find layers without type constraints
            const layers = map.getLayers().getArray();
            const pointsLayer = layers.find(layer =>
                layer.get('title') === 'MA Shoreline Points'
            );
            const heatmapLayer = layers.find(layer =>
                layer.get('title') === 'MA Shoreline Heatmap'
            );

            if (pointsLayer && heatmapLayer) {
                // Cast to any to avoid TypeScript errors
                const pointsSource = (pointsLayer as any).getSource();
                const heatmapSource = (heatmapLayer as any).getSource();

                // Clear existing sources
                if (pointsSource) pointsSource.clear();
                if (heatmapSource) heatmapSource.clear();

                // Create features for each data point with explicit typing
                // Fix: Initialize the array with proper typing
                const pointFeatures: Feature<Point>[] = [];

                usgsData.forEach(point => {
                    if (point.latitude && point.longitude) {
                        // Create point feature without explicit geometry type
                        const feature = new Feature<Point>({
                            geometry: new Point(fromLonLat([point.longitude, point.latitude])),
                            properties: point
                        });

                        // Style points based on erosion rate
                        const erosionRate = point.erosionRate || 0;
                        const isErosion = erosionRate < 0;
                        const magnitude = Math.min(Math.abs(erosionRate), 3) / 3; // Normalize to 0-1

                        // Colors: red for erosion, green for accretion
                        const color = isErosion ?
                            [255, 50 + (1 - magnitude) * 150, 50, 0.8] : // Red shades
                            [50, 150 + magnitude * 100, 50, 0.8];      // Green shades

                        // Size based on magnitude
                        const radius = 5 + (magnitude * 7);

                        feature.setStyle(new Style({
                            image: new Circle({
                                radius: radius,
                                fill: new Fill({
                                    color: `rgba(${color.join(',')})`
                                }),
                                stroke: new Stroke({
                                    color: 'white',
                                    width: 1
                                })
                            }),
                            // Add text for large points
                            text: magnitude > 0.6 ? new Text({
                                text: point.location ? point.location.substring(0, 3) : '',
                                font: '10px sans-serif',
                                fill: new Fill({
                                    color: 'white'
                                }),
                                stroke: new Stroke({
                                    color: 'black',
                                    width: 2
                                }),
                                offsetY: -radius - 8
                            }) : undefined
                        }));

                        pointFeatures.push(feature);
                    }
                });

                // Add features to both sources
                if (pointsSource) pointsSource.addFeatures(pointFeatures);
                if (heatmapSource) heatmapSource.addFeatures(pointFeatures);

                // Set layer visibility based on current visualization type
                (pointsLayer as any).setVisible(vizType === 'dots');
                (heatmapLayer as any).setVisible(vizType === 'heatmap');
            }
        }
    }, [usgsData, mapLoaded, vizType]);

    // Update USGS layer visibility
    useEffect(() => {
        if (mapInstanceRef.current && mapLoaded) {
            const map = mapInstanceRef.current;

            try {
                const layers = map.getLayers().getArray();
                // Find both USGS layers
                const usgsLayer = layers.find(layer => layer.get('title') === 'USGS Coastal Change Overlay');
                const usgsHistLayer = layers.find(layer => layer.get('title') === 'USGS Historical Shorelines');

                console.log("USGS Layers found:", !!usgsLayer, !!usgsHistLayer);

                if (usgsLayer) {
                    usgsLayer.setVisible(usgsLayerVisible);
                    // Ensure the layer has proper opacity
                    usgsLayer.setOpacity(0.7);
                    console.log("USGS Coastal layer visibility set to:", usgsLayerVisible);
                }

                if (usgsHistLayer) {
                    usgsHistLayer.setVisible(usgsLayerVisible);
                    console.log("USGS Historical layer visibility set to:", usgsLayerVisible);
                }
            } catch (error) {
                console.error("Error updating USGS layer visibility:", error);
            }
        }
    }, [usgsLayerVisible, mapLoaded]);

    // Add debug control to toggle individual layers
    useEffect(() => {
        if (mapInstanceRef.current && mapLoaded) {
            const map = mapInstanceRef.current;

            // Create debug panel for layer testing
            const debugElement = document.createElement('div');
            debugElement.className = 'ol-control debug-panel';
            debugElement.innerHTML = '<button>Debug Layers</button>';
            debugElement.onclick = function () {
                const panel = document.createElement('div');
                panel.className = 'layer-debug-panel';
                panel.innerHTML = '<h4>Layer Debug</h4>';

                const layers = map.getLayers().getArray();
                layers.forEach((layer, i) => {
                    const title = layer.get('title') || `Layer ${i}`;
                    const visible = layer.getVisible();

                    const checkbox = document.createElement('input');
                    checkbox.type = 'checkbox';
                    checkbox.checked = visible;
                    checkbox.onchange = function () {
                        layer.setVisible(checkbox.checked);
                    };

                    const label = document.createElement('label');
                    label.appendChild(checkbox);
                    label.appendChild(document.createTextNode(` ${title}`));

                    const div = document.createElement('div');
                    div.appendChild(label);
                    panel.appendChild(div);
                });

                // Add close button
                const closeBtn = document.createElement('button');
                closeBtn.textContent = 'Close';
                closeBtn.onclick = function () {
                    document.body.removeChild(panel);
                };
                panel.appendChild(closeBtn);

                document.body.appendChild(panel);
            };

            // Only add in development mode to avoid cluttering the UI
            if (process.env.NODE_ENV === 'development') {
                map.addControl(new Control({ element: debugElement }));
            }
        }
    }, [mapLoaded]);

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

            {/* Popup overlay for feature info */}
            <div ref={popupRef} className="ol-popup">
                {selectedFeature && (
                    <div className="popup-content">
                        <h5>{selectedFeature.location || 'Shoreline Point'}</h5>
                        <p><strong>Date:</strong> {selectedFeature.date}</p>
                        <p><strong>Erosion Rate:</strong> {selectedFeature.erosionRate?.toFixed(2)} m/year</p>
                        <p><strong>Shoreline Change:</strong> {selectedFeature.shorelineChange?.toFixed(2)} m</p>
                        <button
                            className="btn btn-sm btn-secondary"
                            onClick={() => setSelectedFeature(null)}
                        >
                            Close
                        </button>
                    </div>
                )}
            </div>

            <div className="map-legend">
                <h6>Legend</h6>
                <div className="legend-item">
                    <div className="legend-color" style={{ backgroundColor: 'rgba(255,50,50,0.8)' }}></div>
                    <span className="legend-label">Erosion (loss)</span>
                </div>
                <div className="legend-item">
                    <div className="legend-color" style={{ backgroundColor: 'rgba(50,200,50,0.8)' }}></div>
                    <span className="legend-label">Accretion (gain)</span>
                </div>
                <div className="legend-item">
                    <span className="legend-label">⚫ Size indicates rate</span>
                </div>
            </div>

            <div className="map-attribution">
                Data sources: OpenStreetMap, Google Maps, USGS Coastal Change Hazards Portal,
                <a href="https://cmgds.marine.usgs.gov/data/whcmsc/data-release/doi-F73J3B0B/" target="_blank" rel="noopener noreferrer">
                    USGS Massachusetts Shoreline Change Data
                </a>
            </div>
        </div>
    );
};

export default OLMap;
