package com.clr.controller;

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

// Yes, if you run Maven from the project root (/home/kevin/Projects/clr-webui) or from the backend directory,
// Maven will automatically find and use the nearest pom.xml (either the parent or the module's pom.xml).
// The parent pom.xml manages dependencies and plugins for all modules, including backend.

// No changes needed to the code below if your directory and package structure matches:
//   backend/src/main/java/com/clr/model/CoastalData.java  -> package com.clr.model;
//   backend/src/main/java/com/clr/model/PredictionResult.java  -> package com.clr.model;
//   backend/src/main/java/com/clr/repository/CoastalDataRepository.java  -> package com.clr.repository;
//   backend/src/main/java/com/clr/service/PredictionService.java  -> package com.clr.service;

// If you see "The import org.springframework cannot be resolved":
// 1. Make sure you have run `mvn clean install` (or at least `mvn compile`) in the backend directory or project root.
// 2. Ensure your IDE recognizes 'backend' as a Maven project. In VS Code, open the backend folder and reload the Java/Maven extension.
// 3. If using IntelliJ, right-click the backend folder and select "Add as Maven Project" or "Reload All Maven Projects".
// 4. If the error persists, try deleting the `.idea`, `.vscode`, and `target` directories, then re-import the project and rebuild.
// 5. Check that your `pom.xml` contains the correct Spring Boot dependencies (spring-boot-starter, spring-boot-starter-web, etc.).

// This is not a code error, but an IDE or Maven configuration issue.

// VS Code Java/Spring import troubleshooting:
// 1. Open the backend folder directly in VS Code (File > Open Folder... > select 'backend').
// 2. Make sure the Java and Maven extensions are installed and enabled.
// 3. If you see "The import org.springframework cannot be resolved":
//    - Run `mvn clean compile` in the backend directory to ensure dependencies are downloaded.
//    - Press Ctrl+Shift+P and run "Java: Clean Java Language Server Workspace".
//    - Press Ctrl+Shift+P and run "Maven: Reload project".
//    - If still broken, delete the `target/` directory and `.vscode/` folder, then reload VS Code.
//    - Ensure your pom.xml contains spring-boot-starter and spring-boot-starter-web dependencies.
// 4. Wait for VS Code to finish indexing and resolving dependencies (see status bar).
// 5. If all else fails, restart VS Code and repeat the above steps.
