# Development Setup - Windows GUI Host / Linux Verwaltung & Code Verarbeitung

## Kurzfassung

Windows-Host mit Linux-VM für isolierte Entwicklunsarbeit.
Verwaltung per SSH & tmux, Entwicklung über VS Code Remote-SSH.
Automatisierte Backups und systemd-basiertes Monitoring.

## Was dieses Projekt demonstriert

Dieses Repository dokumentiert im Detail ein selbst entworfenes Entwicklungs-Setup unter Ubuntu-VM mit GUI im Windows Host.

- Planung einer isolierten Entwicklungsumgebung
- Sichere Remote-Verwaltung (SSH, tmux)
- Trennung von Host- und Arbeitsumgebung
- Nutzung der gewohnten Windows-GUI, aber Skripting per bash
- Automatisierte Backups mit systemd
- Automatisierte Monitoring Skripte für Festplattenbelegung und Last
- Saubere, nachvollziehbare technische Dokumentation

## Ziel des Setups

Ziel des Setups ist es, eine stabile, bequem erreichbare Linux Arbeitsumgebung für Softwareentwicklung bereitzustellen, während Windows ausschließlich als GUI-Host verwendet wird. Dadurch können Coding-Tutorials und Entwicklungsworkflows einheitlich in einer Linux-Umgebung durchgeführt werden, ohne die gewohnte Windows-Oberfläche, Shortcuts oder Freizeitnutzung aufzugeben. 

Aufgaben der Windows Maschine in diesem Setup

- Host-System inkl. Netzwerkzugang
- Bereitstellung der grafischen Oberfläche(VS Code, Terminal)

Aufgaben der Ubuntu Server VM:

- Ausführung und Verwaltung von Code
- Entwicklungswerkzeuge(z. B. Virtuelle Python Umgebung, Docker)
- Abhängigkeiten
- Regelmäßiger backup job über Tar-Skripte

## Architektur (Tech Stack)

- Windows 10 Host Maschine
- VMWorkstation Pro
- Ubuntu Server (headless, ohne GUI)
- Zugriff nur per SSH (Schlüsselaustausch)
- Robust durch tmux Session
- Entwicklung/Code-Editing über VS Code Remote-SSH
- Bash
- systemd (Services & Timer)
- SSH (Schlüsselbasiert, Agent-Forwarding)
- tmux
- Git & Github
- VS Code Remote-SSH

## Motivation & Designentscheidungen

### Warum Ubuntu in einer VM statt Dual Boot

- Kein Neustart nötig,  Ubuntu Server ohne GUI startet sehr schnell
- Technische Trennung von Arbeits- und Freizeitumgebung, aber nahtloser Übergang zwischen beidem

### Warum Ubuntu Server

- Minimaler Ressourcenverbrauch für lagfreies Arbeiten
- Größerer Lerneffekt durch Verzicht auf GUI, Arbeit am Terminal erzwungen
- Stabile Distro
- Breiter Support

### Warum tmux?

- Sitzungen bleiben bei SSH Abbrüchen erhalten
- Bei Bedarf weitere Funktionen, wie panes

## Technik

Dieser Abschnitt beschreibt konkret die eingesetzten technischen Komponenten sowie deren Integration miteinander. Ziel ist es, nachvollziehbar darzustellen, wie die Trennung zwischen Windsows als Host-/GUI-System und Linux als Arbeitsumgebung praktisch umgesetzt wird.

### Virtualisierung

- VMWare Workstation Pro wird zur Ausführung der Linux Umgebung genutzt
- Die Ubuntu Server VM läuft headless ohne grafische Oberfläche
- Die VM ist dauerhaft und schnell verfügbar

Die Virtualisierung erlaubt eine klare Isolation der Arbeits-/Codingumgebung: Probleme, Fehlkonfigurationen oder Experimente betreffen ausschließlich die Linux-VM und nicht das Windows-Hostsystem.

### (SSH) Zugriff und Authentifizierung

- Authentifizierung ausschließlich über SSH-Key
- Passwort-Login deaktiviert
- Key liegt auf dem Windows Host
- Authentifizierung erfolgt über SSH-Schlüssel
- Agent-Forwarding für reibungsloses Arbeiten
  
Der private SSH-Schlüssel liegt auf dem Windows Host,
der öffentliche Schlüssel ist im `authorized_keys`-File des Linux-Users
hinterlegt.

### Sitzungsmanagement mit tmux

tmux wird auf dem Linux-Server genutzt, um persistente Terminalsitzungen bereitzustellen.

Vorteile:

- SSH-Abbrüche beenden keine laufenden
- Sitzungen können wieder verbunden werden
- Mehrere Shells parallel in einer Session möglich

### Versionsverwaltung mit Git

- Git ist lokal auf der Ubuntu Server VM installiert
- Repositories liegen im Home-Verzeichnis des Linux-Users
- Kommunikation mit GitHub erfolgt über SSH

VS Code greift über Remote-SSH direkt auf die Git-Repositories zu.
Git läuft vollständig auf dem Server, nicht auf dem Windows Host.

### Entwicklungsumgebung

- Entwicklung erfolgt über VS Code auf dem Windows Host
- Verbindung zur Linux-VM über VS Code Remote-SSH
- Dateien werden direkt auf dem Server bearbeitet
- Terminal in VS Code ist die tmux Session des Ubuntu Servers

## Backup & Recovery

Gesichert werden:

- ~/projects
- Relevante Benutzerkonfigurationen
- ~/venv
- Docker-Konfigurationen

### Backup-Skript

~/backup_vm.sh

Eigenschaften:

- Bash-Skript
- Nicht interaktiv
- Absolutpfade (wichtig für systemd)

tar für:
archivierte Snapshots (zeitgestempelt)

### Strategie

- Tar-Archive
- Aufbewahrung: 4 Wochen
- Ziel: Externes Backup Ziel (Hostseitig)

### systemd Service

Datei:
/system/backup-vm.service
type=oneshot
ExecStart=/system/backup_vm.sh
Kein Dauerprozess
sichtbar mit systemctl status

### Systemd Timer

Datei:
/system/backup-vm.timer

Funktion:

- Zeitgesteuerter Start des Services
- Entkoppelt Zeitlogik vom Skript
Aktivierung:

```bash

systemctl daemon-reload
systemctl enable --now backup-vm.timer

```

### Kontrollmechanismen

- systemctl status backup-vm.service
- systemctl list-timers

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

## Lernerfolge

- Saubere & dennoch bequeme Trennung von Host- und Arbeitsumgebung
- Automatisierung mit systemd statt cron
- Schreiben robuster Bash-Skripte (Exit-Codes, Fehlerbehandlung)
- Systemgerechtes Monitoring von Ressourcen
- Gründliche Dokumentation

## Bekannte Probleme & Lösungen

### VS Code Remote-SSH hing bei "Setting up SSH host"

Ursache:

- SSH-Agent auf Manuell gestellt, war bei jedem Start gestoppt
- Verwendung eines shell-skript brechenden Nutzernamen: Beinhaltet ". " (Punkt und Leerzeichen)
- Inkonsistente VS Code Installation

Lösung:

- Neuinstallation von VS Code unter "C:\"
- Erzwungene Verwendung der ssh-config unter "C:\"
- SH-Agent auf automatisch gestellt

### Ständiges Abfragen der SSH Passphrase bei git und VS Code Remote trotz Agent-Forwarding

Ursache:

- Auf der VM und in Github waren ein altes Schlüssel Paar hinterlegt

Lösung:

- Backup der VM-Schlüssel, dann Löschen. Host Schlüssel bei Github eingetragen.
