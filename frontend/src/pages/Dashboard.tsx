import React, { useState, useEffect } from 'react';
import { GoogleMap, LoadScript, Polyline } from '@react-google-maps/api';
import { fetchCoastalData, predictCoastalChange } from '../services/api';
import { CoastalDataTable } from '../components/CoastalDataTable';
import { PredictionForm } from '../components/PredictionForm';

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
  const [prediction, setPrediction] = useState<any>(null);

  useEffect(() => {
    fetchCoastalData().then(res => setData(res.data));
  }, []);

  const handlePredict = (formData: any) => {
    predictCoastalChange(formData).then(res => setPrediction(res.data));
  };

  return (
    <div>
      <h2>US East Coastline Map</h2>
      <LoadScript googleMapsApiKey={process.env.REACT_APP_GOOGLE_MAPS_API_KEY || ''}>
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
      <h2 className="mt-4">Coastal Data</h2>
      <CoastalDataTable data={data} />
      <h2>Predict Coastal Change</h2>
      <PredictionForm onPredict={handlePredict} />
      {prediction && (
        <div>
          <h3>Prediction Result</h3>
          <pre>{JSON.stringify(prediction, null, 2)}</pre>
        </div>
      )}
    </div>
  );
};
