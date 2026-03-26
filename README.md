# Remote Linux Desktop Deployment

A complete automation script for deploying a full Linux desktop environment on a remote Ubuntu server. Designed for persistent, always-on remote development using RDP access from Windows or Android tablets.

## Purpose

This project addresses the need for a **constantly-on remote development environment** that:

- **Reduces local resource usage** - Offloads coding, compilation, and AI assistance to a remote server
- **Provides tablet access** - Full desktop experience from Android tablets via Microsoft Remote Desktop
- **Stays always-on** - No need to keep your local machine running for development tasks
- **Integrates AI tools** - Pre-configured with Claude Code and OpenRouter for AI-assisted development

## Why This Stack?

| Component | Rationale |
|-----------|-----------|
| **GNOME Desktop** | Best tablet experience - touch-friendly, on-screen keyboard support, modern gestures |
| **RDP (xrdp)** | Works natively with Microsoft Remote Desktop on Windows and Android - better compression than VNC |
| **VS Code** | Industry-standard code editor with extensive extension ecosystem |
| **Claude Code** | AI assistant that integrates into the terminal workflow |
| **OpenRouter** | Unified API providing access to multiple AI models (minimax2.5 default) |
| **Chromium** | Full-featured browser for documentation and testing |

## Quick Install

```bash
# Upload the script to your server
scp deploy-desktop.sh user@your-server:/tmp/

# Run the deployment script
sudo bash /tmp/deploy-desktop.sh
```

## Post-Installation Setup

### 1. Set Your OpenRouter API Key

```bash
# Add to your ~/.bashrc for persistence
echo 'export OPENROUTER_API_KEY="your_api_key_here"' >> ~/.bashrc
source ~/.bashrc
```

Get your free API key at: https://openrouter.ai/

### 2. Connect via RDP

- **From Windows:** Open Microsoft Remote Desktop → Add PC → Enter server IP
- **From Android:** Install Microsoft Remote Desktop app → Add connection → Enter server IP

Default RDP port: `3389`

Login with your Ubuntu username and password.

## Installed Components

| Component | Description |
|-----------|-------------|
| GNOME Desktop | Modern, tablet-friendly desktop environment |
| xrdp | Remote desktop protocol (RDP) server |
| VS Code | Full-featured code editor |
| Claude Code | AI assistant (configured for OpenRouter) |
| OpenRouter | API provider with minimax2.5 default model |
| Chromium | Web browser |

## Usage Tips

### Tablet Workflow
- Use landscape mode for best experience
- Enable on-screen keyboard in GNOME Settings → Accessibility → Keyboard
- Three-finger swipe up for app overview
- Three-finger swipe left/right to switch workspaces

### Claude Code Integration
Claude Code is pre-configured to use OpenRouter. After setting your API key:

```bash
# Test Claude Code
claude --version

# Start an interactive session
claude
```

### Development Workflow
1. Connect via RDP from your tablet or Windows PC
2. Use VS Code for coding with full IDE features
3. Use Claude Code for AI assistance (`claude` in terminal)
4. Browse documentation in Chromium
5. All work persists on the server - close your session and reconnect later

## Validation

Run the validation script to verify all components:

```bash
sudo bash tests/validate-install.sh
```

## Project Structure

```
.
├── deploy-desktop.sh         # Main deployment script
├── tests/
│   └── validate-install.sh  # Post-installation validation
├── docs/
│   └── usage-guide.md       # Detailed usage documentation
└── README.md                # This file
```

## Security Considerations

- **Firewall:** The script opens port 3389 (RDP). Consider restricting to specific IPs.
- **API Keys:** Store your OpenRouter API key securely. The script writes it to `~/.config/claude/settings.json`.
- **Strong Passwords:** Use strong passwords for your Ubuntu user account.
- **Updates:** Keep the server updated with `sudo apt update && sudo apt upgrade`.

## Troubleshooting

See [docs/usage-guide.md](docs/usage-guide.md) for detailed troubleshooting covering:
- RDP connection issues
- Desktop environment problems
- Claude Code configuration
- Service status checks