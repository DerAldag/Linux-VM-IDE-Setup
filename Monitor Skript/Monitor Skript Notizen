# Konzept und Use-Case Überlegungen

In diesem Dokument wird festgehalten, wie ich mir Schritt für Schritt ein möglichst robustes, weitgehend Distro-Unabhängiges Bash Skript zum Monitoring von Durchschnittslast und Diskbelegung von Grund auf erstelle.

Basiskonzept: Skript/Service für Automatisches Monitoring von Diskspace und Durchschnittslast, Warnung bei Überschreitungen, einfache logs

Für Diskspace mountlogik verwenden. Damit ließe sich das Skript theoretisch auch auf einer neuen Maschine einfach einbauen.  
/ = Für die Überwachung relevantes Wurzelverzeichnis  
Unter 80 % = OK, über 80 = Warnung, über 90% = Kritisch -Disk läuft meist monoton, daher keiner wiederholten Warnungen, Zustandswechsel sind Aussagekräftig  
Derzeit 2 cores: 2x1 = 2 kritisch 2x0,7 = 1,4 Warnung , Anzahl kann aber variieren, daher ist Auslesen eine langfristige Lösung.  
Lastdurchschnitt der letzten 15 minuten, das skript soll nicht bei jeder Kleinigkeit, die man nichtmal spürt, auslösen, sondern bei lanfristiger Überbeanspruchung.  
Detaillierte logs sind für dieses System und Use Case nicht notwendig, da die Lösung bei Überlast klar ist: Mehr Kerne zuweisen oder mit Verzögerungen leben.  
Zustandsspeicherung ist ebenfalls nicht notwendig, sofern Warnungen korrekt ausgelöst werden, da das Problem bis zum nächsten Start gelöst wird, könnte aber im Nachhinein zur Verallgemeinerung des Skripts eingefügt werden.

## Finden und Ausgeben der Rohdaten

### Last

Beobachtung unter Last mit Strss-NG --cpu 2 -timeout 120  
1 min. avg zwischen 2,4 und 2,99  

loadavg letzte 15 min. auslesen
aus ~/proc/loadavg  
awk '{print $3}' /proc/loadavg -Ausgabe(print) an Positionsargument 3  
Terminal = 0.49  
Im Skript *100 für einen Integer, der nativ von Bash verarbeitet werden kann.  
Mit Variablen für OK, WARN, KRIT abgleichen
ab  WARN: Ausgabe und log

### Kernzanzahl

Für die mathematische Einarbeitung der verfügbaren Kerne in das Skript, um auch bei mehr zugewiesenen Kernen zu funktionieren.

Versucht mit lscpu | grep "CPU(s)" nur die nötige Zeile zu bekommen, schlechte Idee  
lscpu | awk 'NR==5 {print $5}' liefert gewünschte Zahl, aber fragil, da es von einem UI Element abliest.  

Folgende Lösung ist stabil, sprachunabhängig und robust über Distros  
Core_ID sind in ~/sys ... /core_id gespeichert  
Genutzte Funktionen Grep Cut Sort WC Pipe  

grep -h . /sys/devices/system/cpu/cpu*/topology/core_id \ | cut -d: -f2 \ | sort -u \ | wc -l  

Grep -h . /sys/devices/system/cpu/cpu*/topology/core_id -liefert Dateiname und Core ID -h flagge inkludiert immer Dateinamen. Für ein robustes Skript, welches auf dieser Annahme basiert, essenziell  
| cut -d: -f2 -trennt am doppelpunkt und gibt das damit eindeuitige feld 2, die core id aus  
| sort -u -Sortiert die IDs und entfernt duplikate, sodass jede zeile einem Kern zuzuordnen ist  
| wc -l -wordcount zählt die Zeilen  mit -l  

Ergebnis: Anzahl der physischen Kerne als Rohdaten

### Belegung von / als %

df -P / | awk 'NR==2 {print $5}'  

df -P / -Zeigt Belegung des Wurzelverzeichnisses ohne Umbrüche  
| awk 'NR==2 {print $5}'(NR==2) -Gibt es an gawk, um Zeile 2 Feld 5 auszugeben

Next: Prozentzeichen entfernen, Integer oder floatvergleich  

## Syntax und Tests

Sprache: Bash
set -u          -Falls Variable nicht existiert
set -o pipefail -Falls Pipe fehlschläge

### Physische Kerne ermitteln

```bash

CPU_CORES=$(grep -h . /sys/devices/system/cpu/cpu*/topology/core_id \
  | cut -d: -f2 \
  | sort -u \
  | wc -l)

```

### Last Schwellen berechnen & Lastdurchschnitt auslesen

awk kann floats verarbeiten, exit codes setzen und ist auf jedem linux system vorhanden, deshalb awk statt bc

Begin {} bei awk notwendig, da awk normalerweise von STDIN liest, es braucht daher eine Anweisung, zu "beginnen".

```bash

LOAD_WARN=$(awk "BEGIN {printf \"%.2f\", $CPU_CORES * 0.7}")
LOAD_CRIT=$(awk "BEGIN {printf \"%.2f\", $CPU_CORES * 1.0}")

LOAD_15=$(awk '{print $3}' /proc/loadavg)

```

### Lastenvergleich

```bash

LOAD_STATUS="OK"

if awk "BEGIN {exit !($LOAD_15 >= $LOAD_CRIT)}"; then
    LOAD_STATUS="CRIT"
    elif awk "BEGIN {exit !($LOAD_15 >= $LOAD_WARN)}"; then
    LOAD_STATUS="WARN"
fi

```

### Festplattenbelegung des home Verzeichnisses formatgerecht auslesen

DISK_USAGE_RAW=$(df -P / | awk 'NR==2 {print $5}')
DISK_USAGE=${DISK_USAGE_RAW%\%}

### Vergleich Festplatte mit festgelegten CRIT/WARN werten

```bash

DISK_STATUS="OK"

if [ "$DISK_USAGE" -ge 90 ]; then
  DISK_STATUS="CRIT"
elif [ "$DISK_USAGE" -ge 80 ]; then
  DISK_STATUS="WARN"
fi

```

### Ausgabe

```bash

echo "System Health Check"
echo "==================="
echo "CPU Cores        : $CPU_CORES"
echo "Load (15 min)    : $LOAD_15 (WARN >= $LOAD_WARN | CRIT >= $LOAD_CRIT) => $LOAD_STATUS"
echo "Disk Usage (/)   : $DISK_USAGE% => $DISK_STATUS"

```

### Test des Skripts (nur Last unter Stress)

Erstellt 10 gig file für Test, größe muss für System angepasst werden, dann das Skript einmal ausführen:  
fallocate -l 10G ~/disk_test_file  
sudo systemctl start monitor-system.service  
rm ~/disk_test_file

WARN & CRIT werden korrekt angezeigt

Last erzeugen:
Stress-ng --cpu --timeout 180 
&
./monitor_system.sh -mehrfach ausführen, last beobachten.  

Test ohne Last: Keine Veränderung der Last  
Last steigt kontinuierlich = Skript Logik OK

Skript ausführbar machen, best practise: Keine Berechtigungen, die nicht zwingen notwendig sind, deshalb nur (u)ser + x

chmod u+x monitor_system.sh
./monitor_system.sh

## Service Datei & Timer  erstellen

Todo: Vollständiges Verständnis von Service Datei/Timer Logik & Syntax noch nicht adäquat, weitere Quellen finden, folgendes sollte funktionieren.

Erklärung systemd Service als Type=oneshot

### Service Datei

./system/monitor-system.service

[Unit]
Description=System Health Check (Disk + Load)
After=network.target

[Service]
Type=oneshot
ExecStart=/usr/local/bin/monitor_system.sh

[Install]
WantedBy=multi-user.target

### Timer

-/system/monitor-system.timer

[Unit]
Description=Run system health check every 15 minutes

[Timer]
OnBootSec=5min
OnUnitActiveSec=15min
AccuracySec=1min
Persistent=true

[Install]
WantedBy=timers.target

## Logs

Logging erfolgt bewusst nur über STDOUT/STDERR und wird durch systemd im Journal erfasst, mehr wäre für dieses Skript/System Overkill

journalctl -u system-monitor.service
