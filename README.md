# Hytale Server for TrueNAS SCALE

A Docker-based Hytale dedicated server with built-in CGNAT bypass using playit.gg.

**Players connect with just an IP:port — no software installation required!**

## Features

- 🎮 Hytale dedicated server (Java 25)
- 🌐 CGNAT bypass via playit.gg (works with AT&T, etc.)
- 💾 Persistent storage for worlds, config, and backups
- 🔧 Configurable via environment variables
- 📦 TrueNAS SCALE compatible

## Quick Start

### 1. Clone/Copy to TrueNAS

Copy the project files to your TrueNAS server.

### 2. Set Up playit.gg (One-Time)

1. Go to [playit.gg](https://playit.gg) and create an account
2. Create a new **Agent**
3. Add a **UDP tunnel** for port `5520`
4. Copy your **Secret Key**

### 3. Configure Environment

```bash
cp .env.example .env
nano .env
```

Update these values:
- `SERVER_NAME` - Your server's display name
- `PLAYIT_SECRET_KEY` - Your playit.gg secret key
- Storage paths (point to TrueNAS datasets)

### 4. Create Storage Datasets (TrueNAS)

```
/mnt/pool/apps/hytale/
├── worlds/    # World save data
├── config/    # Server configuration
└── backups/   # Automatic backups
```

Update `.env` paths accordingly.

### 5. Deploy

**Via TrueNAS UI (Install via YAML):**
1. Go to Apps → Discover Apps → ⋮ → Install via YAML
2. Paste the contents of `docker-compose.yml`
3. Update environment variables in the UI

**Via Command Line:**
```bash
docker compose up -d
```

### 6. First Run Setup

On first launch:
1. Check logs: `docker compose logs -f hytale`
2. You'll see a Hytale authentication prompt
3. Visit the URL shown and enter the code
4. Server will start after authentication

### 7. Share with Friends

Get your public address from the [playit.gg dashboard](https://playit.gg/account/tunnels).

It will look like: `na.relay.playit.gg:12345`

**Share this with friends** — they just paste it into Hytale!

## Configuration

| Variable | Default | Description |
|----------|---------|-------------|
| `SERVER_NAME` | TrueNAS Hytale Server | Server display name |
| `MAX_PLAYERS` | 10 | Maximum concurrent players |
| `VIEW_DISTANCE` | 192 | View distance in blocks |
| `DIFFICULTY` | normal | Game difficulty |
| `JAVA_MEMORY` | 4G | RAM allocation |
| `ALLOW_OP` | false | Allow /op command |

## Troubleshooting

### Players can't connect
- Verify playit.gg tunnel is active
- Check if secret key is correct
- Ensure UDP port 5520 tunnel exists

### Server won't start
- Check logs: `docker compose logs hytale`
- Verify Java 25 compatibility
- Ensure auth was completed

### Need more players?
Increase `MAX_PLAYERS` and `JAVA_MEMORY` proportionally.

## License

MIT
