class_name WorldLookStats
extends Resource
## Tunable settings for how everything in the world is shaded (`WorldMaterials`). The colours themselves are
## palette roles in `UiTokens`, not tunables.

@export_group("Surfaces")
## Roughness of every world material (1 is fully matte).
@export_range(0.0, 1.0, 0.05) var roughness: float = 1.0
## Strength of the specular highlight on world materials (0 is none, flattest).
@export_range(0.0, 1.0, 0.05) var specular: float = 0.2

@export_group("Team colour")
## Paint each unit's livery parts (the imported models' accent parts) in its team colour. Off: livery parts are a
## dark hull tone, and team colour shows only on the base plate.
@export var team_livery: bool = true
