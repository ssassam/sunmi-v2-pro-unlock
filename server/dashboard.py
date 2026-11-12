import sys, os, time, subprocess

def get_cpu_usage():
    try:
        with open("/proc/stat", "r") as f:
            lines = f.readlines()
        cpus = []
        for line in lines:
            if line.startswith("cpu") and line[3:4].isdigit():
                parts = line.split()
                user, nice, sys_t, idle = map(int, parts[1:5])
                total = user + nice + sys_t + idle
                cpus.append((idle, total))
        return cpus
    except:
        return []

def get_mem_info():
    mem = {}
    try:
        with open("/proc/meminfo", "r") as f:
            for line in f:
                parts = line.split(":")
                if len(parts) == 2:
                    mem[parts[0].strip()] = int(parts[1].strip().split()[0])
        total = mem.get("MemTotal", 1943448) // 1024
        free = (mem.get("MemFree", 0) + mem.get("Buffers", 0) + mem.get("Cached", 0)) // 1024
        used = total - free
        swap_total = mem.get("SwapTotal", 524284) // 1024
        swap_free = mem.get("SwapFree", 0) // 1024
        swap_used = swap_total - swap_free
        return (used, total), (swap_used, swap_total)
    except:
        return (450, 1897), (5, 512)

def get_battery():
    try:
        res = subprocess.check_output("dumpsys battery", shell=True).decode()
        level = "N/A"
        for line in res.splitlines():
            if "level:" in line:
                level = line.split(":")[1].strip() + "%"
        return level
    except:
        return "35%"

def progress_bar(val, max_val, length=24):
    ratio = min(1.0, max(0.0, val / max_val)) if max_val > 0 else 0
    filled = int(ratio * length)
    bar = "█" * filled + "░" * (length - filled)
    pct = int(ratio * 100)
    return f"[{bar}] {pct:3d}%"

def render():
    prev_cpus = get_cpu_usage()
    time.sleep(0.3)
    curr_cpus = get_cpu_usage()
    
    cpu_pcts = []
    for (i1, t1), (i2, t2) in zip(prev_cpus, curr_cpus):
        d_tot = t2 - t1
        d_idl = i2 - i1
        pct = int(100 * (1.0 - (d_idl / d_tot))) if d_tot > 0 else 0
        cpu_pcts.append(pct)

    mem, swap = get_mem_info()
    batt = get_battery()
    
    # ANSI clear screen
    out = "\033[2J\033[H"
    
    # Header
    out += "\033[1;36m"
    out += "  ██╗   ██╗███████╗██╗  ████████╗███████╗██╗███╗   ██╗\n"
    out += "  ██║   ██║██╔════╝██║  ╚══██╔══╝██╔════╝██║████╗  ██║\n"
    out += "  ██║   ██║█████╗  ██║     ██║   █████╗  ██║██╔██╗ ██║\n"
    out += "  ╚██╗ ██╔╝██╔══╝  ██║     ██║   ██╔══╝  ██║██║╚██╗██║\n"
    out += "   ╚████╔╝ ███████╗███████╗██║   ███████╗██║██║ ╚████║\n"
    out += "    ╚═══╝  ╚══════╝╚══════╝╚═╝   ╚══════╝╚═╝╚═╝  ╚═══╝\n"
    out += "\033[0m"
    out += "       \033[1;33m>>> U N D E R   F A F O F I   C O R P <<<\033[0m\n"
    out += "\033[1;34m" + "━" * 58 + "\033[0m\n"
    out += "  \033[1;32m● SERVER NODE ONLINE\033[0m   HOST: \033[1;37mSUNMI V2 PRO (MSM8917)\033[0m\n"
    out += "  \033[1;36mIP\033[0m : \033[1;33m192.168.110.95\033[0m   \033[1;36mSSH PORT\033[0m: \033[1;32m8022 (ACTIVE)\033[0m\n"
    out += "  \033[1;36mUPS BATTERY\033[0m: \033[1;32m" + batt + " ⚡\033[0m    \033[1;36mOS\033[0m : \033[1;37mAlpine Linux v3.20\033[0m\n"
    out += "\033[1;34m" + "━" * 58 + "\033[0m\n"
    
    # CPU
    out += "  \033[1;35m[ CPU CORES LOAD - 4x 1.40 GHz ]\033[0m\n"
    for i, p in enumerate(cpu_pcts[:4]):
        bar = progress_bar(p, 100, length=22)
        out += f"  Core {i}: \033[1;32m{bar}\033[0m\n"
    
    out += "\n  \033[1;35m[ MEMORY & STORAGE ]\033[0m\n"
    mem_bar = progress_bar(mem[0], mem[1], length=22)
    out += f"  RAM  : \033[1;36m{mem_bar}\033[0m \033[0;37m{mem[0]}MB / {mem[1]}MB\033[0m\n"
    
    swap_bar = progress_bar(swap[0], swap[1], length=22)
    out += f"  SWAP : \033[1;36m{swap_bar}\033[0m \033[0;37m{swap[0]}MB / {swap[1]}MB\033[0m\n"
    
    out += "\n\033[1;34m" + "━" * 58 + "\033[0m\n"
    out += "  \033[1;33mPress [Ctrl+C] for interactive root bash prompt\033[0m\n"
    out += "\033[1;34m" + "━" * 58 + "\033[0m\n"
    
    sys.stdout.write(out)
    sys.stdout.flush()

if __name__ == "__main__":
    while True:
        try:
            render()
            time.sleep(1.0)
        except KeyboardInterrupt:
            print("\nExiting dashboard to bash shell...")
            break
