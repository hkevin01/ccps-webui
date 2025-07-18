package com.clr.repository;

import com.clr.model.UsgsCoastalData;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface UsgsCoastalDataRepository extends JpaRepository<UsgsCoastalData, Long> {
    
    List<UsgsCoastalData> findByLocationContainingIgnoreCase(String location);
    
    List<UsgsCoastalData> findByYearBetween(Integer startYear, Integer endYear);
    
    @Query("SELECT DISTINCT u.location FROM UsgsCoastalData u ORDER BY u.location")
    List<String> findDistinctLocations();
    
    @Query("SELECT u FROM UsgsCoastalData u WHERE u.erosionRate > ?1 ORDER BY u.erosionRate DESC")
    List<UsgsCoastalData> findHighErosionAreas(Double threshold);
}
