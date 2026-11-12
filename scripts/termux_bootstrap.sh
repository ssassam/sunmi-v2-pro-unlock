#!/data/data/com.termux/files/usr/bin/bash
# VELTEIN on-device installer. Fetched and run inside Termux:
#   pkg update -y && pkg install -y wget && \
#   wget -qO- https://raw.githubusercontent.com/ssassam/sunmi-v2-pro-unlock/main/scripts/termux_bootstrap.sh | bash
set -e
RAW="https://raw.githubusercontent.com/ssassam/sunmi-v2-pro-unlock/main"
P="$PREFIX"; WWW="$P/share/nginx/html"

echo "[VELTEIN] installing packages (nginx, openssh, python)..."
pkg install -y openssh nginx python wget >/dev/null
mkdir -p ~/veltein ~/.ssh ~/.termux/boot "$WWW"
chmod 700 ~/.ssh

echo "[VELTEIN] authorizing SSH key..."
wget -qO ~/.ssh/authorized_keys "$RAW/server/authorized_keys"
chmod 600 ~/.ssh/authorized_keys

echo "[VELTEIN] fetching server files..."
wget -qO ~/veltein/stats.py     "$RAW/server/stats.py"
wget -qO ~/veltein/dashboard.py "$RAW/server/dashboard.py"
wget -qO "$WWW/index.html"      "$RAW/server/index.html"
wget -qO ~/.termux/boot/00-veltein-server.sh "$RAW/server/boot/00-veltein-server.sh"
chmod +x ~/.termux/boot/00-veltein-server.sh

echo "[VELTEIN] writing nginx config (with CORS stats.json)..."
cat > "$P/etc/nginx/nginx.conf" <<NGINX
worker_processes 1;
events { worker_connections 128; }
http {
  include mime.types;
  default_type application/octet-stream;
  sendfile on;
  server {
    listen 8080;
    server_name localhost;
    location = /stats.json {
      root $WWW;
      add_header Access-Control-Allow-Origin "*" always;
      add_header Cache-Control "no-store" always;
      default_type application/json;
    }
    location / { root $WWW; index index.html; }
  }
}
NGINX

echo "[VELTEIN] dashboard on interactive login..."
grep -q veltein-dashboard ~/.bash_profile 2>/dev/null || cat >> ~/.bash_profile <<'PROF'
# veltein-dashboard
if [ -z "$VELTEIN_NODASH" ] && [ -t 1 ]; then python ~/veltein/dashboard.py; fi
PROF

echo "[VELTEIN] starting services..."
termux-wake-lock 2>/dev/null || true
pgrep -x sshd  >/dev/null || sshd
pkill -f veltein/stats.py 2>/dev/null || true
nohup python ~/veltein/stats.py >/dev/null 2>&1 &
nginx -t >/dev/null 2>&1 && { pgrep -x nginx >/dev/null || nginx; }
sleep 2

echo "[VELTEIN] ====== DONE ======"
echo "  SSH  : port 8022"
echo "  WEB  : port 8080  (http://127.0.0.1:8080/)"
echo "  stats: $(cat "$WWW/stats.json" 2>/dev/null)"
echo "Reboot-safe via Termux:Boot. Launch Termux:Boot once to grant autostart."
