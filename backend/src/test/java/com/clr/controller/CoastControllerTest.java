package com.clr.controller;

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

@SpringBootTest
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
}
