package com.clr.service;

import com.clr.model.UsgsCoastalDataset;
import com.clr.repository.UsgsCoastalDatasetRepository;
import jakarta.annotation.PostConstruct;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.web.client.RestTemplateBuilder;
import org.springframework.core.io.Resource;
import org.springframework.core.io.ResourceLoader;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestTemplate;

import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStreamReader;
import java.net.URL;
import java.time.LocalDate;
import java.time.format.DateTimeFormatter;
import java.util.ArrayList;
import java.util.List;
import java.util.zip.ZipEntry;
import java.util.zip.ZipInputStream;

@Service
@RequiredArgsConstructor
@Slf4j
public class UsgsDataImportService {

    private final UsgsCoastalDatasetRepository datasetRepository;
    private final ResourceLoader resourceLoader;
    private final RestTemplate restTemplate;
    
    @Value("${usgs.data.import.enabled:true}")
    private boolean importEnabled;
    
    @Value("${usgs.data.url:https://cmgds.marine.usgs.gov/data/whcmsc/data-release/doi-F73J3B0B/data/shorelines/mass_shorelines_1800s_to_2018.csv}")
    private String usgsDataUrl;
    
    public UsgsDataImportService(UsgsCoastalDatasetRepository datasetRepository, ResourceLoader resourceLoader) {
        this.datasetRepository = datasetRepository;
        this.resourceLoader = resourceLoader;
        this.restTemplate = new RestTemplateBuilder().build();
    }

    /**
     * Import USGS data on application startup if enabled and the database is empty
     */
    @PostConstruct
    public void initializeData() {
        if (importEnabled && datasetRepository.count() == 0) {
            log.info("Initializing USGS coastal data from {}", usgsDataUrl);
            try {
                importDataFromUrl();
            } catch (Exception e) {
                log.error("Failed to initialize USGS data", e);
            }
        }
    }
    
    /**
     * Scheduled task to refresh USGS data weekly
     */
    @Scheduled(cron = "0 0 0 * * 0") // Every Sunday at midnight
    public void refreshData() {
        if (importEnabled) {
            log.info("Refreshing USGS coastal data");
            try {
                importDataFromUrl();
            } catch (Exception e) {
                log.error("Failed to refresh USGS data", e);
            }
        }
    }
    
    /**
     * Import data from the USGS data URL
     */
    public void importDataFromUrl() {
        try {
            log.info("Importing USGS data from URL: {}", usgsDataUrl);
            
            // For CSV files
            if (usgsDataUrl.endsWith(".csv")) {
                Resource resource = resourceLoader.getResource(usgsDataUrl);
                importCsvData(resource);
            } 
            // For ZIP files
            else if (usgsDataUrl.endsWith(".zip")) {
                URL url = new URL(usgsDataUrl);
                try (ZipInputStream zipIn = new ZipInputStream(url.openStream())) {
                    ZipEntry entry;
                    while ((entry = zipIn.getNextEntry()) != null) {
                        if (entry.getName().endsWith(".csv")) {
                            importCsvData(zipIn);
                        }
                    }
                }
            }
            
            log.info("USGS data import completed successfully");
        } catch (Exception e) {
            log.error("Error importing USGS data", e);
            throw new RuntimeException("Failed to import USGS data", e);
        }
    }
    
    /**
     * Import data from a CSV resource
     */
    private void importCsvData(Resource resource) throws IOException {
        try (BufferedReader reader = new BufferedReader(new InputStreamReader(resource.getInputStream()))) {
            processCSV(reader);
        }
    }
    
    /**
     * Import data from a ZIP input stream
     */
    private void importCsvData(ZipInputStream zipIn) throws IOException {
        try (BufferedReader reader = new BufferedReader(new InputStreamReader(zipIn))) {
            processCSV(reader);
        }
    }
    
    /**
     * Process CSV data from a reader
     */
    private void processCSV(BufferedReader reader) throws IOException {
        String line;
        String[] headers = null;
        List<UsgsCoastalDataset> datasets = new ArrayList<>();
        
        // Read header line
        if ((line = reader.readLine()) != null) {
            headers = line.split(",");
        }
        
        // Process data lines
        int count = 0;
        while ((line = reader.readLine()) != null) {
            String[] values = line.split(",");
            UsgsCoastalDataset dataset = parseDatasetFromCsv(headers, values);
            if (dataset != null) {
                datasets.add(dataset);
                count++;
            }
            
            // Batch save every 1000 records
            if (count % 1000 == 0) {
                datasetRepository.saveAll(datasets);
                datasets.clear();
                log.info("Imported {} USGS coastal data records", count);
            }
        }
        
        // Save any remaining records
        if (!datasets.isEmpty()) {
            datasetRepository.saveAll(datasets);
        }
        
        log.info("Total USGS coastal data records imported: {}", count);
    }
    
    /**
     * Parse a dataset from CSV values
     */
    private UsgsCoastalDataset parseDatasetFromCsv(String[] headers, String[] values) {
        if (headers == null || values.length < headers.length) {
            return null;
        }
        
        UsgsCoastalDataset dataset = new UsgsCoastalDataset();
        
        for (int i = 0; i < headers.length; i++) {
            String header = headers[i].trim();
            String value = i < values.length ? values[i].trim() : "";
            
            switch (header.toLowerCase()) {
                case "transect_id":
                case "transectid":
                    dataset.setTransectId(value);
                    break;
                case "latitude":
                case "lat":
                    dataset.setLatitude(parseDouble(value));
                    break;
                case "longitude":
                case "long":
                case "lon":
                    dataset.setLongitude(parseDouble(value));
                    break;
                case "location":
                    dataset.setLocation(value);
                    break;
                case "region":
                    dataset.setRegion(value);
                    break;
                case "date":
                case "measurement_date":
                    dataset.setMeasurementDate(parseDate(value));
                    break;
                case "shore_pos_uncert":
                case "uncertainty":
                    dataset.setShorePosUncert(parseDouble(value));
                    break;
                case "shoreline_position":
                case "position":
                    dataset.setShorelinePosition(parseDouble(value));
                    break;
                case "shoreline_change":
                case "change":
                    dataset.setShorelineChange(parseDouble(value));
                    break;
                case "erosion_rate":
                case "rate":
                    dataset.setErosionRate(parseDouble(value));
                    break;
                case "metadata":
                    dataset.setMetadata(value);
                    break;
                default:
                    // Add other fields to metadata
                    String currentMetadata = dataset.getMetadata();
                    String newMetadata = (currentMetadata == null ? "" : currentMetadata + "; ") 
                            + header + ": " + value;
                    dataset.setMetadata(newMetadata);
            }
        }
        
        return dataset;
    }
    
    private Double parseDouble(String value) {
        try {
            return Double.parseDouble(value);
        } catch (NumberFormatException e) {
            return null;
        }
    }
    
    private LocalDate parseDate(String value) {
        try {
            // Try different date formats
            if (value.matches("\\d{4}-\\d{2}-\\d{2}")) {
                return LocalDate.parse(value);
            } else if (value.matches("\\d{2}/\\d{2}/\\d{4}")) {
                return LocalDate.parse(value, DateTimeFormatter.ofPattern("MM/dd/yyyy"));
            } else if (value.matches("\\d{4}")) {
                // Just a year, use January 1
                return LocalDate.of(Integer.parseInt(value), 1, 1);
            }
        } catch (Exception e) {
            // Ignore parsing errors
        }
        return null;
    }
}
