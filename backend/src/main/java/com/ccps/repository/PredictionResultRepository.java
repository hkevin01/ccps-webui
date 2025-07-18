package com.clr.repository;

import com.clr.model.PredictionResult;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

/**
 * Repository interface for managing PredictionResult entities.
 * Extends JpaRepository to provide standard CRUD operations.
 */
@Repository
public interface PredictionResultRepository extends JpaRepository<PredictionResult, Long> {
    // JpaRepository already provides a save method, so you don't need to explicitly define it.
}