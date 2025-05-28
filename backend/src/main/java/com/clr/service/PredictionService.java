package com.clr.service;

import com.clr.model.CoastalData;
import com.clr.model.PredictionResult;
import org.springframework.stereotype.Service;

@Service
public class PredictionService {
    // Example coefficients for a linear regression model
    // likelihood = intercept + a*seaLevel + b*erosionRate + c*precipitation
    private static final double INTERCEPT = 0.1;
    private static final double COEF_SEA_LEVEL = 0.4;
    private static final double COEF_EROSION_RATE = 0.3;
    private static final double COEF_PRECIPITATION = 0.2;

    public PredictionResult predict(CoastalData data) {
        PredictionResult result = new PredictionResult();
        result.setRegion(data.getRegion());
        result.setDate(data.getDate());

        double likelihood = INTERCEPT
                + COEF_SEA_LEVEL * data.getSeaLevel()
                + COEF_EROSION_RATE * data.getErosionRate()
                + COEF_PRECIPITATION * data.getPrecipitation();

        // Clamp to [0, 1]
        likelihood = Math.max(0.0, Math.min(1.0, likelihood));
        result.setLikelihood(likelihood);

        return result;
    }
}
