#!/data/data/com.termux/files/usr/bin/sh
termux-wake-lock
sshd
nginx
sleep 2
pkill -f veltein/stats.py 2>/dev/null
python ~/veltein/stats.py &
