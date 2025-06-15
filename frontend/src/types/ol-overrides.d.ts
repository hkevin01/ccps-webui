// Type declaration file to override and fix OpenLayers type issues

import VectorSource from 'ol/source/Vector';
import { Geometry, Point } from 'ol/geom';

// Augment the OpenLayers module declarations
declare module 'ol/layer/Heatmap' {
    // Override the constructor to accept any VectorSource type
    export default class Heatmap {
        constructor(options: {
            source: VectorSource<any>;
            blur?: number;
            radius?: number;
            weight?: Function;
            visible?: boolean;
            properties?: { [key: string]: any };
            [key: string]: any;
        });

        // Add other methods as needed
        getSource(): VectorSource<any>;
        setSource(source: VectorSource<any>): void;
        setVisible(visible: boolean): void;
    }
}
