import React, { useState, useEffect } from 'react';
import { fetchCoastalData, predictCoastalChange } from '../services/api';
import { CoastalDataTable } from '../components/CoastalDataTable';
import { PredictionForm } from '../components/PredictionForm';
import OLMap from '../components/OLMap';
import '../styles/map-styles.css';

export const Dashboard: React.FC = () => {
  const [data, setData] = useState([]);
  const [prediction, setPrediction] = useState<any>(null);
  const [loading, setLoading] = useState(false);
  const [usgsLayerVisible, setUsgsLayerVisible] = useState(true);

  useEffect(() => {
    fetchCoastalData().then(res => setData(res.data));
  }, []);

  const handlePredict = async (formData: any) => {
    setLoading(true);
    try {
      const res = await predictCoastalChange(formData);
      setPrediction(res.data);
    } finally {
      setLoading(false);
    }
  };

  return (
    <div>
      <h2>US East Coastline Map</h2>
      <div className="mb-3">
        <div className="form-check form-switch">
          <input
            className="form-check-input"
            type="checkbox"
            id="usgsLayerSwitch"
            checked={usgsLayerVisible}
            onChange={(e) => setUsgsLayerVisible(e.target.checked)}
          />
          <label className="form-check-label" htmlFor="usgsLayerSwitch">
            Show USGS Coastal Change Data
          </label>
        </div>
      </div>

      {/* Use OpenLayers Map with Google Maps as a layer */}
      <OLMap usgsLayerVisible={usgsLayerVisible} />

      <h2 className="mt-4">Coastal Data</h2>
      <CoastalDataTable data={data} />

      <h2>Predict Coastal Change</h2>
      <PredictionForm onPredict={handlePredict} isLoading={loading} />

      {prediction && (
        <div>
          <h3>Prediction Result</h3>
          <pre>{JSON.stringify(prediction, null, 2)}</pre>
        </div>
      )}
    </div>
  );
};
