package com.clr.service;

import com.clr.model.UsgsCoastalData;
import com.clr.repository.UsgsCoastalDataRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.web.client.RestTemplateBuilder;
import org.springframework.http.ResponseEntity;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestTemplate;

import java.util.Arrays;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class UsgsDataService {

    private final UsgsCoastalDataRepository usgsRepository;
    private final RestTemplate restTemplate;
    
    @Value("${usgs.api.baseUrl:https://coastalmap.marine.usgs.gov/cmgp/rest/services}")
    private String usgsApiBaseUrl;
    
    public UsgsDataService(UsgsCoastalDataRepository usgsRepository, RestTemplateBuilder restTemplateBuilder) {
        this.usgsRepository = usgsRepository;
        this.restTemplate = restTemplateBuilder.build();
    }
    
    public List<UsgsCoastalData> getAllUsgsData() {
        return usgsRepository.findAll();
    }
    
    public List<UsgsCoastalData> getDataByLocation(String location) {
        return usgsRepository.findByLocationContainingIgnoreCase(location);
    }
    
    public List<UsgsCoastalData> getDataByYearRange(Integer startYear, Integer endYear) {
        return usgsRepository.findByYearBetween(startYear, endYear);
    }
    
    public List<UsgsCoastalData> getHighErosionAreas(Double threshold) {
        return usgsRepository.findHighErosionAreas(threshold);
    }
    
    public List<String> getAvailableLocations() {
        return usgsRepository.findDistinctLocations();
    }
    
    // Scheduled task to fetch and update USGS data (runs weekly)
    @Scheduled(cron = "0 0 0 * * 0") // Every Sunday at midnight
    public void updateUsgsData() {
        // Fetch data from USGS API
        String url = usgsApiBaseUrl + "/CoastalChangeHazardsPortal/ShorelineChangeRates/MapServer/query?where=1%3D1&outFields=*&f=json";
        
        try {
            ResponseEntity<Map> response = restTemplate.getForEntity(url, Map.class);
            
            if (response.getStatusCode().is2xxSuccessful() && response.getBody() != null) {
                Map<String, Object> responseBody = response.getBody();
                List<Map<String, Object>> features = (List<Map<String, Object>>) responseBody.get("features");
                
                if (features != null) {
                    List<UsgsCoastalData> usgsData = features.stream()
                        .map(this::convertFeatureToUsgsData)
                        .collect(Collectors.toList());
                    
                    usgsRepository.saveAll(usgsData);
                }
            }
        } catch (Exception e) {
            // Log error and continue
            System.err.println("Error fetching USGS data: " + e.getMessage());
        }
    }
    
    private UsgsCoastalData convertFeatureToUsgsData(Map<String, Object> feature) {
        Map<String, Object> attributes = (Map<String, Object>) feature.get("attributes");
        
        UsgsCoastalData data = new UsgsCoastalData();
        
        // Map fields from USGS data to our model
        if (attributes != null) {
            data.setLocation((String) attributes.getOrDefault("LOCATION", "Unknown"));
            data.setYear(((Number) attributes.getOrDefault("YEAR", 0)).intValue());
            data.setErosionRate(((Number) attributes.getOrDefault("EPR", 0)).doubleValue());
            data.setConfidence((String) attributes.getOrDefault("CONFIDENCE", "Medium"));
            data.setDataSource("USGS Coastal Change Hazards Portal");
            data.setDatasetName((String) attributes.getOrDefault("DATASET_NAME", "Unknown"));
            data.setMethodType((String) attributes.getOrDefault("METHOD_TYPE", "Unknown"));
            data.setUnitOfMeasure((String) attributes.getOrDefault("UNIT", "m/yr"));
            
            // Extract coordinates if available
            Map<String, Object> geometry = (Map<String, Object>) feature.get("geometry");
            if (geometry != null) {
                data.setLongitude(((Number) geometry.getOrDefault("x", 0)).doubleValue());
                data.setLatitude(((Number) geometry.getOrDefault("y", 0)).doubleValue());
            }
        }
        
        return data;
    }
}
