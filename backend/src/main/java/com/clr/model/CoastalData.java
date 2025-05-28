package com.clr.model;

import javax.persistence.*;

@Entity
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

    // Getters and setters...
    public String getRegion() {
        return region;
    }
    public void setRegion(String region) {
        this.region = region;
    }
    public String getDate() {
        return date;
    }
    public void setDate(String date) {
        this.date = date;
    }
    public double getSeaLevel() {
        return seaLevel;
    }
    public void setSeaLevel(double seaLevel) {
        this.seaLevel = seaLevel;
    }
    public double getErosionRate() {
        return erosionRate;
    }
    public void setErosionRate(double erosionRate) {
        this.erosionRate = erosionRate;
    }
    public double getPrecipitation() {
        return precipitation;
    }
    public void setPrecipitation(double precipitation) {
        this.precipitation = precipitation;
    }
}
