
# Julian Loontjens MOTD

A clean, modern, and slightly personal **Message of the Day (MOTD)** setup for Linux servers.  
Built from scratch to replace the default Ubuntu MOTD with something that actually feels yours —  
with ASCII style, color, system info, and a touch of character.

---

## ✨ Features

- Custom ASCII banner with your name  
- Clean and colorized system information  
- Shows hostname, uptime, load, IPs, temperature, and more  
- Modular structure using `/etc/update-motd.d/`  
- Safe backup and restore system  
- Easy install and uninstall scripts  

---

## 🧩 Example Output

When you log in via SSH, you’ll see something like this:

```
       ____  ____    _______    _   __   __    ____  ____  _   ________  _________   _______
      / / / / / /   /  _/   |  / | / /  / /   / __ \/ __ \/ | / /_  __/ / / ____/ | / / ___/
 __  / / / / / /    / // /| | /  |/ /  / /   / / / / / / /  |/ / / /_  / / __/ /  |/ /\__ \ 
/ /_/ / /_/ / /____/ // ___ |/ /|  /  / /___/ /_/ / /_/ / /|  / / / /_/ / /___/ /|  /___/ / 
\____/\____/_____/___/_/  |_/_/ |_/  /_____/\____/\____/_/ |_/ /_/\____/_____/_/ |_//____/ 

Welcome to julianloontjens-server (GNU/Linux 6.8.0-86-generic x86_64)

Hostname:     julian-server
Uptime:       56 minutes
Load:         0.00, 0.00, 0.00
Kernel:       6.8.0-86-generic
Date:         Tuesday 28 October 2025, 20:28
Local IP:     192.168.178.108
External IP:  2001:1c05:884:8700:be24:11ff:fe50:d2a
Temperature:  N/A

All systems nominal... or pretending to be.
Take a breath. Check the logs. Maybe grab a tea.
```

---

## ⚙️ Installation

Clone the repository and run the installer:

```bash
git clone https://github.com/JulienLoon/julianloontjens-motd.git
cd julianloontjens-motd
sudo bash install.sh
```

The script will:
- Backup your existing `/etc/update-motd.d/` files into `/etc/update-motd.d/backup-julianloontjens/`
- Copy new MOTD files from `motd/` into `/etc/update-motd.d/`
- Display your new banner when you log in

---

## 🧹 Uninstall

If you ever want to restore the original MOTD:

```bash
sudo bash uninstall.sh
```

This will:
- Remove all custom MOTD scripts from `/etc/update-motd.d/`
- Restore the backup folder created during installation

---

## 📄 License

MIT License © 2025 [Julian Loontjens](https://github.com/JulienLoon)
