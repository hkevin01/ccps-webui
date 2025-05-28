package com.clr.service;

import com.clr.model.CoastalData;
import com.clr.model.PredictionResult;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;

/**
 * Service for predicting coastal change likelihood.
 */
@Service
public class PredictionService {
    private static final Logger logger = LoggerFactory.getLogger(PredictionService.class);

    // Example coefficients for a linear regression model
    // likelihood = intercept + a*seaLevel + b*erosionRate + c*precipitation
    private static final double INTERCEPT = 0.1;
    private static final double COEF_SEA_LEVEL = 0.4;
    private static final double COEF_EROSION_RATE = 0.3;
    private static final double COEF_PRECIPITATION = 0.2;

    /**
     * Predicts the likelihood of coastal change for the given data.
     * @param data CoastalData input
     * @return PredictionResult with likelihood [0,1]
     */
    public PredictionResult predict(CoastalData data) {
        logger.debug("Predicting for region={}, date={}", data.getRegion(), data.getDate());
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

        logger.info("Prediction for region={} date={}: likelihood={}", data.getRegion(), data.getDate(), likelihood);

        return result;
    }
}
