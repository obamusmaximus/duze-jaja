class_name UiTokens
extends RefCounted
## The one home of the style guide's values (`docs/style_guide.md`): palette, spacing unit, border weight and the
## type scale. Everything that draws (theme, HUD, world marks) reads them from here; nothing else holds a hex value.

# Accents (meaning, never decoration).
## Player team, friendly information.
const CYAN: Color = Color("#00D9FF")
## Opposing team.
const VIOLET: Color = Color("#9933FF")
## Warnings, damage, hostile orders, third team.
const ORANGE: Color = Color("#FF7300")
## Selection, confirm, focus, fourth team.
const GREEN: Color = Color("#B8FF00")

# Bases.
## Panel backgrounds, text on light and on accents, the void around the map.
const BLACK: Color = Color("#0D0D10")
## Ground, secondary panels, disabled states.
const CONCRETE: Color = Color("#8A8A86")
## Panel fills in light mode, dividers.
const BONE: Color = Color("#E3DDCB")
## Text on dark, highlights, bright surfaces.
const OFF_WHITE: Color = Color("#F2F0E9")

# Tones stacked between black and concrete (depth comes from tone, not effects).
## Raised dark surface: cards and modules on the black HUD.
const GRAPHITE: Color = Color("#1E1E22")
## Thin rules on dark: borders, dividers, minimap grid, hatching.
const RULE: Color = Color("#45454A")
## Opacity of the HUD's dark panel fills (graphite and black), so the map shows through. Text, borders, header
## strips and buttons stay solid.
const PANEL_ALPHA: float = 0.72

# The world palette: the roles models are coloured in (`WorldMaterials`, style guide "Prototyping rules"). Hull
# tones reuse the bases, so the UI and the world share one set of neutrals; only nature adds its own tones, kept
# desaturated so they never read as an accent.
## Main hull tone: most of every model.
const WORLD_HULL: Color = BONE
## Secondary hull panels.
const WORLD_HULL_MID: Color = CONCRETE
## Dark hull parts: machinery, decks, recesses.
const WORLD_HULL_DARK: Color = RULE
## Darkest trim: vents, openings, edges.
const WORLD_TRIM: Color = GRAPHITE
## Rock and earth.
const WORLD_STONE: Color = Color("#6F6B62")
## Shadowed or darker rock.
const WORLD_STONE_DARK: Color = Color("#4E4B45")
## Crystals and other minerals: pale, never an accent hue.
const WORLD_MINERAL: Color = OFF_WHITE

# Nature: muted and greyed, so team cyan, selection green and warning orange always stand out against it. The sea is
# a dark slate, never cyan; plants are sage and olive, never acid green; soil is a brown, never orange.
## Sea where no light reaches it (facets turned away, shadows).
const WORLD_SEA_DEEP: Color = Color("#1B2A33")
## Sea lifted by the sun.
const WORLD_SEA_SHALLOW: Color = Color("#3A5566")
## Shore foam and wave lines.
const WORLD_FOAM: Color = OFF_WHITE
## Grass and low ground cover.
const WORLD_GRASS: Color = Color("#66705C")
## Leaves and canopies.
const WORLD_LEAF: Color = Color("#4A5644")
## Tree trunks and wood.
const WORLD_BARK: Color = WORLD_STONE_DARK
## Beaches, dunes and pale cliffs.
const WORLD_SAND: Color = Color("#B3A88C")
## Mars and other rust-brown ground.
const WORLD_SOIL: Color = Color("#7D5E4E")

# Light and air (`WorldLight`).
## The sky overhead.
const WORLD_SKY: Color = Color("#8E9EA6")
## The horizon and the haze that distance fades into; also the ambient light.
const WORLD_HAZE: Color = Color("#C9CCC6")
## Sunlight.
const WORLD_SUN: Color = OFF_WHITE
## The void around maps with no sky.
const WORLD_VOID: Color = BLACK

## Team number to colour: the first four accents in the guide's order. Teams past the end wrap around.
const TEAM_COLORS: Array[Color] = [CYAN, VIOLET, ORANGE, GREEN]

## The base spacing unit in pixels at the 1920x1080 base size. Every margin and size is a multiple of it.
const UNIT: int = 8
## The one border weight, in pixels.
const BORDER: int = 2
## The heavier bar on one edge that marks emphasis, in pixels.
const ACCENT_BAR: int = 6

# The type scale (pixels at the base size): a few steps, not free choice.
const TEXT_SMALL: int = 32
const TEXT_BODY: int = 36
const TEXT_HEADING: int = 44
const TEXT_TITLE: int = 64
const TEXT_DISPLAY: int = 88

# The one type family: Anybody (OFL, `assets/fonts/`), a variable font with a width axis (50 tall and narrow to 150
# wide) and a weight axis (100 to 900). Each face is (width, weight).
const FONT_PATH: String = "res://assets/fonts/anybody_variable.ttf"
## Labels and captions: tall, narrow, upper case.
const FACE_CONDENSED: Vector2i = Vector2i(55, 700)
## Running text and readouts.
const FACE_TEXT: Vector2i = Vector2i(80, 500)
## Figures (always tabular).
const FACE_NUMBERS: Vector2i = Vector2i(70, 650)
## Names, headings and titles: wide and heavy.
const FACE_WIDE: Vector2i = Vector2i(150, 850)
## Big figures (the match clock): tall, narrow and heavy.
const FACE_DISPLAY: Vector2i = Vector2i(50, 900)

# The tool scale, for dense dev tools such as the tuning panel (`docs/plans/tuning_panel_redesign.md`). The HUD scale
# above is sized to read in a small play window; tools run at full screen and need many rows. Nothing below 18.
const TEXT_TOOL_SMALL: int = 18
const TEXT_TOOL: int = 20
const TEXT_TOOL_HEADING: int = 24
## Height of one row of a tool list, in base units.
const TOOL_ROW_UNITS: int = 5

# The tool reading face: IBM Plex Sans (OFL, `assets/fonts/`), a variable font with a width axis (85 to 100) and a
# weight axis (100 to 700). Anybody keeps the structure (tabs, titles, headers); Plex carries labels, figures
# and descriptions. Each face is (width, weight).
const TOOL_FONT_PATH: String = "res://assets/fonts/ibm_plex_sans_variable.ttf"
## Row labels, descriptions, figures (tabular).
const FACE_TOOL: Vector2i = Vector2i(100, 400)
## Buttons and emphasis.
const FACE_TOOL_STRONG: Vector2i = Vector2i(100, 600)
## Upper-case structure labels (tabs, group and file headers): a little narrow and heavy.
const FACE_TOOL_CAPS: Vector2i = Vector2i(90, 700)

## Diagonal hatching of empty slots: line spacing and line width in pixels.
const HATCH_SPACING: int = 10
const HATCH_WIDTH: int = 2

## Health below this fraction turns the bar to the warning accent.
const LOW_HEALTH: float = 0.25


## A dark panel fill at `PANEL_ALPHA`.
static func glass(fill: Color) -> Color:
	return Color(fill, PANEL_ALPHA)


static func team_color(team: int) -> Color:
	return TEAM_COLORS[posmod(team, TEAM_COLORS.size())]


## `units` base units in pixels.
static func px(units: int) -> int:
	return units * UNIT
