{ lib
, buildPythonPackage
, pytestCheckHook
, rustPlatform
, maturin
, pythonX
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

buildPythonPackage rec {
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
    hash = "sha256:19fkq71mls6rik9kkszjc734xvsjrx88516gj3g6mvqsyrb3angc";
  };

  nativeBuildInputs = with rustPlatform; [ cargoSetupHook maturinBuildHook pythonX ];
  checkInputs = [ pytestCheckHook ];
  pythonImportsCheck = [ "pyfst" ];

  meta = with lib; {
    homepage = "https://github.com/rmcgibbo/pyfst";
    description = "Python bindings for FST";
    license = licenses.mit;
  };
}
