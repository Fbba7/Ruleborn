class_name CreatureBust
extends RefCounted
## Head-and-shoulders busts of the characters for the heist's crew row and
## its Sage disc (02-heist.png: each face fills its disc), rendered from the
## models in the hero light and cut round, so a caller draws one straight on
## its disc. Each is drawn once, in one offscreen viewport, and kept; the
## texture comes at once and the picture fills in a frame or two later. Two
## are painted instead (PAINTED) and come drawn at once.

## The pixel size busts are drawn at, square.
const SIZE := 192
## The looks a bust takes: its own, a form, or the guard form.
const LOOKS := ["", "hush", "spark", "echo", "guard"]
## The busts painted by hand rather than rendered (board 1's note G): a
## Bramble's furred shell and a Hollow's faceted glass minify into mottle at
## a portrait's size, so their own look is drawn flat, in two or three tones
## of their own colour lit from the upper left as the toon models are. The
## Bramble keeps its snout, arms and belly bands as shapes, with dark eyes
## and nose; the Hollow's glass is a few large facets, light, mid and dark,
## round its white slit eyes and its gem. Each is a picture SIZE across,
## framed as the studio frames a bust: head and shoulders, three-quarter on.
const PAINTED := {
	"quarryback": """<svg xmlns="http://www.w3.org/2000/svg" width="192" height="192" viewBox="0 0 192 192">
		<path d="M86 70 C96 34 150 28 176 66 C194 94 190 150 168 178 L160 192 L96 192 Z" fill="#7B7298"/>
		<path d="M96 52 C116 36 150 34 170 58 C150 50 128 52 112 64 Z" fill="#9C95B8"/>
		<path d="M176 74 C188 104 184 150 164 182 L156 192 L138 192 C160 160 170 120 160 80 Z" fill="#575073"/>
		<g fill="none" stroke="#4A4266" stroke-width="3" stroke-linecap="round">
		<path d="M112 62 C130 54 152 56 168 70"/>
		<path d="M118 84 C138 76 160 80 176 96"/>
		<path d="M120 108 C142 100 164 106 180 122"/>
		<path d="M120 132 C142 126 162 132 176 148"/>
		<path d="M116 156 C136 152 154 158 166 172"/>
		</g>
		<path d="M60 92 C58 74 78 66 96 66 C118 66 132 78 132 98 C140 130 136 170 124 192 L50 192 C42 166 44 120 60 92
		Z" fill="#A08E9E"/>
		<path d="M118 76 C130 84 134 96 132 110 C138 140 134 172 124 192 L110 192 C122 160 124 120 118 76 Z"
		fill="#75647A"/>
		<path d="M62 120 C62 100 74 92 90 92 C106 92 118 102 118 122 C120 150 112 176 100 192 L72 192 C62 172 60 146 62
		120 Z" fill="#C9B7C3"/>
		<g fill="none" stroke="#75647A" stroke-width="3" stroke-linecap="round">
		<path d="M66 116 C80 120 102 120 116 114"/>
		<path d="M63 134 C80 139 104 139 118 132"/>
		<path d="M63 152 C80 157 104 157 117 150"/>
		<path d="M66 170 C80 175 102 175 114 168"/>
		</g>
		<path d="M62 92 C48 98 40 114 38 132 C36 142 40 150 48 150 C56 150 60 142 62 130 C64 116 70 104 74 98 Z"
		fill="#A08E9E"/>
		<path d="M44 108 C38 120 36 136 40 146 C44 150 48 150 50 148 C44 138 44 122 48 110 Z" fill="#75647A"/>
		<path d="M62 92 C48 98 40 114 38 132 C36 142 40 150 48 150 C56 150 60 142 62 130 C64 116 70 104 74 98"
		fill="none" stroke="#43364F" stroke-width="2.5" stroke-linejoin="round"/>
		<g fill="#EEE4D4" stroke="#43364F" stroke-width="1.5" stroke-linejoin="round">
		<path d="M37 144 L30 160 L40 150 Z"/>
		<path d="M44 148 L41 166 L49 151 Z"/>
		<path d="M52 147 L55 164 L57 146 Z"/>
		</g>
		<path d="M114 96 C126 100 132 112 134 128 C136 140 132 150 124 150 C116 150 112 142 110 130 C108 118 108 106 114
		96 Z" fill="#A08E9E"/>
		<path d="M128 104 C134 116 136 132 134 142 C132 148 128 150 124 150 C130 140 130 120 124 104 Z" fill="#75647A"/>
		<path d="M114 96 C126 100 132 112 134 128 C136 140 132 150 124 150 C116 150 112 142 110 130 C108 118 108 106 114
		96 Z" fill="none" stroke="#43364F" stroke-width="2.5" stroke-linejoin="round"/>
		<g fill="#EEE4D4" stroke="#43364F" stroke-width="1.5" stroke-linejoin="round">
		<path d="M113 145 L110 162 L119 149 Z"/>
		<path d="M121 149 L121 167 L127 149 Z"/>
		<path d="M129 147 L135 162 L134 144 Z"/>
		</g>
		<path d="M66 40 C58 26 54 12 58 4 C66 6 74 20 76 36 Z" fill="#8A7A8E"/>
		<path d="M65 34 C60 24 59 14 61 9 C66 12 70 22 71 33 Z" fill="#D9A9B4"/>
		<path d="M98 36 C102 22 108 8 116 4 C120 12 114 28 108 40 Z" fill="#75647A"/>
		<path d="M102 34 C105 24 109 14 114 10 C115 17 111 27 107 35 Z" fill="#D9A9B4"/>
		<path d="M58 54 C58 36 72 28 88 28 C106 28 118 38 118 56 C118 70 108 80 92 82 C74 84 58 72 58 54 Z"
		fill="#A08E9E"/>
		<path d="M110 38 C118 46 120 60 114 70 C108 78 98 82 90 82 C104 74 112 60 110 38 Z" fill="#75647A"/>
		<path d="M62 42 C66 32 76 26 88 26 C100 26 110 32 114 42 C104 36 96 34 88 34 C78 34 70 36 62 42 Z"
		fill="#7B7298"/>
		<path d="M66 40 C74 34 82 33 88 33" fill="none" stroke="#9C95B8" stroke-width="3" stroke-linecap="round"/>
		<path d="M64 46 C72 39 80 38 88 38 C98 38 106 40 112 46" fill="none" stroke="#4A4266" stroke-width="2.5"
		stroke-linecap="round"/>
		<circle cx="80" cy="30" r="7" fill="#C8902A"/>
		<circle cx="80" cy="30" r="5" fill="#F2C24A"/>
		<circle cx="78.5" cy="28.5" r="2.2" fill="#FFF4C8"/>
		<path d="M86 58 C76 53 62 55 48 59 C39 62 32 64 31 68 C31 74 40 77 50 78 C64 79 78 78 88 71 Z" fill="#A08E9E"/>
		<path d="M82 57 C68 56 54 58 42 62 C52 63 66 63 80 62 Z" fill="#C9B7C3"/>
		<path d="M50 78 C64 79 78 78 88 71 C86 78 76 82 62 82 C55 82 50 80 50 78 Z" fill="#75647A"/>
		<ellipse cx="34" cy="67" rx="6" ry="5" fill="#2A2033"/>
		<ellipse cx="32.5" cy="65.5" rx="1.8" ry="1.3" fill="#8C7A8A"/>
		<path d="M62 47 C66 44 72 44 76 47" fill="none" stroke="#43364F" stroke-width="3" stroke-linecap="round"/>
		<path d="M92 46 C97 43 103 43 107 46" fill="none" stroke="#43364F" stroke-width="3" stroke-linecap="round"/>
		<ellipse cx="70" cy="52" rx="4.2" ry="4.6" fill="#1E1626"/>
		<ellipse cx="99" cy="51" rx="4" ry="4.6" fill="#1E1626"/>
		<circle cx="68.6" cy="50.4" r="1.4" fill="#FFFFFF"/>
		<circle cx="97.6" cy="49.4" r="1.4" fill="#FFFFFF"/>
		</svg>""",
	"glassgolem": """<svg xmlns="http://www.w3.org/2000/svg" width="192" height="192" viewBox="0 0 192 192">
		<g transform="translate(0 6)">
		<path d="M40 70 L50 4 L64 58 Z" fill="#B9A8FC"/>
		<path d="M50 4 L64 58 L56 66 Z" fill="#7E63E6"/>
		<path d="M152 70 L142 4 L128 58 Z" fill="#7E63E6"/>
		<path d="M142 4 L128 58 L136 66 Z" fill="#4A30B4"/>
		<path d="M54 60 L138 60 L148 120 L132 192 L60 192 L44 120 Z" fill="#7E63E6"/>
		<path d="M54 60 L96 64 L84 112 L44 120 Z" fill="#AE9AFB"/>
		<path d="M96 64 L138 60 L148 120 L108 112 Z" fill="#7E63E6"/>
		<path d="M84 112 L108 112 L96 124 Z" fill="#AE9AFB"/>
		<path d="M44 120 L84 112 L96 124 L76 192 L60 192 Z" fill="#7E63E6"/>
		<path d="M96 124 L108 112 L148 120 L132 192 L112 192 Z" fill="#4A30B4"/>
		<path d="M76 192 L96 124 L112 192 Z" fill="#6448D2"/>
		<path d="M24 62 L56 52 L76 70 L64 104 L30 108 L16 86 Z" fill="#AE9AFB"/>
		<path d="M16 86 L30 108 L64 104 L56 120 L22 118 Z" fill="#7E63E6"/>
		<path d="M24 62 L56 52 L46 70 Z" fill="#D2C6FF"/>
		<path d="M168 62 L136 52 L116 70 L128 104 L162 108 L176 86 Z" fill="#7E63E6"/>
		<path d="M176 86 L162 108 L128 104 L136 120 L170 118 Z" fill="#4A30B4"/>
		<path d="M168 62 L136 52 L146 70 Z" fill="#AE9AFB"/>
		<path d="M22 118 L56 120 L52 150 L20 150 Z" fill="#7E63E6"/>
		<path d="M22 118 L38 120 L34 150 L20 150 Z" fill="#AE9AFB"/>
		<path d="M170 118 L136 120 L140 150 L172 150 Z" fill="#4A30B4"/>
		<path d="M170 118 L156 120 L158 150 L172 150 Z" fill="#7E63E6"/>
		<path d="M18 150 L54 150 L56 176 L16 176 Z" fill="#8E889C"/>
		<path d="M18 150 L54 150 L54 156 L18 156 Z" fill="#B4AEC0"/>
		<path d="M16 170 L56 170 L56 176 L16 176 Z" fill="#3A3644"/>
		<path d="M138 150 L174 150 L176 176 L136 176 Z" fill="#6E6878"/>
		<path d="M138 150 L174 150 L174 156 L138 156 Z" fill="#8E889C"/>
		<path d="M136 170 L176 170 L176 176 L136 176 Z" fill="#3A3644"/>
		<g transform="translate(96 62) scale(1.2) translate(-96 -62)">
		<path d="M78 24 L86 10 L96 18 L106 10 L114 24 L118 46 L108 60 L84 60 L74 46 Z" fill="#7E63E6"/>
		<path d="M78 24 L86 10 L96 18 L94 32 L74 46 Z" fill="#AE9AFB"/>
		<path d="M96 18 L106 10 L114 24 L118 46 L100 34 Z" fill="#4A30B4"/>
		<path d="M74 46 L94 32 L100 34 L118 46 L108 60 L84 60 Z" fill="#6448D2"/>
		<path d="M78 34 L96 40 L114 34 L114 48 L78 48 Z" fill="#241466"/>
		<path d="M81 39 L93 43 L92 46 L81 44 Z" fill="#FFFFFF"/>
		<path d="M111 39 L99 43 L100 46 L111 44 Z" fill="#FFFFFF"/>
		</g>
		<g transform="translate(0 -10)">
		<path d="M96 80 L111 88.5 L111 105.5 L96 114 L81 105.5 L81 88.5 Z" fill="#2A1870"/>
		<path d="M96 84 L107.5 90.5 L107.5 103.5 L96 110 L84.5 103.5 L84.5 90.5 Z" fill="#FFFFFF"/>
		<path d="M96 90 L102 93.5 L102 100.5 L96 104 L90 100.5 L90 93.5 Z" fill="#7E63E6"/>
		<path d="M96 84 L96 90 M107.5 90.5 L102 93.5 M107.5 103.5 L102 100.5 M96 110 L96 104 M84.5 103.5 L90 100.5 M84.5
		90.5 L90 93.5" stroke="#7E63E6" stroke-width="2"/>
		</g>
		</g>
		</svg>""",
}

static var _cache := {}
## The studio, untyped so the two scripts' statics never load each other.
static var _studio: Node = null


## The bust of `kind` ("glass_golem" or "glassgolem") in `form` ("" its own,
## "hush", "spark", "echo" or "guard"): a round picture, clear outside its
## circle; on a lit disc of `ground` (the role's or school's colour, lighter
## at the middle as 02-heist.png's are) when one is given, else clear behind.
## Blank where nothing can draw (a headless run) or for a kind the export
## lacks.
static func of(kind: String, form := "", ground := Color(0, 0, 0, 0)) -> Texture2D:
	var exported := StageHeroFigure.key(kind).replace("_", "")
	var look := form if form in LOOKS else ""
	var key := "%s/%s/%s" % [exported, look, ground.to_html()]
	if _cache.has(key):
		return _cache[key]
	var texture := ImageTexture.create_from_image(Image.create_empty(SIZE, SIZE, false, Image.FORMAT_RGBA8))
	_cache[key] = texture
	if _can_draw() and look == "" and PAINTED.has(exported):
		texture.set_image(_painted(exported, ground))
	elif _can_draw() and CreatureModel.manifest().has(exported):
		_ensure_studio()
		_studio.call("ask", exported, look, ground, texture)
	return texture


## Whether a bust's picture has been drawn into its texture yet.
static func drawn(texture: Texture2D) -> bool:
	return texture != null and texture.get_image() != null and not texture.get_image().is_invisible()


## Whether every bust asked for has been drawn.
static func settled() -> bool:
	return _studio == null or not is_instance_valid(_studio) or bool(_studio.call("idle"))


## Forgets every bust, as a change of contrast mode needs.
static func clear() -> void:
	_cache.clear()


## A painted bust, cut round as a rendered one is (on its lit disc of
## `ground`, or clear behind); drawn at once, with no studio.
static func _painted(exported: String, ground: Color) -> Image:
	var image := Image.new()
	image.load_svg_from_string(str(PAINTED[exported]), SIZE / 192.0)
	return _studio_script().call("round_cut", image, ground)


static func _can_draw() -> bool:
	return DisplayServer.get_name() != "headless" and Engine.get_main_loop() is SceneTree


static func _ensure_studio() -> void:
	if _studio != null and is_instance_valid(_studio):
		return
	_studio = _studio_script().new()
	(Engine.get_main_loop() as SceneTree).root.add_child.call_deferred(_studio)


static func _studio_script() -> GDScript:
	return load("res://world/creature_bust_studio.gd")
