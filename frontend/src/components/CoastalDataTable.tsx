import React, { useState } from 'react';
import { Line } from 'react-chartjs-2';
import {
  Chart as ChartJS,
  LineElement,
  PointElement,
  CategoryScale,
  LinearScale,
  Legend,
  Tooltip,
} from 'chart.js';

ChartJS.register(LineElement, PointElement, CategoryScale, LinearScale, Legend, Tooltip);

type CoastalData = {
  id: number;
  region: string;
  date: string;
  seaLevel: number;
  erosionRate: number;
  precipitation: number;
};

type Props = {
  data: CoastalData[];
};

export const CoastalDataTable: React.FC<Props> = ({ data }) => {
  // Filter state
  const [regionFilter, setRegionFilter] = useState('');
  const [dateFrom, setDateFrom] = useState('');
  const [dateTo, setDateTo] = useState('');

  // Get unique regions for filter dropdown
  const regions = Array.from(new Set(data.map(row => row.region)));

  // Filtering logic
  const filteredData = data.filter((row: CoastalData) => {
    const regionMatch = regionFilter ? row.region === regionFilter : true;
    const dateMatch =
      (!dateFrom || row.date >= dateFrom) &&
      (!dateTo || row.date <= dateTo);
    return regionMatch && dateMatch;
  });

  // Prepare data for charts
  const sortedData = [...filteredData].sort((a: CoastalData, b: CoastalData) => a.date.localeCompare(b.date));
  const labels = sortedData.map((row: CoastalData) => row.date);
  const seaLevels = sortedData.map((row: CoastalData) => row.seaLevel);
  const erosionRates = sortedData.map((row: CoastalData) => row.erosionRate);
  const predictionLikelihoods = sortedData.map((row: CoastalData) =>
    // Example: simple likelihood formula for visualization
    Math.max(
      0,
      Math.min(
        1,
        0.1 + 0.4 * row.seaLevel + 0.3 * row.erosionRate + 0.2 * row.precipitation
      )
    )
  );

  const chartOptions = {
    responsive: true,
    plugins: {
      legend: { display: true },
      tooltip: { enabled: true },
    },
    scales: {
      y: { beginAtZero: true, max: 1 },
    },
  };

  return (
    <div className="card shadow-sm mb-4">
      <div className="card-body">
        <form className="row g-3 mb-3">
          <div className="col-md-4">
            <label className="form-label">Region</label>
            <select
              className="form-select"
              value={regionFilter}
              onChange={e => setRegionFilter(e.target.value)}
            >
              <option value="">All</option>
              {regions.map(region => (
                <option key={region} value={region}>
                  {region}
                </option>
              ))}
            </select>
          </div>
          <div className="col-md-3">
            <label className="form-label">Date From</label>
            <input
              type="date"
              className="form-control"
              value={dateFrom}
              onChange={e => setDateFrom(e.target.value)}
            />
          </div>
          <div className="col-md-3">
            <label className="form-label">Date To</label>
            <input
              type="date"
              className="form-control"
              value={dateTo}
              onChange={e => setDateTo(e.target.value)}
            />
          </div>
          <div className="col-md-2 d-flex align-items-end">
            <button
              type="button"
              className="btn btn-outline-secondary w-100"
              onClick={() => {
                setRegionFilter('');
                setDateFrom('');
                setDateTo('');
              }}
            >
              Reset
            </button>
          </div>
        </form>
        <div className="row mb-4">
          <div className="col-md-4">
            <h6>Sea Level Trend</h6>
            <Line
              data={{
                labels,
                datasets: [
                  {
                    label: 'Sea Level',
                    data: seaLevels,
                    borderColor: '#0d6efd',
                    backgroundColor: 'rgba(13,110,253,0.1)',
                    tension: 0.3,
                  },
                ],
              }}
              options={{
                ...chartOptions,
                scales: { y: { beginAtZero: true } },
              }}
            />
          </div>
          <div className="col-md-4">
            <h6>Erosion Rate Trend</h6>
            <Line
              data={{
                labels,
                datasets: [
                  {
                    label: 'Erosion Rate',
                    data: erosionRates,
                    borderColor: '#dc3545',
                    backgroundColor: 'rgba(220,53,69,0.1)',
                    tension: 0.3,
                  },
                ],
              }}
              options={{
                ...chartOptions,
                scales: { y: { beginAtZero: true } },
              }}
            />
          </div>
          <div className="col-md-4">
            <h6>Prediction Likelihood</h6>
            <Line
              data={{
                labels,
                datasets: [
                  {
                    label: 'Likelihood',
                    data: predictionLikelihoods,
                    borderColor: '#198754',
                    backgroundColor: 'rgba(25,135,84,0.1)',
                    tension: 0.3,
                  },
                ],
              }}
              options={chartOptions}
            />
          </div>
        </div>
        <div className="table-responsive">
          <table className="table table-striped table-hover align-middle">
            <thead className="table-light">
              <tr>
                <th>Region</th>
                <th>Date</th>
                <th>Sea Level</th>
                <th>Erosion Rate</th>
                <th>Precipitation</th>
              </tr>
            </thead>
            <tbody>
              {filteredData.length === 0 ? (
                <tr>
                  <td colSpan={5} className="text-center text-muted">
                    No data found.
                  </td>
                </tr>
              ) : (
                filteredData.map((row: CoastalData) => (
                  <tr key={row.id}>
                    <td>{row.region}</td>
                    <td>{row.date}</td>
                    <td>{row.seaLevel}</td>
                    <td>{row.erosionRate}</td>
                    <td>{row.precipitation}</td>
                  </tr>
                ))
              )}
            </tbody>
          </table>
        </div>
      </div>
    </div>
  );
};
