# Village Recruits – Dorfrekruten (village_recruits)

Eine Mod für **Luanti** mit dem Spiel **VoxeLibre**: Heuere Dorfbewohner mit
Smaragden als Rekruten an. Sie folgen dir, halten eine Stellung, kämpfen gegen
Monster und lassen sich mit Rüstung, Waffe, Schild, Totem und Essen ausrüsten.

**🇬🇧 [English version below](#english)**

Getestet mit **Luanti 5.17.0** und **VoxeLibre 0.92.3**.

---

## Installation

Die Mod muss als Ordner **`village_recruits`** in den `mods`-Ordner von Luanti.

**Am einfachsten:** In Luanti im Hauptmenü *Inhalte → Online-Inhalte
durchsuchen*, nach „Village Recruits“ suchen und installieren (sobald die Mod
auf ContentDB veröffentlicht ist). Dann weiter mit Schritt 4.

**Von Hand:**

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

3. **Ordner hineinkopieren und umbenennen.** Der Ordner heißt nach dem
   Entpacken z. B. `village_recruits-main`. Er muss genau **`village_recruits`**
   heißen, und `mod.conf` muss direkt darin liegen:
   ```
   mods/
     village_recruits/
       init.lua
       mod.conf
       ...
   ```
   Mit Git geht es in einem Schritt (im `mods`-Ordner ausführen):
   ```bash
   git clone https://github.com/trnq1ll0/village_recruits.git village_recruits
   ```
4. **Mod in der Welt aktivieren.** Im Hauptmenü eine VoxeLibre-Welt auswählen,
   auf *Mods auswählen* klicken, **village_recruits** anhaken und
   speichern.

### Mehrspieler im LAN
Die Mod muss **nur auf dem Rechner installiert sein, der den Server startet**
(„Server hosten“). Mitspieler brauchen nichts zu installieren: Luanti lädt
Texturen und Übersetzungen beim Verbinden automatisch herunter.

### Aktualisieren
Den alten Ordner `village_recruits` durch den neuen ersetzen (oder `git pull`)
und die Welt neu starten. Vorhandene Rekruten und ihre Ausrüstung bleiben
erhalten.

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
Sie wirken auf deine eigenen Rekruten im Umkreis von 32 Blöcken. Jeden Befehl
gibt es auf Englisch (`/recruits …`) und auf Deutsch (`/rekruten …`).

| Befehl | Deutsch | Wirkung |
|---|---|---|
| `/recruits follow` | `/rekruten folgen` | Alle Rekruten in der Nähe folgen dir. |
| `/recruits stay` | `/rekruten bleiben` | Alle Rekruten in der Nähe halten ihre Stellung. |
| `/recruits list` | `/rekruten liste` | Zeigt, wie viele Rekruten du hast (gesamt, geladen, in der Nähe). |
| `/recruits dismiss` | `/rekruten entlassen` | Den Rekruten, den du anschaust, wieder zum Dorfbewohner machen. |

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

Im Hauptmenü unter *Einstellungen → Alle Einstellungen → Mods → village_recruits*,
oder direkt in `minetest.conf`:

| Einstellung | Standard | Bedeutung |
|---|---|---|
| `village_recruits_cost` | 3 | Smaragde pro Rekrut |
| `village_recruits_max_per_player` | 10 | Höchstzahl Rekruten pro Spieler |
| `village_recruits_teleport_distance` | 16 | Ab dieser Entfernung wird ein folgender Rekrut teleportiert |
| `village_recruits_selftest` | false | Selbsttest beim Serverstart, nur für die Entwicklung |
| `village_recruits_convert_vl_recruits` | false | Übernimmt Rekruten aus der Entwicklungsversion `vl_recruits` (nur für solche alten Welten) |

---

## Bekannte Einschränkungen

- **Entladene Gebiete:** Teleportierst du dich weit weg oder gehst durch ein
  Portal, bleiben folgende Rekruten zurück. Sie sind dann entladen und können
  dir nicht folgen. Geh zurück und hol sie ab.
- Rüstung und Waffen nutzen sich beim Rekruten (noch) nicht ab, nur der Schild.
- Fernkampf (Bogen, Armbrust) gibt es noch nicht.

---

## Entwicklung

- Einstieg ist `init.lua`, der Rekrut steht in `recruit.lua`, die Ausrüstung
  in `equipment.lua`, das Anheuern in `hire.lua`.
- Selbsttest auf einem Wegwerf-Server ohne Fenster (macOS):
  ```bash
  docs/tools/run_selftest.sh
  ```
  Exit-Code 0 bedeutet, dass alle Prüfungen bestanden sind.
- Plan und Notizen: `docs/Aufgabe.md` (Deutsch), `docs/PLAN.md` (Englisch)
- Vor der ersten Veröffentlichung hieß die Mod `vl_recruits`. Rekruten aus
  solchen Welten werden übernommen, wenn `village_recruits_convert_vl_recruits`
  eingeschaltet ist. Dafür in der Welt `village_recruits` statt `vl_recruits`
  aktivieren.

## Lizenz

Code: MIT, Textur: CC0, siehe [`LICENSE`](LICENSE). Dort stehen auch die
Hinweise zu KI-Unterstützung und zu den genutzten VoxeLibre-Inhalten.

Das Verhalten ist an die Minecraft-Mod „Villager Recruits“ angelehnt. Code
oder Grafiken von dort sind nicht enthalten. Zur Laufzeit nutzt die Mod Modelle
und Texturen von VoxeLibre. Sie sind nicht in diesem Repository enthalten und
stehen unter den Lizenzen von VoxeLibre.

---
---

<a id="english"></a>

# English

# Village Recruits (village_recruits)

A mod for **Luanti** with the game **VoxeLibre**: hire villagers as recruits
with emeralds. They follow you, guard a position, fight hostile mobs and can be
equipped with armor, a weapon, a shield, a totem and food.

The in-game texts are available in English and German.

Tested with **Luanti 5.17.0** and **VoxeLibre 0.92.3**.

---

## Installation

The mod goes into Luanti's `mods` folder as a folder named
**`village_recruits`**.

**Easiest:** In the Luanti main menu, open *Content → Browse online content*,
search for "Village Recruits" and install it (once the mod is published on
ContentDB). Then continue with step 4.

**Manually:**

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

3. **Copy the folder into it and rename it.** After unpacking, the folder is
   called e.g. `village_recruits-main`. It must be named exactly
   **`village_recruits`**, with `mod.conf` directly inside:
   ```
   mods/
     village_recruits/
       init.lua
       mod.conf
       ...
   ```
   With Git it's one step (run inside the `mods` folder):
   ```bash
   git clone https://github.com/trnq1ll0/village_recruits.git village_recruits
   ```
4. **Enable the mod in your world.** In the main menu, select a VoxeLibre
   world, click *Select Mods*, tick **village_recruits** and save.

### Multiplayer on a LAN
The mod only has to be **installed on the computer that hosts the server**
("Host Server"). Other players don't need to install anything: Luanti
downloads textures and translations automatically when they connect.

### Updating
Replace the old `village_recruits` folder with the new one (or `git pull`) and
restart the world. Existing recruits and their equipment are kept.

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
They affect your own recruits within 32 blocks. `/rekruten` is a German alias
(`folgen`, `bleiben`, `liste`, `entlassen`).

| Command | Effect |
|---|---|
| `/recruits follow` | All recruits nearby follow you. |
| `/recruits stay` | All recruits nearby hold their position. |
| `/recruits list` | Shows how many recruits you have (total, loaded, nearby). |
| `/recruits dismiss` | Turns the recruit you are looking at back into a villager. |

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

In the main menu under *Settings → All Settings → Mods → village_recruits*, or
directly in `minetest.conf`:

| Setting | Default | Meaning |
|---|---|---|
| `village_recruits_cost` | 3 | Emeralds per recruit |
| `village_recruits_max_per_player` | 10 | Maximum number of recruits per player |
| `village_recruits_teleport_distance` | 16 | A following recruit further away than this is teleported |
| `village_recruits_selftest` | false | Self test on server start, for development only |
| `village_recruits_convert_vl_recruits` | false | Converts recruits from the development version `vl_recruits` (only for such old worlds) |

---

## Known limitations

- **Unloaded areas:** If you teleport far away or go through a portal,
  following recruits stay behind. They are unloaded then and cannot follow
  you. Go back and pick them up.
- Armor and weapons don't wear down on recruits (yet), only the shield does.
- There is no ranged combat (bow, crossbow) yet.

---

## Development

- The entry point is `init.lua`, the recruit is in `recruit.lua`, the
  equipment in `equipment.lua`, hiring in `hire.lua`.
- Self test on a throwaway headless server (macOS):
  ```bash
  docs/tools/run_selftest.sh
  ```
  Exit code 0 means all checks passed.
- Plan and notes: `docs/PLAN.md` (English), `docs/Aufgabe.md` (German)
- Before its first release the mod was called `vl_recruits`. Recruits from such
  worlds are converted when `village_recruits_convert_vl_recruits` is enabled.
  Enable `village_recruits` in the world instead of `vl_recruits`.

## License

Code: MIT, texture: CC0, see [`LICENSE`](LICENSE), which also contains the
notes on AI assistance and on the VoxeLibre assets used.

The behaviour is inspired by the Minecraft mod "Villager Recruits". No code or
graphics from it are included. At runtime the mod uses models and textures from
VoxeLibre. They are not part of this repository and are under VoxeLibre's
licenses.
