#!/data/data/com.termux/files/usr/bin/bash
# Start the VELTEIN services inside Termux (web :8080 + ssh :8022)
pgrep sshd  >/dev/null || sshd
pgrep nginx >/dev/null || nginx
echo "VELTEIN up -> web :8080  ssh :8022"
