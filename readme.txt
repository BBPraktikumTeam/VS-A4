How to start the Programm:

Alle Dateien m�ssen im Verzeichnis "$HOME/workspace/VS-A4" liegen,
da dieser Pfad Hardcoded ist.
Die Datasource muss ebenfalls in diesem Verzeichnis liegen.

Programm auf allen Verf�gbaren Rechnern in der Range 172.16.1.2-18 starten:

- SSH Key hinterlegen f�r den Anmeldevorgang
- das Script start_all.sh �ffnen und die gew�nschte Multicast IP, Port und Team einzutragen
- Script ausf�hren.
- zum Beenden kill_all_pid.sh ausf�hren


Programm auf bestimmten Rechnern starten:
- Das Script start_all.sh editieren um Port, IP, und Team anzupassen
- Script ausf�hren mit: ./start_all.sh <rechner1> <rechner2> ...
- zum Beenden ./kill_all.sh <rechner1> <rechner2> ... ausf�hren


