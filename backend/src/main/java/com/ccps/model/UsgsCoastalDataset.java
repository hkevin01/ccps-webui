package com.clr.model;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDate;

/**
 * Entity representing USGS coastal data from:
 * https://cmgds.marine.usgs.gov/data/whcmsc/data-release/doi-F73J3B0B/
 * Dataset: "Massachusetts Shoreline Change Project, 1800s to 2018"
 */
@Entity
@Table(name = "usgs_coastal_datasets")
@Data
@NoArgsConstructor
@AllArgsConstructor
public class UsgsCoastalDataset {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;
    
    private String transectId;
    
    private Double latitude;
    
    private Double longitude;
    
    private String location;
    
    private String region;
    
    private LocalDate measurementDate;
    
    private Double shorePosUncert;
    
    private Double shorelinePosition;
    
    private Double shorelineChange;
    
    private Double erosionRate;
    
    @Column(length = 2000)
    private String metadata;
    
    private String dataSource = "USGS CMGDS";
    
    private String datasetDoi = "F73J3B0B";
    
    private String dataUrl = "https://cmgds.marine.usgs.gov/data/whcmsc/data-release/doi-F73J3B0B/";
}
