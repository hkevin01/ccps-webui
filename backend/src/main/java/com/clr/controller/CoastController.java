package com.clr.controller;

import com.clr.model.CoastalData;
import com.clr.model.PredictionResult;
import com.clr.repository.CoastalDataRepository;
import com.clr.repository.PredictionResultRepository;
import com.clr.service.PredictionService;
import java.util.List;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/coast")
public class CoastController {
    @Autowired
    private CoastalDataRepository coastalDataRepository;
    @Autowired
    private PredictionService predictionService;
    @Autowired
    private PredictionResultRepository predictionResultRepository;

    @GetMapping("/data")
    @PreAuthorize("hasAnyRole('ADMIN', 'USER')")
    public List<CoastalData> getCoastalData(@RequestParam(required = false) String region) {
        if (region != null) {
            return coastalDataRepository.findByRegion(region);
        }
        return coastalDataRepository.findAll();
    }

    @PostMapping("/predict")
    @PreAuthorize("hasAnyRole('ADMIN', 'USER')")
    public PredictionResult predict(@RequestBody CoastalData data) {
        PredictionResult result = predictionService.predict(data);
        predictionResultRepository.save(result);
        return result;
    }
}
