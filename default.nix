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
    hash = "sha256:19fkq71mls6rik9kkszjc734xvsjrx88516gj3g6mvqsyrb3angc";
  };

  nativeBuildInputs = [ which ] ++ ( with rustPlatform; [ cargoSetupHook cargo maturin ] );
  checkInputs = [ pytestCheckHook ];
  pythonImportsCheck = [ "pyfst" ];

  buildPhase = with rustPlatform;
    let
      ccForBuild = "${stdenv.cc}/bin/${stdenv.cc.targetPrefix}cc";
      cxxForBuild = "${stdenv.cc}/bin/${stdenv.cc.targetPrefix}c++";
      ccForHost = "${stdenv.cc}/bin/${stdenv.cc.targetPrefix}cc";
      cxxForHost = "${stdenv.cc}/bin/${stdenv.cc.targetPrefix}c++";
      rustBuildPlatform = rust.toRustTarget stdenv.buildPlatform;
      rustTargetPlatform = rust.toRustTarget stdenv.hostPlatform;
      rustTargetPlatformSpec = rust.toRustTargetSpec stdenv.hostPlatform;
    in ''
      echo "Executing maturinBuildHook"
      runHook preBuild

      (
      set -x
      env \
        "CC_${rustBuildPlatform}=${ccForBuild}" \
        "CXX_${rustBuildPlatform}=${cxxForBuild}" \
        "CC_${rustTargetPlatform}=${ccForHost}" \
        "CXX_${rustTargetPlatform}=${cxxForHost}" \
        maturin build \
          --cargo-extra-args="-j $NIX_BUILD_CORES --frozen" \
          --target ${rustTargetPlatformSpec} \
          --manylinux off \
          --interpreter $(which python) \
          --strip \
          --release
      )

      runHook postBuild
      # Move the wheel to dist/ so that regular Python tooling can find it.
      mkdir -p dist
      mv target/wheels/*.whl dist/

      echo "Finished maturinBuildHook"
    '';

  meta = with lib; {
    homepage = "https://github.com/rmcgibbo/pyfst";
    description = "Python bindings for FST";
    license = licenses.mit;
  };
}
