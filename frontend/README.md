# ccps-webui Frontend

## Interactive Map

This frontend uses the Google Maps API to display the US East Coastline and a dashboard for coastal data and predictions.

### Setup

1. Get a Google Maps JavaScript API key: https://console.cloud.google.com/apis/library/maps-backend.googleapis.com
2. Add your key to `frontend/.env`:
   ```
   REACT_APP_GOOGLE_MAPS_API_KEY=your_google_maps_api_key_here
   ```
3. Install dependencies:
   ```
   npm install
   ```
4. Start the app:
   ```
   npm start
   ```

You should see an interactive map with the US East Coastline and a dashboard.
