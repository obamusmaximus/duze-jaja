class_name HudPlacement
extends Resource
## One module in a `HudLayout`: which module scene, which screen section, and its place among the others there.

## The nine sections of the screen, a 3x3 grid. Edge and corner sections hug their edge; the centre floats.
enum Section { TOP_LEFT, TOP, TOP_RIGHT, LEFT, CENTER, RIGHT, BOTTOM_LEFT, BOTTOM, BOTTOM_RIGHT }

## A scene whose root is a `HudModule`.
@export var module: PackedScene
@export var section: Section = Section.BOTTOM
## Lower comes first (left to right in a row, top to bottom in a column).
@export var order: int = 0
## Take the room left over along its edge (the middle of the Generals bar).
@export var expand: bool = false
