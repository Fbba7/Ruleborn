#!/usr/bin/env bash
# The character screen's scripted fit check (board 5's A): renders the screen
# at 100% and 200% text in English, Brazilian Portuguese and German, and in
# high contrast, with FIT=1, and fails when any shot does not print "fit ok".
# Run from the repository's root, after `bash client/build.sh`.
# OUT=<dir> keeps the stills (a temporary folder by default).
set -u
out=${OUT:-$(mktemp -d)}
mkdir -p "$out"
fail=0
for spec in "100 en" "100 pt_BR" "100 de" "200 en" "200 pt_BR" "200 de" "hc en" "hc pt_BR"; do
	set -- $spec
	env=(FIT=1 LOCALE="$2")
	if [ "$1" = hc ]; then env+=(HC=1); else env+=(TEXT="$1"); fi
	log=$(env "${env[@]}" bash tools/render/shoot.sh client/tests/shots/screen_character.gd "$out/character-$1-$2.png" 2>&1)
	if grep -q "^fit ok" <<<"$log"; then
		echo "fit_character: $1 $2 ok"
	else
		echo "fit_character: $1 $2 FAIL"
		grep -E "fit FAIL|ERROR" <<<"$log" | head -5
		fail=1
	fi
done
echo "fit_character: stills in $out"
exit $fail
