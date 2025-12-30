# Konzept und Use-Case Überlegungen

Skript/Service für Automatisches Monitoring von Diskspace und Durchschnittslast, Warnung bei Überschreitungen, einfache logs

Für Diskspace mountlogik verwenden. Damit ließe sich das Skript theoretisch auch auf einer neuen Maschine einfach einbauen.
/ = Für die Überwachung relevantes Wurzelverzeichnis
Unter 80 % = OK, über 80 = Warnung, über 90% = Kritisch -Disk läuft meist monoton, daher keiner wiederholten Warnungen, Zustandswechsel sind Aussagekräftig
Derzeit 2 cores: 2x1 = 2 kritisch 2x0,7 = 1,4 Warnung
Lastdurchschnitt der 15 minuten, das skript soll nicht bei jeder Kleinigkeit, die man nichtmal spürt, auslösen, sondern bei lanfristiger Überbeanspruchung
Detaillierte logs sind für dieses System und Use Case nicht notwendig, da die Lösung bei Überlast klar ist: Mehr Kerne zuweisen oder mit Verzögerungen leben.
Zustandsspeicherung ist ebenfalls nicht notwendig, sofern Warnungen korrekt ausgelöst werden, da das Problem bis zum nächsten Start gelöst wird.

## Erarbeitungd er Rohdaten

### Last

Beobachtung unter Last mit Strss-NG --cpu 2 -timeout 120
1 min. avg zwischen 2,4 und 2,99

loadavg letzte 15 min. auslesen
aus ~/proc/loadavg
awk '{print $3}' /proc/loadavg	-Ausgabe(print) an Positionsargument 3
Terminal = 0.49

### Kernzanzahl

Versucht mit lscpu | grep "CPU(s)" nur die nötige Zeile zu bekommen, schlechte Idee  
lscpu | awk 'NR==5 {print $5}' liefert gewünschte Zahl, aber fragil, da es von einem UI Element abliest.  

Folgende Lösung ist stabil, sprachunabhängig und robust über Distros  
Core_ID sind in ~/sys ... /core_id gespeichert  
Genutzte Funktionen Grep Cut Sort WC Pipe  

grep -h . /sys/devices/system/cpu/cpu*/topology/core_id \ | cut -d: -f2 \ | sort -u \ | wc -l  

Grep -h . /sys/devices/system/cpu/cpu*/topology/core_id 	-liefert Dateiname und Core ID -h flagge inkludiert immer Dateinamen. Für ein robustes Skript, welches auf dieser Annahme basiert, essenziell
| cut -d: -f2 	-trennt am doppelpunkt und gibt das damit eindeuitige feld 2, die core id aus
| sort -u 	-Sortiert die IDs und entfernt duplikate, sodass jede zeile einem Kern zuzuordnen ist
| wc -l 	-wordcount zählt die Zeilen  mit -l

Ergebnis: Anzahl der physischen Kerne als Rohdaten

### Belegung von / als %

df -P / | awk 'NR==2 {print $5}'  

df -P / 			-Zeigt Belegung des Wurzelverzeichnisses ohne Umbrüche
| awk 'NR==2 {print $5}' 	-Ausgabe wird an awk weitergegeben, welches in Zeile 2(NR==2) 5. Feld({print$5} ausgibt, awk braucht einfache Anführungszeichen
