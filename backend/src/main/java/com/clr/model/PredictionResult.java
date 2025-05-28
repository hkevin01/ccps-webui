package com.clr.model;

import javax.persistence.*;
import lombok.Data;

/**
 * Entity representing the result of a coastal change prediction.
 */
@Entity
@Data
public class PredictionResult {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    private String region;
    private String date;
    private double likelihood; // 0-1 scale
}
