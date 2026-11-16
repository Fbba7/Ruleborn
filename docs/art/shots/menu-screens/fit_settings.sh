#!/usr/bin/env bash
# The settings screen's scripted fit check (board 5's E): renders the access
# tab at 100% and 200% text in English, Brazilian Portuguese and German, and
# in high contrast, the account tab at 100% in English and German (board 5's
# I), and the game and account tabs at 200% in German, with
# FIT=1, and fails when any shot does not print "fit ok" (a word broken in
# two fails it too).
# Run from the repository's root, after `bash client/build.sh`.
# OUT=<dir> keeps the stills (a temporary folder by default).
set -u
out=${OUT:-$(mktemp -d)}
mkdir -p "$out"
fail=0
for spec in "100 en access" "100 pt_BR access" "100 de access" "200 en access" "200 pt_BR access" \
		"200 de access" "hc en access" "hc pt_BR access" "100 en account" "100 de account" "200 de game" "200 de account"; do
	set -- $spec
	env=(FIT=1 LOCALE="$2" TAB="$3")
	if [ "$1" = hc ]; then env+=(HC=1); else env+=(TEXT="$1"); fi
	log=$(env "${env[@]}" bash tools/render/shoot.sh client/tests/shots/screen_settings.gd "$out/settings-$1-$2-$3.png" 2>&1)
	if grep -q "^fit ok" <<<"$log"; then
		echo "fit_settings: $1 $2 $3 ok"
	else
		echo "fit_settings: $1 $2 $3 FAIL"
		grep -E "fit FAIL|ERROR" <<<"$log" | head -5
		fail=1
	fi
done
echo "fit_settings: stills in $out"
exit $fail
