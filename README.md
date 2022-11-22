# Tut-Tool

Eine Flutter-App, um die Arbeit von Tutoren an der FUB im Institut Ma/Inf zu erleichtern.

## Wie kann ich loslegen?

Du kannst dir entweder das neueste **Windows**-Release aus dem Release-Tab des GitHub-Repos herunterladen. Danach einfach die `Release.zip`-Datei unzippen und dann `app.exe` ausführen. 

Andernfalls kannst du sehr einfach [Flutter installieren](https://docs.flutter.dev/get-started/install), dieses Repo klonen und einfach selber bauen. 

> Für Windows-User: Ihr müsst zum Selber-Bauen den channel auf `beta` oder `master` stellen. `stable` hat momentan einen Bug wodurch `TextField`s quasi unbrauchbar werden.  

## Die Grundidee

Das wichtigste Feature ist, dass man Studierende in Gruppen zusammenfügen kann. Das erleichtert jeden weiteren Schritt extrem, da der Unterschied zwischen Realität und digitaler Welt minimiert wird. Die Realität sieht so aus, dass es Zwei- bis Dreiergruppen gibt, in denen eine Person abgibt für die ganze Gruppe abgibt. Diese Gruppen sind ab einem bestimmten Zeitpunkt (meistens nach 1-3 Wochen) sehr stabil. Im Whiteboard sieht es jedoch so aus, dass eigentlich jede Person für sich selbst verantwortlich ist und die Erstellung von Gruppen zwar generell möglich, aber bei großen Veranstaltungen nicht umsetzbar ist.

Dadurch können zum Beispiel immer beide Gruppenmitglieder die Kommentare erhalten und nicht nur das Mitglied, das abgegeben hat. 

### Andere coole Features

1. Automatische Gruppenbildung: Die App geht durch die Abgaben und matched die Studenten zusammen, die in einer Abgabe gemeinsam erwähnt werden. 
2. Der Workflow: Man muss sich nicht mehr durch Ordnerstrukturen durchkämpfen, sondern kann sich entspannt durch Gruppen durchklicken, die Abgaben anschauen, kommentieren und bewerten. `Tut-Tool` möchte den Korrekturaufwand auf das Minimum reduzieren, denn das erhöht unsere Leistungsfähigkeit und die Qualität der Korrekturen für die Studis. 
3. File-Utils:
    - Ausführen: Ruft für interpretierte Sprachen eine Interpreter-Instanz auf.
    - Öffnen: Öffnet die Datei in eurem Lieblingprogramm (VSCode).
    - Ordner öffnen: Öffnet die Datei in dem System-File-Explorer (Dateien kopieren, o.ä.).
    - CMD starten: Startet die Commandozeile in dem Dateiordner (CLI-Tools).
    - Coming Soon: Automatisches Testen
4. Punktzahl: Wird in die letzte nicht-leere Zeile der Kommentare geschrieben (25/30) und wird dann automatisch bei allen Gruppenteilnehmern eingetragen. Das heißt kein manuelles Eintragen von Punktzahlen in CSV-Dateien mehr 😉.
5. Man kann Gruppenabgaben als erledigt markieren oder als nicht erledigt. Dann geht man wie in einer Prüfung zur nächsten Abgabe (bzw. Aufgabe) und zum Schluss springt man zu der Gruppe zurück, die noch nicht ganz fertig ist.

## Changelog

### v1.0.4 (geplant)
- Localization mit Deutsch und Englisch
- Support für mehr Ausführoptionen (Python und vielleicht auch Make oder Ähnliches für ASM und C)
- "Automatisches" Testen (Details folgen)

### v1.0.3 (geplant)
- Kommentartemplate für Projekte
- Vorschau der Grade unter den Kommentaren
- Änderung am bisherigen finished System. Man schließt eine Gruppe nun mit dem Eintragen des Grades ab und nicht durch das Klicken der grünen Buttons
- File-Utils-Context-Menu
- Besseres Auto Feature
- Bessere Warnung vor unbenoteten Abgaben

Anderes
- Besseres I/O
- Mehr Tooltips
- Bessere Resetfunktion
- Weniger Crashes

### v1.0.2
- Ein sicker Dark Mode
- Korrekte File-Utils für Linux und Windows
- Korrektes automatisches Zippen
- Nice Sortierung der Gruppen

### v1.0.1
- Kleiner Bug fix