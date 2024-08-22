# ad-init

## What is it?

A testing tool that installs and configures a Windows VM with Active Directory, and configures a Stackable Data Platform
cluster to use it.

The latter includes, for example:

- Rewriting the Kubernetes Corefile to delegate DNS for the AD domain
- Creating a SecretClass for provisioning Kerberos principals
- Creating a user for the SecretClass
- Installing credentials for the above into the Kubernetes cluster

## What isn't it?

It does not configure a production-ready cluster. For example, many passwords will be the hard-coded dummy value "Asdf1234".

It also assumes that the Kubernetes cluster and Windows VM will be running on the same machine, or have full connectivity between each other.

## Prerequisites

- Libvirt and QEMU
- Ansible
- A Windows Server installation ISO (download from https://www.microsoft.com/en-us/evalcenter/download-windows-server-2022)
- A Kubernetes cluster (kind is suggested) running the Stackable Data Platform

When using Nix, you *need* to run inside `direnv` or `nix-shell` (which will provide Ansible for you). Nixpkgs's regular Ansible is *not* enough.

## Using it

1. Put your Windows ISO in `target/Windows Server 2022 EVAL.iso` (or modify `install_iso_windows` to point at it)
2. Run `ansible-playbook install.yaml -i inventory.ini`
3. Wait for the playbook to complete
4. Done!

### Completely unattended on UEFI (noprompt patch)

NOTE: This is mostly a note for any future remigration to UEFI. This patch is not required when using BIOS boot.

The "press any key to boot" prompt can be disabled by patching the Windows ISO, but this requires a slightly manual one-time process as root:

```shell
mkdir tmp
sudo mount "/path/to/Windows Server 2022 EVAL.iso" tmp -o loop -t udf
mkisofs -o windows-2k22-noprompt.iso --udf -eltorito-boot efi/microsoft/boot/efisys_noprompt.bin --iso-level 4 tmp
sudo umount tmp
rmdir tmp
```

After this, `install_iso_windows` can be pointed at `windows-2k22-noprompt.iso` instead to fully automate the process. `ansible-playbook install.yaml -i inventory.ini` should then be enough.

### Running against a preinstalled Windows (such as cloud images)

Generally, a preinstalled Windows can be connected to by setting `ansible_connection=ssh` in `inventory.ini`, for example:

```
sble-addc ansible_connection=ssh ansible_host=1.2.3.4 vm_network_ipv4=1.2.3.4
```

Where `ansible_host` is the IP address that will be connected to, and `vm_network_ipv4` is the address that can be used to connect to the Windows host from the Kubernetes cluster.

*However*, requires SSH to be enabled manually, and for Ansible to have valid SSH authentication credentials to connect.

SSH can be enabled by running the following PowerShell on the Windows target:

``` powershell
Add-WindowsCapability -Online -Name OpenSSH.Server
Start-Service sshd
Set-Service -Name sshd -StartupType 'Automatic'
```

Credentials can be provided to Ansible by adding the `-u USERNAME --ask-pass` flags. Alternatively, you can install your public SSH key to the server instead of using password authentication.

Finally, Kubernetes must still be able to connect to the Windows's LDAP, DNS, and Kerberos services. When running in a cloud environment, this typically means running Kubernetes in the same VPC as the Windows VM.

## Troubleshooting

### LDAP error: connection reset by peer

Once everything installed, it will take a little bit for Windows to decide to provision a certificate for the domain controller. It should resolve itself after a few minutes.
