# Live Server Dashboard + Boot Autostart

The default home screen is a **live SERVER MODE dashboard** that shows real
per-core CPU load, RAM and SWAP usage, IP, uptime and a clock — animated, over a
matrix-rain background. It reads real telemetry from the on-device server and
starts automatically on boot.

## How it works

```
 Home launcher APK (com.veltein.home)
   └─ WebView loads  file:///android_asset/veltein_home.html
        └─ every 2s:  fetch http://127.0.0.1:8080/stats.json   (CORS: *)
                         ▲
 Termux server          │
   ├─ python stats.py  ─┘  writes stats.json into nginx webroot each second
   │     reads /proc/stat (per-core %) + /proc/meminfo (RAM/SWAP) + ifconfig (IP)
   └─ nginx :8080  serves /stats.json with Access-Control-Allow-Origin: *
```

If the server is not running, the page animates realistic values and shows
`monitor --live`; when real data is flowing the footer shows `monitor --live • REAL`.

## 1. Stats writer

`server/stats.py` samples `/proc/stat` once per second, computes per-core busy %
(`1 - idle_delta/total_delta`), reads `/proc/meminfo` for RAM/SWAP %, gets the
Wi-Fi IP from `ifconfig wlan0`, and writes JSON atomically into the nginx webroot:

```json
{"cores":[66,61,50,28],"ram":43,"swap":3,"ip":"192.168.110.94","ts":1794505994}
```

Install on device:

```sh
mkdir -p ~/veltein
cp server/stats.py ~/veltein/stats.py        # (push via scp/ssh)
python ~/veltein/stats.py &
```

## 2. nginx CORS location

The WebView runs from a `file://` origin, so nginx must allow cross-origin reads.
Add this block **before** `location / {` in `$PREFIX/etc/nginx/nginx.conf`:

```nginx
location = /stats.json {
    root   /data/data/com.termux/files/usr/share/nginx/html;
    add_header Access-Control-Allow-Origin "*" always;
    add_header Cache-Control "no-store" always;
    default_type application/json;
}
```

Then `nginx -t && nginx -s reload` (or just `nginx`).

## 3. Boot autostart (Termux:Boot)

Install **Termux:Boot** (must be signed by the same key as Termux — use the
GitHub release build, not F-Droid, if your Termux is from GitHub). Then:

```sh
mkdir -p ~/.termux/boot
cp server/boot/00-veltein-server.sh ~/.termux/boot/
chmod +x ~/.termux/boot/00-veltein-server.sh
```

`server/boot/00-veltein-server.sh` takes a wake-lock and starts `sshd`, `nginx`
and the stats writer on every boot. Launch Termux:Boot once so Android grants it
the autostart permission.

## 4. Manual start (no reboot)

```sh
termux-wake-lock
sshd                      # SSH on :8022
nginx                     # web + stats.json on :8080
python ~/veltein/stats.py &
```

## Breaking out of the dashboard shell

The interactive dashboard (`server/dashboard.py`, auto-run on login) holds the
terminal. Press **Ctrl+C** to drop to the bash prompt. When driving the device
over ADB before SSH exists, tap the on-screen **CTRL** extra-key then **c**:

```sh
adb shell "input tap 157 860"   # CTRL extra-key (720x1440 layout)
adb shell "input tap 285 1175"  # the 'c' key
adb shell "input text 'sshd'"; adb shell "input keyevent 66"
```
