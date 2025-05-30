# Setting Up Google Maps API for Production

To remove the "For development purposes only" watermark from Google Maps, you need to:

1. **Create a Google Cloud Project**:
   - Go to the [Google Cloud Console](https://console.cloud.google.com/)
   - Create a new project or select an existing one

2. **Enable the Maps JavaScript API**:
   - In your Google Cloud Project, navigate to "APIs & Services" > "Library"
   - Search for "Maps JavaScript API"
   - Click on it and press "Enable"

3. **Set up billing**:
   - Google Maps requires a billing account for production use
   - In Google Cloud Console, go to "Billing"
   - Set up a billing account if you don't have one
   - Link your project to the billing account
   - Note: Google provides a $200 monthly credit, which is enough for most small to medium applications

4. **Create API credentials**:
   - Go to "APIs & Services" > "Credentials"
   - Click "Create credentials" > "API key"
   - Copy your new API key

5. **Add restrictions to your API key (recommended)**:
   - In the credentials page, edit your API key
   - Under "Application restrictions", select "HTTP referrers"
   - Add your application domains (e.g., `*.yourdomain.com/*`)
   - Under "API restrictions", select "Maps JavaScript API"
   - Save the changes

6. **Add the API key to your application**:
   - Create a `.env` file in the `frontend` directory
   - Add the following line:
     ```
     REACT_APP_GOOGLE_MAPS_API_KEY=your_api_key_here
     ```
   - Replace `your_api_key_here` with your actual API key

7. **For production deployment**:
   - Make sure the API key is set in your environment variables during build
   - For Docker: add the environment variable in your Docker Compose file or Dockerfile
   - For other deployment platforms: consult your hosting documentation

Once properly set up with billing, the "For development purposes only" watermark will be removed.

## Using OpenLayers as an Alternative

This application also supports OpenLayers, which is a free and open-source alternative to Google Maps. You can switch between the two map providers using the selector in the dashboard.

### Benefits of OpenLayers:
- Free and open-source, no API key or billing required
- No usage limits or watermarks
- Extensive customization options
- Support for many different map sources and projections

For more information, visit the [OpenLayers website](https://openlayers.org/).
