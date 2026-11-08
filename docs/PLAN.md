# Plan: Rebuilding Villager Recruits for VoxeLibre

*English translation of [`Aufgabe.md`](Aufgabe.md). The German file is the original.*

## What the original can do
Villager Recruits is a very large mod. For this remake, the following core matters:
• Hiring: villagers become soldiers in exchange for emeralds. Dedicated screens are used to lead and manage them (MetaMods).
• Types: basic recruit, shieldman, bowman, horseman.
• Commands: follow, hold position, return to position, wander freely, clear targets, guard, move to the point you look at, arrow volley. On top of that there are groups (mc-mod.net).
• Stances: neutral only attacks hostile mobs. Aggressive also attacks players and other recruits. Raid attacks everything that lives.
• AI: recruits heal themselves with food and potions and block attacks with shields.
• Newer versions: teams, diplomacy, territory claims and sieges (CurseForge).

## Constraints in Luanti and VoxeLibre
Four limitations shape what the remake has to look like:
1. No custom keys: mods can only read the existing controls; Aux1 can be used freely (Luanti docs). Commands therefore go through an item (e.g. a "command staff"), a menu (formspec) and chat commands.
2. Mob API barely documented: according to its own note, the mcl_mobs documentation is completely outdated (api.txt). The source code has to be read. The tameable wolf and the villager are good templates.
3. License: the original is "All Rights Reserved" (Modrinth). Only the behaviour is rebuilt, neither code nor textures.
4. Unloaded chunks: recruits following the player fall far behind and out of the loaded world. Logic that teleports them to the player is needed.

## Implementation phases
We start with a playable MVP and then extend it step by step:
1. Phase 0 – Analysis: go through mcl_mobs, the villager and the wolf in the VoxeLibre version in use.
2. Phase 1 – MVP: hiring with emeralds, follow/stay, melee combat in neutral stance, saving across restarts.
3. Phase 2 – Equipment: inventory per recruit, armor and weapon, healing with food, management menu.
4. Phase 3 – Types: bowman and crossbowman, shieldman (probably simplified as damage reduction).
5. Phase 4 – Commands: target point, guard, stances, groups, arrow volley.
6. Phase 5 – Progression: experience and levels, food supply, configuration.
7. Phase 6 – Optional: horsemen, teams/PvP, territories and sieges. This is a lot of work and left out for now.

---

## Environment (as of 2026-11-07)

### Luanti
- Version **5.17.0**, Apple Silicon (arm64), application: `/Applications/luanti.app`
- User data: `~/Library/Application Support/minetest/`. The folder still has the old name "minetest".
  - `minetest.conf` – client/server settings
  - `games/` – installed games
  - `mods/` – additional mods (this is where our mod goes)
  - `worlds/` – worlds, each with a `world.mt` listing the enabled mods
  - `debug.txt` – log; Lua errors from our mod end up here
- An older installer (5.15.1) is located in `~/Recordings/Software/VSTfx/MacOS/`.

### VoxeLibre
- Version **0.92.3** (release 38585), folder: `~/Library/Application Support/minetest/games/mineclone2` (gameid `mineclone2`, the old name).
- Relevant source code:
  - `mods/ENTITIES/mcl_mobs/` – mob framework (api.lua, combat.lua, movement.lua, breeding.lua, items.lua …)
  - `mods/ENTITIES/mobs_mc/villager.lua` – villager (`mobs_mc:villager`)
  - `mods/ENTITIES/mobs_mc/wolf.lua` – wolf and tamed dog (`mobs_mc:dog`)
  - `mods/ENTITIES/mobs_mc/villager_vindicator.lua` – vindicator (model with weapon and attack animation)
  - `mods/ENTITIES/vl_held_item/` – item entity for held items
- Other games: Mineclonia, Minetest Game, Asuna. The mod only targets VoxeLibre.

### Worlds with VoxeLibre
| World | Damage | Creative | Note |
|---|---|---|---|
| KreativExperimente | off | on | all additional mods enabled |
| Testkupfer | off | off | |
| test | on | on | |

Without damage (`enable_damage = false`) monsters don't attack, and in creative mode they ignore the player. For combat tests we need a separate world **"Rekruten-Test"** in survival mode with damage.

### Additional mods already installed
armor_stand_arms, candles_3d, copper_golem, mcl_bronze_stuff, mcl_copper_stuff, vl_copper_rails_recipes, vl_copper_spear. `copper_golem` is a custom mob without mcl_mobs and serves as an example for mod structure, tests and `mod.conf`.

### How the game is played
- The server runs **only locally** on this MacBook ("Host Server" in the main menu, port 30000) and is only used on the **private LAN**. `server_announce = false`.
- Consequences:
  - The mod runs server-side only. Other players download textures and sounds automatically when connecting.
  - No privilege or anti-cheat system needed. It is enough that only the owner can command their recruits.
  - Still build it multiplayer-ready: recruits always belong to a player name.
  - Performance matters because the MacBook is server and client at the same time. That's why there is a limit of recruits per player.

---

## Results of Phase 0 – Analysis of the mob API (VoxeLibre 0.92.3)

**Registration.** `mcl_mobs.register_mob(name, def)` creates an entity with the class `mcl_mobs.mob_class`. Custom logic is hooked in via `do_custom(self, dtime)`. If that function returns `false`, the default AI is skipped for this tick.

**Order per tick** (`api.lua`, `on_step_work`): despawn check → `check_follow` → `monster_attack` → `npc_attack` → `do_custom` → `do_states` (stand/walk/attack/…).

**Saving.** `get_staticdata` serializes *all* fields of the entity except functions and userdata. Custom fields like `owner`, `order` or `_recruit_*` are therefore kept across restarts automatically. Only `attack`, `following` and `state` are reset. With `can_despawn = false` the recruit never disappears.

**Owner and orders.**
- `self.owner` (player name) and `self.order` control the behaviour. For mobs of type `npc`, `check_follow` follows the owner when `order == "follow"`, even without bait in the hand.
- With `order == "stand"` the mob stays put (`do_states_stand`); `"sit"` works similarly.
- `owner_loyal = true`: if the owner hits a mob, their recruits attack that mob (`combat.lua`, `on_punch`). That gives us "attack what I attack" for free.

**Combat.**
- For mobs of type `npc` with `attacks_monsters = true`, `npc_attack` looks for the nearest visible monster. That is exactly the **neutral stance**.
- `monster_attack` only attacks players if the mob is a monster or `_aggro` is set. The fields `attack_npcs`, `attack_animals` and `specific_attack` control the other targets. The aggressive and raid stances will build on this later.
- `attack_type = "dogfight"` means melee, `"shoot"`/`"dogshoot"` means ranged combat (for phase 3).

**Pitfalls.**
- `mcl_extended_pet_control` is on by default. For mobs with `tamed = true`, the framework calls `toggle_sit` on every right-click by the owner, **before** our code runs. Recruits therefore get `tamed = false` and their own owner logic.
- Right-clicking a villager opens the trading menu, and emeralds are the trading currency. Hiring is therefore done with **sneak + right-click with an emerald**.
- Villagers claim a bed and a job site in the node metadata (`_bed`, `_jobsite`). When converting, we have to release them, otherwise those spots stay blocked (see `on_die` in villager.lua).
- A mob is only active while its map block is loaded. `mobs_mc.make_owner_teleport_function(dist, interval)` (used by the dog) only teleports active mobs and only skips `order == "sit"`. We need our own variant that only teleports on `"follow"`.
- Armor on mobs already exists (`wears_armor`, `armor_list`, `set_armor_texture` in items.lua, used by the zombie). We'll use it in phase 2.

**Model.** The villager model has crossed arms, so no weapon and no attack animation. The vindicator model (`mobs_mc_vindicator.b3d`) has a texture slot for the weapon and a punch animation. Plan: vindicator model with villager skin. Whether the texture layout fits is the first thing we test. Fallback: villager model plus `vl_held_item`.

---

## Implementation plan Phase 1 – MVP

### 1. Project skeleton
- Mod name: **`vl_recruits`** (display name "Dorfrekruten"). The code lives in this folder; a symlink to it goes into `~/Library/Application Support/minetest/mods/` so Luanti loads it directly.
- Files:
  ```
  vl_recruits/
    mod.conf            name, depends = mcl_mobs, mobs_mc, mcl_core, mcl_util
    settingtypes.txt    cost, limit per player, teleport distance
    init.lua            loads the modules
    recruit.lua         mob definition vl_recruits:recruit
    hire.lua            hiring (override of the villager right-click)
    commands.lua        chat commands
    locale/vl_recruits.de.tr
    textures/           own textures (self-made only, none from the original)
  ```
- Create a Git repository in the project folder.
- Create the test world "Rekruten-Test" (VoxeLibre, survival, damage on) and set `load_mod_vl_recruits = true`.

### 2. Recruit mob (`recruit.lua`)
- `type = "npc"`, `passive = false`, `attacks_monsters = true`, `attack_npcs = false`, `attack_animals = false`
- `attack_type = "dogfight"`, `damage` ≈ 4 (as strong as with a wooden sword), `reach = 2`, `hp_max = 20`
- `can_despawn = false`, `owner_loyal = true`, `tamed = false`, `order = "follow"`, `follow_velocity = 3.2`
- Take over model and skin from the villager (see model above); `_recruit_skin` stores the original skin.
- `on_punch` wrapper: hits from the owner and from recruits of the same owner don't trigger a counterattack.
- `do_custom`: own teleport to the owner when `order == "follow"` and distance > 16 (checked every second).
- Name tag above the head: "<owner>'s recruit", or the name from the name tag item.

### 3. Hiring (`hire.lua`)
- Wrap the `on_rightclick` of `core.registered_entities["mobs_mc:villager"]`. If the player is sneaking and holding emeralds, they hire; otherwise the original (trading) runs as usual.
- Conditions: adult, cost paid (default 3 emeralds, free in creative mode), limit per player not reached (default 10).
- Steps: release bed and job site, remember position, rotation, health and skin, remove the villager, create the recruit, set `owner`, play sound and particles, send a chat message.
- Counting per player via `core.get_mod_storage()`. Every recruit gets a UUID (`mcl_util.gen_uuid`) so that deaths and dismissals are counted correctly.

### 4. Commands in the MVP
- The owner's right-click on their own recruit toggles between **follow** and **stay**. A particle icon above the head shows the state, plus a chat message.
- Chat commands (no privileges needed, only affect own recruits within 32 blocks):
  - `/rekruten folgen` | `/rekruten bleiben` | `/rekruten liste`
  - `/rekruten entlassen` (for the recruit you look at; it turns back into a villager)

### 5. Saving and loading
- Mostly automatic via `get_staticdata`. To verify: after a restart, `owner`, `order` and skin are kept and the recruit follows again.
- Mod storage only holds counters and UUIDs, no positions. "Summoning unloaded recruits" is postponed (see risks).

### 6. Test cases (manually in "Rekruten-Test")
1. Right-click a villager without sneaking → trading opens as always.
2. Sneak + right-click with 3 emeralds → recruit appears, 3 emeralds gone, bed and job site free.
3. Recruit follows, stops on right-click and follows again on the next right-click.
4. At night: recruit attacks zombies and skeletons, but no players, villagers or animals.
5. Player hits their recruit → no counterattack.
6. Sprint 50 blocks → recruit teleports after you.
7. Restart the server → recruit is still there, owner and order are correct.
8. Second player on the LAN: cannot command other players' recruits.
9. `debug.txt` has no errors from `vl_recruits`.

### Risks and open points
- **Model and skin:** does the villager skin fit the vindicator model? This is checked first.
- **Unloaded recruits:** whoever teleports, uses a portal or flies very fast leaves recruits behind in the unloaded area. Possible later solution: when a following recruit is unloaded (`get_staticdata` or `on_deactivate`), we store its data in mod storage, remove it and let it reappear at the owner. Duplication must be ruled out (UUID check).
- **Framework updates:** the mcl_mobs API is internal and may change with VoxeLibre updates. So keep all accesses to framework internals in a few places and note the tested version (0.92.3) in the README.

---

## Status Phase 1 (2026-11-07)
- Mod `vl_recruits` written and linked into `~/Library/Application Support/minetest/mods/` via a symlink. The world "Rekruten-Test" is created (survival, damage on, mod enabled).
- Look: vindicator model, body tinted blue, head of the hired villager via a texture mask (`vl_recruits_head_mask.png`), iron sword in the hand.
- Instead of a count per player, mod storage keeps the recruit IDs. When hired, the recruit remembers the villager's complete data. `/rekruten entlassen` restores it with profession and trades.
- Automated self test (headless server): 13/13 passed. It checks registration, hiring, orders, saving across unload/load, not attacking the owner, and dismissal.
- **Open:** the manual test cases 1–9 in the game. In particular: does the skin look good? How does the recruit behave in combat? How does it walk back to its post?

## Status Phase 2, part 1: Equipment (2026-11-07)
- Model change: recruits now use VoxeLibre's player model (`mcl_armor_character.b3d`). The villager's head sits via a mask on an `mcl_skins` body with a blue shirt. Armor is therefore visible like on players. The weapon is an item entity attached to the `Wield_Item` bone.
- Armor via `mcl_armor` (inventory hooks `create_inventory` / `update_armor`): 4 % less damage per armor point, at most 80 %.
- Weapon: sword or axe; the damage comes from the item's tool capabilities.
- Usage: right-click with the piece equips it; sneak + right-click opens the equipment menu. On death or dismissal the equipment drops to the ground.
- Recruits from phase 1 are switched to the new model automatically when loaded.
- Self test: 28/28 passed.
- **Open:** check in the game: look (head on the player model, sword grip), animations, menu. Armor doesn't wear down yet. Food and shield come later.

## Status Phase 2, part 2: Shield, totem, food (2026-11-08)
- New slots in the equipment menu, all in one row: armor (4), weapon, shield, totem, food (3). The menu is 13.4 × 8.6; your inventory is centered below.
- Shield: visible on the left arm. Blocks 50 % of the damage from the front, arrows included. A block of at least 3 damage costs durability (336 blocks; the Unbreaking enchantment counts).
- Totem: a fatal hit leaves the recruit alive with 1 HP, plus Regeneration II for 45 s, particles and sound. The totem is used up.
- Food: every 2 s a hurt recruit takes a bite if the food isn't wasted or it is below 50 % health. It heals as much as the food restores (`eatable`). Poisonous food and food with a container are refused.
- Bug fixed: recruits hopped constantly and therefore didn't follow. Cause: `walk_chance = 0` disables the "block in front of me?" check in `do_jump` in mcl_mobs.
- Self test with `tools/run_selftest.sh`: 49/49 passed.
- **Open:** check the shield position on the arm and the menu in the game. Ranged combat (bow, crossbow, arrows) comes in phase 3.

## Status: Preparing the release (2026-11-08)
- Renamed from `vl_recruits` to **`village_recruits`** ("Village Recruits"), because `vl_` is VoxeLibre's prefix. Old recruits (`vl_recruits:recruit`) are taken over on load via `mcl_mobs.register_conversion`. Missing entries in the recruit registry are added automatically when a recruit activates.
- Repository restructured: the mod now lives in the root folder (`mod.conf` at the top). Plan, notes and test script are in `docs/` and are kept out of the ContentDB package via `.gitattributes`.
- New: `LICENSE` (MIT, with notes on AI assistance and VoxeLibre assets), `.cdb.json`, English metadata in `mod.conf` with `supported_games = mineclone2`.
- German original of this plan: `docs/Aufgabe.md`.
