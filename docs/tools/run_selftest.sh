#!/bin/zsh
# Runs the village_recruits self test on a throwaway headless Luanti server.
# Usage: tools/run_selftest.sh   (needs the village_recruits symlink in the Luanti mods folder)
set -u
LUANTI=/Applications/luanti.app/Contents/MacOS/luanti
TMP=$(mktemp -d -t village_recruits_selftest)
mkdir -p "$TMP/world"
cat > "$TMP/world/world.mt" <<'WORLD'
enable_damage = true
creative_mode = false
gameid = mineclone2
backend = sqlite3
player_backend = sqlite3
auth_backend = sqlite3
mod_storage_backend = sqlite3
load_mod_village_recruits = mods/village_recruits
WORLD
cat > "$TMP/test.conf" <<'CONF'
village_recruits_selftest = true
server_announce = false
CONF
timeout 180 "$LUANTI" --server --world "$TMP/world" --gameid mineclone2 \
	--config "$TMP/test.conf" --port 30099 --logfile "$TMP/server.log" >/dev/null 2>&1
grep -E "village_recruits selftest|ERROR|Bug report" "$TMP/server.log"
grep -q "DONE: .* 0 failed" "$TMP/server.log"
rc=$?
echo "Log: $TMP/server.log"
exit $rc
