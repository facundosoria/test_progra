# ─────────────────────────────────────────────────────────────
# STAGE 1: Build (Maven + Java 21)
# ─────────────────────────────────────────────────────────────
FROM maven:3.9.9-eclipse-temurin-21 AS builder

WORKDIR /app

# Copiar pom.xml primero para cachear dependencias
COPY pom.xml .
RUN mvn dependency:go-offline -q

# Copiar código fuente y compilar
COPY src ./src
RUN mvn clean package -DskipTests -q

# ─────────────────────────────────────────────────────────────
# STAGE 2: Runtime (solo JRE, imagen más liviana)
# ─────────────────────────────────────────────────────────────
FROM eclipse-temurin:21-jre-alpine

WORKDIR /app

# Crear usuario no-root por seguridad
RUN addgroup -S puchamon && adduser -S puchamon -G puchamon

# Copiar el JAR del stage anterior
COPY --from=builder /app/target/*.jar app.jar

# Dar permisos
RUN chown puchamon:puchamon app.jar
USER puchamon

EXPOSE 8080

# Health check interno
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
  CMD wget --spider -q http://localhost:8080/actuator/health || exit 1

ENTRYPOINT ["java", "-jar", "app.jar"]
