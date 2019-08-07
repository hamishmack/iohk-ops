let
  nodeMap = import ./cardano-node-simple-config.nix;
in
import <nixpkgs/nixos/tests/make-test.nix> ({ pkgs, ... }: {
  name = "boot";
  nodes = {
    machine = { config, pkgs, ... }: {
      imports = [ (import ../modules/cardano.nix (nodeMap.machine)) <nixops/nix/options.nix> <nixops/nix/resource.nix> ];
      services.cardano-node-legacy = {
        autoStart = true;
        neighbours = [];
      };
    };
  };
  testScript = ''
    startAll
    $machine->waitForUnit("cardano-node.service");
    # TODO, implement sd_notify?
    $machine->waitForOpenPort(3000);
  '';
})
