Below is a complete `README.md` for the revised `setup_ubuntu.sh`.

---

# Ubuntu Setup

A configurable bootstrap script for **Ubuntu 22.04 and 24.04**, intended for development machines and development servers.

It installs system utilities, Docker, Python tooling, PostgreSQL, and a pinned Oh My Zsh configuration, with optional Snap applications and workstation packages.

> **Important:** This is a bootstrap script—not a complete production-hardening solution. Review the script and its remotely downloaded components before running it. Test on a disposable VM or snapshot-backed instance first.

## Contents

- [Requirements](#requirements)
- [Quick start](#quick-start)
- [What gets installed](#what-gets-installed)
- [Configuration reference](#configuration-reference)
- [Common installation profiles](#common-installation-profiles)
- [Docker modes](#docker-modes)
- [Rootless Docker guide](#rootless-docker-guide)
- [Zsh configuration](#zsh-configuration)
- [CLI tools](#cli-tools)
- [PostgreSQL](#postgresql)
- [Git configuration](#git-configuration)
- [Firewall and AWS networking](#firewall-and-aws-networking)
- [Files and directories](#files-and-directories)
- [Execution order](#execution-order)
- [Reruns and updates](#reruns-and-updates)
- [Verification](#verification)
- [Troubleshooting](#troubleshooting)
- [Security and operational limitations](#security-and-operational-limitations)
- [Recovery and removal](#recovery-and-removal)

## Requirements

The script expects:

- Ubuntu **22.04 or 24.04**.
- A running **systemd** instance.
- A normal login user with **sudo access**.
- Bash.
- `sudo` and `flock` already available.
- Internet access to Ubuntu repositories, GitHub, and the selected tool providers.
- Sufficient disk space for packages, Git repositories, Docker images, and PostgreSQL.

Run the script as the account that will own your shell configuration and development tools.

**Do not run it as root or with `sudo ./setup_ubuntu.sh`.**

Correct:

```bash
./setup_ubuntu.sh
```

Incorrect:

```bash
sudo ./setup_ubuntu.sh
```

The script invokes `sudo` internally for system-level changes.

### Unsupported or unverified environments

The script explicitly rejects Ubuntu versions other than 22.04 and 24.04.

It is not intended for:

- Non-Ubuntu distributions.
- Containers without systemd.
- Minimal environments without a normal user login session.
- Automatically migrating existing Docker distributions.
- Unattended production rollouts without additional testing and controls.

WSL requires systemd to be enabled, but WSL compatibility has not been established by this README.

## Quick start

### 1. Obtain the script

Save the revised script as `setup_ubuntu.sh`.

If it is already in your repository, clone the repository and change into the directory containing it.

### 2. Review the defaults

By default, the script installs:

- Core system utilities.
- Rootful Docker, if Docker is absent.
- Docker Rollout.
- Lazydocker.
- Zoxide.
- uv.
- Native PostgreSQL.
- Snap support, ngrok, and tldr.
- Zsh and pinned Oh My Zsh plugins.

It does **not** enable UFW, change your default shell, install laptop power-management packages, or upgrade all installed packages unless requested.

### 3. Run

```bash
chmod +x setup_ubuntu.sh
./setup_ubuntu.sh
```

### 4. Reconnect

Disconnect and reconnect your SSH or desktop login session after setup.

This is important because Docker group membership does not update in an already-running session.

Then start Zsh:

```bash
exec zsh
```

To make Zsh permanent for the current login user:

```bash
sudo usermod --shell "$(command -v zsh)" "$(id -un)"
```

Reconnect again for the login-shell change to take effect.

## What gets installed

### Core APT packages

These packages are installed regardless of optional tool toggles:

| Package | Purpose |
|---|---|
| `software-properties-common` | Repository-management utilities |
| `ca-certificates` | Trusted CA certificates for HTTPS |
| `curl` | HTTP downloads |
| `git` | Source control and plugin downloads |
| `gnupg` | OpenPGP tooling |
| `zsh` | Interactive shell |
| `uidmap` | User namespace helpers, including rootless prerequisites |
| `dbus-user-session` | User-session D-Bus support |
| `slirp4netns` | Rootless networking support |
| `fuse-overlayfs` | Userspace overlay filesystem support |
| `xdg-utils` | Desktop integration helpers such as `xdg-open` |
| `python3` | Python runtime |
| `python3-pip` | Python package installer |
| `python3-venv` | Python virtual environments |
| `pipx` | Isolated installation of Python CLI applications |
| `tmate` | Terminal sharing |
| `ufw` | Host firewall management |
| `dnsutils` | DNS diagnostics |
| `net-tools` | Legacy network utilities |
| `htop` | Interactive process viewer |
| `btop` | Resource monitor |
| `unzip` | ZIP extraction |
| `jq` | JSON processing |

APT installs package dependencies as needed.

The script enables the Ubuntu `universe` repository and uses:

```bash
apt-get install -y --no-install-recommends
```

It also runs:

```bash
pipx ensurepath
```

This may update user shell configuration so pipx-managed applications are discoverable.

### Optional APT packages

| Toggle | Packages | Default |
|---|---|---|
| `INSTALL_POSTGRES` | `postgresql`, `postgresql-contrib` | `true` |
| `INSTALL_SNAPS` | `snapd` | `true` |
| `INSTALL_FASTFETCH` | `fastfetch`, if available in configured repositories | `false` |
| `INSTALL_NETWORK_MANAGER` | `network-manager` | `false` |
| `INSTALL_TLP` | `tlp`, `tlp-rdw` | `false` |

Fastfetch is skipped with a warning when it is unavailable.

NetworkManager and TLP are opt-in because they are generally unnecessary on cloud servers and may interact with existing networking or power-management services.

### Docker packages

When Docker is absent, the script configures Docker’s official Ubuntu APT repository and installs:

- `docker-ce`
- `docker-ce-cli`
- `containerd.io`
- `docker-buildx-plugin`
- `docker-compose-plugin`
- `docker-ce-rootless-extras`

If a `docker` command already exists, the script preserves that installation and checks for Compose v2.

> An existing Docker CLI does not necessarily imply a compatible local Docker Engine. Later service or daemon checks may still fail.

### Other tools

| Tool | Installation source | Default |
|---|---|---|
| Lazydocker | Upstream GitHub installer | Enabled |
| uv | Astral installer | Enabled |
| Zoxide | Upstream GitHub installer | Enabled |
| Docker Rollout | Upstream GitHub script | Enabled with Docker |
| ngrok | Snap Store | Enabled with Snap |
| tldr | Snap Store | Enabled with Snap |

### Shell components

The script installs:

- Oh My Zsh.
- `zsh-autosuggestions`.
- `zsh-completions`.
- `zsh-autocomplete`.
- `zsh-syntax-highlighting`.

Default theme: **`bira`**.

Powerlevel10k is **not installed**.

### Intentionally not installed

- Neofetch.
- Kernel headers.
- A reverse proxy.
- TLS certificates.
- Application stacks.
- Database backups.
- Monitoring agents.
- A secrets manager.

Kernel headers are not generally required for ordinary Docker and application hosting.

## Configuration reference

Options are supplied as environment variables.

Example:

```bash
INSTALL_POSTGRES=false \
INSTALL_SNAPS=false \
./setup_ubuntu.sh
```

Boolean options must be exactly `true` or `false`.

### Identity and shell

| Variable | Default | Description |
|---|---|---|
| `GIT_USER` | `dhimanparas20` | Global Git author name |
| `GIT_EMAIL` | `dhimanparas20@gmail.com` | Global Git author email |
| `ZSH_THEME` | `bira` | Selected Oh My Zsh theme |
| `CHANGE_SHELL_TO_ZSH` | `false` | Change the current user’s login shell |

`ZSH_THEME` is restricted to a simple set of characters, but the script does not verify that every accepted theme name exists.

The specific value `powerlevel10k/powerlevel10k` is rejected because this script does not install Powerlevel10k.

### Installation options

| Variable | Default | Description |
|---|---|---|
| `INSTALL_DOCKER` | `true` | Configure Docker |
| `DOCKER_MODE` | `rootful` | `rootful` or `rootless` |
| `INSTALL_ROLLOUT` | `true` | Install Docker Rollout when Docker setup is enabled |
| `INSTALL_LAZYDOCKER` | `true` | Install Lazydocker if not found |
| `INSTALL_ZOXIDE` | `true` | Install Zoxide if not found |
| `INSTALL_UV` | `true` | Install uv if not found |
| `INSTALL_POSTGRES` | `true` | Install and enable native PostgreSQL |
| `INSTALL_SNAPS` | `true` | Install Snap support, ngrok, and tldr |
| `INSTALL_FASTFETCH` | `false` | Install Fastfetch if available |
| `INSTALL_NETWORK_MANAGER` | `false` | Install NetworkManager |
| `INSTALL_TLP` | `false` | Install laptop power-management tools |

`INSTALL_DOCKER=false` does not automatically disable Lazydocker.

### System and firewall options

| Variable | Default | Description |
|---|---|---|
| `UPGRADE_SYSTEM` | `false` | Run a general `apt-get upgrade` |
| `ENABLE_UFW` | `false` | Configure and enable UFW |
| `ALLOW_WEB_PORTS` | `false` | Allow TCP 80 and 443 when UFW setup is enabled |
| `SSH_PORT` | `22` | TCP port to allow for SSH |
| `PROMPT_REBOOT` | `false` | Offer an interactive reboot prompt |

`SSH_PORT` only controls a firewall rule. It **does not change the SSH daemon’s listening port**.

`ENABLE_UFW=false` leaves the existing firewall state unchanged. It does not disable an already-enabled UFW installation.

### Download sources

| Variable | Purpose |
|---|---|
| `ALIAS_URL` | Remote Zsh alias file |
| `ROLLOUT_URL` | Docker Rollout executable |

Default alias source:

```text
https://raw.githubusercontent.com/dhimanparas20/Instant-Server-Setup/refs/heads/main/dockerAlias.sh
```

Default Docker Rollout source:

```text
https://raw.githubusercontent.com/wowu/docker-rollout/main/docker-rollout
```

Only HTTPS downloads and HTTPS redirects are permitted by the download helper.

For controlled deployments, replace mutable branch URLs with reviewed, commit-specific URLs and add integrity verification.

## Common installation profiles

### Default development setup

Includes native PostgreSQL, Snap applications, and rootful Docker:

```bash
./setup_ubuntu.sh
```

### Lean EC2 setup

Skips native PostgreSQL and Snap applications:

```bash
INSTALL_POSTGRES=false \
INSTALL_SNAPS=false \
CHANGE_SHELL_TO_ZSH=true \
./setup_ubuntu.sh
```

This is useful when PostgreSQL will run in a container or in a managed service such as Amazon RDS.

### No Docker

```bash
INSTALL_DOCKER=false \
INSTALL_LAZYDOCKER=false \
./setup_ubuntu.sh
```

Docker-related shell plugins and aliases may still be configured. The alias file is external to the script.

### Enable the host firewall

Verify your SSH port before running:

```bash
ENABLE_UFW=true \
SSH_PORT=22 \
ALLOW_WEB_PORTS=true \
./setup_ubuntu.sh
```

### Laptop-specific packages

Only use these options after reviewing your existing networking and power-management configuration:

```bash
INSTALL_NETWORK_MANAGER=true \
INSTALL_TLP=true \
INSTALL_FASTFETCH=true \
./setup_ubuntu.sh
```

### Custom Git identity

```bash
GIT_USER="Your Name" \
GIT_EMAIL="you@example.com" \
./setup_ubuntu.sh
```

### General package upgrades

Run during a suitable maintenance window:

```bash
UPGRADE_SYSTEM=true ./setup_ubuntu.sh
```

Even with this option disabled, packages explicitly requested by the script may be installed or upgraded, and package installation may restart services.

## Docker modes

Docker supports two different daemon arrangements.

| Property | Rootful | Rootless |
|---|---|---|
| Daemon owner | Root | Your login user |
| Service manager | System systemd | User systemd |
| Script-selected context | `default` | `rootless` |
| Typical socket | `/var/run/docker.sock` | `/run/user/<UID>/docker.sock` |
| Typical data directory | `/var/lib/docker` | `~/.local/share/docker` |
| Docker group needed | Used by this script | No |
| Low-numbered host ports | Normally available | Restricted by default |
| Operational complexity | Lower | Higher |

These are separate daemons with separate containers, images, volumes, and networks.

**Switching context does not migrate workloads.**

### Rootful mode

Default:

```bash
DOCKER_MODE=rootful ./setup_ubuntu.sh
```

The script:

1. Installs Docker if absent.
2. Enables and starts the system Docker service.
3. Adds the current user to the `docker` group.
4. Selects the `default` Docker context.
5. Checks daemon connectivity.
6. Creates `app-net` if it does not exist.
7. Installs Docker Rollout if enabled.

During setup, Docker operations use `sudo` against the local system socket. This avoids depending on group membership becoming active immediately.

> Membership in the `docker` group grants effectively root-level control over the host. Treat it as privileged access.

Reconnect before using Docker without sudo:

```bash
docker info
docker compose version
```

### Existing Docker installations

The script does not automatically migrate another Docker package distribution.

When installing Docker packages, it rejects detected conflicting packages such as:

- `docker.io`
- `docker-compose`
- `docker-compose-v2`
- `podman-docker`
- `containerd`
- `runc`

Do not remove these blindly on a host with workloads. Plan the migration and preserve data first.

## Rootless Docker guide

### What rootless Docker means

Rootless Docker runs the Docker daemon and containers inside user namespaces without running the daemon as host root.

It reduces the privilege of the daemon, but it does not make containers automatically secure or eliminate application vulnerabilities.

### Rootless requirements

The script checks for:

- `dockerd-rootless-setuptool.sh`.
- An accessible user systemd manager.
- `XDG_RUNTIME_DIR`.
- At least one qualifying subordinate UID allocation of 65,536 or more IDs.
- At least one qualifying subordinate GID allocation of 65,536 or more IDs.
- No active system Docker service or socket.

The script installs supporting packages, but it **does not allocate missing subordinate ID ranges automatically**.

Other host restrictions, including Ubuntu user-namespace security policies, can still prevent startup.

### Why a fresh installation may stop

Installing Docker’s official packages normally starts the rootful Docker service.

If you requested rootless mode, the script then detects that active rootful service and stops intentionally:

```text
Rootful Docker is active. Review workloads, stop it, then rerun.
```

This is a safety check.

The script does not assume it is safe to stop a daemon that may own running containers.

### Safe fresh-host procedure

#### 1. Request rootless setup

```bash
DOCKER_MODE=rootless ./setup_ubuntu.sh
```

If the script stops because rootful Docker is active, continue only after reviewing the host.

#### 2. Inspect the rootful daemon

```bash
sudo docker --host unix:///var/run/docker.sock ps -a
sudo docker --host unix:///var/run/docker.sock volume ls
sudo docker --host unix:///var/run/docker.sock image ls
```

If workloads or important data exist, stop here and plan a migration.

#### 3. Stop rootful Docker on an unused host

**This can interrupt workloads.**

Only on a fresh or deliberately decommissioned rootful installation:

```bash
sudo systemctl disable --now docker.service docker.socket
```

Both units matter: an active socket can reactivate the service.

#### 4. Rerun

```bash
DOCKER_MODE=rootless ./setup_ubuntu.sh
```

Preserve any other environment options you used on the first run.

### What the script configures

Once prerequisites pass, it:

1. Installs the rootless user service if absent.
2. Enables lingering for the current user.
3. Enables and starts the user Docker service.
4. Selects the `rootless` Docker context.
5. Checks daemon connectivity.
6. Creates `app-net` in the rootless daemon.

### What lingering does

The script runs the equivalent of:

```bash
sudo loginctl enable-linger "$(id -un)"
```

Lingering allows the user’s systemd manager and enabled services to run without an active login session, including after boot.

This is important for containers that should remain available after you disconnect.

### Verify rootless mode

```bash
docker context show
docker --context rootless info
systemctl --user status docker --no-pager
loginctl show-user "$(id -un)" -p Linger
```

Look for:

- Context `rootless`.
- A running user Docker service.
- Rootless information in Docker’s security options.
- `Linger=yes`.

### Missing subordinate IDs

Inspect your allocations:

```bash
grep "^$(id -un):" /etc/subuid /etc/subgid
```

A typical record has this structure:

```text
username:start_id:number_of_ids
```

If allocations are missing, have an administrator assign non-overlapping subordinate UID and GID ranges.

Do not copy arbitrary ranges from another machine: they may overlap allocations belonging to other users.

After allocation changes, follow Docker’s rootless setup guidance and retry from a normal login session.

### Missing user session

Check:

```bash
printf '%s\n' "${XDG_RUNTIME_DIR:-unset}"
systemctl --user show-environment
```

If these fail:

- Log in directly as the intended user through SSH or a desktop session.
- Avoid running setup through `sudo`, `su`, or a root shell.
- Verify the host’s PAM/systemd login configuration.
- Reconnect after installing user-session dependencies if necessary.

Do not merely invent an `XDG_RUNTIME_DIR` value; the corresponding runtime directory and user manager must exist.

### Rootless port restrictions

Rootless containers normally cannot bind host ports below 1024 without additional host configuration.

For example, prefer:

```yaml
services:
  web:
    image: nginx:stable
    ports:
      - "127.0.0.1:8080:80"
```

This exposes container port 80 through host port 8080 on loopback.

A separately configured host reverse proxy can serve public ports 80 and 443.

The example image tag is illustrative. Pin reviewed versions or digests for production.

The setup script does **not**:

- Change the unprivileged port threshold.
- Add special capabilities to rootless networking helpers.
- Configure a reverse proxy.
- Disable AppArmor restrictions.

### Rootless limitations

Depending on the host configuration:

- Resource controls require appropriate cgroup support and delegation.
- Networking and storage performance may differ from rootful Docker.
- Host networking semantics may differ.
- Some privileged workload patterns are unsupported or behave differently.
- Bind-mounted files may have ownership implications due to UID/GID mapping.

Validate your application stack before selecting rootless mode for production.

### Avoid `sudo docker` in rootless workflows

Use:

```bash
docker --context rootless ps
```

`sudo docker` generally uses root’s configuration and may target the rootful daemon instead.

### Switching back to rootful

The script is **not a mode-migration tool**.

To switch safely:

1. Back up application data.
2. Stop or migrate rootless workloads.
3. Decide whether to disable the user Docker service.
4. Start/configure rootful Docker.
5. Select the appropriate context.
6. Redeploy and validate.

Running with `DOCKER_MODE=rootful` does not automatically stop an existing rootless daemon.

Both daemons can otherwise remain active and compete for published host ports.

## Zsh configuration

### Pinned repositories

The script checks out these refs in detached-HEAD state:

| Repository | Ref |
|---|---|
| Oh My Zsh | `6adfef3` |
| zsh-autosuggestions | `85919cd` |
| zsh-autocomplete | `c10880e` |
| zsh-syntax-highlighting | `1d85c69` |
| zsh-completions | `684021f` |

These are shortened refs inherited from the earlier script.

They are not independently verified by this documentation. For stronger reproducibility, review and replace them with full commit SHAs.

Oh My Zsh automatic updates are disabled so normal shell startup does not intentionally move it away from its selected pin.

### Enabled plugins

```text
git
sudo
history
encode64
copypath
zsh-autosuggestions
zsh-completions
zsh-autocomplete
command-not-found
extract
docker
colored-man-pages
alias-finder
zsh-syntax-highlighting
```

Some plugins require additional commands to provide all their functionality. The script does not install every possible extraction utility or plugin dependency.

### Existing `.zshrc`

If an existing `.zshrc` does not contain the script’s management marker:

1. The script makes a timestamped backup.
2. It replaces `.zshrc` with a small loader.
3. It does **not** source the old configuration automatically.

This avoids initializing Oh My Zsh twice or loading previously appended aliases again.

Move reviewed personal settings into:

```text
~/.zshrc.local
```

That file is loaded last and is never overwritten by the script.

> A `.zshrc` already containing the management marker is overwritten without an additional backup. Keep customizations in `.zshrc.local`.

### `.zshenv`

The script leaves `~/.zshenv` unchanged.

Existing settings in that file can still affect Zsh behavior and syntax-check execution.

### Aliases

The external alias file is downloaded to temporary storage and checked with:

```bash
zsh -n
```

If changed, the previous managed alias file is backed up and the new file replaces it using a rename.

Aliases are not repeatedly appended to `.zshrc`.

**Syntax checking is not a security audit.** The file is executable shell content and runs when sourced.

The exact alias commands depend on the remote file; they are not defined by this README.

### PATH and Zoxide

The managed shell configuration adds:

- `~/.local/bin`
- `~/bin`
- `/snap/bin`

It initializes Zoxide when the command is available.

## CLI tools

### Lazydocker

Installed through its upstream installer if the command is not found.

If no configuration exists, the script creates:

```yaml
gui:
  returnImmediately: true
```

Existing Lazydocker configuration is preserved.

Launch with:

```bash
lazydocker
```

An `ld` alias is not guaranteed by this script; it depends on your downloaded aliases.

`xdg-utils` supplies `xdg-open`, but installing it does not guarantee browser-opening functionality on a headless server or fix every Lazydocker error.

### uv

Installed through Astral’s installer if absent.

The script does not create Python projects or virtual environments automatically.

Verify:

```bash
uv --version
```

Avoid installing application dependencies into Ubuntu’s system Python. Use uv-managed environments, `venv`, or pipx.

### Zoxide

Installed if absent and initialized in the managed Zsh configuration.

Verify:

```bash
zoxide --version
```

### Snap applications

When enabled, the script:

1. Installs `snapd`.
2. Enables and starts `snapd.socket`.
3. Waits up to 300 seconds for Snap seeding.
4. Installs missing `ngrok` and `tldr` snaps.
5. Attempts to update the tldr cache.

A tldr cache-update failure is a warning rather than a fatal error.

Existing snaps are not explicitly refreshed by the script. Snap’s own automatic-update policy remains in effect.

ngrok is installed but not authenticated or configured. Review its exposure and access controls before creating tunnels.

### Docker Rollout

Installed as a system-wide Docker CLI plugin:

```text
/usr/local/lib/docker/cli-plugins/docker-rollout
```

The script checks Bash syntax and marks the file executable.

Installing this plugin does **not** guarantee zero-downtime deployments. Application health checks, proxy behavior, startup time, capacity, and deployment design still matter.

## PostgreSQL

Enabled by default.

The script installs Ubuntu’s PostgreSQL packages and enables the `postgresql` service.

It does not:

- Pin a PostgreSQL major version.
- Create application users or databases.
- Set application passwords.
- Configure remote access.
- Open TCP 5432.
- Configure backups, replication, TLS, or monitoring.
- Tune PostgreSQL for your workload.

Package selection follows the configured Ubuntu repositories.

Verify:

```bash
sudo systemctl status postgresql --no-pager
sudo -u postgres psql -c 'SELECT version();'
```

The `postgresql` systemd unit can be a wrapper for database clusters. A successful service status alone is not a full database health check.

For containerized PostgreSQL or a managed database:

```bash
INSTALL_POSTGRES=false ./setup_ubuntu.sh
```

This skips future setup; it does not uninstall an existing database.

## Git configuration

The script sets:

```text
user.name
user.email
init.defaultBranch = main
```

It does not change pull behavior or install a credential helper.

If it detects a global plaintext `store` credential helper, it warns but preserves the existing configuration.

For server repository access, prefer appropriately scoped deploy keys or another managed credential mechanism.

Do not put credentials in the script or commit them to the repository.

## Firewall and AWS networking

### Default behavior

UFW is installed, but its configuration is skipped unless:

```text
ENABLE_UFW=true
```

Existing firewall state remains unchanged when skipped.

### Enabled behavior

The script:

1. Sets default incoming traffic to deny.
2. Sets default outgoing traffic to allow.
3. Allows the configured SSH TCP port.
4. Optionally allows TCP 80 and 443.
5. Enables UFW.
6. Prints status.

It does not reset or remove existing allow rules.

### SSH lockout warning

`SSH_PORT` must match your actual SSH listener.

Before changing firewall settings remotely:

- Keep a second SSH session open.
- Verify the configured SSH port.
- Ensure you have recovery access, such as AWS Systems Manager or an appropriate console path.
- Check IPv4 and IPv6 requirements.

The script does not automatically detect the SSH daemon’s listening port.

### Docker and UFW

Docker-published ports may bypass ordinary UFW filtering because Docker manages its own packet-forwarding rules.

Do not assume that `ufw default deny incoming` makes every published container port private.

Safer practices include:

- Publish internal services only on loopback.
- Avoid publishing databases publicly.
- Restrict AWS Security Groups.
- Design Docker-aware host firewall rules appropriate to your firewall backend.
- Verify actual external reachability.

### AWS Security Groups

Recommended general policy:

| Port | Typical purpose | Suggested source |
|---|---|---|
| TCP 22 | SSH | Your administrative IP/CIDR |
| TCP 80 | Public HTTP | Public only if required |
| TCP 443 | Public HTTPS | Public only if required |
| TCP 5432 | PostgreSQL | Private application sources only, if needed |

The script does not modify Security Groups, network ACLs, or AWS routing.

## Files and directories

| Path | Purpose |
|---|---|
| `~/.config/ubuntu-setup/` | Script-managed user configuration |
| `~/.config/ubuntu-setup/setup.log` | Append-only setup log |
| `~/.config/ubuntu-setup/setup.lock` | Concurrent-run lock |
| `~/.config/ubuntu-setup/shell.zsh` | Managed shell configuration |
| `~/.config/ubuntu-setup/aliases.zsh` | Downloaded alias file |
| `~/.zshrc` | Managed configuration loader |
| `~/.zshrc.local` | Optional personal overrides |
| `~/.oh-my-zsh/` | Oh My Zsh checkout |
| `~/.oh-my-zsh/custom/plugins/` | Pinned plugin checkouts |
| `~/.config/lazydocker/config.yml` | Created only if absent |
| `/etc/apt/keyrings/docker.asc` | Docker repository key, on new Docker installs |
| `/etc/apt/sources.list.d/docker.sources` | Docker APT source, on new installs |
| `/usr/local/lib/docker/cli-plugins/docker-rollout` | Docker Rollout plugin |

Unlike the earlier `server_setup.sh`, this version does **not** create `~/apps` or `~/docker`.

Create them if desired:

```bash
mkdir -p ~/apps ~/docker
```

## Execution order

1. Validate OS, user, configuration, and systemd.
2. Acquire sudo authorization.
3. Set up logging and a per-user lock.
4. Install system packages.
5. Configure Docker.
6. Install CLI tools.
7. Install Snap applications.
8. Clone and pin Oh My Zsh and plugins.
9. Download and validate aliases.
10. Generate managed Zsh configuration.
11. Configure Git identity.
12. Optionally configure UFW.
13. Optionally change the login shell.
14. Print the summary and reboot notice.

Temporary downloaded files are removed on normal exit and handled failures.

Failures do not roll back changes already completed.

## Reruns and updates

The script is designed for practical reruns, but it is not a fully transactional configuration-management system.

### Generally repeatable operations

- APT package installation.
- Docker service enablement.
- Docker group membership.
- Existing `app-net` preservation.
- Checking out the configured Zsh refs.
- Replacing managed shell configuration.
- Downloading aliases without duplicate appends.
- Preserving an existing Lazydocker configuration.
- Skipping installed CLI tools and snaps.

### Important limitations

- Some network operations still occur on reruns.
- Alias and Rollout downloads follow their configured URLs each run.
- Changed aliases create backups.
- Installed Lazydocker, uv, and Zoxide binaries are normally skipped, not updated.
- Existing tracked Git modifications cause plugin setup to stop.
- Existing untracked files are not comprehensively validated.
- An incompatible repository origin is not automatically corrected.
- Boolean settings are not persisted.
- Setting an install toggle to `false` does not uninstall anything.
- Package changes can restart services.
- The log grows without automatic rotation.

Use the same environment settings on subsequent runs.

The lock prevents concurrent runs using the same user configuration directory. It is not a host-wide orchestration lock across different users.

## Verification

### Shell and tools

```bash
zsh --version
git --version
python3 --version
pipx --version
uv --version
zoxide --version
lazydocker --version
```

Only check optional commands you enabled.

### Docker

```bash
docker context ls
docker info
docker compose version
docker network inspect app-net
```

Optional smoke test:

```bash
docker run --rm hello-world
```

This downloads and runs an image.

### Rootful service

```bash
sudo systemctl status docker --no-pager
```

### Rootless service

```bash
systemctl --user status docker --no-pager
docker --context rootless info
```

### Snap

```bash
snap list
/snap/bin/tldr --version
```

### Firewall

```bash
sudo ufw status verbose
```

### Logs

```bash
tail -n 100 ~/.config/ubuntu-setup/setup.log
```

## Troubleshooting

### Docker permission denied

For rootful Docker, reconnect to refresh group membership:

```bash
id -nG
docker info
```

For rootless Docker, check the context and user service instead:

```bash
docker context show
systemctl --user status docker --no-pager
```

Do not fix socket errors with world-writable permissions.

### `DOCKER_HOST` or `DOCKER_CONTEXT` is set

The script refuses these overrides to avoid accidentally operating against the wrong daemon.

Review their current values first:

```bash
printf 'DOCKER_HOST=%s\n' "${DOCKER_HOST:-}"
printf 'DOCKER_CONTEXT=%s\n' "${DOCKER_CONTEXT:-}"
```

If they are not needed for this setup:

```bash
unset DOCKER_HOST DOCKER_CONTEXT
```

### Existing Docker lacks Compose v2

The script does not automatically repair every Docker distribution.

Identify how Docker was installed and install a matching Compose plugin. Do not mix unrelated package sources blindly.

### Rootless user service fails

Inspect:

```bash
journalctl --user -u docker -n 100 --no-pager
```

Check subordinate IDs, user-session state, kernel support, and applicable Ubuntu security policies.

Do not disable AppArmor globally as a troubleshooting shortcut.

### Snap seeding times out

Inspect:

```bash
systemctl status snapd.socket snapd.service --no-pager
snap changes
```

Fix connectivity or Snap initialization, then rerun.

If Snap tools are unnecessary:

```bash
INSTALL_SNAPS=false ./setup_ubuntu.sh
```

### Plugin checkout refuses local changes

Inspect the affected checkout:

```bash
git -C ~/.oh-my-zsh status
```

Back up or intentionally commit/stash your changes. Avoid destructive resets unless you understand what will be lost.

### Zsh configuration disappeared

Find backups:

```bash
find "$HOME" -maxdepth 1 -name '.zshrc.backup.*' -print
```

Move reviewed customizations to `~/.zshrc.local`.

Do not source the entire old `.zshrc` if it also initializes Oh My Zsh.

### Tool installed but command not found

Reconnect or start the managed Zsh configuration:

```bash
exec zsh
```

Inspect:

```bash
printf '%s\n' "$PATH"
ls -ld ~/.local/bin ~/bin /snap/bin 2>/dev/null
```

Upstream installer behavior can change; check its output in the setup log.

### APT lock errors

Another package operation may be running, including unattended updates.

Wait for it to finish. Do not delete APT lock files or terminate package processes without diagnosing the situation.

### Sudo prompts again during a long run

The script authorizes sudo at startup but does not run a sudo keepalive loop.

Later privileged operations may prompt again if the timestamp expires.

### Reboot is required

The script checks:

```text
/var/run/reboot-required
```

Schedule a reboot after reviewing active workloads.

A reboot prompt is shown only when `PROMPT_REBOOT=true` and standard input is interactive.

## Security and operational limitations

### Third-party code execution

Lazydocker, uv, and Zoxide use downloaded upstream installer scripts.

Downloading before execution improves failure handling, but it does **not** establish trust or verify provenance.

The script does not currently verify those installer checksums or signatures.

The alias file also executes as part of shell startup.

For production use:

- Review external scripts.
- Pin reviewed releases or full commit SHAs.
- Verify published checksums or signatures where available.
- Consider internal artifact mirrors.
- Use controlled update and rollback procedures.

### Not fully reproducible

Zsh repositories have selected refs, but the overall installation is not version-locked.

Other components depend on:

- Current APT repository contents.
- Current Snap releases.
- Upstream installer behavior.
- Mutable alias and Rollout URLs.

### Not fully unattended

`DEBIAN_FRONTEND=noninteractive` is applied to package installation, but it does not guarantee every package hook or system change is noninteractive.

Sudo and other components may still require interaction.

### Logging

Logs are stored with restrictive permissions, but command output can still contain sensitive information.

Review logs before sharing them.

### No automatic rollback

A failure may leave:

- Installed packages.
- Running services.
- Updated configuration.
- A partially completed bootstrap.

Correct the failure and rerun, or recover from a known-good snapshot.

### No complete hardening

The script does not configure:

- SSH access policy.
- Automatic security updates.
- Intrusion prevention.
- Audit logging.
- Disk encryption.
- Secret management.
- Backup retention.
- Restore testing.
- Monitoring and alerting.
- Application resource limits.
- TLS termination.

These remain separate deployment responsibilities.

## Recovery and removal

There is no automated uninstall command.

### Restore a previous `.zshrc`

Locate a backup:

```bash
find "$HOME" -maxdepth 1 -name '.zshrc.backup.*' -print
```

Copy the selected backup back to `~/.zshrc` after reviewing it.

### Return to Bash

```bash
sudo usermod --shell /bin/bash "$(id -un)"
```

Reconnect afterward.

### Stop rootless Docker

**This stops workloads managed by that user service.**

```bash
systemctl --user disable --now docker
```

Disabling lingering is a separate decision: other user services may depend on it.

### Stop rootful Docker

**This can interrupt containers and applications.**

```bash
sudo systemctl disable --now docker.service docker.socket
```

### Preserve data

Before removing packages or directories, back up:

- PostgreSQL databases.
- Docker volumes.
- Bind-mounted application data.
- Compose files.
- Secrets and environment files.
- Personal shell configuration.

Do not delete Docker data directories or PostgreSQL storage as a generic cleanup step.

---

**Recommended operating approach:** test the script on a disposable Ubuntu instance, review the resulting services and network exposure, and only then apply the same configuration to an important machine.
