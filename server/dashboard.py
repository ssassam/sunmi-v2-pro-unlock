import sys, os, time, subprocess, random

# ---------- ANSI ----------
G="\033[1;32m"; DG="\033[0;32m"; C="\033[1;36m"; Y="\033[1;33m"
M="\033[1;35m"; R="\033[1;31m"; W="\033[1;37m"; B="\033[1;34m"; X="\033[0m"
TTY = sys.stdout.isatty()

def w(s):
    sys.stdout.write(s); sys.stdout.flush()

def type_out(s, d=0.012):
    if not TTY: d = 0
    for ch in s:
        w(ch)
        if d: time.sleep(d)
    w("\n")

def dots(label, result, color=G, n=20):
    """ > label .............. RESULT  (animated dots)"""
    w(f"  {DG}>{X} {W}{label}{X} ")
    total = max(4, n - len(label))
    for _ in range(total):
        w(f"{DG}.{X}")
        if TTY: time.sleep(0.015)
    w(f" {color}{result}{X}\n")

def real_ip():
    try:
        out = subprocess.check_output(["ifconfig","wlan0"]).decode()
        for t in out.split():
            if t.count(".")==3 and t[0].isdigit():
                return t
    except Exception:
        pass
    return "192.168.x.x"

# ---------- live hack intro ----------
def boot_sequence():
    w("\033[2J\033[H")
    w(C)
    type_out("   ╔═══════════════════════════════════════════════════╗", 0)
    type_out("   ║   V E L T E I N   ::   SECURE NODE INTERCEPT      ║", 0.004)
    type_out("   ╚═══════════════════════════════════════════════════╝", 0)
    w(X)
    type_out(f"   {Y}>>> UNDER FAFOFI CORP <<<{X}", 0.01)
    w("\n")
    ip = real_ip()
    dots("initializing access vector",      "OK",        G)
    dots("probing SUNMI V2 PRO (MSM8917)",  "DETECTED",  C)
    dots("bypassing kiosk lock",            "BYPASSED",  Y)
    dots("escalating termux runtime",       "ROOTLESS",  G)
    dots("mounting /proc telemetry",        "OK",        G)
    dots(f"opening ssh tunnel  {ip}:8022",  "LIVE",      G)
    dots("starting nginx node  :8080",      "LIVE",      G)
    dots("injecting live monitor",          "OK",        G)
    w("\n")
    # decrypt bar
    w(f"  {M}DECRYPTING NODE KEY{X} ")
    bar = 28
    for i in range(bar+1):
        pct = int(100*i/bar)
        fill = G+"█"*i+X + DG+"░"*(bar-i)+X
        w(f"\r  {M}DECRYPTING NODE KEY{X} [{fill}] {pct:3d}%")
        if TTY: time.sleep(0.03)
    w("\n\n")
    # glitch flash
    for _ in range(3 if TTY else 1):
        chars="01<>#/*{}[]ｱｲｳｴｵ"
        line="".join(random.choice(chars) for _ in range(50))
        w(f"  {DG}{line}{X}\r")
        if TTY: time.sleep(0.06)
    w(f"  {G}>> ACCESS GRANTED — NODE IS YOURS{X}            \n")
    if TTY: time.sleep(0.6)

# ---------- live telemetry ----------
def get_cpu_usage():
    try:
        cpus=[]
        with open("/proc/stat") as f:
            for line in f:
                if line.startswith("cpu") and line[3:4].isdigit():
                    p=line.split(); user,nice,sys_t,idle=map(int,p[1:5])
                    cpus.append((idle, user+nice+sys_t+idle))
        return cpus
    except Exception:
        return []

def get_mem_info():
    mem={}
    try:
        with open("/proc/meminfo") as f:
            for line in f:
                p=line.split(":")
                if len(p)==2: mem[p[0].strip()]=int(p[1].split()[0])
        total=mem.get("MemTotal",1943448)//1024
        free=(mem.get("MemFree",0)+mem.get("Buffers",0)+mem.get("Cached",0))//1024
        swt=mem.get("SwapTotal",524284)//1024; swf=mem.get("SwapFree",0)//1024
        return (total-free,total),(swt-swf,swt)
    except Exception:
        return (450,1897),(5,512)

def get_battery():
    try:
        for line in subprocess.check_output("dumpsys battery",shell=True).decode().splitlines():
            if "level:" in line: return line.split(":")[1].strip()+"%"
    except Exception:
        pass
    return "35%"

def bar(val,mx,length=22):
    r=min(1.0,max(0.0,val/mx)) if mx>0 else 0
    f=int(r*length)
    return f"[{'█'*f}{'░'*(length-f)}] {int(r*100):3d}%"

def render(ip):
    prev=get_cpu_usage(); time.sleep(0.3); curr=get_cpu_usage()
    pcts=[]
    for (i1,t1),(i2,t2) in zip(prev,curr):
        dt=t2-t1; di=i2-i1
        pcts.append(int(100*(1-di/dt)) if dt>0 else 0)
    mem,swap=get_mem_info(); batt=get_battery()
    o="\033[2J\033[H"+C
    o+="  ██╗   ██╗███████╗██╗  ████████╗███████╗██╗███╗   ██╗\n"
    o+="  ██║   ██║██╔════╝██║  ╚══██╔══╝██╔════╝██║████╗  ██║\n"
    o+="  ██║   ██║█████╗  ██║     ██║   █████╗  ██║██╔██╗ ██║\n"
    o+="  ╚██╗ ██╔╝██╔══╝  ██║     ██║   ██╔══╝  ██║██║╚██╗██║\n"
    o+="   ╚████╔╝ ███████╗███████╗██║   ███████╗██║██║ ╚████║\n"
    o+="    ╚═══╝  ╚══════╝╚══════╝╚═╝   ╚══════╝╚═╝╚═╝  ╚═══╝\n"+X
    o+=f"       {Y}>>> U N D E R   F A F O F I   C O R P <<<{X}\n"
    o+=B+"━"*58+X+"\n"
    o+=f"  {G}● SERVER NODE ONLINE{X}   HOST: {W}SUNMI V2 PRO (MSM8917){X}\n"
    o+=f"  {C}IP{X} : {Y}{ip}{X}   {C}SSH{X}: {G}8022 LIVE{X}  {C}WEB{X}: {G}8080 LIVE{X}\n"
    o+=f"  {C}UPS BATTERY{X}: {G}{batt} ⚡{X}    {C}OS{X} : {W}Termux / Linux (armv7l){X}\n"
    o+=B+"━"*58+X+"\n"
    o+=f"  {M}[ CPU CORES LOAD - 4x 1.40 GHz ]{X}\n"
    for i,p in enumerate(pcts[:4]):
        col = R if p>80 else (Y if p>50 else G)
        o+=f"  Core {i}: {col}{bar(p,100)}{X}\n"
    o+=f"\n  {M}[ MEMORY & STORAGE ]{X}\n"
    o+=f"  RAM  : {C}{bar(mem[0],mem[1])}{X} {DG}{mem[0]}MB / {mem[1]}MB{X}\n"
    o+=f"  SWAP : {C}{bar(swap[0],swap[1])}{X} {DG}{swap[0]}MB / {swap[1]}MB{X}\n"
    o+="\n"+B+"━"*58+X+"\n"
    o+=f"  {Y}Press [Ctrl+C] for interactive root bash prompt{X}\n"
    o+=B+"━"*58+X+"\n"
    w(o)

if __name__=="__main__":
    ip=real_ip()
    if os.environ.get("VELTEIN_NOINTRO") != "1":
        try: boot_sequence()
        except KeyboardInterrupt:
            print("\nExiting to bash shell..."); sys.exit(0)
    while True:
        try:
            render(ip); time.sleep(1.0)
        except KeyboardInterrupt:
            print("\nExiting dashboard to bash shell..."); break
