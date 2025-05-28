package com.clr.model;

import javax.persistence.*;
import lombok.Data;

/**
 * Entity representing coastal environmental data for prediction.
 */
@Entity
@Data
public class CoastalData {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    private String region;
    private String date;
    private double seaLevel;
    private double erosionRate;
    private double precipitation;
    // ...add more fields as needed...
}
