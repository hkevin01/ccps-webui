package com.clr.repository;

import static org.junit.jupiter.api.Assertions.*;
import java.util.List;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import com.clr.model.CoastalData;

@SpringBootTest(classes = com.ccps.CcpsBackendApplication.class)
class CoastalDataRepositoryTest {

    @Autowired
    private CoastalDataRepository repository;

    @Test
    void testSaveAndFindByRegion() {
        CoastalData data = new CoastalData();
        data.setRegion("TestRegion");
        data.setDate("2024-01-01");
        data.setSeaLevel(1.0);
        data.setErosionRate(2.0);
        data.setPrecipitation(3.0);

        repository.save(data);

        List<CoastalData> found = repository.findByRegion("TestRegion");
        assertFalse(found.isEmpty());
        assertEquals("TestRegion", found.get(0).getRegion());
    }
}
