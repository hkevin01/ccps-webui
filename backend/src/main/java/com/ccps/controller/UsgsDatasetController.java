package com.clr.controller;

import com.clr.model.UsgsCoastalDataset;
import com.clr.repository.UsgsCoastalDatasetRepository;
import com.clr.service.UsgsDataImportService;
import lombok.RequiredArgsConstructor;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDate;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/usgs-datasets")
@RequiredArgsConstructor
public class UsgsDatasetController {

    private final UsgsCoastalDatasetRepository datasetRepository;
    private final UsgsDataImportService dataImportService;

    @GetMapping
    public ResponseEntity<List<UsgsCoastalDataset>> getAllDatasets(
            @RequestParam(required = false) Integer page,
            @RequestParam(required = false, defaultValue = "100") Integer size) {
        // If pagination is requested, return paginated results
        if (page != null) {
            int startIndex = page * size;
            List<UsgsCoastalDataset> datasets = datasetRepository.findAll();
            int endIndex = Math.min(startIndex + size, datasets.size());
            
            if (startIndex < datasets.size()) {
                return ResponseEntity.ok(datasets.subList(startIndex, endIndex));
            } else {
                return ResponseEntity.ok(List.of());
            }
        }
        
        // Otherwise return all (with default limit of 1000)
        List<UsgsCoastalDataset> datasets = datasetRepository.findAll();
        return ResponseEntity.ok(datasets.subList(0, Math.min(1000, datasets.size())));
    }
    
    @GetMapping("/count")
    public ResponseEntity<Map<String, Long>> getCount() {
        return ResponseEntity.ok(Map.of("count", datasetRepository.count()));
    }
    
    @GetMapping("/regions")
    public ResponseEntity<List<String>> getRegions() {
        return ResponseEntity.ok(datasetRepository.findDistinctRegions());
    }
    
    @GetMapping("/locations")
    public ResponseEntity<List<String>> getLocations() {
        return ResponseEntity.ok(datasetRepository.findDistinctLocations());
    }
    
    @GetMapping("/region/{region}")
    public ResponseEntity<List<UsgsCoastalDataset>> getByRegion(@PathVariable String region) {
        return ResponseEntity.ok(datasetRepository.findByRegionIgnoreCase(region));
    }
    
    @GetMapping("/location/{location}")
    public ResponseEntity<List<UsgsCoastalDataset>> getByLocation(@PathVariable String location) {
        return ResponseEntity.ok(datasetRepository.findByLocationContainingIgnoreCase(location));
    }
    
    @GetMapping("/date-range")
    public ResponseEntity<List<UsgsCoastalDataset>> getByDateRange(
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate start,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate end) {
        return ResponseEntity.ok(datasetRepository.findByMeasurementDateBetween(start, end));
    }
    
    @GetMapping("/high-erosion")
    public ResponseEntity<List<UsgsCoastalDataset>> getHighErosionAreas(
            @RequestParam(required = false, defaultValue = "1.0") Double threshold) {
        return ResponseEntity.ok(datasetRepository.findHighErosionAreas(threshold));
    }
    
    @GetMapping("/nearby")
    public ResponseEntity<List<UsgsCoastalDataset>> getNearbyMeasurements(
            @RequestParam Double longitude,
            @RequestParam Double latitude,
            @RequestParam(defaultValue = "10.0") Double radiusKm) {
        return ResponseEntity.ok(datasetRepository.findNearbyMeasurements(longitude, latitude, radiusKm));
    }
    
    @PostMapping("/import")
    public ResponseEntity<Map<String, String>> triggerImport() {
        try {
            dataImportService.importDataFromUrl();
            return ResponseEntity.ok(Map.of("status", "Import completed successfully"));
        } catch (Exception e) {
            return ResponseEntity.internalServerError().body(Map.of("status", "Import failed: " + e.getMessage()));
        }
    }
}
