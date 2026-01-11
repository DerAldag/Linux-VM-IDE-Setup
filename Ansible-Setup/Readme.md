# Minimal Ansible Playbook for Developer VM Setup

## Ziel

Dieses Sub-Repository dokumentiert ein *+minimalistisches Ansible-Setup**, um eine Entwicklungs-VM mit Ubuntu Server automatisch vorzubereiten.  

Es demonstriert:

- Automatisierung der Einrichtung
- Wiederholbarkeit und Struktur
- Einrichtung von Basis-Paketen, Monitoring-Skripten und Systemd-Timern

> Hinweis: Dieses Projekt ist derzeit **nur für Versionskontrolle und Dokumentation** gedacht. SSH-Verbindungen und VM-Bereitstellung müssen manuell erfolgen, bevor das Playbook produktiv laufen kann.

## Setup-Hinweise

1. **VM vorbereiten:**  
   Ubuntu Server minimal installieren. User `Watumba` sollte existieren oder wird durch das Playbook angelegt.

2. **SSH-Zugriff:**  
   - Control-Host (z. B. WSL auf Windows) muss SSH-Zugriff auf die VM haben.
   - 
3. **Inventory konfigurieren:**  

[devvm]
dev-vm ansible_host=<VM-IP> ansible_user=Watumba ansible_ssh_private_key_file=~/.ssh/id_ed25519_ansible

[all:vars]
ansible_python_interpreter=/usr/bin/python3


ansible-playbook -i inventory playbooks/setup_devvm.yml

Playbook: siehe playbook.yml





