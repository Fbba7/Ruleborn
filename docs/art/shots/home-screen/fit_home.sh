#!/usr/bin/env bash
# Home's scripted fit check (lesson M26, P4-S2-home-purse): renders home with
# FIT=1 (client/tests/shots/universe_home.gd) and fails when any shot does not
# print "fit ok".
# - 100%, 125%, 150% and 200% text in English, Brazilian Portuguese and
#   German, each with and without the raid notice (NOTICE=1).
# - 125% in European Portuguese and French, with and without the notice.
# - M26's states at 125% and 200% in English, Brazilian Portuguese and German:
#   every amount at its widest (MOST=1), a new Keeper's empty home (EMPTY=1)
#   and 99 raids not yet seen (RAIDS=99).
# - High contrast (CONTRAST=1) at 100%, 125% and 200%.
# Signed in and signed out draw the same home (docs/art/tracks/home-screen.md,
# "Signed in and signed out"), so each case stands for both.
# Run from the repository's root, after `bash client/build.sh`.
# OUT=<dir> keeps the stills (a temporary folder by default); JOBS=<n> renders
# n shots at once (2 by default).
set -u
godot=${RULEBORN_GODOT:-$HOME/.cache/ruleborn/Godot_v4.7.2-stable_linux.x86_64}
out=${OUT:-$(mktemp -d)}
jobs=${JOBS:-2}
mkdir -p "$out"
[ -x "$godot" ] || bash client/build.sh > /dev/null
"$godot" --headless --path client --import > /dev/null 2>&1 || true
specs=()
for t in 100 125 150 200; do
	for l in en pt_BR de; do specs+=("$t $l" "$t $l NOTICE"); done
done
for l in pt_PT fr; do specs+=("125 $l" "125 $l NOTICE"); done
for t in 125 200; do
	for l in en pt_BR de; do specs+=("$t $l MOST" "$t $l EMPTY" "$t $l RAIDS"); done
done
specs+=("100 en CONTRAST" "125 en CONTRAST" "200 en CONTRAST" "125 de CONTRAST")

# One shot: "<text> <locale> [NOTICE|MOST|EMPTY|RAIDS|CONTRAST]"; prints its
# line, ok or FAIL.
shot() {
	set -- $1
	local env=(FIT=1 TEXT="$1" LOCALE="$2") name="home-$1-$2"
	case "${3:-}" in
		NOTICE) env+=(NOTICE=1) ;;
		MOST) env+=(MOST=1) ;;
		EMPTY) env+=(EMPTY=1) ;;
		RAIDS) env+=(RAIDS=99) ;;
		CONTRAST) env+=(CONTRAST=1) ;;
	esac
	[ -n "${3:-}" ] && name="$name-$3"
	local log
	# As tools/render/shoot.sh renders, with the whole log kept: its last 20
	# lines can leave out the fit lines.
	log=$(env "${env[@]}" SHOT="$out/$name.png" timeout 300 xvfb-run -a -s "-screen 0 1080x2340x24" "$godot" \
		--rendering-driver opengl3 --path client -s res://tests/shots/universe_home.gd 2>&1)
	if grep -qx "fit ok" <<<"$log"; then
		echo "fit_home: $* ok"
	else
		echo "fit_home: $* FAIL"
		grep -E "^fit FAIL|SCRIPT ERROR|Parse Error" <<<"$log" | head -5
	fi
}

# Each shot's lines go to its own file, gathered in order once all are done.
i=0
for spec in "${specs[@]}"; do
	while [ "$(jobs -rp | wc -l)" -ge "$jobs" ]; do wait -n; done
	shot "$spec" > "$out/.fit_home-$i" &
	i=$((i + 1))
done
wait
results=$out/fit_home.txt
for ((j = 0; j < i; j++)); do cat "$out/.fit_home-$j"; rm -f "$out/.fit_home-$j"; done > "$results"
cat "$results"
echo "fit_home: ${#specs[@]} shots, stills in $out"
! grep -q " FAIL$" "$results"
