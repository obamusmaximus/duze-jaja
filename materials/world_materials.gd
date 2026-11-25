class_name WorldMaterials
extends RefCounted
## Visual only: the shared flat materials everything in the world is drawn with (`docs/style_guide.md`, "Prototyping
## rules"). There is one material per palette role (one livery material per team), shared by every model, so a look
## change applies everywhere at once. Imported models are recoloured into the roles by their material names
## (`recolour`). Shading settings come from `WorldLookStats` (`tuning/world_look_default.tres`) and apply live.

enum Role { HULL, HULL_MID, HULL_DARK, TRIM, WARNING, LIVERY, STONE, STONE_DARK, MINERAL, GRASS, LEAF, BARK, SAND, SOIL }

const STATS_PATH: String = "res://tuning/world_look_default.tres"
## Imported material names (Kenney Space Kit) to the role that replaces them. Names not listed keep their own
## material.
const IMPORTED_ROLES: Dictionary = {
	"metal": Role.HULL,
	"_defaultMat": Role.HULL,
	"metalDark": Role.HULL_MID,
	"dark": Role.HULL_DARK,
	"metalRed": Role.LIVERY,
	"rock": Role.STONE,
	"rockTrack": Role.STONE,
	"rockDark": Role.STONE_DARK,
	"crystal": Role.MINERAL,
	"leaves": Role.LEAF,
	"bark": Role.BARK,
}

static var _stats: WorldLookStats
## Role (or LIVERY plus team) key to its lit material.
static var _lit: Dictionary = {}
## Colour to its unshaded mark material.
static var _marks: Dictionary = {}
## Opacity to its round shadow material.
static var _shadows: Dictionary = {}


## The lit material for `role`. `team` picks the livery colour; with no team (-1) livery is a dark hull tone.
static func role(which: Role, team: int = -1) -> StandardMaterial3D:
	var key: Vector2i = Vector2i(which, team if which == Role.LIVERY else -1)
	if not _lit.has(key):
		var material := StandardMaterial3D.new()
		_lit[key] = material
		_shade(material, key)
	return _lit[key]


## A flat unshaded material for marks on the world (base plates, rings, deck lines): hard-edged colour that reads
## the same in any light.
static func mark(color: Color) -> StandardMaterial3D:
	if not _marks.has(color):
		var material := StandardMaterial3D.new()
		material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		material.albedo_color = color
		_marks[color] = material
	return _marks[color]


## A soft round dark patch for a flat quad on the ground (the shadow under a flyer), `opacity` at its middle.
static func blob_shadow(opacity: float) -> StandardMaterial3D:
	if not _shadows.has(opacity):
		var fade := Gradient.new()
		fade.offsets = PackedFloat32Array([0.0, 0.55, 1.0])
		var dark := Color(UiTokens.BLACK, opacity)
		fade.colors = PackedColorArray([dark, dark, Color(UiTokens.BLACK, 0.0)])
		var texture := GradientTexture2D.new()
		texture.gradient = fade
		texture.fill = GradientTexture2D.FILL_RADIAL
		texture.fill_from = Vector2(0.5, 0.5)
		texture.fill_to = Vector2(1.0, 0.5)
		texture.width = 64
		texture.height = 64
		var material := StandardMaterial3D.new()
		material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		material.albedo_texture = texture
		_shadows[opacity] = material
	return _shadows[opacity]


## Replaces the materials of every mesh under `model` whose imported material name has a role (IMPORTED_ROLES).
## `team` colours the livery parts.
static func recolour(model: Node, team: int = -1) -> void:
	var mesh_instance := model as MeshInstance3D
	if mesh_instance != null and mesh_instance.mesh != null:
		for surface: int in mesh_instance.mesh.get_surface_count():
			var imported: Material = mesh_instance.mesh.surface_get_material(surface)
			if imported != null and IMPORTED_ROLES.has(imported.resource_name):
				mesh_instance.set_surface_override_material(surface, role(IMPORTED_ROLES[imported.resource_name], team))
	for child: Node in model.get_children():
		recolour(child, team)


## The palette colour of `which` (`team` for livery), for materials that can't be shared (double-sided cliffs).
static func color_of(which: Role, team: int = -1) -> Color:
	return _color(Vector2i(which, team))


static func _color(key: Vector2i) -> Color:
	match key.x:
		Role.HULL:
			return UiTokens.WORLD_HULL
		Role.HULL_MID:
			return UiTokens.WORLD_HULL_MID
		Role.HULL_DARK:
			return UiTokens.WORLD_HULL_DARK
		Role.TRIM:
			return UiTokens.WORLD_TRIM
		Role.WARNING:
			return UiTokens.ORANGE
		Role.LIVERY:
			# Without a team, or with livery off, the accent parts go neutral: an accent must mean something.
			if key.y < 0 or not _get_stats().team_livery:
				return UiTokens.WORLD_HULL_DARK
			return UiTokens.team_color(key.y)
		Role.STONE:
			return UiTokens.WORLD_STONE
		Role.STONE_DARK:
			return UiTokens.WORLD_STONE_DARK
		Role.GRASS:
			return UiTokens.WORLD_GRASS
		Role.LEAF:
			return UiTokens.WORLD_LEAF
		Role.BARK:
			return UiTokens.WORLD_BARK
		Role.SAND:
			return UiTokens.WORLD_SAND
		Role.SOIL:
			return UiTokens.WORLD_SOIL
		_:
			return UiTokens.WORLD_MINERAL


static func _shade(material: StandardMaterial3D, key: Vector2i) -> void:
	var stats: WorldLookStats = _get_stats()
	material.albedo_color = _color(key)
	material.vertex_color_use_as_albedo = true # Terrain chunks carry baked light in their vertex colours (white elsewhere).
	material.roughness = stats.roughness
	material.metallic = 0.0
	material.metallic_specular = stats.specular


static func _get_stats() -> WorldLookStats:
	if _stats == null:
		_stats = load(STATS_PATH) as WorldLookStats
		_stats.changed.connect(func() -> void: _refresh())
	return _stats


static func _refresh() -> void:
	for key: Vector2i in _lit:
		_shade(_lit[key], key)
