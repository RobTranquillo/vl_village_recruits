# Dorfrekruten (vl_recruits)

Eine Mod für **Luanti** mit dem Spiel **VoxeLibre**: Heuere Dorfbewohner mit
Smaragden als Rekruten an. Sie folgen dir, halten eine Stellung, kämpfen gegen
Monster und lassen sich mit Rüstung, Waffe, Schild, Totem und Essen ausrüsten.

**🇬🇧 [English version below](#english)**

Getestet mit **Luanti 5.17.0** und **VoxeLibre 0.92.3**.

---

## Installation

Die Mod besteht nur aus dem Ordner **`vl_recruits`**. Er muss in den
`mods`-Ordner von Luanti.

1. **Mod herunterladen.** Auf GitHub über *Code → Download ZIP* und entpacken,
   oder mit `git clone`.
2. **`mods`-Ordner finden.** Im Luanti-Hauptmenü im Reiter *Über* auf
   *Benutzerdatenverzeichnis öffnen* klicken. Dort liegt der Ordner `mods`.
   Typische Orte:

   | System | Ordner |
   |---|---|
   | macOS | `~/Library/Application Support/minetest/mods` |
   | Windows | `mods` im Luanti-Ordner (z. B. `C:\Luanti\mods`) |
   | Linux | `~/.minetest/mods` bzw. `~/.luanti/mods` |
   | Linux (Flatpak) | `~/.var/app/org.luanti.luanti/.minetest/mods` |

3. **Ordner `vl_recruits` hineinkopieren.** Wichtig: Kopiert wird der
   *Unterordner* `vl_recruits`, nicht der ganze heruntergeladene Ordner. Der
   Ordnername muss genau `vl_recruits` lauten.
   ```
   mods/
     vl_recruits/
       init.lua
       mod.conf
       ...
   ```
4. **Mod in der Welt aktivieren.** Im Hauptmenü eine VoxeLibre-Welt auswählen,
   auf *Mods auswählen* klicken, **vl_recruits** (Dorfrekruten) anhaken und
   speichern.

### Mehrspieler im LAN
Die Mod muss **nur auf dem Rechner installiert sein, der den Server startet**
(„Server hosten“). Mitspieler brauchen nichts zu installieren: Luanti lädt
Texturen und Übersetzungen beim Verbinden automatisch herunter.

### Aktualisieren
Den alten Ordner `vl_recruits` durch den neuen ersetzen und die Welt neu
starten. Vorhandene Rekruten und ihre Ausrüstung bleiben erhalten.

---

## Bedienung

| Was | Wie |
|---|---|
| **Anheuern** | **Schleichen + Rechtsklick** mit Smaragden in der Hand auf einen erwachsenen Dorfbewohner. Kostet 3 Smaragde, im Kreativmodus gratis. |
| **Handeln** wie gewohnt | Rechtsklick *ohne* Schleichen. |
| **Folgen ↔ Stellung halten** | Rechtsklick mit leerer Hand auf den eigenen Rekruten. |
| **Ausrüsten** | Rechtsklick mit dem Gegenstand in der Hand: Rüstung, Schwert/Axt, Schild, Totem oder Essen. Ein vorher getragenes Teil bekommst du zurück. |
| **Ausrüstungsmenü** | **Schleichen + Rechtsklick** auf den eigenen Rekruten. |
| **Benennen** | Rechtsklick mit einem beschrifteten Namensschild. |

Über dem Kopf zeigt kurz ein Symbol den neuen Befehl: **Pfeil nach unten** =
Stellung halten, **Pfeil links-rechts** = Folgen.

### Chatbefehle
Sie wirken auf deine eigenen Rekruten im Umkreis von 32 Blöcken.

| Befehl | Wirkung |
|---|---|
| `/rekruten folgen` | Alle Rekruten in der Nähe folgen dir. |
| `/rekruten bleiben` | Alle Rekruten in der Nähe halten ihre Stellung. |
| `/rekruten liste` | Zeigt, wie viele Rekruten du hast (gesamt, geladen, in der Nähe). |
| `/rekruten entlassen` | Den Rekruten, den du anschaust, wieder zum Dorfbewohner machen. |

---

## Was Rekruten können

### Befehle
- **Folgen:** Ab 3 Blöcken Abstand läuft der Rekrut hinter dir her. Bist du mehr
  als 16 Blöcke entfernt, wird er zu dir teleportiert. Das passiert nicht,
  solange du in einem Boot, einer Lore oder auf einem Reittier sitzt.
- **Stellung halten:** Er bleibt an seinem Platz, kämpft gegen Monster in der
  Nähe und kehrt danach dorthin zurück. Er wird nie teleportiert.

### Kampf
- Greift feindliche Mobs an (Zombies, Skelette, Spinnen …).
- Hilft dir: Schlägst du einen Mob, greifen ihn deine Rekruten ebenfalls an.
- Lässt Spieler, Dorfbewohner und Tiere in Ruhe. Dich und deine anderen
  Rekruten greift er nie an.

### Ausrüstung
| Platz | Wirkung |
|---|---|
| **Rüstung** (Helm, Brustplatte, Hose, Stiefel) | Sichtbar am Rekruten. 4 % weniger Schaden pro Rüstungspunkt, höchstens 80 %. |
| **Waffe** (Schwert oder Axt) | Sichtbar in der Hand. Bestimmt den Angriffsschaden, ohne Waffe 3. |
| **Schild** | Am linken Arm. Blockt die Hälfte des Schadens von vorne, auch bei Pfeilen. Nutzt sich dabei ab. |
| **Totem der Unsterblichkeit** | Rettet ihn einmal vor dem Tod (1 Leben + Regeneration) und wird verbraucht. |
| **Essen** (3 Plätze) | Ist er verletzt, isst er alle 2 Sekunden einen Bissen und heilt so viel, wie das Essen satt macht. Giftiges Essen und Essen mit Schüssel oder Flasche nimmt er nicht. |

Stirbt ein Rekrut oder wird er entlassen, fällt seine Ausrüstung zu Boden.
Ein entlassener Rekrut wird wieder zu dem Dorfbewohner, der er war, mit Beruf
und Handelsangeboten.

---

## Einstellungen

Im Hauptmenü unter *Einstellungen → Alle Einstellungen → Mods → vl_recruits*,
oder direkt in `minetest.conf`:

| Einstellung | Standard | Bedeutung |
|---|---|---|
| `vl_recruits_cost` | 3 | Smaragde pro Rekrut |
| `vl_recruits_max_per_player` | 10 | Höchstzahl Rekruten pro Spieler |
| `vl_recruits_teleport_distance` | 16 | Ab dieser Entfernung wird ein folgender Rekrut teleportiert |
| `vl_recruits_selftest` | false | Selbsttest beim Serverstart, nur für die Entwicklung |

---

## Bekannte Einschränkungen

- **Entladene Gebiete:** Teleportierst du dich weit weg oder gehst durch ein
  Portal, bleiben folgende Rekruten zurück. Sie sind dann entladen und können
  dir nicht folgen. Geh zurück und hol sie ab.
- Rüstung und Waffen nutzen sich beim Rekruten (noch) nicht ab, nur der Schild.
- Fernkampf (Bogen, Armbrust) gibt es noch nicht.

---

## Entwicklung

- Code: `vl_recruits/`. Einstieg ist `init.lua`, der Rekrut steht in
  `recruit.lua`, die Ausrüstung in `equipment.lua`.
- Selbsttest auf einem Wegwerf-Server ohne Fenster (macOS):
  ```bash
  tools/run_selftest.sh
  ```
  Exit-Code 0 bedeutet, dass alle Prüfungen bestanden sind.
- Plan und Notizen: `Aufgabe.md`

## Lizenz

Code: MIT, siehe `LICENSE`. Die Textur `vl_recruits_head_mask.png` ist selbst
erstellt und steht unter derselben Lizenz.

Das Verhalten ist an die Minecraft-Mod „Villager Recruits“ angelehnt. Code
oder Grafiken von dort sind nicht enthalten. Zur Laufzeit nutzt die Mod Modelle
und Texturen von VoxeLibre. Sie sind nicht in diesem Repository enthalten und
stehen unter den Lizenzen von VoxeLibre.

---
---

<a id="english"></a>

# English

# Village Recruits (vl_recruits)

A mod for **Luanti** with the game **VoxeLibre**: hire villagers as recruits
with emeralds. They follow you, guard a position, fight hostile mobs and can be
equipped with armor, a weapon, a shield, a totem and food.

The in-game texts are available in English and German. The chat commands use
German words (see below).

Tested with **Luanti 5.17.0** and **VoxeLibre 0.92.3**.

---

## Installation

The mod consists only of the folder **`vl_recruits`**. It goes into Luanti's
`mods` folder.

1. **Download the mod.** On GitHub via *Code → Download ZIP* and unpack it,
   or with `git clone`.
2. **Find the `mods` folder.** In the Luanti main menu, open the *About* tab
   and click *Open User Data Directory*. The `mods` folder is in there.
   Typical locations:

   | System | Folder |
   |---|---|
   | macOS | `~/Library/Application Support/minetest/mods` |
   | Windows | `mods` in the Luanti folder (e.g. `C:\Luanti\mods`) |
   | Linux | `~/.minetest/mods` or `~/.luanti/mods` |
   | Linux (Flatpak) | `~/.var/app/org.luanti.luanti/.minetest/mods` |

3. **Copy the `vl_recruits` folder into it.** Important: copy the
   *subfolder* `vl_recruits`, not the whole downloaded folder. The folder
   name must be exactly `vl_recruits`.
   ```
   mods/
     vl_recruits/
       init.lua
       mod.conf
       ...
   ```
4. **Enable the mod in your world.** In the main menu, select a VoxeLibre
   world, click *Select Mods*, tick **vl_recruits** and save.

### Multiplayer on a LAN
The mod only has to be **installed on the computer that hosts the server**
("Host Server"). Other players don't need to install anything: Luanti
downloads textures and translations automatically when they connect.

### Updating
Replace the old `vl_recruits` folder with the new one and restart the world.
Existing recruits and their equipment are kept.

---

## How to use

| What | How |
|---|---|
| **Hire** | **Sneak + right-click** an adult villager while holding emeralds. Costs 3 emeralds, free in creative mode. |
| **Trade** as usual | Right-click *without* sneaking. |
| **Follow ↔ hold position** | Right-click your own recruit with an empty hand. |
| **Equip** | Right-click with the item in your hand: armor, sword/axe, shield, totem or food. Anything worn before is given back to you. |
| **Equipment menu** | **Sneak + right-click** your own recruit. |
| **Name** | Right-click with a named name tag. |

A short icon above the recruit's head shows the new order: **arrow pointing
down** = hold position, **left-right arrow** = follow.

### Chat commands
They affect your own recruits within 32 blocks. The commands are German
words: *folgen* = follow, *bleiben* = stay, *liste* = list,
*entlassen* = dismiss.

| Command | Effect |
|---|---|
| `/rekruten folgen` | All recruits nearby follow you. |
| `/rekruten bleiben` | All recruits nearby hold their position. |
| `/rekruten liste` | Shows how many recruits you have (total, loaded, nearby). |
| `/rekruten entlassen` | Turns the recruit you are looking at back into a villager. |

---

## What recruits can do

### Orders
- **Follow:** Once you are more than 3 blocks away, the recruit walks after
  you. If you are more than 16 blocks away, it is teleported to you. This
  does not happen while you sit in a boat, a minecart or on a mount.
- **Hold position:** It stays at its post, fights hostile mobs nearby and
  returns to the post afterwards. It is never teleported.

### Combat
- Attacks hostile mobs (zombies, skeletons, spiders …).
- Helps you: if you hit a mob, your recruits attack it too.
- Leaves players, villagers and animals alone. It never attacks you or your
  other recruits.

### Equipment
| Slot | Effect |
|---|---|
| **Armor** (helmet, chestplate, leggings, boots) | Visible on the recruit. 4 % less damage per armor point, at most 80 %. |
| **Weapon** (sword or axe) | Visible in the hand. Sets the attack damage, 3 without a weapon. |
| **Shield** | On the left arm. Blocks half of the damage from the front, arrows included. Wears down while blocking. |
| **Totem of Undying** | Saves it from death once (1 HP + regeneration) and is used up. |
| **Food** (3 slots) | When hurt, it takes a bite every 2 seconds and heals as much as the food restores. It refuses poisonous food and food that comes in a bowl or bottle. |

When a recruit dies or is dismissed, its equipment drops to the ground.
A dismissed recruit turns back into the villager it was, with its profession
and trades.

---

## Settings

In the main menu under *Settings → All Settings → Mods → vl_recruits*, or
directly in `minetest.conf`:

| Setting | Default | Meaning |
|---|---|---|
| `vl_recruits_cost` | 3 | Emeralds per recruit |
| `vl_recruits_max_per_player` | 10 | Maximum number of recruits per player |
| `vl_recruits_teleport_distance` | 16 | A following recruit further away than this is teleported |
| `vl_recruits_selftest` | false | Self test on server start, for development only |

---

## Known limitations

- **Unloaded areas:** If you teleport far away or go through a portal,
  following recruits stay behind. They are unloaded then and cannot follow
  you. Go back and pick them up.
- Armor and weapons don't wear down on recruits (yet), only the shield does.
- There is no ranged combat (bow, crossbow) yet.

---

## Development

- Code: `vl_recruits/`. The entry point is `init.lua`, the recruit is in
  `recruit.lua`, the equipment in `equipment.lua`.
- Self test on a throwaway headless server (macOS):
  ```bash
  tools/run_selftest.sh
  ```
  Exit code 0 means all checks passed.
- Plan and notes (German): `Aufgabe.md`

## License

Code: MIT, see `LICENSE`. The texture `vl_recruits_head_mask.png` was made for
this mod and is under the same license.

The behaviour is inspired by the Minecraft mod "Villager Recruits". No code or
graphics from it are included. At runtime the mod uses models and textures from
VoxeLibre. They are not part of this repository and are under VoxeLibre's
licenses.
