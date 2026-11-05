{
  description = "Mytheme Obsidian theme development environment";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};

      buildTheme = pkgs.writeShellScriptBin "build-theme" ''
        set -e
        echo "🎨 Compilando SCSS para Mytheme..."
        ${pkgs.dart-sass}/bin/sass src/theme.scss theme.css
        echo "✅ Compilación exitosa: theme.css generado."
      '';

      watchTheme = pkgs.writeShellScriptBin "watch-theme" ''
        echo "👀 Escuchando cambios en SCSS en tiempo real..."
        ${pkgs.dart-sass}/bin/sass --watch src/theme.scss:theme.css
      '';

      makeInstaller = development: pkgs.writeShellScriptBin
        (if development then "install-theme-dev" else "install-theme") ''
        set -e
        REPO_DIR="$(pwd)"
        DEFAULT_VAULT="/home/manu/Documents/repositorios/MizarOS/obsidian/Vault_base"
        TARGET_VAULT="''${TARGET_VAULT:-$DEFAULT_VAULT}"
        TARGET_DIR="$TARGET_VAULT/.obsidian/themes/Mytheme"

        # Rechazar alias del repositorio antes de compilar o tocar el destino.
        if [ -L "$TARGET_DIR" ] || [ "$(realpath -m "$TARGET_DIR")" = "$(realpath "$REPO_DIR")" ]; then
          echo "Error: el destino no puede ser un symlink ni el repositorio." >&2
          exit 1
        fi
        for artifact in manifest.json theme.css; do
          if [ -d "$TARGET_DIR/$artifact" ] && [ ! -L "$TARGET_DIR/$artifact" ]; then
            echo "Error: $TARGET_DIR/$artifact es un directorio." >&2
            exit 1
          fi
        done

        # Ambos modos parten siempre del SCSS actual, incluso si ya hay CSS.
        ${buildTheme}/bin/build-theme
        test -f "$REPO_DIR/manifest.json"
        mkdir -p "$TARGET_DIR"

        ${if development then ''
          ln -sfnT "$REPO_DIR/manifest.json" "$TARGET_DIR/manifest.json"
          ln -sfnT "$REPO_DIR/theme.css" "$TARGET_DIR/theme.css"
          echo "Enlaces de desarrollo creados en $TARGET_DIR"
        '' else ''
          # Desvincular enlaces anteriores, nunca escribir a través de ellos.
          cp --remove-destination -T "$REPO_DIR/manifest.json" "$TARGET_DIR/manifest.json"
          cp --remove-destination -T "$REPO_DIR/theme.css" "$TARGET_DIR/theme.css"
          echo "Copias independientes instaladas en $TARGET_DIR"
        ''}

        APPEARANCE_FILE="$TARGET_VAULT/.obsidian/appearance.json"
        if [ -f "$APPEARANCE_FILE" ]; then
          ${pkgs.jq}/bin/jq '.cssTheme = "Mytheme"' "$APPEARANCE_FILE" > "$APPEARANCE_FILE.tmp" && mv "$APPEARANCE_FILE.tmp" "$APPEARANCE_FILE"
          echo "✅ Tema activo configurado a 'Mytheme' en appearance.json"
        fi
      '';

      installTheme = makeInstaller false;
      installThemeDev = makeInstaller true;
    in
    {
      packages.${system}.default = pkgs.stdenv.mkDerivation {
        pname = "obsidian-mytheme";
        version = "1.0.1";
        src = self;
        nativeBuildInputs = [ pkgs.dart-sass ];
        buildPhase = ''
          sass src/theme.scss theme.css
        '';
        installPhase = ''
          mkdir -p $out
          cp manifest.json theme.css $out/
        '';
      };

      apps.${system} = {
        build = {
          type = "app";
          program = "${buildTheme}/bin/build-theme";
        };
        watch = {
          type = "app";
          program = "${watchTheme}/bin/watch-theme";
        };
        install = {
          type = "app";
          program = "${installTheme}/bin/install-theme";
        };
        install-dev = {
          type = "app";
          program = "${installThemeDev}/bin/install-theme-dev";
        };
      };

      devShells.${system}.default = pkgs.mkShell {
        buildInputs = [
          pkgs.dart-sass
          pkgs.jq
          buildTheme
          watchTheme
          installTheme
          installThemeDev
        ];
      };
    };
}
