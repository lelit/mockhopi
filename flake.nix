# -*- coding: utf-8 -*-
# :Project:   HoPi —
# :Created:   lun 3 gen 2022, 15:47:26
# :Author:    Lele Gaifax <lele@metapensiero.it>
# :License:   No license
# :Copyright: © 2022, 2023 eTour s.r.l.
#

{
  description = "MockHoPi";

  inputs = {
    flake-utils.url = "github:numtide/flake-utils";
    nixpkgs.url = "github:NixOS/nixpkgs";
    nixos-generators = {
      url = "github:nix-community/nixos-generators";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    poetry2nix = {
      url = "github:nix-community/poetry2nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, flake-utils, nixpkgs, nixos-generators, poetry2nix }:
    let
      overlay = final: prev:
        let
          pkgs = final;
          # This must match the --nodejs-xx in assets/Makefile
          nodejs = pkgs.nodejs-18_x;
        in {
          hopi = rec {
            py = pkgs.python311;
            pyPkgs = pkgs.python311Packages;

            assetsPkgs = import ./assets {
              inherit pkgs nodejs;
            };
            assetsUtils = assetsPkgs.shell.nodeDependencies.overrideAttrs (attrs: {
              buildInputs = attrs.buildInputs ++ [ pkgs.makeWrapper ];
              # wrap nodejs-based executables so that they will correctly find
              # their libraries.
              preFixup = ''
                  rm -f $out/bin
                  mkdir -p $out/bin
                  for f in $(find $out/lib/node_modules/.bin -type l -executable); do
                    makeWrapper $f $out/bin/$(basename $f) --set NODE_PATH $out/lib/node_modules
                  done
                '';
            });
            poetryOverrides = pkgs.poetry2nix.defaultPoetryOverrides.overrideOverlay (self: super: {
              attrs = super.attrs.overridePythonAttrs (old: {
                nativeBuildInputs = (old.nativeBuildInputs or [ ]) ++ [
                  self.hatchling
                  self.hatch-fancy-pypi-readme
                  self.hatch-vcs
                ];
              });
              "click-didyoumean" = super."click-didyoumean".overridePythonAttrs (old: {
                nativeBuildInputs = (old.nativeBuildInputs or [ ]) ++ [ self.poetry-core ];
              });
              codext = super.codext.overridePythonAttrs (old: {
                nativeBuildInputs = (old.nativeBuildInputs or [ ]) ++ [ self.setuptools ];
              });
              colander = super.colander.overridePythonAttrs (old: {
                nativeBuildInputs = (old.nativeBuildInputs or [ ]) ++ [
                  self.babel
                  self.setuptools
                ];
              });
              # rlPyCairo requires freetype-py > 2.3, nixpkgs has 2.1.0.post1
              freetype-py = super.freetype-py.overridePythonAttrs (old: rec {
                version = "2.4.0";
                src = pkgs.fetchFromGitHub {
                  owner = "rougier";
                  repo = old.pname;
                  rev = "v${version}";
                  hash = "sha256-GmIDSbJ/xGtzYNQZq73skx1HRI9ArUaM+KPhBg55bvM=";
                };
              });
              # Building Furo from its source requires sphinx-theme-builder, that in turn
              # wants nodeenv... take the easy path and slurp the prebuilt wheel instead
              furo = super.furo.override { preferWheel = true; };
              html-diff = super.html-diff.overridePythonAttrs (old: {
                nativeBuildInputs = (old.nativeBuildInputs or [ ]) ++ [ self.poetry ];
              });
              iniconfig = super.iniconfig.overridePythonAttrs (old: {
                nativeBuildInputs = (old.nativeBuildInputs or [ ]) ++ [
                  self.hatchling
                  self.hatch-vcs
                ];
              });
              "metapensiero-deform-semantic-ui" = super."metapensiero-deform-semantic-ui".overridePythonAttrs (old: {
                nativeBuildInputs = (old.nativeBuildInputs or [ ]) ++ [ self.setuptools ];
              });
              "metapensiero-markup-semtext" = super."metapensiero-markup-semtext".overridePythonAttrs (old: {
                nativeBuildInputs = (old.nativeBuildInputs or [ ]) ++ [ self.setuptools ];
              });
              "metapensiero-sphinx-autodoc-sa" = super."metapensiero-sphinx-autodoc-sa".overridePythonAttrs (old: {
                nativeBuildInputs = (old.nativeBuildInputs or [ ]) ++ [ self.pdm-pep517 ];
              });
              "metapensiero-sphinx-patchdb" = super."metapensiero-sphinx-patchdb".overridePythonAttrs (old: {
                nativeBuildInputs = (old.nativeBuildInputs or [ ]) ++ [ self.pdm-pep517 ];
              });
              "metapensiero-sqlalchemy-dbloady" = super."metapensiero-sqlalchemy-dbloady".overridePythonAttrs (old: {
                nativeBuildInputs = (old.nativeBuildInputs or [ ]) ++ [ self.pdm-pep517 ];
              });
              "metapensiero-sqlalchemy-proxy" = super."metapensiero-sqlalchemy-proxy".overridePythonAttrs (old: {
                nativeBuildInputs = (old.nativeBuildInputs or [ ]) ++ [ self.pdm-pep517 ];
              });
              "metapensiero-tool-tinject" = super."metapensiero-tool-tinject".overridePythonAttrs (old: {
                nativeBuildInputs = (old.nativeBuildInputs or [ ]) ++ [ self.pdm-pep517 ];
              });
              # Use nixpkgs version of Pillow, to avoid long compilation
              pillow = pyPkgs.pillow;
              "psycopg-c" = super."psycopg-c".overridePythonAttrs (old: {
                nativeBuildInputs = (old.nativeBuildInputs or [ ]) ++ [
                  pkgs.postgresql_15
                  self.setuptools
                  self.tomli
                ];
              });
              "pyramid-tm" = super."pyramid-tm".overridePythonAttrs (old: {
                nativeBuildInputs = (old.nativeBuildInputs or [ ]) ++ [ self.setuptools ];
              });
              pyrxp = super.pyrxp.overridePythonAttrs (old: {
                nativeBuildInputs = (old.nativeBuildInputs or [ ]) ++ [ self.setuptools ];
              });
              publicsuffix2 = super.publicsuffix2.overridePythonAttrs (old: {
                nativeBuildInputs = (old.nativeBuildInputs or [ ]) ++ [
                  self.requests
                  self.setuptools
                ];
              });
              rl-accel = pyPkgs.buildPythonPackage rec {
                pname = "rl-accel";
                version = "0.9.0";
                src = pkgs.fetchhg {
                  url = "https://hg.reportlab.com/hg-public/rl-accel";
                  rev = "7e290653ed6a1d1de6b6b2bc3bd04f2dbc4e93d1";
                  hash = "sha256-FeiQOHMlXUL9gpwe3tlfON8ZBymgmPqiMd6SkCgZLhM=";
                };
              };
              rlpycairo = pyPkgs.buildPythonPackage rec {
                pname = "rlpycairo";
                version = "0.3.0";
                src = pkgs.fetchhg {
                  url = "https://hg.reportlab.com/hg-public/rlPyCairo";
                  rev = "3c6cc9281052a358b18faf5993bb25eaa9c4e1de";
                  hash = "sha256-KlGG1Qw/TYkq96cE2cwqftZKozprbbufh4xpWoXLOL8=";
                };
                propagatedBuildInputs = [
                  self.freetype-py
                  self.pycairo
                ];
                doCheck = false;
              };
              reportlab = super.reportlab.overridePythonAttrs (old: {
                nativeBuildInputs = (old.nativeBuildInputs or [ ]) ++ [ self.setuptools ];
                propagatedBuildInputs = (old.propagatedBuildInputs or [ ]) ++ [
                  self.rl-accel
                  self.rlpycairo
                ];
              });
              sphinx = super.sphinx.overridePythonAttrs (old: {
                nativeBuildInputs = (old.nativeBuildInputs or [ ]) ++ [ self.flit-core ];
              });
              sphinxcontrib-applehelp = super.sphinxcontrib-applehelp.overridePythonAttrs (old: {
                nativeBuildInputs = (old.nativeBuildInputs or [ ]) ++ [
                  self.flit-core
                  self.setuptools
                ];
              });
              sqlparse = super.sqlparse.overridePythonAttrs (old: {
                nativeBuildInputs = (old.nativeBuildInputs or [ ]) ++ [ self.flit-core ];
              });
              "zope-sqlalchemy" = super."zope-sqlalchemy".overridePythonAttrs (old: {
                nativeBuildInputs = (old.nativeBuildInputs or [ ]) ++ [ self.setuptools ];
              });
            });

            hopiEnv = pkgs.poetry2nix.mkPoetryEnv {
              projectDir = ./.;
              python = py;

              editablePackageSources = {
                hopi = ./hopi;
              };

              overrides = poetryOverrides;
            };

            # See https://github.com/microsoft/pyright/blob/main/docs/configuration.md
            pyrightConf = builtins.toJSON {
              extraPaths = [ "${hopiEnv}/lib/python${py.pythonVersion}/site-packages" ];
            };

            runtimePackages = [
              pkgs.dejavu_fonts
              pkgs.nginx
              pkgs.poppler_utils
              pkgs.postgresql_15
              pkgs.redis
            ];

            buildPackages = [
              pkgs.gettext
              nodejs
              pkgs.plantuml

              assetsUtils
            ];

            developmentPackages = [
              pkgs.gnumake
              pkgs.just
              pkgs.nodePackages.node2nix
              pkgs.pspg
              pkgs.tmux

              pyPkgs.pgcli
              pkgs.poetry

              (pyPkgs.buildPythonPackage rec {
                pname = "metapensiero.tool.banner";
                version = "0.1";
                src = pyPkgs.fetchPypi {
                  inherit pname version;
                  sha256 = "5a743d9a14dd0754b7e38a5e9b1f43cdf036442372fd5836aa4f919badcb273c";
                };
              })
            ];

            pdfjs =
              let
                version = "3.5.141";
              in pkgs.fetchzip rec {
                name = "pdfjs-${version}";
                url = "https://github.com/mozilla/pdf.js/releases/download/v${version}/${name}-dist.zip";
                sha256 = "sha256-93uwQZMYJLZjMCaN8Z6C+CQcJHlEaoD7+36nZbl0eXk=";
                stripRoot = false;
              };

            assets = pkgs.stdenv.mkDerivation {
              pname = "hopi-assets";
              version = "2.0.0";
              src = ./assets;
              buildInputs = [ assetsUtils ];
              buildPhase = ''
                  ln -s "${assetsUtils}/lib/node_modules" node_modules
                  webpack --mode production --output-path ./dist/
                '';
              installPhase = ''
                  mkdir -p $out
                  cp -r dist/* $out
                '';
            };
          };
        };
    in flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          overlays = [ poetry2nix.overlay overlay ];
        };
      in {
        devShell = pkgs.mkShell {
          name = "MockHoPi";

          packages = with pkgs.hopi; [ hopiEnv ]
                                     ++ runtimePackages
                                     ++ buildPackages
                                     ++ developmentPackages;
        };
        packages.default = pkgs.buildEnv {
          name = "mockhopi";
          paths = with pkgs.hopi; [ hopiEnv ]
                                  ++ runtimePackages
                                  ++ buildPackages
                                  ++ developmentPackages;
        };
      });
}
