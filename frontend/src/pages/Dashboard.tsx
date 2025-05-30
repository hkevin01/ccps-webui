import React, { useState, useEffect } from 'react';
import { GoogleMap, LoadScript, Polyline } from '@react-google-maps/api';
import { fetchCoastalData, predictCoastalChange, fetchUsgsCoastalData } from '../services/api';
import { CoastalDataTable } from '../components/CoastalDataTable';
import { PredictionForm } from '../components/PredictionForm';
import { MapSelector } from '../components/MapSelector';
import { OpenLayersMap } from '../components/OpenLayersMap';

const mapContainerStyle = {
  width: '100%',
  height: '400px',
};

const eastCoastPath = [
  // Example coordinates for US East Coast (simplified)
  { lat: 44.8101, lng: -66.9647 }, // Maine
  { lat: 42.4072, lng: -71.3824 }, // Massachusetts
  { lat: 40.7128, lng: -74.0060 }, // New York
  { lat: 39.2904, lng: -76.6122 }, // Maryland
  { lat: 38.9072, lng: -77.0369 }, // DC
  { lat: 36.8508, lng: -76.2859 }, // Virginia
  { lat: 34.2257, lng: -77.9447 }, // North Carolina
  { lat: 32.0835, lng: -81.0998 }, // Georgia
  { lat: 25.7617, lng: -80.1918 }, // Miami, FL
];

export const Dashboard: React.FC = () => {
  const [data, setData] = useState([]);
  const [usgsData, setUsgsData] = useState([]);
  const [prediction, setPrediction] = useState<any>(null);
  const [mapProvider, setMapProvider] = useState<'google' | 'openlayers'>('google');
  const [loading, setLoading] = useState(false);

  const googleMapsApiKey = process.env.REACT_APP_GOOGLE_MAPS_API_KEY || '';

  useEffect(() => {
    const fetchData = async () => {
      setLoading(true);
      try {
        const coastalResponse = await fetchCoastalData();
        setData(coastalResponse.data);

        const usgsResponse = await fetchUsgsCoastalData();
        setUsgsData(usgsResponse.data);
      } catch (error) {
        console.error('Error fetching data:', error);
      } finally {
        setLoading(false);
      }
    };

    fetchData();
  }, []);

  const handlePredict = async (formData: any) => {
    setLoading(true);
    try {
      const response = await predictCoastalChange(formData);
      setPrediction(response.data);
    } catch (error) {
      console.error('Error making prediction:', error);
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="container py-4">
      <h1 className="mb-4">Coastal Change Prediction System</h1>

      <div className="card shadow-sm mb-4">
        <div className="card-body">
          <h2 className="card-title">US East Coastline Map</h2>
          <p className="text-muted mb-3">
            View coastal erosion data from USGS and make predictions about future changes.
          </p>

          <MapSelector
            activeProvider={mapProvider}
            onProviderChange={setMapProvider}
          />

          {mapProvider === 'google' ? (
            <LoadScript googleMapsApiKey={googleMapsApiKey}>
              <GoogleMap
                mapContainerStyle={mapContainerStyle}
                center={{ lat: 36.8508, lng: -76.2859 }} // Centered on Virginia
                zoom={5}
              >
                <Polyline
                  path={eastCoastPath}
                  options={{
                    strokeColor: '#0d6efd',
                    strokeOpacity: 0.8,
                    strokeWeight: 4,
                  }}
                />
              </GoogleMap>
            </LoadScript>
          ) : (
            <OpenLayersMap usgsLayerVisible={true} />
          )}

          <div className="mt-2 text-end">
            <small className="text-muted">
              Data source: <a href="https://www.usgs.gov/apps/coastalsciencenavigator/productdetails.html?id=44" target="_blank" rel="noopener noreferrer">USGS Coastal Science Navigator</a>
            </small>
          </div>
        </div>
      </div>

      <div className="row">
        <div className="col-md-8">
          <h2 className="mb-3">Coastal Data</h2>
          {loading && <div className="alert alert-info">Loading data...</div>}
          <CoastalDataTable data={data} />
        </div>

        <div className="col-md-4">
          <h2 className="mb-3">Predict Coastal Change</h2>
          <PredictionForm onPredict={handlePredict} isLoading={loading} />

          {prediction && (
            <div className="card mt-4">
              <div className="card-body">
                <h3 className="card-title h5">Prediction Result</h3>
                <pre className="bg-light p-3 rounded" style={{ overflow: 'auto', maxHeight: '200px' }}>
                  {JSON.stringify(prediction, null, 2)}
                </pre>
              </div>
            </div>
          )}
        </div>
      </div>

      {usgsData.length > 0 && (
        <div className="mt-4">
          <h2>USGS Coastal Erosion Data</h2>
          <div className="table-responsive">
            <table className="table table-striped table-hover">
              <thead className="table-light">
                <tr>
                  <th>Location</th>
                  <th>Year</th>
                  <th>Erosion Rate (m/yr)</th>
                  <th>Confidence</th>
                </tr>
              </thead>
              <tbody>
                {usgsData.map((item: any, index) => (
                  <tr key={index}>
                    <td>{item.location}</td>
                    <td>{item.year}</td>
                    <td>{item.erosionRate}</td>
                    <td>{item.confidence}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </div>
      )}
    </div>
  );
};
