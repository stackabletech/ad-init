{ sources ? import nix/sources.nix
, pkgs ? import sources.nixpkgs {} }:

let
  python = pkgs.python3;
  extraAnsibleDeps = pypkgs: [
    # community.libvirt
    pypkgs.libvirt pypkgs.lxml

    # kubernetes.core
    pypkgs.kubernetes
  ];
in
pkgs.mkShell rec {
  # buildInputs = [ pkgs.ansible ];
  buildInputs = [ ansible ];

  # Ansible barfs when it doesn't recognize the locale, and may not have *your*
  # locale available, so...
  LC_ALL = "C.UTF-8";

  # Ansible runs plugins in its own interpreter, so we need to add plugin dependencies to
  # its Python environment
  ansible = python.pkgs.toPythonApplication
    (python.pkgs.ansible-core.overridePythonAttrs (old: {
      propagatedBuildInputs = old.propagatedBuildInputs ++ extraAnsibleDeps python.pkgs;
    }));

  # Ansible runs modules in a separate interpreter, which bypasses Nix's added packages
  # Hence, override that interpreter with one that has the required dependencies installed
  ansiblePython = pkgs.python3.withPackages extraAnsibleDeps;
  ANSIBLE_PYTHON_INTERPRETER = ansiblePython + "/bin/python";
}
