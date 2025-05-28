import axios from 'axios';

const API_BASE = '/api/coast';

export const fetchCoastalData = (region?: string) =>
  axios.get(`${API_BASE}/data`, { params: region ? { region } : {} });

export const predictCoastalChange = (data: any) =>
  axios.post(`${API_BASE}/predict`, data);
