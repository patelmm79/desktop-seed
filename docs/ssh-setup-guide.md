# SSH Setup Guide for Remote Server Access

This guide walks you through setting up SSH keys so you can connect to your remote server without entering a password each time.

## Overview

You have two machines:
- **Your computer** (Windows) — local machine
- **Remote server** (Ubuntu/Hetzner) — where Claude Code installation failed

## Prerequisites

- Access to your Windows computer
- Login credentials for your remote server (IP: 204.168.182.32, username: root)

---

## Step 1: Generate SSH Keys on Your Computer

1. Open PowerShell
2. Run:

```bash
ssh-keygen -t ed25519
```

3. Press **Enter** three times (accept defaults, no passphrase)

This creates two files:
- `C:\Users\YOUR_USERNAME\.ssh\id_ed25519` (private key — keep secret)
- `C:\Users\YOUR_USERNAME\.ssh\id_ed25519.pub` (public key — safe to share)

---

## Step 2: Copy Public Key to Remote Server

### 2.1 Get your public key

In PowerShell, run:

```bash
type C:\Users\YOUR_USERNAME\.ssh\id_ed25519.pub
```

Copy the entire output (it starts with `ssh-ed25519` and ends with your email/computer name).

### 2.2 Log into your remote server

In PowerShell, run:

```bash
ssh root@204.168.182.32
```

Enter your password when prompted. You should now see a prompt like `root@your-server:~#`.

### 2.3 Add the public key

On the remote server, run:

```bash
mkdir -p ~/.ssh
chmod 700 ~/.ssh
nano ~/.ssh/authorized_keys
```

This opens a text editor.

1. Press **Ctrl+Shift+V** to paste your public key
2. Press **Ctrl+O** then **Enter** to save
3. Press **Ctrl+X** to exit

### 2.4 Secure the key file

On the remote server, run:

```bash
chmod 600 ~/.ssh/authorized_keys
```

### 2.5 Log out

On the remote server, type:

```bash
exit
```

You're back on your Windows machine.

---

## Step 3: Create SSH Config Alias

Now you can connect with a short alias instead of typing the IP each time.

### 3.1 Open Notepad as Admin

1. Search for "Notepad" in the Start menu
2. Right-click → Run as administrator
3. File → Open
4. Navigate to `C:\Users\YOUR_USERNAME\.ssh\`
5. In the file type dropdown, select "All Files (*.*)"
6. Open `config` (if it doesn't exist, you'll create it new)

### 3.2 Add the config

If the file is empty or new, add:

```
Host hetzner
    HostName 204.168.182.32
    User root
    IdentityFile C:\Users\YOUR_USERNAME\.ssh\id_ed25519
```

Replace `YOUR_USERNAME` with your actual Windows username.

### 3.3 Save

1. File → Save
2. Make sure filename is just `config` (not "config.txt")
3. Save to `C:\Users\YOUR_USERNAME\.ssh\`

---

## Step 4: Test the Connection

In PowerShell, run:

```bash
ssh hetzner "echo 'success'"
```

If it works, you'll see "success" without being asked for a password.

---

## Usage

Now you can connect to your server anytime with:

```bash
ssh hetzner
```

To run a single command without logging in:

```bash
ssh hetzner "whoami"
```

---

## Troubleshooting

### "Permission denied (publickey)"
Your public key wasn't added correctly. Go back to Step 2.3 and verify the key is in `authorized_keys`.

### "Could not resolve hostname hetzner"
The config file wasn't saved correctly. Verify Step 3.3 — the file must be named exactly `config`, not `config.txt`.

### Still asks for password
Make sure the IdentityFile path in your config matches where your private key actually is.
