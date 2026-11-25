class_name OrderStats
extends Resource
## Tunable numbers for how orders are carried out (orders/), held by the CommandIssuer
## (tuning/order_default.tres).

@export_group("Group move")
## Gap between the destinations of a group move, as a multiple of the largest unit's diameter in the group.
@export_range(1.0, 5.0, 0.05) var formation_spacing: float = 1.5

@export_group("Markers")
## Map markers a team may have at once; a new one beyond this takes the oldest away.
@export_range(1, 40, 1) var max_markers: int = 12
