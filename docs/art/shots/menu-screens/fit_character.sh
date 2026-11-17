#!/usr/bin/env bash
# The character screen's scripted fit check (board 5's A, lesson M26): renders
# the screen with FIT=1 and fails when any shot does not find "fit ok".
# - Character 5 (the default) on its Heist tab at 100% text in English,
#   Brazilian Portuguese and German, and in high contrast.
# - At 200% text, in English, Brazilian Portuguese and German, every fixture
#   of ShotData's roster the screen shows: characters 1 to 5 (1 the lowest
#   level, 4 the Mossbear at the highest, 10 of 10, board 5b's K) on each
#   tab (0 Heist, 1 Stats, 2 Compare).
# - Offline (OFFLINE=1, the roster's load failed as "no server is set" fails
#   it): character 5 at 100% in English, and at 200% in Brazilian Portuguese
#   and German, where the notice takes one line (AD-R64).
# The shot writes what it found to the still's .fit.txt (shoot.sh keeps only
# the run's last lines, which Godot's exit report can fill).
# Run from the repository's root, after `bash client/build.sh`.
# OUT=<dir> keeps the stills (a temporary folder by default); JOBS=<n> renders
# n shots at once (2 by default).
set -u
out=${OUT:-$(mktemp -d)}
jobs=${JOBS:-2}
mkdir -p "$out"
specs=("100 en" "100 pt_BR" "100 de" "hc en" "hc pt_BR")
for l in en pt_BR de; do
	for id in 1 2 3 4 5; do
		for tab in 0 1 2; do specs+=("200 $l $id $tab"); done
	done
done
specs+=("100 en 5 0 offline" "200 pt_BR 5 0 offline" "200 de 5 0 offline")

# One shot: "<text|hc> <locale> [id] [tab] [offline]"; prints its line, ok or
# FAIL.
shot() {
	set -- $1
	local env=(FIT=1 LOCALE="$2") name="character-$1-$2"
	if [ "$1" = hc ]; then env+=(HC=1); else env+=(TEXT="$1"); fi
	if [ -n "${3:-}" ]; then env+=(ID="$3"); name="$name-id$3"; fi
	if [ -n "${4:-}" ]; then env+=(TAB="$4"); name="$name-tab$4"; fi
	if [ -n "${5:-}" ]; then env+=(OFFLINE=1); name="$name-offline"; fi
	rm -f "$out/$name.fit.txt"
	local log
	log=$(env "${env[@]}" bash tools/render/shoot.sh client/tests/shots/screen_character.gd "$out/$name.png" 2>&1)
	if grep -qx "fit ok" "$out/$name.fit.txt" 2>/dev/null; then
		echo "fit_character: $* ok"
	else
		echo "fit_character: $* FAIL"
		{ cat "$out/$name.fit.txt" 2>/dev/null; grep -E "SCRIPT ERROR|Parse Error" <<<"$log"; } | head -5
	fi
}

# Each shot's lines go to its own file, gathered in order once all are done.
i=0
for spec in "${specs[@]}"; do
	while [ "$(jobs -rp | wc -l)" -ge "$jobs" ]; do wait -n; done
	shot "$spec" > "$out/.fit_character-$i" &
	i=$((i + 1))
done
wait
results=$out/fit_character.txt
for ((j = 0; j < i; j++)); do cat "$out/.fit_character-$j"; rm -f "$out/.fit_character-$j"; done > "$results"
cat "$results"
echo "fit_character: ${#specs[@]} shots, stills in $out"
! grep -q " FAIL$" "$results"
