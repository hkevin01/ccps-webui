package com.clr.repository;

import com.clr.model.CoastalData;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.List;

public interface CoastalDataRepository extends JpaRepository<CoastalData, Long> {
    List<CoastalData> findByRegion(String region);
}
