{
  description = "Python bindings for FST";
  inputs.nixpkgs.url = "github:NixOS/nixpkgs";
  inputs.py-utils.url = "github:rmcgibbo/python-flake-utils";
  inputs.utils.url = "github:numtide/flake-utils";

  outputs = { self, nixpkgs, utils, py-utils }: {
    overlay = py-utils.lib.mkPythonOverlay (pkgs: {
      pyfst = pkgs.callPackage ./. { };
    });
   } //
    utils.lib.eachDefaultSystem (system:
    let
      pkgs = import nixpkgs {
        inherit system;
        overlays = [ self.overlay ]; };
    in {
      defaultPackage = pkgs.python3.pkgs.pyfst;
    });
}
