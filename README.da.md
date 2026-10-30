# TOTP til ISPConfig (egen fork)

Login med authenticator-app som anden faktor i ISPConfig 3.3. Forket fra
[brightcolor/ispconfig-totp](https://github.com/brightcolor/ispconfig-totp)
0.1.0 (BSD-2-Clause), gennemgået og tilpasset. Den tyske `README.md` beskriver
funktionen i detaljer; her står det, vi selv skal vide.

## Hvad vi har ændret

- Dansk sprog (`module/totpauth/lib/lang/dk.lng`).
- Nyt session-id, når koden er godkendt.
- Testkrogen `TOTPAUTH_SETUP_CMD` afvises, når installeren kører som root.
- `check.sh`, som opdager, når en ISPConfig-opdatering har fjernet eller
  brudt modulet.

Se `CHANGELOG.md` for detaljer.

## Installation

Kør som root på ISPConfig-serveren, fra et checkout som root ejer:

```bash
sudo ./install.sh
sudo ./check.sh -v
```

Installeren afviser at installere, hvis "Force password change after X
days" står over 0 (System → Interface → Interface Config, fanen Misc).

**Tag `/usr/local/ispconfig/totpauth/secret.key` med i backup.** Uden den
virker ingen af de opsatte apps.

## Efter hver ISPConfig-opdatering

1. `sudo ./check.sh` – fortæller, hvis noget mangler, eller ISPConfig er
   opdateret siden installationen.
2. Hvis ISPConfigs `interface/web/login/index.php` er ændret, så læs
   ændringerne igennem. Det er den fil, plugin'et afhænger af.
3. `sudo ./install.sh`
4. Test et rigtigt login med en testkonto:
   ```bash
   TOTP_E2E_PASSWORD=... sh tests/e2e.sh https://panel.example.dk totp-test
   ```

## Overvågning med cron

`check.sh` er tavs, når alt er i orden, og skriver kun ved problemer, så
cron sender en mail. Fx i `/etc/cron.d/totpauth`:

```
MAILTO=drift@example.dk
17 6 * * * root /root/ispconfig-totp/check.sh
```

## Opdateringer fra den oprindelige forfatter

Den oprindelige kilde ligger som remote `upstream`. Hent og gennemgå
ændringer, før de merges:

```bash
git fetch upstream
git log -p main..upstream/main
```
