{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = {
    nixpkgs,
    flake-utils,
    ...
  }:
    flake-utils.lib.eachDefaultSystem (
      system: let
        version = "1.8.0";
        pkgs = import nixpkgs {inherit system;};
        inherit (pkgs) stdenv lib;

        pyffmpeg = pkgs.python3Packages.buildPythonPackage rec {
          pname = "pyffmpeg";
          version = "2.4.2.18.1";
          pyproject = true;
          GITHUB_REF = "refs/tags/v2.4.2.18.1-linux";

          src = pkgs.fetchFromGitHub {
            owner = "deuteronomy-works";
            repo = "pyffmpeg";
            rev = "fbbbc13d5e1a2bb60814f06ca440ebffe10703fb";
            sha256 = "sha256-IjLeKlmmZapPUxudOeIq/AfeYj99olZxoRR1hJhk4x0=";
          };

          propagatedBuildInputs = with pkgs.python3Packages; [
            requests
            # py7zr
            setuptools
            wheel
            twine

            # setuptools
          ];

          nativeBuildInputs = with pkgs.python3Packages; [
            requests
            # py7zr
            setuptools
            wheel
            twine

            setuptools
          ];
          # pythonImportsCheck = ["ffmpeg"];

          meta = {
            homepage = "https://github.com/deuteronomy-works/pyffmpeg";
            description = " FFmpeg wrapper for python ";
            maintainers = with lib.maintainers; [];
          };
        };

        py311-deps = ps:
          with ps; [
            ffmpeg-python
            pyside6
            mutagen
            unidecode
          ];

        setupPy = pkgs.writeText "setup.py" ''
          from setuptools import setup
          setup(
            name='infinite-music-discs',
            version='${version}',
            scripts=[
              'main.pyw',
            ],
          )
        '';
      in {
        packages.default = pkgs.python3Packages.buildPythonApplication rec {
          pname = "infinite-music-discs";
          inherit version;

          src = ./.;

          nativeBuildInputs = with pkgs; [copyDesktopItems makeWrapper];

          propagatedBuildInputs = with pkgs.python3Packages; [
            pyside6
            pyffmpeg
            mutagen
            unidecode

            # requests
          ];

          # wrap manually to avoid having a bash script in $out/bin with a .py extension
          dontWrapPythonPrograms = true;

          doCheck = false; # No tests defined
          # pythonImportsCheck = ["OneDriveGUI"];

          # desktopItems = [
          #   (makeDesktopItem {
          #     name = "OneDriveGUI";
          #     exec = "onedrivegui";
          #     desktopName = "OneDriveGUI";
          #     comment = "OneDrive GUI Client";
          #     type = "Application";
          #     icon = "OneDriveGUI";
          #     terminal = false;
          #     categories = ["Utility"];
          #   })
          # ];

          postPatch = ''
            # Patch OneDriveGUI.py so DIR_PATH points to shared files location
            # sed -i src/OneDriveGUI.py -e "s@^DIR_PATH =.*@DIR_PATH = '$out/share/OneDriveGUI'@"

            cp ${setupPy} ${setupPy.name}
          '';

          postInstall = ''
            # we put our own executable wrapper in place instead
            rm -r $out/bin/*

            mkdir $out/lib/${pkgs.python3Packages.python.libPrefix}/site-packages-tmp/
            mv $out/lib/${pkgs.python3Packages.python.libPrefix}/site-packages/* $out/lib/${pkgs.python3Packages.python.libPrefix}/site-packages-tmp/
            mkdir $out/lib/${pkgs.python3Packages.python.libPrefix}/site-packages/src
            mv $out/lib/${pkgs.python3Packages.python.libPrefix}/site-packages-tmp/* $out/lib/${pkgs.python3Packages.python.libPrefix}/site-packages/src
            rm -r $out/lib/${pkgs.python3Packages.python.libPrefix}/site-packages-tmp/

            cp ./main.pyw $out/lib/${pkgs.python3Packages.python.libPrefix}/site-packages/
            cp -r ./build $out/lib/${pkgs.python3Packages.python.libPrefix}/site-packages/
            cp -r ./data $out/lib/${pkgs.python3Packages.python.libPrefix}/site-packages/

            makeWrapper ${pkgs.python3Packages.python.interpreter} $out/bin/infinite-music-discs \
              --prefix PYTHONPATH : ${pkgs.python3Packages.makePythonPath (propagatedBuildInputs ++ [(placeholder "out")])} \
              --add-flags $out/lib/${pkgs.python3Packages.python.libPrefix}/site-packages/main.pyw
          '';

          meta = {
            description = "Tool for adding lots of custom music discs to Minecraft ";
            homepage = "https://github.com/TeamTernate/infinite-music-discs";
            maintainers = with lib.maintainers; [];
            platforms = lib.platforms.linux;
          };
        };
      }
    );
}
