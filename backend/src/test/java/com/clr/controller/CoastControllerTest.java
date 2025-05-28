package com.clr.controller;

import com.clr.ClrBackendApplication;
import com.clr.model.CoastalData;
import com.clr.model.PredictionResult;
import com.clr.service.PredictionService;
import com.clr.repository.CoastalDataRepository;
import com.clr.repository.PredictionResultRepository;
import org.junit.jupiter.api.Test;
import org.mockito.Mockito;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.http.MediaType;
import org.springframework.security.test.context.support.WithMockUser;
import org.springframework.test.web.servlet.MockMvc;

import java.util.Collections;

import static org.mockito.ArgumentMatchers.any;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@SpringBootTest(classes = ClrBackendApplication.class)
class CoastControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @MockBean
    private CoastalDataRepository coastalDataRepository;
    @MockBean
    private PredictionService predictionService;
    @MockBean
    private PredictionResultRepository predictionResultRepository;

    @Test
    @WithMockUser(roles = "USER")
    void testGetCoastalData() throws Exception {
        Mockito.when(coastalDataRepository.findAll()).thenReturn(Collections.emptyList());
        mockMvc.perform(get("/api/coast/data"))
                .andExpect(status().isOk())
                .andExpect(content().json("[]"));
    }

    @Test
    @WithMockUser(roles = "USER")
    void testGetCoastalDataWithRegion() throws Exception {
        CoastalData data = new CoastalData();
        data.setRegion("RegionA");
        Mockito.when(coastalDataRepository.findByRegion("RegionA")).thenReturn(Collections.singletonList(data));
        mockMvc.perform(get("/api/coast/data?region=RegionA"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$[0].region").value("RegionA"));
    }

    @Test
    @WithMockUser(roles = "USER")
    void testPredict() throws Exception {
        CoastalData data = new CoastalData();
        data.setRegion("TestRegion");
        data.setDate("2024-01-01");
        data.setSeaLevel(1.0);
        data.setErosionRate(2.0);
        data.setPrecipitation(3.0);

        PredictionResult result = new PredictionResult();
        result.setRegion("TestRegion");
        result.setDate("2024-01-01");
        result.setLikelihood(0.5);

        Mockito.when(predictionService.predict(any(CoastalData.class))).thenReturn(result);

        String json = "{\"region\":\"TestRegion\",\"date\":\"2024-01-01\",\"seaLevel\":1.0,\"erosionRate\":2.0,\"precipitation\":3.0}";

        mockMvc.perform(post("/api/coast/predict")
                .contentType(MediaType.APPLICATION_JSON)
                .content(json))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.region").value("TestRegion"))
                .andExpect(jsonPath("$.likelihood").value(0.5));
    }

    @Test
    @WithMockUser(roles = "USER")
    void testPredictSavesResult() throws Exception {
        CoastalData data = new CoastalData();
        data.setRegion("SaveRegion");
        data.setDate("2024-02-02");
        data.setSeaLevel(2.0);
        data.setErosionRate(3.0);
        data.setPrecipitation(4.0);

        PredictionResult result = new PredictionResult();
        result.setRegion("SaveRegion");
        result.setDate("2024-02-02");
        result.setLikelihood(0.7);

        Mockito.when(predictionService.predict(any(CoastalData.class))).thenReturn(result);

        String json = "{\"region\":\"SaveRegion\",\"date\":\"2024-02-02\",\"seaLevel\":2.0,\"erosionRate\":3.0,\"precipitation\":4.0}";

        mockMvc.perform(post("/api/coast/predict")
                .contentType(MediaType.APPLICATION_JSON)
                .content(json))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.region").value("SaveRegion"))
                .andExpect(jsonPath("$.likelihood").value(0.7));

        Mockito.verify(predictionResultRepository).save(result);
    }

    @Test
    void testUnauthorizedAccess() throws Exception {
        mockMvc.perform(get("/api/coast/data"))
                .andExpect(status().isUnauthorized());
        mockMvc.perform(post("/api/coast/predict")
                .contentType(MediaType.APPLICATION_JSON)
                .content("{}"))
                .andExpect(status().isUnauthorized());
    }

    @Test
    @WithMockUser(roles = "USER")
    void testGetCoastalDataWithEmptyRegionParam() throws Exception {
        Mockito.when(coastalDataRepository.findAll()).thenReturn(Collections.emptyList());
        mockMvc.perform(get("/api/coast/data?region="))
                .andExpect(status().isOk())
                .andExpect(content().json("[]"));
    }

    @Test
    @WithMockUser(roles = "USER")
    void testPredictWithInvalidJson() throws Exception {
        String invalidJson = "{\"region\":\"TestRegion\""; // malformed JSON
        mockMvc.perform(post("/api/coast/predict")
                .contentType(MediaType.APPLICATION_JSON)
                .content(invalidJson))
                .andExpect(status().isBadRequest());
    }

    @Test
    @WithMockUser(roles = "USER")
    void testPredictWithMissingFields() throws Exception {
        String json = "{\"region\":\"TestRegion\"}";
        // Depending on your controller's validation, this may be 400 or 200
        mockMvc.perform(post("/api/coast/predict")
                .contentType(MediaType.APPLICATION_JSON)
                .content(json))
                .andExpect(status().isBadRequest());
    }

    @Test
    @WithMockUser(roles = "USER")
    void testPredictServiceThrowsException() throws Exception {
        Mockito.when(predictionService.predict(any(CoastalData.class))).thenThrow(new RuntimeException("Prediction failed"));
        String json = "{\"region\":\"TestRegion\",\"date\":\"2024-01-01\",\"seaLevel\":1.0,\"erosionRate\":2.0,\"precipitation\":3.0}";
        mockMvc.perform(post("/api/coast/predict")
                .contentType(MediaType.APPLICATION_JSON)
                .content(json))
                .andExpect(status().is5xxServerError());
    }
}
