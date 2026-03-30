# Rules: Docker & Docker Compose

**Applies to:** `**/Dockerfile`, `docker-compose*.yml`, `.dockerignore`

---

## Dockerfile Rules

### Multi-Stage Builds (required for all services)
```dockerfile
# Stage 1: Build
FROM eclipse-temurin:21-jdk-alpine AS builder
WORKDIR /app
COPY . .
RUN ./gradlew bootJar --no-daemon

# Stage 2: Runtime (no build tools, no source code)
FROM eclipse-temurin:21-jre-alpine AS runtime
WORKDIR /app
COPY --from=builder /app/build/libs/*.jar app.jar
```

### Security Rules
- Never run as root — always set `USER` to a non-root user
- No secrets in `ENV` or `ARG` instructions — inject at runtime via Secrets Manager
- No `.env` files copied into the image
- Use `.dockerignore` to exclude: `.git`, `*.md`, `test/`, `build/`, `node_modules/`, `.env*`
- Pin base image versions — no `:latest` tags

```dockerfile
# ✅ Correct
FROM eclipse-temurin:21.0.5_11-jre-alpine

# ❌ Wrong
FROM openjdk:latest
```

### Health Checks (required)
```dockerfile
HEALTHCHECK --interval=30s --timeout=5s --start-period=60s --retries=3 \
  CMD wget -qO- http://localhost:8080/actuator/health || exit 1
```

## Docker Compose Rules (local development)

### Service Definitions
- All services must have `healthcheck` defined
- Use named volumes for persistent data (PostgreSQL, Kafka) — not anonymous volumes
- Set explicit memory limits to prevent resource starvation in local dev
- Never commit `.env` with real values — use `.env.example` as the template

### Required Services in `docker-compose.yml`
```yaml
services:
  postgres:
    image: postgres:16-alpine
    # healthcheck, volumes, env_file

  kafka:
    image: confluentinc/cp-kafka:{version}
    # healthcheck, environment, depends_on: zookeeper

  localstack:
    image: localstack/localstack:{version}
    # SERVICES: s3,sqs,secretsmanager,ses
```

### Environment Variables
- Use `env_file: .env` — never hardcode values in `docker-compose.yml`
- `.env.example` must document every variable with a description comment
- LocalStack services simulated locally must mirror the real AWS service names

### Secrets in Local Dev
- LocalStack Secrets Manager for local secrets — same code path as production
- Never use plaintext passwords in `docker-compose.yml` — use `${VARIABLE}` substitution from `.env`

## .dockerignore (minimum required)
```
.git
.env
.env.*
*.md
node_modules
build
dist
.gradle
target
**/__pycache__
**/*.test.*
**/test/
```
