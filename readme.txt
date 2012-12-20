How to start the Programm:

Alle Dateien müssen im Verzeichnis "$HOME/workspace/VS-A4" liegen,
da dieser Pfad Hardcoded ist.
Die Datasource muss ebenfalls in diesem Verzeichnis liegen.

Programm auf allen Verfügbaren Rechnern in der Range 172.16.1.2-18 starten:

- SSH Key hinterlegen für den Anmeldevorgang
- das Script start_all.sh öffnen und die gewünschte Multicast IP, Port und Team einzutragen
- Script ausführen.
- zum Beenden kill_all_pid.sh ausführen


Programm auf bestimmten Rechnern starten:
- Das Script start_all.sh editieren um Port, IP, und Team anzupassen
- Script ausführen mit: ./start_all.sh <rechner1> <rechner2> ...
- zum Beenden ./kill_all.sh <rechner1> <rechner2> ... ausführen


