{ lib
, buildPythonPackage
, pytestCheckHook
, rust
, stdenv
, cargo
, rustPlatform
, maturin
, which
}:

let
  filterSrcByPrefix = src: prefixList:
    lib.cleanSourceWith {
      filter = (path: type:
        let relPath = lib.removePrefix (toString ./. + "/") (toString path);
        in lib.any (prefix: lib.hasPrefix prefix relPath) prefixList);
      inherit src;
    };

in buildPythonPackage rec {
  pname = "pyfst";
  version = "0.1.0";
  format = "pyproject";

  src = filterSrcByPrefix ./. [
    "pyproject.toml"
    "src"
    "Cargo.lock"
    "Cargo.toml"
    "tests"
  ];

  cargoDeps = rustPlatform.fetchCargoTarball {
    inherit src;
    name = "${pname}-${version}";
    hash = "sha256:1wnn2fbkbi20bsqpq9yb6iwafdxkcfkndmziva2wrb8zcyg25n3w";
  };

  nativeBuildInputs = with rustPlatform; [
    cargoSetupHook
    maturinBuildHook
  ];
  checkInputs = [ pytestCheckHook ];
  pythonImportsCheck = [ "pyfst" ];

  meta = with lib; {
    homepage = "https://github.com/rmcgibbo/pyfst";
    description = "Python bindings for FST";
    license = licenses.mit;
  };
}
