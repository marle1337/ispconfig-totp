# Changelog

Alle nennenswerten Änderungen.
Das Format folgt [Keep a Changelog](https://keepachangelog.com/de/1.1.0/),
die Versionierung [Semantic Versioning](https://semver.org/lang/de/).

## [0.3.2] — 2026-10-30

### Behoben

- Installer scheiterte, wenn MySQLs root ein Passwort hat (kein Login über
  den Socket). `setup.php` nimmt dann die Zugangsdaten, die ISPConfig selbst
  in `server/lib/mysql_clientdb.conf` hält.

## [0.3.1] — 2026-10-30

### Behoben

- Link im Banner tat nichts: `capp.php` nimmt als Weiterleitung nur
  `seite.php?id=<n>`. Der Link öffnet jetzt das Modul Werkzeuge, dessen
  Startseite die Einstellungen sind.

## [0.3.0] — 2026-10-30

### Neu

- Rotes Banner über jeder Panel-Seite, solange das Konto keinen zweiten
  Faktor hat (weder App noch Code per E-Mail), mit Link zu den Einstellungen.
  Verschwindet, sobald einer eingerichtet ist.
- `api.php?action=status` liefert `has_2fa`.

## [0.2.1] — 2026-10-30

### Behoben

- Einrichtungsfenster flackerte und verlor seinen Inhalt: `dataLogNotification()`
  von ISPConfig überschreibt alle `.modal-body` der Seite alle paar Sekunden.
  Der Fensterinhalt hat jetzt eine eigene Klasse `totpauth-body`.
- Codefelder tragen `no-page-form-change`, damit ISPConfig das Profilformular
  nicht als geändert ansieht.

## [0.2.0] — 2026-10-30

Eigene Fassung (Fork von brightcolor/ispconfig-totp 0.1.0).

### Neu

- Texte dänisch (`dk.lng`, der Sprachcode von ISPConfig für Dänisch).
- `check.sh` für Cron und nach ISPConfig-Updates: meldet fehlende Dateien,
  ein ISPConfig-Update seit der Installation, fehlende Einhakpunkte, einen
  fehlenden oder lesbaren Schlüssel und den erzwungenen Passwortwechsel.
- Der Installer schreibt die ISPConfig-Version in `totpauth/ISPC_VERSION`.

### Geändert

- Neue Sitzungs-ID, sobald der Code stimmt (`session_regenerate_id`).
- `TOTPAUTH_SETUP_CMD` (nur für Tests) wird als root abgelehnt.
- Einhakpunkte in `install/hooks.sh`, von Installer und `check.sh` geteilt.
- Ersatztexte im Skript englisch statt deutsch, Dateiname der
  Wiederherstellungscodes englisch.

## [0.1.0] — 2026-09-21

Erste Fassung.

### Neu

- Anmeldung mit Authenticator-App (TOTP, RFC 6238) nach dem Passwort, als
  Plugin am Anmeldeereignis von ISPConfig, ohne Änderung an Dateien von
  ISPConfig.
- Einrichten im Profil (Werkzeuge → Einstellungen) in einem Fenster: QR-Code,
  Bestätigungscode, acht Wiederherstellungscodes zum Kopieren oder Speichern.
- Deaktivieren mit App- oder Wiederherstellungscode; Admins setzen die App
  eines Kontos unter System → Benutzer zurück.
- Schlüssel verschlüsselt und an das Konto gebunden gespeichert,
  Wiederherstellungscodes als Hash; jeder Code gilt einmal.
- Grenzen: fünf Fehlversuche je Anmeldung, zehn seit der letzten
  erfolgreichen Anmeldung sperren die App.
- Einträge im `auth.log` für Anmeldungen, Fehlversuche, Einrichten und
  Zurücksetzen.
- Texte deutsch und englisch.
- Installer mit Prüfung der Einhakpunkte und des erzwungenen
  Passwortwechsels, Deinstallation mit und ohne Daten, Tests für TOTP-Kern,
  Speicher, Installer und die ganze Anmeldung gegen ein echtes Panel.
