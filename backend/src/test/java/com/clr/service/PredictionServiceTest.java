package com.clr.service;

import com.clr.model.CoastalData;
import com.clr.model.PredictionResult;
import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.*;

class PredictionServiceTest {

    private final PredictionService predictionService = new PredictionService();

    @Test
    void testPredictReturnsExpectedLikelihood() {
        CoastalData data = new CoastalData();
        data.setRegion("TestRegion");
        data.setDate("2024-01-01");
        data.setSeaLevel(1.0);
        data.setErosionRate(2.0);
        data.setPrecipitation(3.0);

        PredictionResult result = predictionService.predict(data);

        assertEquals("TestRegion", result.getRegion());
        assertEquals("2024-01-01", result.getDate());
        assertTrue(result.getLikelihood() >= 0.0 && result.getLikelihood() <= 1.0);
    }
}
