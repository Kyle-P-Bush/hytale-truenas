# Complete Setup Guide: Hytale Server on TrueNAS

This guide walks you through every step to get your Hytale server running on TrueNAS SCALE with CGNAT bypass.

**Time Required:** ~30 minutes  
**Difficulty:** Beginner-friendly

---

## Prerequisites Checklist

Before starting, ensure you have:

- [ ] TrueNAS SCALE 24.10 (Electric Eel) or later
- [ ] At least 6GB RAM available for the app
- [ ] A Hytale account (for server authentication)
- [ ] Basic familiarity with TrueNAS web interface

---

## Part 1: Understand playit.gg (No Pre-Setup Needed!)

> **Good news!** With the Docker approach, you **don't need to create an agent beforehand**.
> The agent gets created automatically when you first run the container.

playit.gg creates a public address for your server so players can connect without installing anything.

### How It Works (Simplified)
1. You start the Docker container
2. Check container logs for a **claim link**
3. Open the link to claim the agent to your playit.gg account
4. Add a UDP tunnel for port 5520
5. Get your public address to share with friends

We'll do all of this in **Part 6** after the containers are running.

---

## Part 2: Prepare TrueNAS Storage (5 minutes)

### Step 2.0: Find Your Pool Name
First, find your pool's mount path. In TrueNAS Shell or SSH:
```bash
ls /mnt/
```
You'll see your pool name (common names: `tank`, `pool`, `storage`, `data`).

> **Example:** If you see `storage`, your base path is `/mnt/storage/`

### Step 2.1: Create Datasets
1. Log into your **TrueNAS web interface**
2. Go to **Datasets** in the sidebar
3. Select your pool
4. Click **Add Dataset** and create these:

| Dataset Name | Example Path (if pool is "storage") |
|-------------|-------------------------------------|
| `hytale` | `/mnt/storage/hytale` |
| `hytale/worlds` | `/mnt/storage/hytale/worlds` |
| `hytale/config` | `/mnt/storage/hytale/config` |
| `hytale/backups` | `/mnt/storage/hytale/backups` |

### Step 2.2: Set Permissions
1. Select the `hytale` dataset
2. Click **Edit** next to Permissions
3. Set:
   - **User:** `apps` (or UID `568`)
   - **Group:** `apps` (or GID `568`)
4. Check **Apply Recursively**
5. Click **Save**

---

## Part 3: Get the Project Files (2 minutes)

SSH into TrueNAS or use **System → Shell** in the web UI.

> **Important:** You'll need `sudo` for write permissions. The project files should go in a **separate directory** from your data datasets.

```bash
# Replace YOUR_POOL with your actual pool name (e.g., storage, tank)
cd /mnt/YOUR_POOL
sudo git clone https://github.com/Kyle-P-Bush/hytale-truenas.git hytale-server
cd hytale-server
```

**Your directory structure will be:**
```
/mnt/YOUR_POOL/
├── hytale/              ← Data storage (your datasets)
│   ├── worlds/
│   ├── config/
│   └── backups/
└── hytale-server/       ← Project files (Dockerfile, docker-compose, etc.)
```

This separation keeps your world saves and configs safe even if you update the project files.

---

## Part 4: Configure the Application (5 minutes)

### Step 4.1: Create Environment File
1. SSH into TrueNAS or use the web Shell
2. Navigate to the project directory:
   ```bash
   cd /mnt/YOUR_POOL/hytale-server
   ```
3. Create environment file:
   ```bash
   sudo cp .env.example .env
   sudo nano .env
   ```

### Step 4.2: Edit Configuration
Update these values in `.env`:

```bash
# Your server name
SERVER_NAME=My Hytale Server

# Player settings
MAX_PLAYERS=10
JAVA_MEMORY=4G

# Storage paths - UPDATE THESE TO MATCH YOUR POOL!
# Example for pool named "storage":
HYTALE_WORLDS=/mnt/storage/hytale/worlds
HYTALE_CONFIG=/mnt/storage/hytale/config
HYTALE_BACKUPS=/mnt/storage/hytale/backups

# NOTE: Leave PLAYIT_SECRET_KEY empty for now
# We'll claim the agent after starting the containers
PLAYIT_SECRET_KEY=
```


Save and exit (Ctrl+X, Y, Enter in nano).

---

## Part 5: Deploy the Application (2 minutes)

1. SSH into TrueNAS or use the web Shell
2. Navigate to the project directory:
   ```bash
   cd /mnt/YOUR_POOL/hytale-server
   ```
3. Start the stack:
   ```bash
   sudo docker compose up -d
   ```
4. Check it's running:
   ```bash
   sudo docker compose ps
   ```

You should see two containers: `hytale-server` and `hytale-playit`.

---

## Part 6: First-Time Setup (10 minutes)

After deploying, you need to complete two things: **claim playit.gg agent** and **authenticate Hytale**.

### Step 6.1: Claim Your playit.gg Agent

1. View the playit container logs:
   ```bash
   sudo docker compose logs -f playit
   ```
   Or in TrueNAS UI: **Apps** → Click on Hytale → **Logs** → select playit container

2. Look for a **claim link** in the logs:
   ```
   link=https://playit.gg/claim/xxxxxxx
   ```

3. **Open that link in your browser**
4. If you don't have a playit.gg account, create one
5. The agent will be claimed to your account

### Step 6.2: Create UDP Tunnel for Hytale

1. Go to **https://playit.gg** and log in
2. Click on **Tunnels** in the sidebar
3. Click **Create Tunnel**
4. Configure:
   - **Tunnel Type:** Custom UDP
   - **Local Port:** `5520`
   - **Agent:** Select your claimed agent
5. Click **Create**
6. **Copy the public address** shown (e.g., `na.relay.playit.gg:12345`)
   - This is what you'll share with friends!

### Step 6.3: Add Hytale Server Files

Hytale doesn't provide public server downloads. You need to copy files from your Hytale installation.

1. On your gaming PC, find your Hytale installation:
   - **Windows:** `C:\Users\YOU\AppData\Local\Hytale\`
   - **Mac:** `~/Library/Application Support/Hytale/`

2. Copy the server files from the `server/` folder:
   - `hytale-server.jar` (the main file)
   - Any `.dll` or config files

3. Transfer these files to your TrueNAS `config` dataset:
   ```bash
   # From your TrueNAS shell, the config folder is:
   /mnt/YOUR_POOL/hytale/config/
   ```
   You can use SMB share, SCP, or any file transfer method.

4. After adding the files, restart the container:
   ```bash
   cd /mnt/YOUR_POOL/hytale-server
   sudo docker compose restart hytale
   ```

### Step 6.4: Complete Hytale Server Authentication

1. View the Hytale container logs:
   ```bash
   sudo docker compose logs -f hytale
   ```

2. Look for the authentication prompt:
   ```
   ==========================================
     AUTHENTICATION REQUIRED
   ==========================================
   
   Visit https://hytale.com/link and enter code: XXXX-XXXX
   ```

3. Open that URL in your browser
4. Log in with your Hytale account
5. Enter the code from the logs
6. The server will continue starting

### Step 6.5: Verify Everything is Working

Check the logs for:
```bash
sudo docker compose logs -f hytale
```

Look for:
```
[INFO] Server started on port 5520
[INFO] Waiting for players...
```

And verify in playit.gg dashboard that your agent shows **Online**.

---

## Part 7: Connect and Play! 🎮

### Your Connection Address
Go back to your **playit.gg dashboard** → **Tunnels**

Your public address will look like:
```
na.relay.playit.gg:12345
```

### Share with Friends
1. Copy the full address (including port)
2. Send to friends via Discord, text, etc.
3. Friends paste it into Hytale's "Join Server" screen
4. **That's it!** — No installation needed on their end

### Connect Yourself
You can connect via:
- The playit.gg address (like your friends)
- Or directly via `YOUR_TRUENAS_IP:5520` if on the same network

---

## Troubleshooting

### Server won't start
```bash
# Check logs
sudo docker compose logs hytale

# Common fixes:
# - Ensure hytale-server.jar is in /mnt/YOUR_POOL/hytale/config/
# - Verify .env file has correct paths
# - Check dataset permissions (apps:apps)
```

### playit.gg not connecting
```bash
# Check playit logs
sudo docker compose logs playit

# Verify:
# - You claimed the agent via the link in logs
# - Tunnel is set to Custom UDP, port 5520
# - Agent shows "Online" in playit.gg dashboard
```

### Friends can't connect
1. Verify your tunnel shows "Active" in playit.gg
2. Ensure server authentication completed
3. Check they're using UDP address, not TCP
4. Try restarting playit container: `sudo docker compose restart playit`

### Need to stop the server
```bash
sudo docker compose down
```

### View real-time logs
```bash
sudo docker compose logs -f
```

---

## Maintenance

### Backup Your World
Your world is automatically saved to `/mnt/YOUR_POOL/hytale/worlds`.

To create a snapshot:
1. Go to **Datasets** → Select `hytale/worlds`
2. Click **Create Snapshot**

### Update the Server
```bash
cd /mnt/YOUR_POOL/hytale-server
sudo docker compose pull
sudo docker compose up -d
```

### Check Resource Usage
```bash
docker stats hytale-server
```

---

## Quick Reference

| Item | Value |
|------|-------|
| **Server Port** | UDP 5520 |
| **Java Version** | 25 (Temurin) |
| **playit.gg Dashboard** | https://playit.gg/account |
| **Project Location** | `/mnt/pool/hytale/` |
| **Logs Command** | `docker compose logs -f` |

---

**Congratulations!** 🎉 Your Hytale server is now running on TrueNAS with CGNAT bypass. Friends can join without installing anything — just share the playit.gg address!
