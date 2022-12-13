import 'dart:io';
import 'package:get/get.dart' as getx;

class Translations extends getx.Translations {
  @override
  Map<String, Map<String, String>> get keys => {
        'en_US': {
          // actions and buttons
          'delete': "Delete",
          'create_project': "Create new project",
          'create': "Create",
          'sort': "Sort",
          'auto': "Auto",
          'reset': "Reset",
          'expand': "Expand",
          'submit': "Submit",
          'apply_template': "Apply",
          'enable_dark_mode': "Enable dark mode",
          'template': "Template",
          // file-utils
          'terminal': "Terminal",
          'open_directory': "Open directory",
          'open_file': "Open file",
          'run_file': "Run file",
          // file-utils warnings
          'not_supported': "Not supported on @system",
          'cant_open_file': "Can't open file",
          'cant_open_dir': "Can't open directory",
          'cant_open_terminal': "Can't open terminal",
          'cant_run_file': "Can't run file",
          'cant_copy_dir': "Can't copy directory",
          // titles
          'home': "Home",
          'menu': "Menu",
          'about': "About",
          'new_project': "New Project",
          'submit_project': "Submit @project",
          'settings': "Settings",
          'comment_template': "Comments Template",
          // text-field decorations
          'comments': "Comments",
          'choose_dir': "Choose directory",
          'name': "Name",
          // warnings/exceptions/instructions
          'loading': "Loading ...",
          // new project form
          'enter_name': "Enter a name",
          'directory_doesnt_exist': "Directory doesn't exist",
          'select_dir': "Select the directory",
          // submission files
          'pdf_warning': "PDF is in the working",
          'cant_extract_pdf': "Couldn't extract text from PDF: @path",
          'unknown_file_format': "Unknown file format",
          // zip
          'zip_failed': "Failed to zip",
          'zip_encoder_failed': "ZipEncoder failed",
          // projects
          'couldnt_load_project': "Couldn't load project @project",
          'couldnt_remove_project': "Couldn't remove project persistently",
          'couldnt_add_project': "Couldn't add project persistently",
        },
        'de_DE': {
          'delete': "Entfernen",
          'create_project': "Neues Projekt erstellen",
          'create': "Erstellen",
          'sort': "Sortieren",
          'auto': "Auto",
          'reset': "Reset",
          'expand': "Aufspalten",
          'submit': "Fertigstellen",
          'apply_template': "Anwenden",
          'enable_dark_mode': "Dark Mode anschalten",
          'template': "Template",
          // file-utils
          'terminal': "Terminal",
          'open_directory': "Ordner öffnen",
          'open_file': "Datei öffnen",
          'run_file': "Datei ausführen",
          // file-utils warnings
          'not_supported': "@system wird nicht unterstützt",
          'cant_open_file': "Datei kann nicht geöffnet werden",
          'cant_open_dir': "Ordner kann nicht geöffnet werden",
          'cant_open_terminal': "Terminal konnte nicht geöffnet werden",
          'cant_run_file': "Datei kann nicht ausgeführt werden",
          'cant_copy_dir': "Ordner kann nicht kopiert werden",
          // titles
          'home': "Projekte",
          'menu': "Menu",
          'about': "About",
          'new_project': "Neues Project",
          'submit_project': "@project fertigstellen",
          'settings': "Einstellungen",
          'comment_template': "Kommentartemplate",
          // text-field decorations
          'comments': "Kommentare",
          'choose_dir': "Ordner auswählen",
          'name': "Name",
          // warnings/exceptions/instructions
          'loading': "Lädt ...",
          // new project form
          'enter_name': "Name fehlt",
          'directory_doesnt_exist': "Ordner existiert nicht",
          'select_dir': "Ordner auswählen", // TODO: mit choose_dir mergen?
          // submission files
          'pdf_warning': "Es wird an einer PDF-Ansicht gearbeitet",
          'cant_extract_pdf': "PDF konnte nicht extrahiert werden: @path",
          'unknown_file_format': "Unbekanntes Dateiformat",
          // zip
          'zip_failed': "Zip ist fehlgeschlagen",
          'zip_encoder_failed': "ZipEncoder ist fehlgeschlagen",
          // projects
          'couldnt_load_project':
              "Projekt @project konnte nicht geladen werden",
          'couldnt_remove_project':
              "Projekt konnte nicht persistent entfernt werden",
          'couldnt_add_project':
              "Projekt konnte nicht persistent gespeichert werden",
        }
      };
}

String notSupportedOnPlatform() =>
    "not_supported".trParams({"system": Platform.operatingSystem});
