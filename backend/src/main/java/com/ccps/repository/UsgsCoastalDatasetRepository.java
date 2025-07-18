package com.clr.repository;

import com.clr.model.UsgsCoastalDataset;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.stereotype.Repository;

import java.time.LocalDate;
import java.util.List;

@Repository
public interface UsgsCoastalDatasetRepository extends JpaRepository<UsgsCoastalDataset, Long> {

    List<UsgsCoastalDataset> findByRegionIgnoreCase(String region);
    
    List<UsgsCoastalDataset> findByLocationContainingIgnoreCase(String location);
    
    List<UsgsCoastalDataset> findByMeasurementDateBetween(LocalDate startDate, LocalDate endDate);
    
    @Query("SELECT DISTINCT u.region FROM UsgsCoastalDataset u ORDER BY u.region")
    List<String> findDistinctRegions();
    
    @Query("SELECT DISTINCT u.location FROM UsgsCoastalDataset u ORDER BY u.location")
    List<String> findDistinctLocations();
    
    @Query("SELECT u FROM UsgsCoastalDataset u WHERE u.erosionRate > ?1 ORDER BY u.erosionRate DESC")
    List<UsgsCoastalDataset> findHighErosionAreas(Double threshold);
    
    @Query(value = "SELECT * FROM usgs_coastal_datasets u " +
           "WHERE ST_Distance(ST_MakePoint(u.longitude, u.latitude), ST_MakePoint(?1, ?2)) <= ?3 " +
           "ORDER BY ST_Distance(ST_MakePoint(u.longitude, u.latitude), ST_MakePoint(?1, ?2))",
           nativeQuery = true)
    List<UsgsCoastalDataset> findNearbyMeasurements(Double longitude, Double latitude, Double radiusInKm);
}
