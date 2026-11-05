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

      installTheme = pkgs.writeShellScriptBin "install-theme" ''
        set -e
        REPO_DIR="$(pwd)"
        DEFAULT_VAULT="/home/manu/Documents/repositorios/MizarOS/obsidian/Vault_base"
        TARGET_VAULT="''${TARGET_VAULT:-$DEFAULT_VAULT}"
        TARGET_DIR="$TARGET_VAULT/.obsidian/themes/Mytheme"

        if [ ! -f "$REPO_DIR/theme.css" ]; then
          echo "⚙️ theme.css no encontrado, compilando..."
          ${pkgs.dart-sass}/bin/sass src/theme.scss theme.css
        fi

        echo "🔗 Instalando artefactos de Mytheme en $TARGET_VAULT..."
        mkdir -p "$TARGET_DIR"

        ln -sfnT "$REPO_DIR/manifest.json" "$TARGET_DIR/manifest.json"
        ln -sfnT "$REPO_DIR/theme.css" "$TARGET_DIR/theme.css"
        echo "✅ Enlaces individuales creados en $TARGET_DIR (manifest.json, theme.css)"

        APPEARANCE_FILE="$TARGET_VAULT/.obsidian/appearance.json"
        if [ -f "$APPEARANCE_FILE" ]; then
          ${pkgs.jq}/bin/jq '.cssTheme = "Mytheme"' "$APPEARANCE_FILE" > "$APPEARANCE_FILE.tmp" && mv "$APPEARANCE_FILE.tmp" "$APPEARANCE_FILE"
          echo "✅ Tema activo configurado a 'Mytheme' en appearance.json"
        fi
      '';
    in
    {
      packages.${system}.default = pkgs.stdenv.mkDerivation {
        pname = "obsidian-mytheme";
        version = "1.0.0";
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
      };

      devShells.${system}.default = pkgs.mkShell {
        buildInputs = [
          pkgs.dart-sass
          pkgs.jq
          buildTheme
          watchTheme
          installTheme
        ];
      };
    };
}
