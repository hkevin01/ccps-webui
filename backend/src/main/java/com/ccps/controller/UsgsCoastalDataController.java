package com.clr.controller;

import com.clr.model.UsgsCoastalData;
import com.clr.service.UsgsDataService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/usgs")
@RequiredArgsConstructor
public class UsgsCoastalDataController {

    private final UsgsDataService usgsDataService;
    
    @GetMapping
    public ResponseEntity<List<UsgsCoastalData>> getAllUsgsData() {
        return ResponseEntity.ok(usgsDataService.getAllUsgsData());
    }
    
    @GetMapping("/locations")
    public ResponseEntity<List<String>> getAvailableLocations() {
        return ResponseEntity.ok(usgsDataService.getAvailableLocations());
    }
    
    @GetMapping("/location/{location}")
    public ResponseEntity<List<UsgsCoastalData>> getDataByLocation(@PathVariable String location) {
        return ResponseEntity.ok(usgsDataService.getDataByLocation(location));
    }
    
    @GetMapping("/years")
    public ResponseEntity<List<UsgsCoastalData>> getDataByYearRange(
            @RequestParam(required = false, defaultValue = "1900") Integer startYear,
            @RequestParam(required = false, defaultValue = "2023") Integer endYear) {
        return ResponseEntity.ok(usgsDataService.getDataByYearRange(startYear, endYear));
    }
    
    @GetMapping("/high-erosion")
    public ResponseEntity<List<UsgsCoastalData>> getHighErosionAreas(
            @RequestParam(required = false, defaultValue = "2.0") Double threshold) {
        return ResponseEntity.ok(usgsDataService.getHighErosionAreas(threshold));
    }
    
    @PostMapping("/update")
    public ResponseEntity<Map<String, String>> triggerUpdate() {
        usgsDataService.updateUsgsData();
        return ResponseEntity.ok(Map.of("status", "USGS data update triggered"));
    }
}
