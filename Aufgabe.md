# Plan: Villager Recruits für VoxeLibre nachbauen

## Was das Original kann
Villager Recruits ist sehr umfangreich. Für den Nachbau zählt dieser Kern:
• Anheuern: Dorfbewohner werden gegen Smaragde zu Soldaten. Eigene Bildschirme dienen zum Führen und Verwalten (MetaMods).
• Typen: einfacher Rekrut, Schildträger, Bogenschütze, Reiter.
• Befehle: Folgen, Position halten, zurück zur Position, frei umherlaufen, Ziele löschen, Bewachen, zum angeschauten Punkt laufen, Pfeilhagel. Dazu kommen Gruppen (mc-mod.net).
• Haltungen: Neutral greift nur feindliche Mobs an. Aggressiv greift auch Spieler und andere Rekruten an. Raid greift alles Lebende an.
• KI: Rekruten heilen sich selbst mit Essen und Tränken und blocken Angriffe mit Schilden.
• Neuere Versionen: Teams, Diplomatie, Gebietsansprüche und Belagerungen (CurseForge).

## Rahmenbedingungen in Luanti und VoxeLibre
Vier Einschränkungen bestimmen, wie der Nachbau aussehen muss:
1. Keine eigenen Tasten: Mods können nur die vorhandenen Steuerbefehle abfragen, Aux1 lässt sich frei belegen (Luanti-Doku). Befehle laufen deshalb über ein Item (z. B. einen „Kommandostab“), ein Menü (Formspec) und Chatbefehle.
2. Mob-API kaum dokumentiert: Die Doku von mcl_mobs ist laut eigenem Hinweis völlig veraltet (api.txt). Der Quellcode muss gelesen werden. Als Vorlagen bieten sich der zähmbare Wolf und der Dorfbewohner an.
3. Lizenz: Das Original ist „All Rights Reserved“ (Modrinth). Nachgebaut wird nur das Verhalten, weder Code noch Texturen.
4. Entladene Chunks: Rekruten, die dem Spieler folgen, fallen weit hinter ihm aus der geladenen Welt. Nötig ist eine Logik, die sie zum Spieler teleportiert.

## Umsetzungsphasen
Wir starten mit einem spielbaren MVP und bauen danach Schritt für Schritt aus:
1. Phase 0 – Analyse: mcl_mobs, Dorfbewohner und Wolf in der genutzten VoxeLibre-Version durchgehen.
2. Phase 1 – MVP: Anheuern per Smaragd, Folgen/Bleiben, Nahkampf in neutraler Haltung, Speichern über Neustarts.
3. Phase 2 – Ausrüstung: Inventar pro Rekrut, Rüstung und Waffe, Heilen mit Essen, Verwaltungsmenü.
4. Phase 3 – Typen: Bogen- und Armbrustschütze, Schildträger (vermutlich vereinfacht als Schadensreduktion).
5. Phase 4 – Befehle: Zielpunkt, Bewachen, Haltungen, Gruppen, Pfeilhagel.
6. Phase 5 – Fortschritt: Erfahrung und Level, Versorgung mit Nahrung, Konfiguration.
7. Phase 6 – Optional: Reiter, Teams/PvP, Gebiete und Belagerung. Das ist sehr aufwendig und wird vorerst ausgeklammert.

---

## Umgebung (Stand 07.11.2026)

### Luanti
- Version **5.17.0**, Apple Silicon (arm64), Programm: `/Applications/luanti.app`
- Benutzerdaten: `~/Library/Application Support/minetest/`. Der Ordner trägt noch den alten Namen „minetest“.
  - `minetest.conf` – Client-/Server-Einstellungen
  - `games/` – installierte Spiele
  - `mods/` – zusätzliche Mods (hierhin kommt unsere Mod)
  - `worlds/` – Welten, je Welt eine `world.mt` mit den aktivierten Mods
  - `debug.txt` – Log, hier landen Lua-Fehler unserer Mod
- Ein älterer Installer (5.15.1) liegt unter `~/Recordings/Software/VSTfx/MacOS/`.

### VoxeLibre
- Version **0.92.3** (release 38585), Ordner: `~/Library/Application Support/minetest/games/mineclone2` (gameid `mineclone2`, alter Name).
- Relevanter Quellcode:
  - `mods/ENTITIES/mcl_mobs/` – Mob-Framework (api.lua, combat.lua, movement.lua, breeding.lua, items.lua …)
  - `mods/ENTITIES/mobs_mc/villager.lua` – Dorfbewohner (`mobs_mc:villager`)
  - `mods/ENTITIES/mobs_mc/wolf.lua` – Wolf und gezähmter Hund (`mobs_mc:dog`)
  - `mods/ENTITIES/mobs_mc/villager_vindicator.lua` – Diener (Modell mit Waffe und Schlaganimation)
  - `mods/ENTITIES/vl_held_item/` – Item-Entity für gehaltene Gegenstände
- Weitere Spiele: Mineclonia, Minetest Game, Asuna. Die Mod zielt nur auf VoxeLibre.

### Welten mit VoxeLibre
| Welt | Schaden | Kreativ | Bemerkung |
|---|---|---|---|
| KreativExperimente | aus | an | alle Zusatz-Mods aktiv |
| Testkupfer | aus | aus | |
| test | an | an | |

Ohne Schaden (`enable_damage = false`) greifen Monster nicht an, im Kreativmodus ignorieren sie den Spieler. Für Kampftests brauchen wir eine eigene Welt **„Rekruten-Test“** im Überlebensmodus mit Schaden.

### Bereits installierte Zusatz-Mods
armor_stand_arms, candles_3d, copper_golem, mcl_bronze_stuff, mcl_copper_stuff, vl_copper_rails_recipes, vl_copper_spear. Der `copper_golem` ist ein eigener Mob ohne mcl_mobs und dient als Beispiel für Mod-Aufbau, Tests und `mod.conf`.

### Spielbetrieb
- Der Server läuft **nur lokal** auf diesem MacBook („Server hosten“ im Hauptmenü, Port 30000) und wird nur im **privaten LAN** genutzt. `server_announce = false`.
- Daraus folgt:
  - Die Mod läuft nur serverseitig. Mitspieler laden Texturen und Sounds beim Verbinden automatisch herunter.
  - Kein Rechte- oder Anti-Cheat-System nötig. Es reicht, dass nur der Besitzer seine Rekruten befehligt.
  - Trotzdem mehrspielerfähig bauen: Rekruten gehören immer einem Spielernamen.
  - Leistung zählt, weil der MacBook Server und Client gleichzeitig ist. Darum gibt es ein Limit für Rekruten pro Spieler.

---

## Ergebnisse Phase 0 – Analyse der Mob-API (VoxeLibre 0.92.3)

**Registrierung.** `mcl_mobs.register_mob(name, def)` erzeugt eine Entity mit der Klasse `mcl_mobs.mob_class`. Eigene Logik hängt man über `do_custom(self, dtime)` ein. Gibt die Funktion `false` zurück, wird die Standard-KI für diesen Tick übersprungen.

**Ablauf pro Tick** (`api.lua`, `on_step_work`): Despawn-Prüfung → `check_follow` → `monster_attack` → `npc_attack` → `do_custom` → `do_states` (stand/walk/attack/…).

**Speichern.** `get_staticdata` serialisiert *alle* Felder der Entity, außer Funktionen und Userdata. Eigene Felder wie `owner`, `order` oder `_recruit_*` bleiben damit automatisch über Neustarts erhalten. Zurückgesetzt werden nur `attack`, `following` und `state`. Mit `can_despawn = false` verschwindet der Rekrut nie.

**Besitzer und Befehle.**
- `self.owner` (Spielername) und `self.order` steuern das Verhalten. Für Mobs vom Typ `npc` folgt `check_follow` dem Besitzer, wenn `order == "follow"`, auch ohne Lockfutter in der Hand.
- Bei `order == "stand"` bleibt der Mob stehen (`do_states_stand`), `"sit"` funktioniert ähnlich.
- `owner_loyal = true`: Schlägt der Besitzer einen Mob, greifen dessen Rekruten diesen Mob an (`combat.lua`, `on_punch`). Das ergibt kostenlos „greif an, was ich angreife“.

**Kampf.**
- `npc_attack` sucht für Mobs vom Typ `npc` mit `attacks_monsters = true` das nächste sichtbare Monster. Das entspricht genau der **neutralen Haltung**.
- `monster_attack` greift Spieler nur an, wenn der Mob ein Monster ist oder `_aggro` gesetzt ist. Die Felder `attack_npcs`, `attack_animals` und `specific_attack` steuern die anderen Ziele. Darauf bauen später die Haltungen Aggressiv und Raid auf.
- `attack_type = "dogfight"` steht für Nahkampf, `"shoot"`/`"dogshoot"` für Fernkampf (für Phase 3).

**Fallstricke.**
- `mcl_extended_pet_control` ist standardmäßig an. Bei Mobs mit `tamed = true` ruft das Framework bei jedem Rechtsklick des Besitzers **vor** unserem Code `toggle_sit` auf. Rekruten bekommen deshalb `tamed = false` und eine eigene Besitzerlogik.
- Ein Rechtsklick auf Dorfbewohner öffnet das Handelsmenü, und Smaragde sind die Handelswährung. Angeheuert wird deshalb mit **Schleichen + Rechtsklick mit Smaragd**.
- Dorfbewohner reservieren Bett und Arbeitsplatz in den Node-Metadaten (`_bed`, `_jobsite`). Beim Umwandeln müssen wir das freigeben, sonst bleiben die Plätze blockiert (siehe `on_die` in villager.lua).
- Ein Mob ist nur aktiv, solange sein Mapblock geladen ist. `mobs_mc.make_owner_teleport_function(dist, interval)` (vom Hund genutzt) teleportiert nur aktive Mobs und überspringt nur `order == "sit"`. Wir brauchen eine eigene Variante, die nur bei `"follow"` teleportiert.
- Rüstung an Mobs gibt es schon (`wears_armor`, `armor_list`, `set_armor_texture` in items.lua, genutzt vom Zombie). Das nutzen wir in Phase 2.

**Modell.** Das Dorfbewohner-Modell hat verschränkte Arme, also keine Waffe und keine Schlaganimation. Das Diener-Modell (`mobs_mc_vindicator.b3d`) hat einen Texturplatz für die Waffe und eine Punch-Animation. Plan: Diener-Modell mit Dorfbewohner-Skin. Ob die Texturaufteilung passt, testen wir als Erstes. Ersatzlösung: Dorfbewohner-Modell plus `vl_held_item`.

---

## Umsetzungsplan Phase 1 – MVP

### 1. Projektgerüst
- Mod-Name: **`vl_recruits`** (Anzeigename „Dorfrekruten“). Der Code liegt in diesem Ordner, in `~/Library/Application Support/minetest/mods/` kommt ein Symlink darauf, damit Luanti ihn direkt lädt.
- Dateien:
  ```
  vl_recruits/
    mod.conf            name, depends = mcl_mobs, mobs_mc, mcl_core, mcl_util
    settingtypes.txt    Kosten, Limit pro Spieler, Teleport-Distanz
    init.lua            lädt die Module
    recruit.lua         Mob-Definition vl_recruits:recruit
    hire.lua            Anheuern (Override des Dorfbewohner-Rechtsklicks)
    commands.lua        Chatbefehle
    locale/vl_recruits.de.tr
    textures/           eigene Texturen (nur selbst erstellt, keine aus dem Original)
  ```
- Git-Repository im Projektordner anlegen.
- Testwelt „Rekruten-Test“ (VoxeLibre, Überleben, Schaden an) anlegen und `load_mod_vl_recruits = true` setzen.

### 2. Rekrut-Mob (`recruit.lua`)
- `type = "npc"`, `passive = false`, `attacks_monsters = true`, `attack_npcs = false`, `attack_animals = false`
- `attack_type = "dogfight"`, `damage` ≈ 4 (so stark wie mit Holzschwert), `reach = 2`, `hp_max = 20`
- `can_despawn = false`, `owner_loyal = true`, `tamed = false`, `order = "follow"`, `follow_velocity = 3.2`
- Modell und Skin vom Dorfbewohner übernehmen (siehe Modell oben), `_recruit_skin` speichert den ursprünglichen Skin.
- `on_punch`-Hülle: Schläge vom Besitzer und von Rekruten desselben Besitzers lösen keinen Gegenangriff aus.
- `do_custom`: eigener Teleport zum Besitzer, wenn `order == "follow"` und Abstand > 16 (Prüfung jede Sekunde).
- Namensschild über dem Kopf: „<Besitzer>s Rekrut“, oder der Name vom Namensschild-Item.

### 3. Anheuern (`hire.lua`)
- Den `on_rightclick` von `core.registered_entities["mobs_mc:villager"]` umhüllen. Wenn der Spieler schleicht und Smaragde hält, wird angeheuert, sonst läuft das Original (Handel) normal weiter.
- Bedingungen: erwachsen, Kosten erfüllt (Standard 3 Smaragde, im Kreativmodus gratis), Limit pro Spieler nicht erreicht (Standard 10).
- Ablauf: Bett und Arbeitsplatz freigeben, Position, Drehung, Lebenspunkte und Skin merken, Dorfbewohner entfernen, Rekrut erzeugen, `owner` setzen, Sound und Partikel abspielen, Chatmeldung ausgeben.
- Zählung pro Spieler über `core.get_mod_storage()`. Jeder Rekrut bekommt eine UUID (`mcl_util.gen_uuid`), damit Tod und Entlassung sauber gezählt werden.

### 4. Befehle im MVP
- Rechtsklick des Besitzers auf den eigenen Rekruten wechselt zwischen **Folgen** und **Bleiben**. Ein Partikel-Icon über dem Kopf zeigt den Zustand, dazu gibt es eine Chatmeldung.
- Chatbefehle (ohne Rechte, wirken nur auf eigene Rekruten im Umkreis von 32 Blöcken):
  - `/rekruten folgen` | `/rekruten bleiben` | `/rekruten liste`
  - `/rekruten entlassen` (für den angeschauten Rekruten, wird wieder zum Dorfbewohner)

### 5. Speichern und Laden
- Läuft größtenteils automatisch über `get_staticdata`. Zu prüfen: Nach einem Neustart sind `owner`, `order` und Skin erhalten, der Rekrut folgt wieder.
- In der Mod-Storage stehen nur Zähler und UUIDs, keine Positionen. Das „Herbeirufen entladener Rekruten“ verschieben wir auf später (siehe Risiken).

### 6. Testfälle (manuell in „Rekruten-Test“)
1. Ohne Schleichen auf einen Dorfbewohner rechtsklicken → Handel öffnet sich wie immer.
2. Schleichen + Rechtsklick mit 3 Smaragden → Rekrut erscheint, 3 Smaragde weg, Bett und Arbeitsplatz frei.
3. Rekrut folgt, bleibt bei Rechtsklick stehen und folgt beim nächsten Rechtsklick wieder.
4. Nachts: Rekrut greift Zombies und Skelette an, aber keine Spieler, Dorfbewohner oder Tiere.
5. Spieler schlägt seinen Rekruten → kein Gegenangriff.
6. 50 Blöcke sprinten → Rekrut teleportiert hinterher.
7. Server neu starten → Rekrut ist noch da, Besitzer und Befehl stimmen.
8. Zweiter Spieler im LAN: kann fremde Rekruten nicht befehligen.
9. `debug.txt` ist frei von Fehlern aus `vl_recruits`.

### Risiken und offene Punkte
- **Modell und Skin:** Passt der Dorfbewohner-Skin auf das Diener-Modell? Das wird als Erstes geprüft.
- **Entladene Rekruten:** Wer sich teleportiert, durch ein Portal geht oder sehr schnell fliegt, lässt Rekruten im entladenen Gebiet zurück. Mögliche Lösung für später: Beim Entladen eines folgenden Rekruten (`get_staticdata` bzw. `on_deactivate`) speichern wir seine Daten in der Mod-Storage, entfernen ihn und lassen ihn beim Besitzer neu erscheinen. Dabei muss Duplizierung ausgeschlossen sein (UUID-Prüfung).
- **Framework-Updates:** Die API von mcl_mobs ist intern und kann sich mit VoxeLibre-Updates ändern. Darum alle Zugriffe auf Framework-Interna an wenigen Stellen bündeln und die getestete Version (0.92.3) in der README notieren.

---

## Stand Phase 1 (07.11.2026)
- Mod `vl_recruits` geschrieben, per Symlink in `~/Library/Application Support/minetest/mods/` eingebunden. Die Welt „Rekruten-Test“ ist angelegt (Überleben, Schaden an, Mod aktiv).
- Optik: Diener-Modell, Körper blau eingefärbt, Kopf des angeheuerten Dorfbewohners per Textur-Maske (`vl_recruits_head_mask.png`), Eisenschwert in der Hand.
- Statt einer Zählung pro Spieler speichert die Mod-Storage die Rekruten-IDs. Beim Anheuern merkt sich der Rekrut die kompletten Daten des Dorfbewohners. `/rekruten entlassen` stellt ihn mit Beruf und Handel wieder her.
- Automatischer Selbsttest (Server ohne Fenster): 13/13 bestanden. Geprüft werden Registrierung, Anheuern, Befehle, Speichern über Entladen/Laden, kein Angriff auf den Besitzer und Entlassen.
- **Offen:** Die manuellen Testfälle 1–9 im Spiel. Dazu gehört besonders: Sieht der Skin gut aus? Wie verhält sich der Rekrut im Kampf? Wie läuft er zurück zur Stellung?

## Stand Phase 2, Teil 1: Ausrüstung (07.11.2026)
- Modellwechsel: Rekruten nutzen jetzt das Spieler-Modell von VoxeLibre (`mcl_armor_character.b3d`). Der Kopf des Dorfbewohners sitzt per Maske auf einem `mcl_skins`-Körper mit blauem Hemd. Rüstung ist damit wie beim Spieler sichtbar. Die Waffe hängt als Item-Entity am Knochen `Wield_Item`.
- Rüstung über `mcl_armor` (Inventar-Hooks `create_inventory` / `update_armor`): 4 % weniger Schaden pro Rüstungspunkt, höchstens 80 %.
- Waffe: Schwert oder Axt, der Schaden kommt aus den Werkzeugwerten des Items.
- Bedienung: Rechtsklick mit dem Teil legt es an, Schleichen + Rechtsklick öffnet das Ausrüstungsmenü. Bei Tod oder Entlassung fällt die Ausrüstung zu Boden.
- Rekruten aus Phase 1 werden beim Laden automatisch auf das neue Modell umgestellt.
- Selbsttest: 28/28 bestanden.
- **Offen:** Im Spiel prüfen: Optik (Kopf auf dem Spieler-Modell, Haltung des Schwerts), Animationen, Menü. Rüstung nutzt sich noch nicht ab. Essen und Schild kommen später.

## Stand Phase 2, Teil 2: Schild, Totem, Essen (08.11.2026)
- Neue Slots im Ausrüstungsmenü, alle in einer Reihe: Rüstung (4), Waffe, Schild, Totem, Essen (3). Das Menü ist 13,4 × 8,6 groß, dein Inventar steht zentriert darunter.
- Schild: Am linken Arm sichtbar. Blockt 50 % des Schadens von vorne, auch bei Pfeilen. Ein Block mit mindestens 3 Schaden kostet Haltbarkeit (336 Blocks, Haltbarkeit-Verzauberung zählt mit).
- Totem: Ein tödlicher Treffer lässt den Rekruten mit 1 Leben überleben. Dazu gibt es Regeneration II für 45 s, Partikel und Sound. Das Totem wird verbraucht.
- Essen: Alle 2 s isst ein verletzter Rekrut einen Bissen, wenn das Essen nicht verschwendet wird oder er unter 50 % Leben hat. Geheilt wird so viel, wie das Essen satt macht (`eatable`). Giftiges Essen und Essen mit Behälter wird abgelehnt.
- Fehler behoben: Rekruten sind dauernd gehüpft und deshalb nicht gefolgt. Ursache: `walk_chance = 0` schaltet in mcl_mobs die Prüfung „Block vor mir?“ in `do_jump` ab.
- Selbsttest mit `tools/run_selftest.sh`: 49/49 bestanden.
- **Offen:** Schild-Position am Arm und das Menü im Spiel prüfen. Fernkampf (Bogen, Armbrust, Pfeile) kommt in Phase 3.
