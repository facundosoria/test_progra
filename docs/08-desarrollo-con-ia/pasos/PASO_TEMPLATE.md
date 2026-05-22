---
id: PASO_X_Y
equipo: A | B | C
bloque: 0 | 1 | 1B | 2 | 3 | 3B | 4 | 4B | 5 | 5B | 6
dep: [PASO_X_Y_anterior, ...]
siguiente: PASO_X_Y_proximo
context_files:
  - GLOSARIO.md          # SIEMPRE primero
  - CONVENCIONES.md      # SIEMPRE segundo
  - <archivo específico del paso>
outputs:
  - <ruta exacta de cada archivo que el paso debe crear o modificar>
---

# PASO X.Y — <Título corto en imperativo>
**Grupo legacy:** X — <Nombre del grupo legacy> | **Equipo:** A/B/C | **Dificultad:** 🟢/🟡/🔴/🔥 | **Tiempo:** N–M h

## Navegación
← **Anterior:** [PASO_X_Y](PASO_X_Y.md) — <qué dejó listo>
→ **Siguiente:** [PASO_X_Z](PASO_X_Z.md) — <qué viene>

---

## Qué construye este paso

<2–4 líneas en lenguaje natural. Describe el OUTCOME, no la implementación. Ejemplo correcto: "El endpoint que permite a un usuario crear un mazo y validarlo contra las reglas oficiales del TCG." Ejemplo incorrecto: "Crea la clase DeckController con método createDeck()." (eso ya está en outputs).>

---

## Trazabilidad

- HU principal: HU-xx-xx | TT-xx-xx | sin HU directa
- Issue HU: #pendiente
- Epica: EPIC-xx
- Issue Epica: #pendiente
- Fuente normativa: [../TRAZABILIDAD_PASOS_HU.yml](../TRAZABILIDAD_PASOS_HU.yml)
- Vista humana: [../TRAZABILIDAD_PASOS_HU.md](../TRAZABILIDAD_PASOS_HU.md)
- Regla de cierre: la HU pasa a `Done` solo cuando todos sus pasos requeridos estan `DONE` y verificados.

---

## Prerrequisitos

<Listar lo que debe estar implementado antes. Si la dependencia es atípica (forward dep, cross-bloque), explicar el porqué.>

- PASO_X_Y completado: deja disponible <qué exactamente>
- BD migración V<N> aplicada (incluye tablas: ...)
- Bean Spring `<nombre>Service` autowireable

---

## Contratos a respetar

<Sección clave: definir las INTERFACES y NOMBRES que el agente DEBE usar, sin servir la implementación.>

### Endpoints REST (si aplica)
| Verbo + Path | Request | Response | Códigos |
|---|---|---|---|
| `POST /api/...` | `XRequest` | `XResponse` | 200, 400, 401 |

### Clases obligatorias
| FQN | Tipo | Métodos públicos requeridos |
|---|---|---|
| `com.codemon.<feature>.service.XService` | `@Service` | `metodoA(...)`, `metodoB(...)` |
| `com.codemon.<feature>.entity.X` | `@Entity` | mapea tabla `xs` |
| `com.codemon.<feature>.dto.XRequest` | `record` | campos: ... |

### Eventos WebSocket emitidos (si aplica)
- `EVENT_NAME_1` (público / privado): payload `{ ... }`. Definido en `06-system-logic.md`.

### Tipos compartidos
- Reutilizar nombres de [GLOSARIO.md](../../05-referencia-tecnica/GLOSARIO.md). NO inventar variantes.

---

## Política de idioma

Este archivo `.md` se redacta en español para humanos y agentes. Sin embargo, todo lo que el paso implemente o defina para runtime debe estar en inglés:

- Código, identificadores, comentarios, logs, excepciones, errores, validaciones, tests, fixtures, mocks y seeds visibles al usuario.
- Textos visibles de UI: labels, botones, placeholders, tooltips, toasts, modales, empty states, loading states, mensajes de sistema y mensajes de bot/chat.
- Snippets, contratos, payloads de ejemplo y strings runtime incluidos en este PASO.

---

## Instrucciones para el agente

<Aquí va el "qué hacer", en imperativo y por puntos. NO incluir bloques de código completos. Pseudocódigo está OK para algoritmos. Permitir libertad de implementación siempre que se respeten los contratos de arriba.>

1. Crear la entidad `X` mapeada a la tabla `xs` (ver schema en BD_Y_TABLAS.md). Campos críticos no negociables: `id`, `<otros>`.
2. Crear `XRequest` y `XResponse` como `record` Java 21 en `com.codemon.<feature>.dto`.
3. Implementar `XService` con los métodos del contrato. Lógica:
   - Algoritmo / pseudocódigo si es no-trivial.
   - Casos borde a contemplar (lista).
4. Implementar `XController` que mapea los endpoints del contrato a `XService`.
5. Aplicar las convenciones de [CONVENCIONES.md](../CONVENCIONES.md): inyección por constructor, validaciones con `@Valid`, errores con `GlobalExceptionHandler`.

---

## Casos borde / errores comunes

<Tabla de errores que el agente debe evitar. Cada fila: síntoma → causa → solución.>

| Síntoma | Causa | Solución |
|---|---|---|
| ... | ... | ... |

---

## Tests obligatorios

<Lista de los nombres de tests que deben existir. NO el código del test, solo el nombre y qué verifica. El agente decide cómo escribirlo.>

- `XServiceTest.crea_X_con_datos_validos` — happy path
- `XServiceTest.rechaza_X_sin_<campo_requerido>` — validación
- `XControllerTest.devuelve_401_sin_token` — security
- `XServiceTest.<caso_borde_específico>` — caso borde

**Cobertura mínima:** ≥80% en este paquete.

---

## Verificación automatizada

```bash
# Cada línea debe terminar con exit 0 (PASS) o exit ≠ 0 (FAIL).
# El script verify_paso.sh ejecuta estos comandos.

./mvnw test -Dtest=XServiceTest                                      # PASS si: BUILD SUCCESS
./mvnw test -Dtest=XControllerTest                                   # PASS si: BUILD SUCCESS
curl -fs http://localhost:8088/actuator/health -o /dev/null          # PASS si: HTTP 200
test -f api/src/main/java/com/codemon/<feature>/service/XService.java  # PASS si: archivo existe
```

---

## Entrega al siguiente paso

<Sección obligatoria. Lo que este paso deja "compatible y disponible" para que el siguiente arranque sin sorpresas.>

- Endpoint disponible: `POST /api/...` con DTO `XRequest` → `XResponse`
- Bean Spring `XService` autowireable
- Tabla `xs` poblada con datos seed (si aplica)
- Tests pasan: `./mvnw test -Dtest=X*Test`
- Para el equipo B: el endpoint sigue el contrato declarado, sin desviaciones de naming

---

## Actualizacion de seguimiento

Al cerrar, pausar o bloquear este paso:

- Verificar que la relacion Paso -> HU/TT -> Epica exista en [../TRAZABILIDAD_PASOS_HU.yml](../TRAZABILIDAD_PASOS_HU.yml).
- Actualizar [../ESTADO_PASOS.md](../ESTADO_PASOS.md) con estado, avance, responsable, commit/rama, bloqueos y proxima accion.
- Agregar una entrada en [../HISTORIAL_PASOS.md](../HISTORIAL_PASOS.md) con checks ejecutados, resultado, archivos tocados y handoff.
- Si este paso queda `DONE`, revisar dependencias y marcar como `READY` los pasos desbloqueados.
- Si todas las relaciones requeridas de una HU quedan `DONE`, actualizar GitHub Projects mediante `scripts/agent-complete-paso.sh PASO_X_Y`.

---

## Definition of Done

- [ ] Todos los archivos de `outputs:` existen
- [ ] `./verify_paso.sh PASO_X_Y` retorna exit 0
- [ ] Tests obligatorios pasan con cobertura ≥ 80%
- [ ] Sección "Entrega al siguiente paso" refleja el estado real
- [ ] Trazabilidad Paso -> HU/TT -> Epica revisada en [../TRAZABILIDAD_PASOS_HU.yml](../TRAZABILIDAD_PASOS_HU.yml)
- [ ] [../ESTADO_PASOS.md](../ESTADO_PASOS.md) actualizado
- [ ] [../HISTORIAL_PASOS.md](../HISTORIAL_PASOS.md) actualizado
- [ ] Sin TODOs / FIXMEs en el código entregado
- [ ] Naming respeta [GLOSARIO.md](../../05-referencia-tecnica/GLOSARIO.md) (entidades, paquetes, DTOs, eventos)
- [ ] Código, comentarios, logs, errores, tests, datos runtime y UI visible en inglés
