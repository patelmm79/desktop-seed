# SSH Setup Guide

This guide walks you through setting up SSH keys so you can connect to your remote server without entering a password each time.

SSH keys are more secure than passwords, and once set up, they're more convenient too — no typing a password every time you connect.

## What You're Working With

- **Your computer** — Windows (local machine)
- **Remote server** — Ubuntu server you want to connect to

---

## Step 1 — Generate an SSH Key on Your Computer

1. Open **PowerShell** (search for it in the Start menu)
2. Run:

```bash
ssh-keygen -t ed25519
```

3. Press **Enter** three times to accept the defaults (no passphrase is fine for most use cases)

This creates two files in `C:\Users\YOUR_USERNAME\.ssh\`:
- `id_ed25519` — your **private key** (keep this secret, never share it)
- `id_ed25519.pub` — your **public key** (safe to copy to servers)

---

## Step 2 — Copy Your Public Key to the Server

### 2.1 Get your public key

In PowerShell:

```bash
type C:\Users\YOUR_USERNAME\.ssh\id_ed25519.pub
```

Copy the entire output — it starts with `ssh-ed25519` and ends with your computer name or email.

### 2.2 Log into your server with your password (one last time)

```bash
ssh root@YOUR_SERVER_IP
```

Enter your password when prompted.

### 2.3 Add the public key to the server

Once logged in, run:

```bash
mkdir -p ~/.ssh
chmod 700 ~/.ssh
nano ~/.ssh/authorized_keys
```

This opens a text editor.

1. Press **Ctrl+Shift+V** to paste your public key
2. Press **Ctrl+O** then **Enter** to save
3. Press **Ctrl+X** to exit

### 2.4 Secure the file

```bash
chmod 600 ~/.ssh/authorized_keys
```

### 2.5 Log out

```bash
exit
```

---

## Step 3 — Create a Shortcut (SSH Config)

Instead of typing your server's IP every time, you can give it a short nickname.

### 3.1 Open the SSH config file

1. Open **Notepad** (search in the Start menu)
2. File → Open
3. Navigate to `C:\Users\YOUR_USERNAME\.ssh\`
4. In the file type dropdown, select **All Files (\*.\*)**
5. Open the file named `config` — if it doesn't exist, just start a new file

### 3.2 Add your server

```
Host myserver
    HostName YOUR_SERVER_IP
    User root
    IdentityFile C:\Users\YOUR_USERNAME\.ssh\id_ed25519
```

Replace `YOUR_USERNAME` with your actual Windows username and `YOUR_SERVER_IP` with your server's IP.

### 3.3 Save the file

File → Save. Make sure the filename is exactly `config` (not `config.txt`). Save it to `C:\Users\YOUR_USERNAME\.ssh\`.

---

## Step 4 — Test It

In PowerShell:

```bash
ssh myserver "echo 'connection successful'"
```

You should see `connection successful` without being asked for a password.

From now on, connect to your server with just:

```bash
ssh myserver
```

---

## Troubleshooting

### "Permission denied (publickey)"
The public key wasn't added correctly. Go back to Step 2.3 and make sure the key is in `~/.ssh/authorized_keys` on the server.

### "Could not resolve hostname myserver"
The config file wasn't saved correctly. Check Step 3.3 — the file must be named exactly `config`, not `config.txt`. Open File Explorer, navigate to `C:\Users\YOUR_USERNAME\.ssh\`, and verify the filename.

### Still being asked for a password
The `IdentityFile` path in your config might not match where your private key is saved. Open PowerShell and run:
```bash
ls C:\Users\YOUR_USERNAME\.ssh\
```
Verify that `id_ed25519` exists there, and that the path in your config file matches exactly.
