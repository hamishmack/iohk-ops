{ resources, config, pkgs, lib, nodes, ... }:

with lib;

let
  hydraDnsName = "mantis-hydra.aws.iohkdev.io";
  commonBuildMachineOpt = {
    speedFactor = 1;
    sshKey = "/etc/nix/id_buildfarm";
    sshUser = "root";
    system = "x86_64-linux";
    supportedFeatures = [ "kvm" "nixos-test" ];
  };
  mkLinux = hostName: commonBuildMachineOpt // {
    inherit hostName;
    maxJobs = 4;
  };
in {
  environment.etc = lib.singleton {
    target = "nix/id_buildfarm";
    source = ../static/id_buildfarm2;
    uid = config.ids.uids.hydra;
    gid = config.ids.gids.hydra;
    mode = "0440";
  };

  nix = {
    buildMachines = [
      (mkLinux "mantis-slave-packet-1.aws.iohkdev.io")
      (mkLinux "mantis-slave-packet-2.aws.iohkdev.io")
    ];
    gc.automatic = true;

    distributedBuilds = true;
    binaryCaches = mkForce [ "https://cache.nixos.org" ];
  };

  services.fail2ban.enable = true;
  virtualisation.docker.enable = true;

  services.hydra = {
    hydraURL = "https://${hydraDnsName}";
    package = pkgs.callPackage ./hydra-fork.nix { nixpkgsPath = pkgs.path;
      src = pkgs.fetchFromGitHub {
        owner = "input-output-hk";
        repo = "hydra";
        rev = "5f30a105edeecf7c3408e56832a859e4385f06cb";
        sha256 = "102b085wmcnwl1qk077js8rv77f5y6jr0rnc3m6r25662h4lz7l4";
      };
    };
    # max output is 4GB because of amis
    # auth token needs `repo`
    extraConfig = ''
      max_output_size = 4294967296
      store-uri = file:///nix/store?secret-key=/etc/nix/${hydraDnsName}-1/secret
      binary_cache_secret_key_file = /etc/nix/${hydraDnsName}-1/secret
      <github_authorization>
        input-output-hk = ${builtins.readFile ../static/github_token_mantis_hydra}
      </github_authorization>
    '';
  };

  services.nginx = {
    virtualHosts = {
      "${hydraDnsName}" = {
        forceSSL = true;
        enableACME = true;
        locations."/".extraConfig = ''
          proxy_pass http://127.0.0.1:8080;
          proxy_set_header Host $http_host;
          proxy_set_header REMOTE_ADDR $remote_addr;
          proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
          proxy_set_header X-Forwarded-Proto https;
        '';
      };
    };
    commonHttpConfig = ''
      server_names_hash_bucket_size 64;
      keepalive_timeout   70;
      gzip            on;
      gzip_min_length 1000;
      gzip_proxied    expired no-cache no-store private auth;
      gzip_types      text/plain application/xml application/javascript application/x-javascript text/javascript text/xml text/css;
    '';
  };
}
