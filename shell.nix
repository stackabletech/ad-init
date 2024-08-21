{ sources ? import nix/sources.nix
, pkgs ? import sources.nixpkgs {} }:

with pkgs;

mkShell {
  buildInputs = [ pkgs.ansible ];

  # Ansible runs modules in a separate interpreter, which bypasses Nix's added packages
  # Hence, override that interpreter with one that has the required dependencies installed
  ANSIBLE_PYTHON_INTERPRETER = pkgs.python3.withPackages (pkgs: [
    # community.libvirt
    pkgs.libvirt pkgs.lxml
  ]) + "/bin/python";
}
