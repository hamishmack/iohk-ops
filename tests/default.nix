{ pkgs ? (import <nixpkgs> {}), supportedSystems ? [ "x86_64-linux" ] }:

with pkgs;
with pkgs.lib;

let
  forAllSystems = genAttrs supportedSystems;
  importTest = fn: args: system: import fn ({
    inherit system;
  } // args);
  callTest = fn: args: forAllSystems (system: hydraJob (importTest fn args system));
  hydraLocally = import ../modules/test-hydra-locally.nix;
in rec {
  inherit hydraLocally;
  # TODO: tests of images
  # simpleNode = callTest ./simple-node.nix {};
  # simpleNodeNixOps = callTest ./simple-node-nixops.nix {};

}
