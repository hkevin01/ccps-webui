// Update the import paths below to match your actual package structure if different
// If your model and repository classes are not in com.clr.model or com.clr.repository,
// update these imports to the correct package names or move the files accordingly.

// For example, if your structure is:
// backend/src/main/java/model/CoastalData.java
// backend/src/main/java/repository/CoastalDataRepository.java
// then use:
// import model.CoastalData;
// import repository.CoastalDataRepository;

import com.clr.model.CoastalData;
import com.clr.model.PredictionResult;
import com.clr.repository.CoastalDataRepository;
import com.clr.repository.PredictionResultRepository;
import com.clr.service.PredictionService;
import java.util.List;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/coast")
public class CoastController {
    @Autowired
    private CoastalDataRepository coastalDataRepository;
    @Autowired
    private PredictionService predictionService;
    @Autowired
    private PredictionResultRepository predictionResultRepository;

    @GetMapping("/data")
    @PreAuthorize("hasAnyRole('ADMIN','USER')")
    public List<CoastalData> getCoastalData(@RequestParam(required = false) String region) {
        if (region != null && !region.isEmpty()) {
            return coastalDataRepository.findByRegion(region);
        }
        return coastalDataRepository.findAll();
    }

    @PostMapping("/predict")
    @PreAuthorize("hasAnyRole('ADMIN','USER')")
    public PredictionResult predict(@RequestBody CoastalData data) {
        PredictionResult result = predictionService.predict(data);
        predictionResultRepository.save(result);
        return result;
    }
}

// If you see "package com.clr.model does not exist" or similar errors,
// ensure that the following files exist at these locations:
//   backend/src/main/java/com/clr/model/CoastalData.java
//   backend/src/main/java/com/clr/model/PredictionResult.java
//   backend/src/main/java/com/clr/repository/CoastalDataRepository.java
//   backend/src/main/java/com/clr/repository/PredictionResultRepository.java
//   backend/src/main/java/com/clr/service/PredictionService.java
//
// If your files are in a different package, update the import statements accordingly.
// For example, if your files are in 'model' instead of 'com.clr.model', use:
// import model.CoastalData;
// import model.PredictionResult;
// etc.

// The import errors are likely due to IDE/project misconfiguration, not code issues.
// Your directory structure is correct for package com.clr.model.CoastalData, etc.
// Make sure your IDE/project is set up as a Maven project and recognizes 'src/main/java' as a source root.

// If you see "The import com.clr cannot be resolved":
// 1. Ensure your IDE (e.g., VS Code, IntelliJ) recognizes 'backend' as a Maven project.
// 2. If using VS Code, open the 'backend' folder directly or reload the Maven/Java extension.
// 3. Run `mvn clean compile` in the backend directory to verify compilation works outside the IDE.

// No changes needed to the code below if your directory and package structure matches:
//   backend/src/main/java/com/clr/model/CoastalData.java  -> package com.clr.model;
//   backend/src/main/java/com/clr/model/PredictionResult.java  -> package com.clr.model;
//   backend/src/main/java/com/clr/repository/CoastalDataRepository.java  -> package com.clr.repository;
//   backend/src/main/java/com/clr/service/PredictionService.java  -> package com.clr.service;
