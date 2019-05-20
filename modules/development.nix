{ name, config, resources, ... }:

with import ./../lib.nix;
{
  config = {

    global = {
      allocateElasticIP            = false;
      enableEkgWeb                 = true;
      dnsHostname                  = "${name}-${config.deployment.name}";
      dnsDomainname                = "aws.iohkdev.io";
      omitDetailedSecurityGroups   = true;
    };

    services = {
      # DEVOPS-64: disable log bursting
      journald.rateLimitBurst    = 0;
      journald.extraConfig       = "SystemMaxUse=50M";

      monitoring-exporters.enable = true;
      monitoring-exporters.metrics = true;
      # Monitoring server currently not enabled in the development environment
      monitoring-exporters.logging = false;
    };

  };
}
