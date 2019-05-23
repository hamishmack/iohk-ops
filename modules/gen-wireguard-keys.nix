{ hosts ? [ "monitoring" ] }:

let
  pkgs = import (import ../fetch-nixpkgs.nix) {};
in pkgs.stdenv.mkDerivation {
  name = "gen-wireguard-keys";
  buildInputs = [ pkgs.wireguard ];
  shellHook = ''
    cd ${toString ../static}
    umask 077
    for host in ${toString hosts}; do
      wg genkey > ''${host}.wgprivate
      wg pubkey < ''${host}.wgprivate > ''${host}.wgpublic
    done
    exit 0
  '';
}
