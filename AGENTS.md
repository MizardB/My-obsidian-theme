# Flujo de trabajo del theme

## Entorno de pruebas

- Repositorio del tema: `/home/manu/Documents/repositorios/My-obsidian-theme`.
- Vault de pruebas: `/home/manu/Documents/repositorios/MizarOS/obsidian/Vault_base`.
- Usar la CLI oficial de Obsidian para inspeccionar y probar la interfaz. No es necesario instalar un MCP.
- Dirigir cada llamada explícitamente con `obsidian vault=Vault_base ...`. Antes de intervenir, comprobar con `obsidian vault=Vault_base vault info=path` que apunta al destino esperado. La selección del vault no constituye aislamiento de seguridad.
- Preservar las notas, atajos, plugins y demás configuración existente. No operar sobre otros vaults.

## Del prototipo a la implementación

1. **Prototipar en Obsidian.** Inspeccionar DOM y CSS y probar cambios visuales temporales, reversibles y separados del SCSS del tema. Limitar cada intervención al alcance solicitado por Manu; acordar el alcance si aún no está definido.
2. **Revisar con Manu.** Mostrar el resultado en vivo y mediante capturas cuando sean útiles. Iterar hasta su visto bueno. Revisar los estados pertinentes al cambio, como hover, foco, paneles abiertos/cerrados y modos claro/oscuro. La emulación móvil no sustituye una prueba en un dispositivo real.
3. **Preparar el ticket.** Tras aprobar el diseño, guardar una especificación con referencias visuales, selectores y variables relevantes, archivos SCSS afectados, hallazgos útiles, límites y criterios de aceptación. No guardar la conversación completa. Acordar el destino antes de escribir; los tickets persistentes de Cortex quedan fuera del repositorio. Aplicar las skills de documentación pertinentes y usar brief/blueprint solo cuando el alcance lo justifique.
4. **Delegar al worker.** Entregar un ticket acotado con el diseño aprobado, fuentes, destinos autorizados, exclusiones y verificaciones. El visto bueno visual no autoriza cambios ajenos al ticket. Preservar todo trabajo previo o ajeno.
5. **Verificar la implementación.** Compilar, retirar únicamente el prototipo temporal creado para el cambio y revisar el tema real en Obsidian. El padre contrasta el resultado del worker con los criterios de aceptación y con Manu cuando corresponda. Distinguir lo implementado de lo verificado y de lo pendiente.
6. **Cerrar con commit.** Tras la conformidad final, el worker puede crear un commit limitado al ticket autorizado, siguiendo la skill de Git. No incluir cambios ajenos ni hacer push sin autorización explícita. Un commit no sustituye la validación visual.

## Comandos del repositorio

Ejecutarlos desde la raíz del repositorio:

- `nix run .#install`: instala/enlaza `theme.css` y `manifest.json` en el vault de pruebas y selecciona Mytheme. `TARGET_VAULT` permite otro destino, pero no debe usarse para ampliar el alcance sin autorización.
- `nix run .#build`: compila `src/theme.scss` en `theme.css`.
- `nix run .#watch`: recompila al cambiar el SCSS. El vault recibe el CSS mediante el enlace instalado.

La implementación permanente se hace en los archivos SCSS correspondientes, no solo en el CSS generado ni en cambios temporales del DOM. No instalar dependencias, cambiar configuración de sistema ni reiniciar aplicaciones fuera de lo autorizado.
