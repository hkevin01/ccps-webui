# Backend

Spring Boot REST API for coastal change prediction.

## Build & Run

```bash
cd backend
mvn clean package
java -jar target/*.jar
```

## API Docs

Javadoc is generated with:

```bash
cd backend
mvn javadoc:javadoc
```

Docs output: `target/site/apidocs/index.html`

## Diagnostics

- Uses SLF4J for logging (see logs for errors/warnings).
- Helper libraries: Apache Commons Lang, Lombok (for code clarity).
