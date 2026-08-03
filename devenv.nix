{ pkgs, ... }:
{
  # The launcher resolves the Package Skill by immutable Git SHA and drives
  # OpenTofu plus Ansible. Provider CLIs are diagnostic conveniences only.
  languages.clojure.enable = true;
  languages.ansible.enable = true;
  languages.opentofu.enable = true;

  packages = with pkgs; [
    awscli2
    babashka
    doctl
    fluxcd
    jq
    kubectl
    openssh
  ];
}
