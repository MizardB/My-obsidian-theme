# Mytheme

Tema personalizado para Obsidian, basado en [Cupertino](https://github.com/aaaaalexis/obsidian-cupertino) de [@aaaaalexis](https://github.com/aaaaalexis).

![Vista previa del tema](img/hero.png)

## Requisitos

- **Obsidian 1.13.4 o superior**, según la versión mínima declarada en `manifest.json`.
- **No requiere plugins** para aplicar el tema y usar su apariencia predeterminada.
- Si tienes **Minimal Theme Settings**, desactívalo: no es compatible con este tema.

### Style Settings (opcional)

El plugin [Style Settings](https://github.com/mgmeyers/obsidian-style-settings) permite cambiar las opciones del tema desde Obsidian: colores dinámicos, paneles laterales al pasar el cursor, vista de enfoque, resaltado de la línea activa, tamaño de interfaz y movimiento reducido, entre otras.

1. Abre **Ajustes → Plugins de la comunidad** y habilita su uso si es necesario.
2. Busca **Style Settings**, instálalo y actívalo.
3. Abre sus ajustes y busca la sección **Cupertino**. El tema conserva ese nombre en sus opciones de personalización.

## Instalación manual

1. Descarga `theme.css` y `manifest.json` de este repositorio.
2. Dentro de tu bóveda, crea la carpeta `.obsidian/themes/Mytheme/` y copia ambos archivos en ella. Si usas una carpeta de configuración distinta de `.obsidian`, adapta la ruta.
3. En Obsidian, abre **Ajustes → Apariencia → Temas** y selecciona **Mytheme**. Si no aparece, reinicia Obsidian.

No necesitas copiar `src/` ni compilar el tema: `theme.css` ya contiene los estilos listos para usar.

## Comandos de desarrollo e instalación

Desde la raíz del repositorio, con Nix:

- `nix run .#build`: compila el SCSS actual en `theme.css`.
- `nix run .#install`: compila siempre e instala copias independientes de `theme.css` y `manifest.json`. Sustituye los enlaces individuales de una instalación de desarrollo sin escribir a través de ellos. Cambios posteriores del repositorio no afectan a esa copia.
- `nix run .#install-dev`: compila siempre y crea enlaces individuales a ambos archivos del repositorio, sustituyendo las copias existentes.
- `nix run .#watch`: recompila al editar SCSS; para ver estos cambios en el vault hay que ejecutar antes `install-dev` explícitamente. No actualiza una instalación estable.

Ambos instaladores usan por defecto `/home/manu/Documents/repositorios/MizarOS/obsidian/Vault_base` y seleccionan Mytheme solo si ya existe `.obsidian/appearance.json`, conservando las otras claves. `TARGET_VAULT` permite indicar otro destino, pero requiere autorización para intervenir en él. Rechazan un directorio Mytheme que sea un symlink o coincida con el repositorio; no migran enlaces de directorio automáticamente.

Tras aprobar los cambios visuales, cerrar el ciclo con `nix run .#install` para dejar una instalación estable, sin dependencia del repositorio. Compilar o instalar no sustituye la revisión visual ni autoriza cambios en otros vaults.

## Funciones incluidas

- Apariencia adaptada al sistema operativo, con estilos para escritorio y móvil.
- Banners, filtros de imagen y casillas de verificación alternativas.
- Clases de ayuda para ajustar el ancho de notas, tablas, imágenes y contenido incrustado.
- Estilos de tarjetas para listas y tablas de Dataview. Para generar tablas con consultas de Dataview sí necesitas ese plugin; no es un requisito del tema.

Muchas clases de ayuda proceden de [Minimal](https://github.com/kepano/obsidian-minimal). Puedes consultar su documentación de [anchos de bloque](https://minimal.guide/features/block-width), [tarjetas](https://minimal.guide/Block+types/Cards) y [tablas](https://minimal.guide/tables) como referencia.

## Créditos

- [Cupertino, de aaaaalexis](https://github.com/aaaaalexis/obsidian-cupertino): tema original.
- [Craft Docs](https://www.craft.do/): inspiración de diseño.
- [Yushan Main East Peak, de Huang Chung Yu](https://commons.wikimedia.org/wiki/File:Yushan_main_east_peak%2BHuang_Chung_Yu%E9%BB%83%E4%B8%AD%E4%BD%91%2B9030.png): imagen de fondo.
- [Minimal, de kepano](https://github.com/kepano/obsidian-minimal): tarjetas de Dataview, filtros de imagen y clases de ayuda para tablas.

## Licencia

[MIT](LICENSE.txt). Basado en Cupertino, creado originalmente por [@aaaaalexis](https://github.com/aaaaalexis).
