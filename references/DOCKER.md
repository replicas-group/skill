# Docker

Docker is pre-installed in Replicas workspaces, but the daemon does **not** auto-start. You must start it manually before running any `docker` or `docker compose` commands.

## Starting the Docker Daemon

```bash
sudo service docker start
```

After starting, verify the daemon is running:

```bash
docker info
```

## Important Notes

- **Start once per session.** The daemon stays running until the workspace shuts down. You do not need to restart it between commands.
- **Check before starting.** If you are unsure whether the daemon is already running, check first to avoid an unnecessary restart:
  ```bash
  docker info > /dev/null 2>&1 || sudo service docker start
  ```
- **Sudo is required** for starting the daemon, but regular `docker` commands run without sudo (the user is in the `docker` group).
