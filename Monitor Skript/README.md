## System Health Monitoring (Festplatte/Last)

### Ziel des Skripts

Ein selbst entwickeltes Bash-Monitoring-Skript überwacht das Root-Dateisystem '/' sowie die durchschnittliche 15-Minuten Last des Linux Systems
-Warnung bei Überschreitung vordefinierter Schwellenwerte
-Einfaches Logging über systemd journal
-Exit-Codes für maschinelle Auswertung und Automatisierung

### Rohdaten

#### Physische Kerne zählen

Ermöglicht die dynamische Berechnung von WARN/CRIT für Festplattenplatz

```bash

CPU_CORES=$(grep -h . /sys/devices/system/cpu/cpu*/topology/core_id \  
     | cut -d: -f2 \  
     | sort -u \  
     | wc -l)  

```

#### Schwellenwerte berechnen

```bash

LOAD_WARN=$(-awk "BEGIN {printf \"%.2f\", $CPU_CORES * 0.7}")
LOAD_CRIT=$(awk "BEGIN {printf \"%.2f\", $CPU_CORES * 1.0}")

```

#### 15 min. auslesen

```bash

LOAD_15=$(awk '{print $3}' /proc/loadavg)

```

### Schwellenwerte / Status

Last: OK, WARN, CRIT
Festplattenplatz: OK, WARN, CRIT
Exit-Code 0,1,2

### Ausgabe

```text

System Health Check
===================
CPU Cores        : 2
Load (15 min)    : 0.95 (WARN >= 1.40 | CRIT >= 2.00) => OK
Disk Usage (/)   : 29% => OK
Exit-Code: 0

```

### Service & Timer

Service: Type=oneshot
Start Skript einmal und beendet sich danach, dies ist notwendig da es sich um eine Momentaufnahme(Messung) handelt.  

Timer: läuft in diesem Falle alle 15 Minuten (OnUnitActiveSec=15min) und ist persistent (Persistent=true)  

### Logs & Tests

Logging erfolgt über STDOUT/STDERR in systemd-journal

#### Timer vs crontab

- Kein einfaches Tracking von Status/Exit-Codes bei cron
- Kein natives Logging direkt ins systemd journal
- Systemd Timer können verpasste Läufe nachholen (Persistent)

#### Prüfen von Exit Codes

Logs: Journalctl -u monitor-system.service -n 20
Exit-Code maschinell auswertbar:
systemctl show monitor-system.service -p ExecMainStatus

#### Funktionstests

Skript nur für aktuellen User ausführbar machen: chmod u+x monitor_system.sh, unnötige Berechtigungen vermeiden, mehr braucht es in diesem Fall nicht.
Systemd starten: sudo systemctl start monitor-system.service  Timer aktivieren: sudo systemctl enable --now monitor-system.timer
Lasttest: stress-ng --cpu 2 --timeout 180  
Diskspace-Test: fallocate -l 10G ~/disk_test_file
echo $? -Zeigt nach manuellem Skriptlauf
