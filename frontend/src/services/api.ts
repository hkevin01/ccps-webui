import axios from 'axios';

const API_BASE_URL = '/api';

export const fetchCoastalData = () => {
  return axios.get(`${API_BASE_URL}/coastal-data`);
};

export const predictCoastalChange = (data: any) => {
  return axios.post(`${API_BASE_URL}/predict`, data);
};

export const fetchUsgsCoastalData = () => {
  return axios.get(`${API_BASE_URL}/usgs`);
};

export const fetchUsgsLocationData = (location: string) => {
  return axios.get(`${API_BASE_URL}/usgs/location/${encodeURIComponent(location)}`);
};

export const fetchUsgsHighErosionAreas = (threshold = 2.0) => {
  return axios.get(`${API_BASE_URL}/usgs/high-erosion`, {
    params: { threshold }
  });
};

export const fetchUsgsDataByYearRange = (startYear: number, endYear: number) => {
  return axios.get(`${API_BASE_URL}/usgs/years`, {
    params: { startYear, endYear }
  });
};

export const fetchUsgsLocations = () => {
  return axios.get(`${API_BASE_URL}/usgs/locations`);
};

// Add new USGS dataset API functions
export const fetchUsgsDatasets = (page = 0, size = 100) => {
  return axios.get(`${API_BASE_URL}/usgs-datasets`, {
    params: { page, size }
  });
};

export const fetchUsgsDatasetCount = () => {
  return axios.get(`${API_BASE_URL}/usgs-datasets/count`);
};

export const fetchUsgsDatasetRegions = () => {
  return axios.get(`${API_BASE_URL}/usgs-datasets/regions`);
};

export const fetchUsgsDatasetsByRegion = (region: string) => {
  return axios.get(`${API_BASE_URL}/usgs-datasets/region/${encodeURIComponent(region)}`);
};

export const fetchUsgsDatasetsByDateRange = (startDate: string, endDate: string) => {
  return axios.get(`${API_BASE_URL}/usgs-datasets/date-range`, {
    params: { start: startDate, end: endDate }
  });
};

export const fetchHighErosionAreas = (threshold = 1.0) => {
  return axios.get(`${API_BASE_URL}/usgs-datasets/high-erosion`, {
    params: { threshold }
  });
};

export const fetchNearbyMeasurements = (longitude: number, latitude: number, radiusKm = 10) => {
  return axios.get(`${API_BASE_URL}/usgs-datasets/nearby`, {
    params: { longitude, latitude, radiusKm }
  });
};
