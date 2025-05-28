import React, { useEffect, useState } from 'react';
import { fetchCoastalData, predictCoastalChange } from '../services/api';
import { CoastalDataTable } from '../components/CoastalDataTable';
import { PredictionForm } from '../components/PredictionForm';

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
      <h2>Coastal Data</h2>
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
