# Development Setup - Windows GUI Host / Linux Verwaltung & Code Verarbeitung

## Ziel

Ziel des Setups ist es, eine stabile Linux Arbeitsumgebung für Softwareentwicklung bereitszustellen, während Windwos ausschließlich als GUI-Host verwendet wird.

Dadurch können Coding-Tutorials und Enticklungsworkflows einheitlich in einer LInux-Umbegung durchgeführt werden, ohne die gewohnte Windows-Oberfläche, Shortcuts oder Freizeitnutzung aufzugeben

Aufgaben der Windows Maschine in diesem Setup

- Host-System inkl. Netzwerkzugang
- Bereitstellung der grafischen Oberfläche(VS Code, Terminal)

Aufgaben der Ubuntu Server VM:

- Ausführung und Verwaltung von Code
- Entwicklungswerkzeuge(z. B. Virtuelle Python Umgebung, Docker)
- Abhängigkeiten
- Regelmäßiger backup job über Tar-Skripte

## Architektur

- Windows 10 Host Maschine
- VMWorkstation Pro
- Ubuntu Server (headless, ohne GUI)
- Zugriff nur per SSH (Schlüsselaustausch)
- Robust durch tmux Session
- Entwicklung/Code-Editing über VS Code Remote-SSH

## Motivation & Designentscheidungen


### Warum Ubuntu in einer VM statt Dual Boot
- Kein Neustart nötig,  Ubuntu Server ohne GUI startet sehr schnell
- Interessantere Integrationsmöglichkeiten, wie Anbindung per SSH vom Windwos Host
- Technisch saubere Trennung von Arbeits- und Freizeitumgebung, aber nahtloser Übergang zwischen beidem

### Warum Ubuntu Server
- Minimaler Ressourcenverbrauch für lagfreies Arbeiten
- Größerer Lerneffekt durch verzicht auf GUI, Arbeit am Terminal erzwungen
- Keine GUI Abhängigkeit

### Warum tmux?
- Sitzungen bleiben bei SSH Abbrüchen erhalten
- Bei Bedarf weitere Funktionen, wie panes

## Technik

Dieser Abschnitt beschreibt konkret die eingesetzten technischen Komponenten sowie deren Integration miteinander. Ziel ist es, nachvollziehbar darzustellen, wie die Trennung zwischen Winds als Host-/GUI-System und Linux als Arbeitsumgebung praktisch umgesetzt wird.

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
- ~/.ssh
- ~/venv
- Docker-Konfigurationen

### Backup-Skript
Ort:
/usr/local/bin/backup_vm.sh


Eigenschaften:
- Bash-Skript
- Nicht interaktiv
- Absolutpfade (wichtig für systemd)

tar für:
archivierte Snapshots (zeitgestempelt)

### systemd Service
Datei:
/etc/systemd/system/backup-vm.service
type=oneshot
ExecStart=/usr/local/bin/backup_vm.sh
Kein Dauerprozess
sichtbar mit Systemctl status

### Systemd Timer
Datei:
/etc/systemd/system/backup-vm.timer
Funktion:
- Zeitgesteuerter Start des Services
- Entkoppelt Zeitlogik vom Skript
Aktivierung:
Systemctl Daemon-reload
systemctl enable --now backup-vm.timer

### Kontrollmechanismen
- systemctl status backup-vm.service
- systemctl list-timers

Manuelles Testen:
/usr/local/bin/backup_vm.sh

### Strategie:
- Tar-Archive
- Aufbewahrung: 4 Wochen
- Ziel: Shared Folder auf Host-System

## Bekannte Probleme & Lösungen

### VS Code Remote-SSH hing bei "Setting up SSH host"
Ursache:
- Verwendung eines shell-skript brechenden Nutzernamen: Beinhaltet ". " (Punkt und Leerzeichen)
- Inkonsistente VS Code Installation

Lösung:
- Neuinstallation von VS Code unter "C:\"
- Erzwungene Verwendung der ssh-config unter "C:\"

