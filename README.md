<p align="center">
  <img src="https://raw.githubusercontent.com/blackoutmode/docker-mlat-server/main/logo.png" alt="mlat-server logo" width="200">
</p>

# docker-mlat-server

> LinuxServer.io–style containerized server that coordinates Mode S
> multilateration across many mlat-client receivers.

[![GitHub Stars](https://img.shields.io/github/stars/blackoutmode/docker-mlat-server.svg?style=flat-square&color=E68523&logo=github&logoColor=FFFFFF)](https://github.com/blackoutmode/docker-mlat-server/stargazers)
[![Docker Pulls](https://img.shields.io/docker/pulls/blackoutmode/mlat-server.svg?style=flat-square&color=E68523&logo=docker&logoColor=FFFFFF)](https://hub.docker.com/r/blackoutmode/mlat-server)
[![GitHub Release](https://img.shields.io/github/release/blackoutmode/docker-mlat-server.svg?style=flat-square&color=E68523&logo=github&logoColor=FFFFFF)](https://github.com/blackoutmode/docker-mlat-server/releases)
[![Release CI](https://img.shields.io/github/actions/workflow/status/blackoutmode/docker-mlat-server/release.yml?style=flat-square&logo=github&label=release)](https://github.com/blackoutmode/docker-mlat-server/actions/workflows/release.yml)
[![Publish CI](https://img.shields.io/github/actions/workflow/status/blackoutmode/docker-mlat-server/publish.yml?style=flat-square&logo=github&label=publish)](https://github.com/blackoutmode/docker-mlat-server/actions/workflows/publish.yml)
[![License: AGPL v3](https://img.shields.io/badge/License-AGPLv3-blue.svg?style=flat-square)](https://www.gnu.org/licenses/agpl-3.0)

Unofficial community image for [mlat-server](https://github.com/wiedehopf/mlat-server),
built with [LinuxServer.io](https://linuxserver.io/) style container patterns
(s6, hardened defaults, practical runtime options) for ADS-B multilateration
workloads.

Sponsored and maintained by [Blackout Secure](https://blackoutsecure.com/).

> **Important**
> This repository is not an official LinuxServer.io image release.

## Overview

This project packages upstream [wiedehopf/mlat-server](https://github.com/wiedehopf/mlat-server)
into an easy-to-run, LinuxServer.io-style container image with practical
defaults for running your own Mode S multilateration coordinator.

The mlat-server is the *server side* of the multilateration protocol: many
[mlat-client](https://github.com/wiedehopf/mlat-client) instances forward
timestamped Mode S messages from their receivers to this server, which
correlates the signals and resolves aircraft positions geometrically.

> **AGPL-3.0 Network Use Notice**
> mlat-server is licensed under the GNU **Affero** GPL v3. If you operate a
> modified copy of this server and allow third parties to connect to it over
> a network, AGPL Section 13 requires you to provide those users with a way
> to obtain the complete corresponding source code of your modifications.
> See [LICENSE](LICENSE) for the full text.

Quick links:

- Docker Hub listing: [blackoutmode/mlat-server](https://hub.docker.com/r/blackoutmode/mlat-server)
- Balena block listing: [mlat-server block on Balena Hub](https://hub.balena.io/)
- GitHub repository: [blackoutmode/docker-mlat-server](https://github.com/blackoutmode/docker-mlat-server)
- Upstream application: [wiedehopf/mlat-server](https://github.com/wiedehopf/mlat-server)

## Table of Contents

- [Quick Start](#quick-start)
- [Image Availability](#image-availability)
- [About The mlat-server Application](#about-the-mlat-server-application)
- [Supported Architectures](#supported-architectures)
- [Network Topology](#network-topology)
- [Usage](#usage)
  - [Docker Compose](#docker-compose-recommended)
  - [Docker CLI](#docker-cli)
  - [Balena Deployment](#balena-deployment)
- [Parameters](#parameters)
- [Configuration](#configuration)
- [Application Setup](#application-setup)
- [Troubleshooting](#troubleshooting)
- [Release & Versioning](#release--versioning)
- [License](#license)
- [Support & Getting Help](#support--getting-help)
- [References](#references)

## Quick Start

5-minute multilateration server setup:

```bash
docker run -d \
  --name=mlat-server \
  --restart unless-stopped \
  -e TZ=Etc/UTC \
  -e MLAT_SERVER_CLIENT_LISTEN=31090 \
  -e MLAT_SERVER_FILTERED_BASESTATION_LISTEN=31003 \
  -e MLAT_SERVER_BASESTATION_LISTEN=31004 \
  -e MLAT_SERVER_WORK_DIR=/config/work \
  -e MLAT_SERVER_MOTD="Welcome to my MLAT server" \
  -p 31090:31090/tcp \
  -p 31090:31090/udp \
  -p 31003:31003/tcp \
  -p 31004:31004/tcp \
  -v mlat-server-config:/config \
  blackoutmode/mlat-server:latest
```

For compose files, balena, and more examples, see [Usage](#usage) below.

## Image Availability

Docker Hub (Recommended):

- All images published to [Docker Hub](https://hub.docker.com/r/blackoutmode/mlat-server)
- Simple pull command: `docker pull blackoutmode/mlat-server:latest`
- Multi-arch support: amd64, arm64
- No registry prefix needed (defaults to Docker Hub)

```bash
# Pull latest
docker pull blackoutmode/mlat-server:latest

# Pull a specific commit-pinned build
docker pull blackoutmode/mlat-server:0.0.0-g9b27a6d
```

> **Note on versioning:** Upstream `wiedehopf/mlat-server` does not maintain a
> `version` file or git tags. This image synthesizes a PEP 440-style local
> version from the upstream commit short SHA (e.g. `0.0.0+g9b27a6d`), and
> publishes a Docker-tag-safe variant (`+` → `-`).

## About The mlat-server Application

[mlat-server](https://github.com/wiedehopf/mlat-server) is a Mode S
multilateration server. It accepts connections from many
[mlat-client](https://github.com/wiedehopf/mlat-client) feeders, ingests their
synchronized Mode S timing data, and resolves transmitter positions by
multilateration.

Author and maintenance credits (upstream):

- Original author: [Oliver Jowett](mailto:oliver@mutability.co.uk) (mutability)
- Current upstream maintainer: [wiedehopf](https://github.com/wiedehopf) (Matthias Wirth)
- Additional contributor: [TanerH](https://github.com/TanerH)
- Upstream repository and documentation: [wiedehopf/mlat-server](https://github.com/wiedehopf/mlat-server)

## Supported Architectures

This image is published as a multi-arch manifest. Pulling
`blackoutmode/mlat-server:latest` retrieves the correct image for your host
architecture.

The architectures supported by this image are:

| Architecture | Tag |
| --- | --- |
| x86-64 | amd64-latest |
| arm64 | arm64v8-latest |

## Network Topology

The mlat-server *listens* on a set of ports; it does not connect outbound to
receivers. Mode S timing data flows **into** the server, and resolved aircraft
positions flow **out** of the server in Basestation/SBS format.

```
                   ┌──────────────────────────────────┐
   mlat-client ──► │  31090/tcp + 31090/udp           │
   mlat-client ──► │     (--client-listen)            │
   mlat-client ──► │                                  │
                   │           mlat-server            │
                   │                                  │
                   │  31003/tcp ──► SBS (filtered) ──►│ to glue/MQTT/etc.
                   │  31004/tcp ──► SBS (raw) ───────►│ to local consumers
                   └──────────────────────────────────┘
```

| Port | Proto | Purpose |
| --- | --- | --- |
| 31090 | tcp | mlat-client primary connection (control, sync) |
| 31090 | udp | mlat-client message stream (lower latency, optional) |
| 31003 | tcp | Basestation/SBS output — Kalman-filtered positions |
| 31004 | tcp | Basestation/SBS output — unfiltered positions |

UDP for `--client-listen` is optional; if you do not publish 31090/udp, the
client will fall back to TCP-only.

## Usage

### docker-compose (recommended, [click here for more info](https://docs.linuxserver.io/general/docker-compose))

```yaml
---
services:
  mlat-server:
    image: blackoutmode/mlat-server:latest
    container_name: mlat-server
    environment:
      - TZ=Etc/UTC
      - MLAT_SERVER_CLIENT_LISTEN=31090
      - MLAT_SERVER_FILTERED_BASESTATION_LISTEN=31003
      - MLAT_SERVER_BASESTATION_LISTEN=31004
      - MLAT_SERVER_WORK_DIR=/config/work
      - MLAT_SERVER_TAG=mlat-server
      - MLAT_SERVER_STATUS_INTERVAL=15
      - MLAT_SERVER_MOTD=Welcome to this Mode S multilateration server
      - LOG_LEVEL=info                # debug | info | warn | error | fatal
    ports:
      - 31090:31090/tcp
      - 31090:31090/udp
      - 31003:31003/tcp
      - 31004:31004/tcp
    volumes:
      - mlat-server-config:/config
    tmpfs:
      - /tmp
      - /run:exec
    restart: unless-stopped

volumes:
  mlat-server-config:
```

### docker-compose with mlat-client (server + co-located feeder)

```yaml
---
services:
  mlat-server:
    image: blackoutmode/mlat-server:latest
    container_name: mlat-server
    environment:
      - TZ=Etc/UTC
      - MLAT_SERVER_CLIENT_LISTEN=31090
      - MLAT_SERVER_FILTERED_BASESTATION_LISTEN=31003
      - MLAT_SERVER_BASESTATION_LISTEN=31004
      - MLAT_SERVER_WORK_DIR=/config/work
      - MLAT_SERVER_MOTD=Private MLAT network
      - LOG_LEVEL=info
    ports:
      - 31090:31090/tcp
      - 31090:31090/udp
      - 31003:31003/tcp
      - 31004:31004/tcp
    volumes:
      - mlat-server-config:/config
    tmpfs:
      - /tmp
      - /run:exec
    restart: unless-stopped

  mlat-client:
    image: blackoutmode/mlat-client:latest
    container_name: mlat-feeder
    depends_on:
      - mlat-server
    environment:
      - TZ=Etc/UTC
      - MLAT_CLIENT_INPUT_CONNECT=readsb:30005
      - MLAT_CLIENT_SERVER=mlat-server:31090
      - MLAT_CLIENT_LAT=51.5
      - MLAT_CLIENT_LON=-0.1
      - MLAT_CLIENT_ALT=50m
      - MLAT_CLIENT_USER_ID=local-receiver-1
      - MLAT_CLIENT_RESULTS=beast,connect,readsb:30104
      - LOG_LEVEL=info
    volumes:
      - mlat-client-config:/config
    tmpfs:
      - /tmp
      - /run:exec
    restart: unless-stopped

volumes:
  mlat-server-config:
  mlat-client-config:
```

> **Note:** When both services are in the same compose file, Docker Compose
> creates a shared network automatically — the client can reach the server at
> `mlat-server:31090`. If you run mlat-server and mlat-client from
> **separate** compose files or hosts, expose 31090/tcp+udp via published
> ports and have the client connect to `<host>:31090`.

### docker-cli ([click here for more info](https://docs.docker.com/engine/reference/commandline/cli/))

```bash
docker run -d \
  --name=mlat-server \
  -e TZ=Etc/UTC \
  -e MLAT_SERVER_CLIENT_LISTEN=31090 \
  -e MLAT_SERVER_FILTERED_BASESTATION_LISTEN=31003 \
  -e MLAT_SERVER_BASESTATION_LISTEN=31004 \
  -e MLAT_SERVER_WORK_DIR=/config/work \
  -e MLAT_SERVER_MOTD="Welcome to this Mode S multilateration server" \
  -p 31090:31090/tcp \
  -p 31090:31090/udp \
  -p 31003:31003/tcp \
  -p 31004:31004/tcp \
  -v /path/to/mlat-server/config:/config \
  --restart unless-stopped \
  blackoutmode/mlat-server:latest
```

### Balena Deployment

This image can be deployed to Balena-powered IoT devices using the included
`docker-compose.yml` file (which contains the required Balena labels):

```bash
balena push <your-app-slug>
```

For deployment via the web interface, use the deploy button in this
repository. See [Balena documentation](https://docs.balena.io/) for details.

## Parameters

### Environment Variables (Required)

| Parameter | Description | Example |
| --- | --- | --- |
| `-e MLAT_SERVER_CLIENT_LISTEN=` | Listening port(s) for mlat-client connections — `tcp_port`, `host:tcp_port`, `tcp_port:udp_port`, or `host:tcp_port:udp_port`; multiple endpoints comma-separated | `31090` |
| `-e MLAT_SERVER_WORK_DIR=` | Directory for sync.json, aircraft.json, blacklist, and other runtime state | `/config/work` |

### Environment Variables (Optional)

| Parameter | Default | Description |
| --- | --- | --- |
| `-e TZ=Etc/UTC` | `Etc/UTC` | Timezone (TZ database) |
| `-e MLAT_SERVER_MOTD=` | *(none)* | Message of the day sent to clients on connect |
| `-e MLAT_SERVER_BASESTATION_LISTEN=` | *(none)* | Listen on `[host:]port` for unfiltered Basestation/SBS results |
| `-e MLAT_SERVER_BASESTATION_CONNECT=` | *(none)* | Connect to `host:port` and push unfiltered SBS results |
| `-e MLAT_SERVER_FILTERED_BASESTATION_LISTEN=` | *(none)* | Listen on `[host:]port` for Kalman-filtered SBS results |
| `-e MLAT_SERVER_FILTERED_BASESTATION_CONNECT=` | *(none)* | Connect to `host:port` and push Kalman-filtered SBS results |
| `-e MLAT_SERVER_WRITE_CSV=` | *(none)* | Write resolved positions to a CSV file (e.g. `/config/work/positions.csv`) |
| `-e MLAT_SERVER_DUMP_PSEUDORANGE=` | *(none)* | Dump pseudorange data in JSON format to a file |
| `-e MLAT_SERVER_PARTITION=` | `1/1` | Cluster partitioning, form `I/N` |
| `-e MLAT_SERVER_TAG=` | `mlat-server` | Process name prefix (requires setproctitle) |
| `-e MLAT_SERVER_STATUS_INTERVAL=` | `15` | Status logging interval in seconds (multiple of 15, `-1` to disable) |
| `-e MLAT_SERVER_CHECK_LEAKS=` | `false` | Enable periodic objgraph memory-leak checks |
| `-e MLAT_SERVER_ARGS=` | *(none)* | Raw arguments passed directly to mlat-server (overrides individual env vars) |
| `-e MLAT_SERVER_USER=` | `root` | Runtime user for the container |
| `-e PUID=911` | `911` | User ID for non-root operation |
| `-e PGID=911` | `911` | Group ID for non-root operation |

### Storage Mounts

| Volume | Description | Required |
| --- | --- | --- |
| `-v /config` | Configuration, work directory, and persistent state | Required |

### Performance Tuning (built-in)

The image sets numerical-library thread limits to prevent runaway BLAS
threads from oversubscribing CPU cores. These are baked into the image and
generally do not need adjustment:

```
MKL_NUM_THREADS=1
NUMEXPR_NUM_THREADS=1
OMP_NUM_THREADS=1
PYTHONOPTIMIZE=2
```

## Configuration

Environment variables are set using `-e` flags in `docker run` or the
`environment:` section in docker-compose.

### Individual Environment Variables vs MLAT_SERVER_ARGS

You can configure mlat-server in two ways:

1. **Individual environment variables** (recommended): Set
   `MLAT_SERVER_CLIENT_LISTEN`, `MLAT_SERVER_WORK_DIR`, etc. The container
   service script assembles the command-line arguments.

2. **Raw arguments**: Set `MLAT_SERVER_ARGS` to the full argument string. This
   takes precedence — individual env vars that match flags already present in
   `MLAT_SERVER_ARGS` are skipped.

### Output Format

`mlat-server` emits resolved aircraft positions in
[Basestation/SBS-1](http://woodair.net/sbs/article/barebones42_socket_data.htm)
format, the de-facto interchange format used by readsb, dump1090, Virtual
Radar Server, FlightAirMap, tar1090, Plane/Ship Plotter, and many others.

| Output | Filtering |
| --- | --- |
| `--filtered-basestation-listen` (`MLAT_SERVER_FILTERED_BASESTATION_LISTEN`) | Kalman-filtered (smoothed) |
| `--basestation-listen` (`MLAT_SERVER_BASESTATION_LISTEN`) | Raw, unfiltered |

You can additionally write a CSV trail of resolved positions with
`MLAT_SERVER_WRITE_CSV=/config/work/positions.csv`.

### Cluster Partitioning

For high-load deployments, mlat-server supports horizontal partitioning. Set
`MLAT_SERVER_PARTITION=I/N` where `N` is the total number of partitions and
`I` is this server's index (1-based). Each partition handles a deterministic
slice of incoming aircraft, allowing the work to be split across multiple
processes or hosts.

## User / Group Identifiers

By default, this container runs as `root`.

Root mode (default):
- No `PUID` or `PGID` needed

Non-root mode (advanced):
- Set `MLAT_SERVER_USER` to your username
- Provide matching `PUID` and `PGID` values
- Defaults to `911:911` if omitted

## Application Setup

The container runs mlat-server, accepting timestamped Mode S messages from
mlat-client feeders and resolving aircraft positions via multilateration.

### Key Features

- **Multilateration coordinator**: Resolves transmitter positions by
  correlating timestamps from three or more synchronized receivers
- **High concurrency**: Uses uvloop and asyncio for thousands of simultaneous
  client connections
- **SBS output**: Filtered (Kalman) and raw Basestation/SBS streams
- **CSV logging**: Optional persistent CSV trail
- **Cluster partitioning**: Built-in `I/N` sharding for horizontal scale-out

### Customizing Configuration

Common environment variable combinations:

```bash
# Public server with both filtered and raw SBS feeds
-e MLAT_SERVER_CLIENT_LISTEN=31090
-e MLAT_SERVER_FILTERED_BASESTATION_LISTEN=31003
-e MLAT_SERVER_BASESTATION_LISTEN=31004

# Private server with persistent CSV log
-e MLAT_SERVER_CLIENT_LISTEN=31090
-e MLAT_SERVER_WRITE_CSV=/config/work/positions.csv

# Pushing SBS results to a downstream consumer
-e MLAT_SERVER_FILTERED_BASESTATION_CONNECT=tar1090:30003

# Partitioned cluster member 2 of 4
-e MLAT_SERVER_PARTITION=2/4
-e MLAT_SERVER_TAG=mlat-server-shard2
```

For all available options, see the [mlat-server documentation](https://github.com/wiedehopf/mlat-server).

## Troubleshooting

### Container won't start or exits immediately

Check logs:

```bash
docker logs mlat-server
docker logs mlat-server --tail 50 -f  # Follow last 50 lines
```

Common causes:

- **Missing required arguments**: Ensure `MLAT_SERVER_CLIENT_LISTEN` and
  `MLAT_SERVER_WORK_DIR` are set
- **Port conflict**: Another service is already bound to one of 31003 / 31004
  / 31090 on the host
- **Permission error on work directory**: When running non-root, ensure the
  mounted `/config` is writable by `PUID:PGID`
- **Configuration syntax error**: Check `MLAT_SERVER_ARGS`

### Clients cannot connect

Verify the client-listen port is reachable:

```bash
docker exec mlat-server nc -zv 127.0.0.1 31090
# from a client host:
nc -zv <docker-host> 31090
```

If connection fails:

- Confirm `-p 31090:31090/tcp` (and optionally `/udp`) are published
- Check host firewall rules
- Verify clients are pointing at the correct host:port and not blocked
  upstream (NAT, security group, etc.)

### No MLAT positions resolved

If clients connect but the server does not produce positions:

- MLAT requires **3 or more synchronized receivers** seeing the same aircraft
  simultaneously — verify multiple clients are connected and reporting fresh
  data
- Each client's reported lat/lon/alt must be accurate (sub-100m for best
  results)
- Inspect the periodic status log line (`MLAT_SERVER_STATUS_INTERVAL`) for
  sync diagnostics
- Check `${MLAT_SERVER_WORK_DIR}/sync.json` for per-pair clock-sync state

### Getting help

- Check [upstream mlat-server documentation](https://github.com/wiedehopf/mlat-server)
- Review container logs: `docker logs -f mlat-server`
- Open an issue on [GitHub](https://github.com/blackoutmode/docker-mlat-server/issues)

## Release & Versioning

This project uses synthetic versioning derived from the upstream mlat-server
commit (since upstream maintains no `version` file or tags):

- Image tag pattern: `0.0.0-g<short_sha>` (e.g. `0.0.0-g9b27a6d`) plus
  `latest`
- Releases published on [GitHub Releases](https://github.com/blackoutmode/docker-mlat-server/releases)
- Multi-arch images (amd64, arm64v8) built automatically
- An `upstream-release-monitor` workflow opens a PR whenever upstream HEAD
  changes

Update to latest:

```bash
docker pull blackoutmode/mlat-server:latest
docker compose up -d  # if using compose
```

Check image version:

```bash
docker inspect -f '{{ index .Config.Labels "build_version" }}' \
  blackoutmode/mlat-server:latest
```

## License

This project (the Dockerfile, scripts, and packaging) and the upstream
`mlat-server` are both licensed under the **GNU Affero General Public License
v3.0 or later** (AGPL-3.0-or-later). See the [LICENSE](LICENSE) file for the
full text.

> **AGPL Section 13 (Network Use):** If you run a modified version of this
> server and let third parties interact with it over a network, you must
> offer those users access to the corresponding source code of your
> modifications. Hosting an unmodified upstream build does not change your
> obligations beyond ordinary AGPL compliance.

The mlat-server application is © 2014 Oliver Jowett, with subsequent
contributions by Matthias Wirth (wiedehopf), TanerH, and others. See
[wiedehopf/mlat-server](https://github.com/wiedehopf/mlat-server) for upstream
authorship and history.

## Support & Getting Help

- Questions: [GitHub Issues](https://github.com/blackoutmode/docker-mlat-server/issues)
- Bug Reports: Include Docker version, container logs, and reproduction steps
- Upstream Documentation: [mlat-server on GitHub](https://github.com/wiedehopf/mlat-server)
- Community: [LinuxServer.io Discord](https://linuxserver.io/discord)

Get help:

```bash
docker logs mlat-server                              # View container logs
docker exec -it mlat-server /bin/bash                # Access container shell
docker inspect blackoutmode/mlat-server              # Check image details
```

## Sponsor & Credits

Sponsored and maintained by [Blackout Secure](https://blackoutsecure.com/)

Upstream project: [wiedehopf/mlat-server](https://github.com/wiedehopf/mlat-server)
Container patterns: [LinuxServer.io](https://linuxserver.io/)

## References

### Project Resources

| Resource | Link |
| --- | --- |
| Docker Hub | [blackoutmode/mlat-server](https://hub.docker.com/r/blackoutmode/mlat-server) |
| Balena Hub | [mlat-server block](https://hub.balena.io/) |
| GitHub Issues | [Report bugs or request features](https://github.com/blackoutmode/docker-mlat-server/issues) |
| GitHub Releases | [Download releases](https://github.com/blackoutmode/docker-mlat-server/releases) |

### Upstream & Related

| Resource | Link |
| --- | --- |
| mlat-server | [wiedehopf/mlat-server](https://github.com/wiedehopf/mlat-server) |
| mlat-client | [wiedehopf/mlat-client](https://github.com/wiedehopf/mlat-client) |
| docker-mlat-client | [blackoutsecure/docker-mlat-client](https://github.com/blackoutsecure/docker-mlat-client) |
| readsb | [wiedehopf/readsb](https://github.com/wiedehopf/readsb) |
| LinuxServer.io | [linuxserver.io](https://linuxserver.io/) |

### Technical Resources

- [Multilateration (Wikipedia)](https://en.wikipedia.org/wiki/Multilateration)
- [ADS-B Overview](https://en.wikipedia.org/wiki/Automatic_Dependent_Surveillance%E2%80%93Broadcast)
- [Basestation/SBS-1 protocol](http://woodair.net/sbs/article/barebones42_socket_data.htm)
- [Docker Documentation](https://docs.docker.com/)

Made with ❤️ by [Blackout Secure](https://blackoutsecure.com/)
