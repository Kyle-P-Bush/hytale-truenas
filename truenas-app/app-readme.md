# Hytale Server for TrueNAS

Host your own Hytale dedicated server with built-in CGNAT bypass!

## Key Features

- **Zero Install for Players**: Friends just paste an address into Hytale
- **CGNAT Bypass**: Works with AT&T and other carriers using playit.gg
- **Persistent Storage**: World saves, configs, and backups on TrueNAS datasets
- **Easy Configuration**: All settings via TrueNAS UI

## Requirements

- TrueNAS SCALE 24.10 (Electric Eel) or later
- 4GB+ RAM available
- playit.gg account (free)

## First Time Setup

1. Create a free account at [playit.gg](https://playit.gg)
2. Create an Agent and add a UDP tunnel for port 5520
3. Copy your Secret Key into the app configuration
4. Start the app and complete Hytale authentication
5. Share your relay address with friends!

## Storage Recommendations

Create these datasets before installation:
- `pool/apps/hytale/worlds` - World save data
- `pool/apps/hytale/config` - Server configuration  
- `pool/apps/hytale/backups` - Automatic backups
