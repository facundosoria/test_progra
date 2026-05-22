# CONVENCIONES.md
# Directivas globales del proyecto Codemon TCG

**Cargar este archivo al inicio de toda sesión de implementación.**
Aplica a todos los pasos, todos los bloques, cualquier agente de IA.

---

## Cómo usar el sistema de pasos

```
Flujo para cada paso:
1. Cargás CONVENCIONES.md, GLOSARIO.md, ESTADO_PASOS.md e HISTORIAL_PASOS.md — una vez por sesión
2. Cargás el archivo PASO_X.Y.md del paso a implementar
3. Cargás los archivos de referencia que indica el PASO (reglas, schema, etc.)
4. Ejecutás el prompt del PASO respetando los CONTRATOS declarados
5. Verificás con `./verify_paso.sh PASO_X_Y` (sección "Verificación automatizada")
6. Repasás el "Definition of Done" del PASO antes de marcarlo terminado
7. Actualizás ESTADO_PASOS.md e HISTORIAL_PASOS.md antes de cerrar la sesión
```

---

## Doctrina: instrucciones precisas, NO código servido

**Regla fundamental para cada PASO:**

Un PASO le dice al agente *qué construir*, no *cómo escribirlo línea por línea*. El agente debe tener libertad para implementar siempre que respete los contratos declarados (firmas, nombres, contratos REST/WebSocket, esquemas de BD).

| Permitido en un PASO | Prohibido en un PASO |
|---|---|
| Pseudocódigo para algoritmos no triviales (mulligan, attack pipeline) | Bloques de >50 líneas de código copy-paste |
| Firmas de interfaces/métodos a respetar | Implementaciones completas de métodos |
| Schemas SQL o DTOs literales (record Java 21) | Lógica de negocio servida en código |
| Lista de tests por nombre y qué verifican | Tests escritos completos para copiar |
| Referencias a clases del [GLOSARIO](../05-referencia-tecnica/GLOSARIO.md) | Inventar nombres alternativos |

**Razón:** dos agentes IA distintos pueden implementar el mismo PASO con código diferente, pero los contratos los hacen interoperar. Si el PASO sirve código, el agente queda casado a esa implementación y los pasos posteriores se vuelven frágiles.

**Cuando el PASO necesita ser explícito:** firmas de interfaces, DTOs, eventos WebSocket, endpoints REST, nombres de paquetes/clases del GLOSARIO. Eso NO es "código servido", es contrato.

---

## Escala de dificultad

| Ícono | Nivel | Tiempo estimado | Riesgo |
|---|---|---|---|
| 🟢 | Fácil | 1–2 h | Bajo |
| 🟡 | Medio | 3–6 h | Moderado |
| 🔴 | Difícil | 6–12 h | Alto |
| 🔥 | Muy difícil | 12 h+ | Muy alto |

---

## Requisitos técnicos globales

Estos requisitos aplican a **todos** los componentes de todos los pasos.

## Política de idioma

La documentación de trabajo para humanos y agentes se mantiene en español: archivos `.md` dentro de `docs/` (guías, pasos, planificación, criterios y notas de coordinación).

Toda implementación debe estar completamente en inglés:

- Código fuente, identificadores, nombres de clases, métodos, variables, paquetes, componentes, rutas internas, constantes y enums.
- Comentarios de código, logs, mensajes de excepción, mensajes de error, validaciones, tests, fixtures, mocks y datos seed visibles al usuario.
- Todo texto visible de UI: labels, botones, links, placeholders, tooltips, toasts, modales, empty states, loading states, errores, mensajes de sistema, chat/bot messages y contenido de referencia visual en HTML.
- Snippets, contratos, payloads de ejemplo y strings runtime incluidos dentro de archivos `.md`.

Cuando un archivo `.md` describa una funcionalidad, el texto explicativo queda en español, pero cualquier valor que vaya a implementarse o mostrarse en runtime debe estar en inglés.

```
Stack y versiones:
- Java 21 con Spring Boot 3.3.x
- Angular 21+ con TypeScript strict + Tailwind CSS 3 (utility-first)

Estilo de código (backend):
- Usar Lombok (@Data, @Builder, @RequiredArgsConstructor) donde simplifique
- Inyección de dependencias por constructor — nunca @Autowired en campo
- Todos los métodos de servicio que modifican datos deben ser @Transactional
- Usar SLF4J (@Slf4j) para logging — nunca System.out.println

Estilo de código (frontend):
- Standalone Components (no NgModule)
- TypeScript strict — sin any implícito
- Cleanup de suscripciones en ngOnDestroy
- CSS: solo Tailwind (utility-first). Estilos custom en `*.component.scss` con `@apply` Tailwind. La única librería de componentes permitida es `@angular/cdk` (drag/drop, overlays).

Convención de tests:
- Patrón: // Given // When // Then
- Un test por comportamiento, nombres descriptivos
```

---

## Guards de scope

```
No generar código de frontend a menos que el prompt del paso lo pida explícitamente.
No generar código de backend a menos que el prompt del paso lo pida explícitamente.
Prohibido modificar datos de BD sin consultar y sin hacer back up.
```

---

## Verificación post-ejecución (hacer después de cada paso)

```
1. Ejecutar:  ./verify_paso.sh PASO_X_Y
   - Corre los comandos de la sección "Verificación automatizada" del PASO.
   - Exit 0 = todos los checks PASS. Exit 1 = al menos uno falló.

2. Recorrer manualmente el "Definition of Done" del PASO:
   - Outputs declarados existen (la sección outputs: del YAML).
   - Tests pasan con cobertura ≥ 80%.
   - Sin TODOs / FIXMEs en el código entregado.
   - Naming respeta GLOSARIO.md.
   - Código, comentarios, logs, errores, tests, datos runtime y UI visible están en inglés.

3. Validar la sección "Entrega al siguiente paso":
   - El paso siguiente puede arrancar SIN preguntar nada (endpoints, beans,
     tablas, contratos están donde se dijo).
```

---

## Para Claude Code (auto-carga)

Si usás Claude Code, creá un `CLAUDE.md` en la raíz del proyecto con:

```
Lee CONVENCIONES.md antes de implementar cualquier paso.
```

Así este archivo se carga automáticamente en cada sesión sin tener que pedirlo.
