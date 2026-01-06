# Tut-Tool

Eine Flutter-App, um die Arbeit von Tutoren an der FUB im Institut Ma/Inf zu erleichtern.

## Wie kann ich loslegen?

Du kannst dir entweder das neueste Windows/Linux/Android/iOS-Release aus dem Release-Tab des GitHub-Repos herunterladen. Danach einfach die `Release.zip`-Datei unzippen die App ausführen. 

Sonst kannst du auch sehr einfach [Flutter installieren](https://docs.flutter.dev/get-started/install), dieses Repo klonen und einfach selber bauen. 

> Für Windows-User: Ihr müsst zum Selber-Bauen den channel auf `beta` oder `master` stellen. `stable` hat momentan einen Bug wodurch `TextField`s quasi unbrauchbar werden.  

## Die Grundidee

Das wichtigste Feature ist, dass man Studierende in Gruppen zusammenfügen kann. Das erleichtert jeden weiteren Schritt extrem, da der Unterschied zwischen Realität und digitaler Welt minimiert wird. Die Realität sieht so aus, dass es Zwei- bis Dreiergruppen gibt, in denen eine Person für die ganze Gruppe abgibt. Diese Gruppen sind ab einem bestimmten Zeitpunkt (meistens nach 1-3 Wochen) sehr stabil. Im Whiteboard sieht es jedoch so aus, dass eigentlich jede Person für sich selbst verantwortlich ist und die Erstellung von Gruppen zwar generell möglich, aber bei großen Veranstaltungen nicht umsetzbar ist.

Dadurch, dass das Programm in Kenntniss von den Gruppen ist, können zum Beispiel immer beide Gruppenmitglieder die Kommentare erhalten und nicht nur das Mitglied, das abgegeben hat. 

### Andere coole Features

1. Automatische Gruppenbildung: Die App geht durch die Abgaben und matched die Studenten zusammen, die in einer Abgabe gemeinsam erwähnt werden. 
2. Der Workflow: Man muss sich nicht mehr durch Ordnerstrukturen durchkämpfen, sondern kann sich entspannt durch Gruppen durchklicken, die Abgaben anschauen, kommentieren und bewerten. `Tut-Tool` möchte den Korrekturaufwand auf das Minimum reduzieren, denn das erhöht unsere Leistungsfähigkeit und die Qualität der Korrekturen für die Studis. 
3. File-Utils:
    - Ausführen: Ruft für interpretierte Sprachen eine Interpreter-Instanz auf.
    - Öffnen: Öffnet die Datei in eurem Lieblingprogramm (VSCode).
    - Ordner öffnen: Öffnet die Datei in dem System-File-Explorer (Dateien kopieren, o.ä.).
    - Terminal: Startet das Terminal in dem Dateiordner (CLI-Tools).
    - Automatisches Testen (Coming Soon): Man kann einfache Unit-Tests schreiben und sie dann auf eine Datei anwenden
4. Punktzahl: Wird in die letzte nicht-leere Zeile der Kommentare geschrieben (25/30) und wird dann automatisch bei allen Gruppenteilnehmern eingetragen. Das heißt kein manuelles Eintragen von Punktzahlen in CSV-Dateien mehr 😉.

## Changelog

### Geplant
- Support für mehr Ausführoptionen (Python und vielleicht auch `make` oder Ähnliches für ASM und C)
- "Automatisches" Testen (Details folgen)

### v1.1.0
- Upgrade zu Dart 3
- ZIP-Fehler fix


### v1.0.3
- Vorschau der Grade unter den Kommentaren
- Besseres Auto Feature
- Localization mit Deutsch und Englisch
- Releases für Windows, Linux, Android und iOS

### v1.0.2
- Kommentartemplate für Projekte
- Änderung am bisherigen finished-System. Man schließt eine Gruppe nun mit dem Eintragen des Grades ab und nicht durch das Klicken der grünen Buttons
- Ein sicker Dark Mode
- Context-Menu für File-Utils
- und korrekte File-Utils für Linux und Windows
- Korrektes automatisches Zippen
- Nice Sortierung der Gruppen

Anderes
- Bessere Warnung vor unbenoteten Abgaben
- Bessere Resetfunktion
- Mehr Tooltips
- Besseres I/O mit einigen bug fixes
- Weniger Crashes

### v1.0.1
- Kleiner Bug fix