#!/usr/bin/env bash
# The settings screen's scripted fit check (board 5's E and I, lesson M26):
# renders the screen with FIT=1 and fails when any shot does not find
# "fit ok" (a word broken in two fails it too).
# - The access tab at 100% text in English, Brazilian Portuguese and German,
#   and in high contrast; the account tab at 100% in English and German,
#   signed out and, in English, signed in.
# - At 200% text, in English, Brazilian Portuguese and German, every tab
#   (game, access, account) and the account tab signed in (its devices and
#   ways to sign in, SIGNED=1).
# The shot writes what it found to the still's .fit.txt (shoot.sh keeps only
# the run's last lines, which Godot's exit report can fill).
# Run from the repository's root, after `bash client/build.sh`.
# OUT=<dir> keeps the stills (a temporary folder by default); JOBS=<n> renders
# n shots at once (2 by default).
set -u
out=${OUT:-$(mktemp -d)}
jobs=${JOBS:-2}
mkdir -p "$out"
specs=("100 en access" "100 pt_BR access" "100 de access" "hc en access" "hc pt_BR access"
	"100 en account" "100 de account" "100 en account signed")
for l in en pt_BR de; do
	for tab in game access account; do specs+=("200 $l $tab"); done
	specs+=("200 $l account signed")
done

# One shot: "<text|hc> <locale> <tab> [signed]"; prints its line, ok or FAIL.
shot() {
	set -- $1
	local env=(FIT=1 LOCALE="$2" TAB="$3") name="settings-$1-$2-$3"
	if [ "$1" = hc ]; then env+=(HC=1); else env+=(TEXT="$1"); fi
	if [ -n "${4:-}" ]; then env+=(SIGNED=1); name="$name-signed"; fi
	rm -f "$out/$name.fit.txt"
	local log
	log=$(env "${env[@]}" bash tools/render/shoot.sh client/tests/shots/screen_settings.gd "$out/$name.png" 2>&1)
	if grep -qx "fit ok" "$out/$name.fit.txt" 2>/dev/null; then
		echo "fit_settings: $* ok"
	else
		echo "fit_settings: $* FAIL"
		{ cat "$out/$name.fit.txt" 2>/dev/null; grep -E "SCRIPT ERROR|Parse Error" <<<"$log"; } | head -5
	fi
}

# Each shot's lines go to its own file, gathered in order once all are done.
i=0
for spec in "${specs[@]}"; do
	while [ "$(jobs -rp | wc -l)" -ge "$jobs" ]; do wait -n; done
	shot "$spec" > "$out/.fit_settings-$i" &
	i=$((i + 1))
done
wait
results=$out/fit_settings.txt
for ((j = 0; j < i; j++)); do cat "$out/.fit_settings-$j"; rm -f "$out/.fit_settings-$j"; done > "$results"
cat "$results"
echo "fit_settings: ${#specs[@]} shots, stills in $out"
! grep -q " FAIL$" "$results"
