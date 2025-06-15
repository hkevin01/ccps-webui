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
  const [dataLoaded, setDataLoaded] = useState(false);

  useEffect(() => {
    setLoading(true);
    fetchCoastalData()
      .then(res => {
        setData(res.data);
        setDataLoaded(true);
      })
      .catch(err => console.error("Error fetching coastal data:", err))
      .finally(() => setLoading(false));
  }, []);

  const handlePredict = async (formData: any) => {
    setLoading(true);
    try {
      const res = await predictCoastalChange(formData);
      setPrediction(res.data);
    } catch (error) {
      console.error("Error making prediction:", error);
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="container py-4">
      <h1 className="mb-4">Coastal Change Prediction System</h1>

      <div className="card shadow-sm mb-4">
        <div className="card-body">
          <h2 className="card-title mb-3">Coastal Erosion Map</h2>

          <div className="d-flex flex-wrap align-items-center justify-content-between mb-3">
            <div className="form-check form-switch me-3 mb-2">
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

            <small className="text-muted mb-2">
              <a
                href="https://cmgds.marine.usgs.gov/data/whcmsc/data-release/doi-F73J3B0B/"
                target="_blank"
                rel="noopener noreferrer"
                className="text-decoration-none"
              >
                <i className="bi bi-info-circle me-1"></i>
                Massachusetts Shoreline Change Project, 1800s to 2018
              </a>
            </small>
          </div>

          <OLMap
            height="550px"
            usgsLayerVisible={usgsLayerVisible}
          />

          <div className="mt-3">
            <div className="map-legend p-2 bg-light border rounded">
              <h6 className="fw-bold mb-1">Legend</h6>
              <div className="d-flex align-items-center me-3 mb-1">
                <div style={{ width: 20, height: 10, backgroundColor: 'rgba(255,0,0,0.8)', marginRight: 8 }}></div>
                <small>Erosion (negative change)</small>
              </div>
              <div className="d-flex align-items-center">
                <div style={{ width: 20, height: 10, backgroundColor: 'rgba(0,128,0,0.8)', marginRight: 8 }}></div>
                <small>Accretion (positive change)</small>
              </div>
            </div>
          </div>
        </div>
      </div>

      <div className="row">
        <div className="col-md-8">
          <h2 className="mb-3">Coastal Data</h2>
          {loading && !dataLoaded ? (
            <div className="d-flex justify-content-center my-5">
              <div className="spinner-border text-primary" role="status">
                <span className="visually-hidden">Loading...</span>
              </div>
            </div>
          ) : (
            <CoastalDataTable data={data} />
          )}
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
    </div>
  );
};
