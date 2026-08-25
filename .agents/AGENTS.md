# Mytheme - Directrices para Agentes

## 1. Reglas Críticas de Desarrollo
- **Prohibido editar `theme.css` directamente:** Es un artefacto compilado. Cualquier cambio manual será sobreescrito.
- **Edición exclusiva en `src/`:** Todas las modificaciones de estilo, variables y estructura deben realizarse en los archivos SCSS dentro del directorio `src/` (ej. `src/theme.scss`, `src/features/`, etc.).

## 2. Entorno y Compilación (Nix Flake)
El proyecto utiliza Nix Flakes para gestionar las dependencias y scripts de compilación (`dart-sass`):

- **Compilar tema:**
  ```bash
  nix develop --command build-theme
  ```
  *(Dentro del devShell: `build-theme`)*

- **Modo Watch (desarrollo continuo):**
  ```bash
  nix develop --command watch-theme
  ```
  *(Dentro del devShell: `watch-theme`)*

- **Instalar en vault de prueba:**
  ```bash
  nix develop --command install-theme
  ```
  *(Dentro del devShell: `install-theme`)*

## 3. Vault de Pruebas (obsidian-devtools MCP)

- **Vault:** `/home/manu/Documents/repositorios/MizarOS/obsidian/template`
- **Puerto debug:** `9222` (instancia AISLADA, no interfiere con Obsidian principal)
- **Script de inicio:** [`.agents/scripts/start-obsidian-debug.sh`](.agents/scripts/start-obsidian-debug.sh)

**Protocolo de inicio de sesión (OBLIGATORIO antes de cualquier operación DevTools):**

```bash
# Levantar instancia de prueba
./.agents/scripts/start-obsidian-debug.sh

# Si ya está corriendo, el script lo detecta y no lanza otra
# Para cerrarla:
./.agents/scripts/start-obsidian-debug.sh --kill
```

**Una vez arriba:**
1. Llamar `list_pages` — el pageId es DINÁMICO, nunca hardcodearlo
2. Llamar `select_page` con ese `pageId` antes de `evaluate_script`, `take_screenshot`, etc.
3. Verificar vault: `() => app.vault.getName() + ' @ ' + app.vault.adapter.basePath`
   - Debe retornar: `"template @ /home/manu/Documents/repositorios/MizarOS/obsidian/template"`

> **NUNCA operar sobre la ventana de MemorIA** durante pruebas de tema.

## 4. Memoria Externa del Proyecto (Vault MemorIA)
La memoria, arquitectura y registro de lecciones residen fuera del control de versiones de Git para garantizar persistencia absoluta:
- **Mapa de Arquitectura:** [`architecture.md`](file:///home/manu/Documents/MemorIA/02_Projects/Mytheme/architecture.md)
- **Axiomas y Gotchas:** [`learnings.md`](file:///home/manu/Documents/MemorIA/02_Projects/Mytheme/learnings.md)
- **Historial de Planes:** [`plans/`](file:///home/manu/Documents/MemorIA/02_Projects/Mytheme/plans)

## 4. Workflow E2E: Prototipado en Vivo, Memoria y Delegación a Subagentes

> **REGLA DE ORO**: El 80% del éxito radica en el análisis previo. La memoria reside de forma segura e inmune a Git en el vault central [`/home/manu/Documents/MemorIA/02_Projects/Mytheme/`](file:///home/manu/Documents/MemorIA/02_Projects/Mytheme).

### Fase 1: Análisis Total (Agente Orquestador)
1. **Consulta de Memoria Central:**
   - Revisar el mapa de módulos en [`architecture.md`](file:///home/manu/Documents/MemorIA/02_Projects/Mytheme/architecture.md).
   - Revisar los axiomas técnicos conocidos en [`learnings.md`](file:///home/manu/Documents/MemorIA/02_Projects/Mytheme/learnings.md) (Electron, z-index, drag, flexbox).
2. **Contraste con el Repositorio:**
   - Buscar selectores existentes, variables de color/espaciado y reglas `@use` en `src/` para no duplicar estilos.
3. **Inspección en Vivo (MCP DevTools / CDP):**
   - Inspeccionar el DOM real computado (`getBoundingClientRect`, `getComputedStyle`, clases de estado como `.is-sidedock-collapsed`).
   - Simular eventos (`hover`, `click`) para identificar restricciones de layout antes de proponer cambios.
4. **Scope Lock y Plan:**
   - Registrar el plan de trabajo con checkboxes atómicos (`[ ]`) en [`/home/manu/Documents/MemorIA/02_Projects/Mytheme/plans/YYYY-MM-DD-<feature>.md`](file:///home/manu/Documents/MemorIA/02_Projects/Mytheme/plans). No avanzar hasta tener el plan cerrado con el usuario.

### Fase 2: Prototipado en Caliente & Aprendizaje Axiomático Asíncrono
1. **Inyección en Memoria (Cero mutación de archivos):**
   - Inyectar soluciones dinámicas directamente en el DOM mediante DevTools (`evaluate_script`).
   - **Regla del Tag Único:** Usar siempre `<style id="agent-preview">...</style>` y reemplazar su contenido en cada prueba para no acumular basura de iteraciones anteriores.
2. **Validación Visual Directa:**
   - El usuario valida directamente en su pantalla física la interacción y estética en tiempo real.
3. **Registro y Check:**
   - Con cada aprobación parcial del usuario, marcar `[x]` en el archivo del plan en `MemorIA/plans/` y guardar el bloque CSS exacto que funcionó.
4. **Gestión de Errores y Subagente Sintetizador (Axioma > Inductivo):**
   - Si un prototipo no sale a la primera por un comportamiento oculto del framework/DOM:
     - El agente orquestador delega inmediatamente a un **Subagente Sintetizador** en background (`invoke_subagent`).
     - El subagente deduce el principio general, ubica la sección correcta y actualiza directamente [`learnings.md`](file:///home/manu/Documents/MemorIA/02_Projects/Mytheme/learnings.md) en el vault `MemorIA`.
   - **Formato Axiomático Estricto:**
     ```markdown
     ### [Axioma / Principio General]: Regla universal que rige el comportamiento.
     - **Ejemplo concreto:** Selector o caso específico encontrado en Obsidian/Electron.
     ```

### Fase 3: Consolidación Delegada (Subagente Implementador)
Una vez completados y validados todos los checks en el plan de `MemorIA` con el usuario:
1. **Delegación a Subagente Implementador:**
   - El agente orquestador dispara un **Subagente Implementador / Builder** (`invoke_subagent` con write tools) pasándole la carga útil:
     - Lista de archivos SCSS destino en `src/`.
     - Bloques de código CSS/SCSS validados en la Fase 2.
     - Mensaje para el commit.
2. **Ejecución y Compilación por el Subagente:**
   - Escribe quirúrgicamente los cambios en `src/*.scss`.
   - Ejecuta la compilación con Nix: `nix develop --command build-theme`.
   - Valida que `theme.css` se genere sin errores ni advertencias de compilación.
3. **Git Hygiene & Cierre:**
   - Revisa `git status` y `git diff` para asegurar cero efectos secundarios.
   - Realiza el commit semántico (ej. `feat(sidedock): add floating acrylic sidedock`).
   - Ejecuta `git push` y reporta el éxito de la operación al agente orquestador.

