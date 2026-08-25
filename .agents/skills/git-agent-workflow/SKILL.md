---
name: git-agent-workflow
description: >-
  ¡OBLIGATORIO PARA TODA OPERACIÓN DE GIT! Úsala al preparar commits, organizar
  ramas, auditar el historial o sincronizar con GitHub. Exige OBLIGATORIAMENTE
  commits con cuerpo descriptivo (qué, por qué, validación) y aislar todo cambio
  de configuración de agentes bajo el scope 'agents' (ej: docs(agents):, chore(agents):)
  separado de los cambios de código fuente.
---

# Skill: Git & GitHub Agent Workflow (Local - Mytheme)

## Propósito
Estandarizar el uso de Git y GitHub para que humanos y agentes puedan leer, recuperar contexto histórico y tomar decisiones en segundos sin ambigüedades ni inferencias erróneas.

---

## 1. Regla de Oro: Aislamiento de Ámbitos (`scope: agents`)

> **PROHIBICIÓN ESTRICTA:** Jamás mezcles modificaciones al código fuente del proyecto (`src/`, `theme.css`, `flake.nix`) con archivos de infraestructura de agentes (`.agents/`, `AGENTS.md`, `GEMINI.md`, skills, scripts) en el mismo commit.

### Tabla de Clasificación:

| Destino de los cambios | Tipo / Scope | Ejemplo de Header |
|---|---|---|
| Modificación en `.agents/skills/`, `.agents/scripts/` | `feat(agents):` / `chore(agents):` | `feat(agents): add debug runner script` |
| Modificación en `AGENTS.md`, `.agents/rules/` | `docs(agents):` | `docs(agents): update testing vault guidelines` |
| Estilos SCSS en `src/` | `feat(...)` / `fix(...)` | `fix(floating-sidedock): remove bottom gap` |
| Dependencias, compilación Nix | `build(...)` / `chore(...)` | `build(flake): update dart-sass devshell` |

---

## 2. Estructura Obligatoria de Commit (Header + Cuerpo)

Todo commit debe incluir **siempre** un cuerpo explicativo estructurado en 3 bloques mínimos:

```
<type>(<scope>): <resumen imperativo en minúsculas de máx 50 caracteres>

- Qué: Resumen técnico de los selectores, variables, archivos o reglas modificadas.
- Por qué: Razón de negocio, estética o técnica (citar ADR-XXX si aplica, o causa raíz del bug).
- Validación: Evidencia empírica de cómo se verificó (ej: DevTools CDP, compilación Nix, prueba visual).
```

### Ejemplo A: Modificación de Código
```
fix(floating-sidedock): remove bottom gap from floating sidebars

- Qué: Se ajustó 'bottom: 0px' y 'height: calc(100% - 8px)' en .mod-sidedock.
- Por qué: El gap inferior de 8px creaba una asimetría visual no deseada con el borde de la ventana. El diseño floating overlay se mantiene (ADR-001).
- Validación: Inyección en caliente vía DevTools CDP y confirmación visual directa del usuario. Compilación exitosa con Nix.
```

### Ejemplo B: Modificación de Agentes
```
docs(agents): add git workflow skill and update agents guidelines

- Qué: Se integró la skill local 'git-agent-workflow' y se documentó el protocolo de commits con cuerpo.
- Por qué: Evitar commits mudos y aislar los cambios de infraestructura de agentes del historial del tema.
- Validación: Estructura de frontmatter validada y referenciada en AGENTS.md.
```

---

## 3. Estrategia de Ramas: Trunk-Based + Experimentos Efímeros

1. **Flujo Principal (Trunk-Based):**
   - Para desarrollo incremental validado, los commits van directo a `main` (o la rama de feature activa en curso).
2. **Ramas Experimentales:**
   - Crear una rama únicamente si el cambio es especulativo, de alto riesgo y con probabilidad de ser descartado:
     ```bash
     git checkout -b experiment/nombre-corto
     ```
3. **Poda Inmediata (Pruning):**
   - Una vez integrada o descartada una rama, se debe eliminar inmediatamente local y remotamente:
     ```bash
     git branch -d nombre-rama
     git push origin --delete nombre-rama
     ```

---

## 4. Disciplina de Push y Sincronización

1. **Cero Commits Locales Huérfanos:**
   - Tras completar y validar un paquete de trabajo, realizar el `git push` de inmediato.
2. **Auditoría de Desincronización:**
   - Verificar si existen commits locales no respaldados:
     ```bash
     git log --branches --not --remotes --oneline
     ```

---

## 5. Recetas CLI de Lectura Rápida (Para Inicio de Sesión)

Comandos que el agente debe ejecutar para obtener contexto empírico inmediato:

```bash
# 1. Ver últimos 10 commits con archivos afectados
git log -10 --oneline --stat

# 2. Árbol visual de ramas y posición del HEAD
git log -15 --oneline --graph --all --decorate

# 3. Top archivos más modificados (hotspots reales de git)
git log -10 --pretty=format: --name-only | grep -v '^$' | sort | uniq -c | sort -rn

# 4. Leer el cuerpo completo del último commit (para entender el estado actual)
git log -1 --format="%B"

# 5. Estado de ramas y divergencia con remotos
git branch -vv
```
