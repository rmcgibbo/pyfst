{ lib
, python38
, rustPlatform
, maturin
}:

let
  filterSrcByPrefix = src: prefixList:
    lib.cleanSourceWith {
      filter = (path: type:
        let relPath = lib.removePrefix (toString ./. + "/") (toString path);
        in lib.any (prefix: lib.hasPrefix prefix relPath) prefixList);
      inherit src;
    };
in

python38.pkgs.buildPythonPackage rec {
  pname = "pyfst";
  version = "0.1.0";
  format = "pyproject";

  src = filterSrcByPrefix ./. [
    "pyproject.toml"
    "src"
    "Cargo.lock"
    "Cargo.toml"
    "tests"
    "tox.ini"
  ];

  cargoDeps = rustPlatform.fetchCargoTarball {
    inherit src;
    name = "${pname}-${version}";
    hash = "sha256:19fkq71mls6rik9kkszjc734xvsjrx88516gj3g6mvqsyrb3angc";
  };

  nativeBuildInputs = with rustPlatform; [ cargoSetupHook maturinBuildHook ];
  checkInputs = [ python38.pkgs.pytestCheckHook ];
  pythonImportsCheck = [ "pyfst" ];

  meta = with lib; {
    homepage = "https://github.com/kushaldas/johnnycanencrypt";
    description = "Python module for OpenPGP written in Rust";
    license = licenses.gpl3Plus;
    maintainers = with maintainers; [ _0x4A6F ];
  };
}
