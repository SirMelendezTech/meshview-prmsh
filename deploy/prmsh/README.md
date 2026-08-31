# MeshView — Puerto Rico production deployment

Runs MeshView for **meshview.prmsh.com**, ingesting the `msh/US/PR/#` topic from the
public Meshtastic MQTT broker, backed by PostgreSQL, all in Docker.

## Stack

| Service            | Image                                              | Purpose                          |
|--------------------|----------------------------------------------------|----------------------------------|
| `meshview-prmsh`   | `ghcr.io/pablorevilla-meshtastic/meshview:latest`  | MQTT ingest + web UI/API (`mvrun.py`) |
| `meshview-prmsh-db`| `postgres:16-alpine`                               | Database                         |

TLS is **not** handled here. The container is published only on `127.0.0.1:8081`
and also joined to the existing `proxy_default` network so **Nginx Proxy Manager**
can reach it.

## Files

```
deploy/prmsh/
├── docker-compose.yml
├── .env                 # POSTGRES_PASSWORD (gitignored) — must match config.ini
├── .env.example
├── backup.sh            # host-cron pg_dump backup
├── config/config.ini    # MeshView config (gitignored)
└── data/                # postgres data + backups (gitignored)
```

## First run

```bash
cd /home/master/meshview/deploy/prmsh

# 1. (already done) .env has a generated POSTGRES_PASSWORD that matches
#    the connection_string in config/config.ini. If you change one, change both.

# 2. Start
docker compose up -d

# 3. Watch it come up (DB migrations run automatically via startdb.py)
docker compose logs -f meshview
```

Check locally:

```bash
curl -s http://127.0.0.1:8081/health
curl -s http://127.0.0.1:8081/version
```

## Nginx Proxy Manager

In the NPM UI → **Proxy Hosts → Add Proxy Host**:

| Field                  | Value                |
|------------------------|----------------------|
| Domain Names           | `meshview.prmsh.com` |
| Scheme                 | `http`               |
| Forward Hostname / IP  | `meshview-prmsh`     |
| Forward Port           | `8081`               |
| Websockets Support     | **on** (SSE / live map) |
| Block Common Exploits  | on                   |

SSL tab → request a new Let's Encrypt cert, **Force SSL** + **HTTP/2**.

> NPM resolves `meshview-prmsh` because both containers share the `proxy_default`
> Docker network. If NPM lives on a different network, add that network to the
> `meshview` service in `docker-compose.yml` instead.

Point DNS `meshview.prmsh.com` → this host's public IP before requesting the cert.

## Repository / git workflow

This checkout is the **production source** and lives on the fork:

| Remote     | URL                                                   | Use                          |
|------------|-------------------------------------------------------|------------------------------|
| `origin`   | `git@github.com:SirMelendezTech/meshview-prmsh.git`   | production repo — push here  |
| `upstream` | `https://github.com/pablorevilla-meshtastic/meshview` | the upstream project         |

`master` tracks `origin/master`. **Before making changes, always check upstream:**

```bash
git fetch upstream
git log --oneline master..upstream/master     # what's new upstream
git merge upstream/master                      # pull it in when appropriate
git push origin master
```

The `deploy/prmsh/` overlay is only on the fork; upstream never carries it.

## Updating the running stack

```bash
cd /home/master/meshview/deploy/prmsh
git pull                 # latest prod config from the fork
docker compose pull      # latest meshview image
docker compose up -d
```

## Backups

App-level backups only support SQLite, so PostgreSQL is dumped by `backup.sh`.
Add to the host crontab (`crontab -e`):

```
0 3 * * * /home/master/meshview/deploy/prmsh/backup.sh >> /home/master/meshview/deploy/prmsh/logs/backup.log 2>&1
```

Restore:

```bash
gunzip -c data/backups/meshview_YYYYMMDD_HHMMSS.sql.gz \
  | docker exec -i meshview-prmsh-db psql -U meshview -d meshview
```

## Data retention

`config.ini [cleanup]` keeps **30 days** and runs daily at 03:30 local time.
Adjust `days_to_keep` there and `docker compose restart meshview` to apply.

## Ports

`8081` was free on this host and is used (bound to `127.0.0.1` only). Nothing is
exposed publicly by this compose project.
