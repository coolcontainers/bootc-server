A collection of atomic bootc images for servers based on fedora-bootc

Build a container image locally:

```bash
sudo just profile=proxy pull
sudo just profile=proxy build
```

Build an interactive Anaconda installer ISO image:

```bash
just prepare_interactive
sudo podman pull ghcr.io/coolcontainers/proxy:44
sudo just registry=ghcr.io/coolcontainers image=bootc-server tag=44 profile=proxy disk
```

Build an unattended Anaconda installer ISO image:

```bash
just prepare_unattended user defaultpassword "ssh-ed25519 abcdef123456..."
sudo podman pull ghcr.io/coolcontainers/bootc-server:44
sudo just registry=ghcr.io/coolcontainers image=bootc-server tag=44 profile=proxy disk_type=anaconda-iso disk
```

## Images

- ghcr.io/coolcontainers/nas - image for a home NAS
- ghcr.io/coolcontainers/proxy - proxy server
- ghcr.io/coolcontainers/raspberry-pi - image for a Raspberry Pi home server

## Compatible software

### Nextcloud

Nextcloud can be installed on the NAS image using [LorbusChris/nextcloud-quadlet](https://github.com/LorbusChris/nextcloud-quadlet)
and ansible. Ports are already configured in the default firewall config.

## Known issues

### `systemd-remount-fs.service` fails on boot

Happens because Anaconda adds an fstab entry for `/`. Tracked here: https://github.com/bootc-dev/bootc/issues/971

To fix simply remove the `/` entry from fstab
