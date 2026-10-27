class_name UniverseWipe
extends Control
## The cloud wipe between two realms (§21.1's one-second swoop; the design's
## `cloudWipe`): banks of cloud roll in from both sides, close over the jump
## and part again. Each bank is a row of round puffs drawn as the islands are
## lit, violet underneath and cream on top, outlined in ink (§21.3), so it reads
## as the same picture book; a soft night veil dims the world behind it. Under
## reduced motion there is no wipe: the camera cuts (§20.8).

const INK := Color("#1A0C14")
const SHADE := Color("#9C88E0")
const BODY := Color("#EDE6FF")
const LIGHT := Color("#FFFFFF")
const VEIL := Color("#1A1134")
## Rows of cloud down the screen, and puffs in each bank.
const ROWS := 7
const PUFFS := 4

## How far the wipe has closed, 0 (open) to 1 (shut).
var amount := 0.0


func _init() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func set_amount(a: float) -> void:
	amount = clampf(a, 0.0, 1.0)
	queue_redraw()


func _draw() -> void:
	if amount <= 0.01:
		return
	var s := size
	var e := amount * amount * (3.0 - 2.0 * amount)
	draw_rect(Rect2(Vector2.ZERO, s), Color(VEIL, 0.35 * e))
	var ink := maxf(2.0, s.x / 360.0 * 2.0)
	for k: int in ROWS * 2:
		var side := -1.0 if k % 2 == 0 else 1.0
		var row := k / 2
		var y := (row + 0.5) / ROWS * s.y + sin(row * 2.3 + side) * s.y * 0.025
		var r := s.x * (0.17 + 0.04 * fmod(row * 0.618 + side * 0.2, 1.0))
		# Each bank rests just past the middle, so the two overlap when shut.
		var rest := s.x * 0.5 + side * s.x * (0.02 + 0.08 * fmod(row * 0.381, 1.0))
		var gone := s.x * 0.5 + side * (s.x * 0.5 + r * 1.6)
		# Rows roll in one after another, the middle first.
		var lag := absf(row - (ROWS - 1) * 0.5) / ROWS * 0.5
		var f := clampf((e - lag) / (1.0 - lag), 0.0, 1.0) if e < 1.0 else 1.0
		var x := lerpf(gone, rest, sqrt(f))
		_bank(Vector2(x, y), r, side, ink)


## A bank of cloud: puffs in a row, its far end trailing off the screen's
## edge, drawn in three passes so the ink edges only the outside.
func _bank(at: Vector2, r: float, side: float, ink: float) -> void:
	var puffs: Array[Vector3] = []
	for i: int in PUFFS:
		var t := float(i) / (PUFFS - 1)
		var pr := r * (1.0 - 0.18 * absf(t - 0.35))
		var px := at.x + side * r * 1.25 * i
		var py := at.y - r * 0.18 * sin(t * PI * 1.3 + side)
		puffs.append(Vector3(px, py, pr))
	for p: Vector3 in puffs:
		draw_circle(Vector2(p.x, p.y), p.z + ink, INK, true, -1.0, true)
	for p: Vector3 in puffs:
		draw_circle(Vector2(p.x, p.y + p.z * 0.14), p.z, SHADE, true, -1.0, true)
	for p: Vector3 in puffs:
		draw_circle(Vector2(p.x - p.z * 0.06, p.y - p.z * 0.04), p.z * 0.9, BODY, true, -1.0, true)
	for p: Vector3 in puffs:
		draw_circle(Vector2(p.x - p.z * 0.22, p.y - p.z * 0.26), p.z * 0.55, BODY.lerp(LIGHT, 0.5), true, -1.0, true)
