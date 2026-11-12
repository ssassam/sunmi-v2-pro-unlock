import json, time, os, subprocess
WWW = os.environ.get("PREFIX","") + "/share/nginx/html"
OUT = os.path.join(WWW, "stats.json")

def cpu_snapshot():
    snap = {}
    with open("/proc/stat") as f:
        for line in f:
            if line.startswith("cpu") and line[3:4].isdigit():
                p = line.split()
                idx = int(p[0][3:])
                vals = list(map(int, p[1:]))
                idle = vals[3] + (vals[4] if len(vals) > 4 else 0)
                total = sum(vals)
                snap[idx] = (idle, total)
    return snap

def mem():
    m = {}
    with open("/proc/meminfo") as f:
        for line in f:
            k, v = line.split(":"); m[k.strip()] = int(v.split()[0])
    tot = m.get("MemTotal",1); avail = m.get("MemAvailable", m.get("MemFree",0))
    ram = round(100*(tot-avail)/tot) if tot else 0
    st = m.get("SwapTotal",0); sf = m.get("SwapFree",0)
    swap = round(100*(st-sf)/st) if st else 0
    return ram, swap

def ip():
    try:
        out = subprocess.check_output(["ifconfig","wlan0"]).decode()
        for t in out.split():
            if t.startswith("192.") or t.count(".")==3 and "/" in t:
                return t.split("/")[0]
    except Exception:
        pass
    return ""

prev = cpu_snapshot()
myip = ip(); tick = 0
while True:
    time.sleep(1.0)
    cur = cpu_snapshot()
    cores = []
    for i in sorted(cur):
        if i in prev:
            di = cur[i][0]-prev[i][0]; dt = cur[i][1]-prev[i][1]
            cores.append(round(100*(1 - di/dt)) if dt>0 else 0)
    prev = cur
    ram, swap = mem()
    tick += 1
    if tick % 15 == 0: myip = ip() or myip
    data = {"cores": cores, "ram": ram, "swap": swap, "ip": myip, "ts": int(time.time())}
    tmp = OUT + ".tmp"
    with open(tmp,"w") as f: json.dump(data,f)
    os.replace(tmp, OUT)
