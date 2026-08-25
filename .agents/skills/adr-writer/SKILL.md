---
name: adr-writer
description: >-
  ¡OBLIGATORIO Y EXCLUSIVO DEL ORQUESTADOR! ÚSALA inmediatamente cuando el
  usuario valide un prototipo ("sí, así me gusta") y la decisión de diseño sea
  CONTRAINTUITIVA o NO OBVIA (ej: código que parece un bug como position:absolute
  o z-index:999 pero es intencional), o cuando se descarte explícitamente una
  alternativa clásica. EVITA que futuros agentes rompan el diseño asumiendo
  errores donde hay decisiones de arquitectura. NO USAR para cambios triviales.
---

# Skill: ADR Writer (Local - Mytheme)

## Propósito
Registrar decisiones de arquitectura (ADRs) de forma estructurada en el vault central de MemorIA para blindar el diseño contra reinterpretaciones erróneas de futuros agentes.

---

## Heurística de Activación (Trigger)

Hazte esta pregunta:
> *"¿Un agente nuevo viendo este código sin contexto asumiría que es un bug y tomaría la decisión opuesta?"*
> - **SÍ** → Ejecutar esta skill inmediatamente (antes de consolidar/commitear).
> - **NO** → Proceder con commit estándar.

### Casos de Disparo:
1. **Comportamiento contra-intuitivo:** `position: absolute`, `margin: 0`, `z-index: 999` intencionales.
2. **Alternativa descartada:** Se probó flex/grid clásico y se rechazó por romper la estética floating acrylic.
3. **Validación explícita:** El usuario confirmó visualmente en caliente un layout específico.

---

## Ubicación del Archivo
Guardar siempre en:
```
/home/manu/Documents/MemorIA/02_Projects/Mytheme/ADRs/ADR-00N-<slug-descriptivo>.md
```

---

## Estructura Estricta del ADR

```markdown
---
status: active
date: YYYY-MM-DD
scope:
  - floating-sidedock
  - layout
related:
  - doc: "[[learnings]]"
    why: "Contiene axiomas de stacking context y drag regions que condicionan este componente"
---

# ADR-00N — <Título conciso de la decisión>

## Decisión
Declaración atómica de 1-2 oraciones sobre qué se decidió implementar.

## Contexto
Por qué se tomó esta decisión y qué estética/funcionalidad resuelve (ej. Floating Acrylic en Electron).

## Código Clave
Snippet CSS/SCSS mínimo representativo con comentarios inline de intencionalidad.

## Alternativa Rechazada
Qué solución estándar se evaluó (ej. empujar el viewport con márgenes flex) y por qué se descartó. **Crítico para evitar regresiones.**

## Señales de Alarma (Falsos Bugs)
| Lo que se observa en DOM | Lo que parece ser | Lo que realmente es |
|---|---|---|
| Sidebar sobre el editor | Overlap / bug de layout | Diseño intencional |

## Validación
- Fecha y método de validación empírica (ej. DevTools live injection + confirmación visual del usuario).
```

---

## Reglas de Metadata Frontmatter
- **Prohibido:** `id`, `title`, `decider`, `tags`, `cssfiles`, `cssselectors`, `aliases` (redundantes o propensos a desincronizarse).
- **Obligatorio:**
  - `status`: `active` | `deprecated` | `superseded-by: ADR-00X`
  - `date`: `YYYY-MM-DD`
  - `scope`: Lista acotada del área visual afectada.
  - `related`: Enlaces bidireccionales de Obsidian con campo `why` explícito.

---

## Validación Estricta de `related` (Cero Enlaces Rotos)

> **REGLA MANDATORIA:** Queda estrictamente prohibido colocar notas fantasma o supuestas. Todo documento en `related` **DEBE existir físicamente** en el vault de MemorIA antes de ser linkeado.

### Algoritmo de Enlace:
1. **Filtro de Relevancia:** *"¿Si un futuro agente ignora `[[doc-X]]` y toca este código, cometerá un error o romperá un axioma?"*
   - SÍ → Proseguir a validación de existencia.
   - NO → Descartar.
2. **Validación de Existencia Real:**
   - Comprobar en el sistema de archivos que la nota destino existe (ej. `/home/manu/Documents/MemorIA/.../doc-X.md`).
   - Si no existe físicamente, **no se linkea** o se debe crear primero el documento antes de referenciarlo.
3. **Formato Obligatorio:**
   ```yaml
   related:
     - doc: "[[learnings]]"
       why: "Contiene axiomas de stacking context y z-index que condicionan este componente"
   ```
