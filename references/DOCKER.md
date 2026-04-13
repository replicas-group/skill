# Docker

Docker is pre-installed in Replicas workspaces, but the daemon does **not** auto-start (there is no systemd). You must start it manually before running any `docker` or `docker compose` commands.

## Starting the Docker Daemon

```bash
sudo dockerd > /tmp/dockerd.log 2>&1 &
sleep 3  # wait for daemon to be ready
```

After starting, verify the daemon is running:

```bash
docker info
```

If `docker info` fails, check the logs:

```bash
cat /tmp/dockerd.log
```

## Important Notes

- **Start once per session.** The daemon stays running until the workspace shuts down. You do not need to restart it between commands.
- **Check before starting.** If you are unsure whether the daemon is already running, check first to avoid starting a second instance:
  ```bash
  docker info > /dev/null 2>&1 || { sudo dockerd > /tmp/dockerd.log 2>&1 & sleep 3; }
  ```
- **No systemd.** Do not use `systemctl` or `service` commands — they will not work. Always start `dockerd` directly.
- **Sudo is required** for starting the daemon, but regular `docker` commands run without sudo (the user is in the `docker` group).
