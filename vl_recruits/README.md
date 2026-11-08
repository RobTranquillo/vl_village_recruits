# Dorfrekruten (vl_recruits)

Heuere Dorfbewohner in VoxeLibre als Rekruten an. Sie folgen dir, halten
eine Stellung und kämpfen gegen feindliche Mobs.

Getestet mit **Luanti 5.17.0** und **VoxeLibre 0.92.3**.

## Bedienung
- **Anheuern:** Schleichen + Rechtsklick mit Smaragden auf einen erwachsenen
  Dorfbewohner (Standard: 3 Smaragde, im Kreativmodus gratis).
  Ohne Schleichen öffnet sich wie gewohnt der Handel.
- **Folgen / Bleiben:** Rechtsklick auf den eigenen Rekruten (mit leerer Hand
  oder einem Gegenstand, der keine Ausrüstung ist).
- **Ausrüsten:** Rechtsklick mit Rüstung oder einem Schwert/einer Axt auf den
  eigenen Rekruten legt sie an. Ein vorher getragenes Teil bekommst du zurück.
- **Ausrüstungsmenü:** Schleichen + Rechtsklick auf den eigenen Rekruten zeigt
  Rüstung, Waffe, Leben und Schaden. Dort kannst du Teile herausnehmen.
- Rüstung ist sichtbar und senkt den Schaden um 4 % pro Rüstungspunkt (max. 80 %).
  Die Waffe bestimmt den Angriffsschaden (ohne Waffe: 3).
- Stirbt oder wird ein Rekrut entlassen, fällt seine Ausrüstung zu Boden.
- **Chat:** `/rekruten folgen`, `/rekruten bleiben`, `/rekruten liste`,
  `/rekruten entlassen` (den angeschauten Rekruten wieder zum Dorfbewohner machen).
- Rekruten greifen Monster an und helfen, wenn du einen Mob schlägst.
  Spieler, Dorfbewohner und Tiere lassen sie in Ruhe.

## Einstellungen
Siehe `settingtypes.txt`: Kosten, Maximum pro Spieler, Teleport-Distanz.

## Entwicklung
Selbsttest auf einem Testserver: `vl_recruits_selftest = true` setzen, Ergebnis
steht im Log unter `[vl_recruits selftest]`.

## Lizenz
Code: MIT. Verhalten angelehnt an „Villager Recruits“, ohne dessen Code oder
Texturen. Die Rekruten-Optik nutzt zur Laufzeit Texturen und Modelle von VoxeLibre.
