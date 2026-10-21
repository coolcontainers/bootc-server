A collection of atomic bootc images for servers based on fedora-bootc

Build a container image locally:

```bash
sudo just pull
sudo just build
```

Build an interactive Anaconda installer ISO image:

```bash
just prepare_interactive
sudo podman pull ghcr.io/coolcontainers/bootc-server:44
sudo just registry=ghcr.io/coolcontainers image=bootc-server tag=44 disk
```

Build an unattended Anaconda installer ISO image:

```bash
just prepare_unattended user defaultpassword "ssh-ed25519 abcdef123456..."
sudo podman pull ghcr.io/coolcontainers/bootc-server:44
sudo just registry=ghcr.io/coolcontainers image=bootc-server tag=44 disk_type=anaconda-iso disk
```

## Compatible software

### Nextcloud

Nextcloud can be installed on the NAS image using [LorbusChris/nextcloud-quadlet](https://github.com/LorbusChris/nextcloud-quadlet)
and ansible. Ports are already configured in the default firewall config.

## Known issues

### `systemd-remount-fs.service` fails on boot

Happens because Anaconda adds an fstab entry for `/`. Tracked here: https://github.com/bootc-dev/bootc/issues/971

To fix simply remove the `/` entry from fstab
