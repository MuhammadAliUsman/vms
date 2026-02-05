#!/bin/bash
# DragonCloud VPS Optimizer
# Created by DragonGamer

# Ensure running as root
if [[ $EUID -ne 0 ]]; then
   echo "Please run as root: sudo $0" 
   exit 1
fi

clear
echo "🚀 DragonCloud VPS Optimizer Starting..."
sleep 1

# Update & upgrade system
echo "🔄 Updating and Upgrading VPS..."
apt update -y && apt upgrade -y

# Install useful tools
echo "📦 Installing essential packages..."
apt install -y htop iftop unzip curl wget git vim

# Clean unnecessary files
echo "🧹 Cleaning up..."
apt autoremove -y && apt autoclean -y

# Optimize swap and memory usage
echo "⚡ Optimizing swap and memory..."
sysctl -w vm.swappiness=10
sysctl -w vm.vfs_cache_pressure=50

# Increase file descriptors (optional for servers)
echo "🔧 Increasing file descriptor limits..."
ulimit -n 65535

# Disable unnecessary services (example)
echo "🛑 Disabling unnecessary services..."
systemctl disable apache2 2>/dev/null
systemctl disable mysql 2>/dev/null

# Show system info
echo "📊 VPS Optimization Complete! Current resources:"
free -h
df -h
uptime
echo "✅ Your VPS should now perform better!"
