package com.clr.repository;

import com.clr.model.CoastalData;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.List;

@Repository
public interface CoastalDataRepository extends JpaRepository<CoastalData, Long> {
    List<CoastalData> findByRegion(String region);
}
