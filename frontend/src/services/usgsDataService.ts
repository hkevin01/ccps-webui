import axios from 'axios';

// Interface for the Massachusetts shoreline change data
export interface ShorelinePoint {
    transectId: string;
    latitude: number;
    longitude: number;
    date: string;
    erosionRate: number;
    shorelineChange: number;
    uncertainty: number;
    location: string;
}

// USGS data endpoints
const USGS_DATA_URL = 'https://cmgds.marine.usgs.gov/data/whcmsc/data-release/doi-F73J3B0B/data/shorelines/mass_shorelines_1800s_to_2018.csv';
const PROXY_URL = 'https://cors-anywhere.herokuapp.com/'; // CORS proxy (for development)

// Function to fetch and parse CSV data
export const fetchMassShorelineData = async (): Promise<ShorelinePoint[]> => {
    try {
        // First try direct fetch (might fail due to CORS)
        const response = await axios.get(USGS_DATA_URL, {
            responseType: 'text'
        }).catch(() => {
            // If direct fetch fails, try using a CORS proxy
            console.log('Direct fetch failed, trying through CORS proxy...');
            return axios.get(PROXY_URL + USGS_DATA_URL, {
                responseType: 'text'
            });
        });

        return parseCSV(response.data);
    } catch (error) {
        console.error('Error fetching USGS shoreline data:', error);
        // Return mock data if fetch fails (for development)
        return getMockShorelineData();
    }
};

// Parse CSV data to ShorelinePoint objects
const parseCSV = (csvText: string): ShorelinePoint[] => {
    const lines = csvText.trim().split('\n');
    const headers = lines[0].split(',');

    // Find indices for the fields we need
    const fieldIndices: Record<string, number> = {};
    ['transectId', 'latitude', 'longitude', 'date', 'erosionRate', 'shorelineChange', 'uncertainty', 'location'].forEach(field => {
        const index = headers.findIndex(h => h.toLowerCase().includes(field.toLowerCase()));
        fieldIndices[field] = index >= 0 ? index : -1;
    });

    // Parse data rows
    return lines.slice(1).map(line => {
        const values = line.split(',');
        return {
            transectId: values[fieldIndices.transectId] || `T-${Math.random().toString(36).substr(2, 9)}`,
            latitude: parseFloat(values[fieldIndices.latitude] || '0'),
            longitude: parseFloat(values[fieldIndices.longitude] || '0'),
            date: values[fieldIndices.date] || '',
            erosionRate: parseFloat(values[fieldIndices.erosionRate] || '0'),
            shorelineChange: parseFloat(values[fieldIndices.shorelineChange] || '0'),
            uncertainty: parseFloat(values[fieldIndices.uncertainty] || '0'),
            location: values[fieldIndices.location] || 'Unknown'
        };
    }).filter(point => point.latitude && point.longitude); // Filter out invalid points
};

// Provide mock data for development/testing
const getMockShorelineData = (): ShorelinePoint[] => {
    // Massachusetts shoreline points (sample data)
    return [
        // Cape Cod points
        { transectId: 'CC-001', latitude: 42.0565, longitude: -70.1844, date: '2000-01-01', erosionRate: -0.5, shorelineChange: -10, uncertainty: 2, location: 'Cape Cod' },
        { transectId: 'CC-002', latitude: 42.0544, longitude: -70.1833, date: '2010-01-01', erosionRate: -0.7, shorelineChange: -17, uncertainty: 2, location: 'Cape Cod' },
        { transectId: 'CC-003', latitude: 42.0523, longitude: -70.1822, date: '2018-01-01', erosionRate: -0.8, shorelineChange: -22, uncertainty: 2, location: 'Cape Cod' },

        // Martha's Vineyard points
        { transectId: 'MV-001', latitude: 41.4108, longitude: -70.5652, date: '2000-01-01', erosionRate: -1.2, shorelineChange: -24, uncertainty: 3, location: "Martha's Vineyard" },
        { transectId: 'MV-002', latitude: 41.4120, longitude: -70.5630, date: '2010-01-01', erosionRate: -1.5, shorelineChange: -39, uncertainty: 3, location: "Martha's Vineyard" },
        { transectId: 'MV-003', latitude: 41.4132, longitude: -70.5608, date: '2018-01-01', erosionRate: -1.8, shorelineChange: -54, uncertainty: 3, location: "Martha's Vineyard" },

        // Boston Harbor points (with accretion instead of erosion)
        { transectId: 'BH-001', latitude: 42.3305, longitude: -70.9709, date: '2000-01-01', erosionRate: 0.3, shorelineChange: 6, uncertainty: 2, location: 'Boston Harbor' },
        { transectId: 'BH-002', latitude: 42.3299, longitude: -70.9695, date: '2010-01-01', erosionRate: 0.4, shorelineChange: 10, uncertainty: 2, location: 'Boston Harbor' },
        { transectId: 'BH-003', latitude: 42.3293, longitude: -70.9681, date: '2018-01-01', erosionRate: 0.5, shorelineChange: 14, uncertainty: 2, location: 'Boston Harbor' },
    ];
};
