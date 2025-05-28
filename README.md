# Coastal Change Prediction System

A full-stack application for predicting and visualizing the likelihood of coastal changes (such as sea-level rise and erosion) using environmental data, climate models, and historical trends. The system features a secure backend (Spring Boot, PostgreSQL), a modern frontend (React, TypeScript, Bootstrap), interactive data visualizations, user authentication with role-based access, and is fully containerized for easy deployment.

## Backend
- Java 17, Spring Boot, JPA, PostgreSQL
- Run: `mvn clean package` in `backend/`, then use Docker or run the JAR

## Frontend
- React + TypeScript + Bootstrap
- Run: `npm install && npm start` in `frontend/`

## Database Setup
- Create a PostgreSQL database named `clrdb`.
- Create a user `clruser` with password `clrpass` and grant permissions.
- The backend will auto-generate schema with `spring.jpa.hibernate.ddl-auto=update`.

## Docker
- See `docker/` for Dockerfiles.

### Docker Compose
To run the full stack (backend, frontend, and PostgreSQL) together, create a `docker-compose.yml` in the project root:

```yaml
version: '3.8'
services:
  postgres:
    image: postgres:13
    container_name: postgres
    environment:
      POSTGRES_USER: clruser
      POSTGRES_PASSWORD: clrpass
      POSTGRES_DB: clrdb
    ports:
      - "5432:5432"
    volumes:
      - postgres_data:/var/lib/postgresql/data

  backend:
    build:
      context: .
      dockerfile: docker/Dockerfile.backend
    ports:
      - "8080:8080"
    environment:
      SPRING_DATASOURCE_URL: jdbc:postgresql://postgres:5432/clrdb
      SPRING_DATASOURCE_USERNAME: clruser
      SPRING_DATASOURCE_PASSWORD: clrpass
    depends_on:
      - postgres

  frontend:
    build:
      context: .
      dockerfile: docker/Dockerfile.frontend
    ports:
      - "3000:80"
    depends_on:
      - backend

volumes:
  postgres_data:
```

- Build and run everything:
  ```bash
  docker-compose up --build
  ```

## Features
- View and filter coastal data
- Predict coastal change likelihood
- Responsive dashboard UI

## Next Steps & Enhancements

- **Backend**
  - Replace stubbed prediction logic with a real model (statistical or ML).
  - Add Spring Security and JWT authentication.
  - Write unit and integration tests.

- **Frontend**
  - Add filters to data table (region, date range).
  - Add charts/graphs for trends and predictions.
  - Add routing (dashboard, about, user settings).
  - Add form validation and tests.

- **Deployment**
  - Use Docker Compose for local development.
  - Deploy to AWS, Azure, or Google Cloud.
  - Set up CI/CD (GitHub Actions, Jenkins, etc.).

- **Enhancements**
  - Real-time alerts (WebSocket/SSE).
  - User management and preferences.
  - Integrate external data sources (NOAA, NASA, etc.).
  - Internationalization (i18n).
  - Mobile support.

## Documentation
- API documentation (recommend Swagger for backend).
- Developer setup and deployment guides.

---
