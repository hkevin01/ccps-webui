package com.clr.service;

import static org.junit.jupiter.api.Assertions.*;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import com.clr.model.CoastalData;
import com.clr.model.PredictionResult;
import com.clr.service.PredictionService;

@SpringBootTest(classes = com.ccps.CcpsBackendApplication.class)
class PredictionServiceTest {

    @Autowired
    private PredictionService predictionService;

    @Test
    void testPredictReturnsExpectedLikelihood() {
        // Arrange
        CoastalData data = new CoastalData();
        data.setRegion("TestRegion");
        data.setDate("2025-01-01");
        data.setSeaLevel(1.5);
        data.setErosionRate(0.8);
        data.setPrecipitation(2.3);

        // Act
        PredictionResult result = predictionService.predict(data);

        // Assert
        assertEquals("TestRegion", result.getRegion());
        assertEquals("2025-01-01", result.getDate());
        assertTrue(result.getLikelihood() >= 0.0 && result.getLikelihood() <= 1.0);
    }
}