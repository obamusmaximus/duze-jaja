class_name FadeMaterials
extends RefCounted
## Visual only: draws a mesh partly there, for units fading in and out of view. The Mobile renderer ignores
## `GeometryInstance3D.transparency`, so a fading mesh takes a copy of its material with alpha hash (it stays in the
## opaque pass, under the bird's-eye post pass), one copy per material and step, shared by every mesh. A whole mesh
## gets its own materials back.

## Steps from hidden to whole.
const STEPS: int = 8
const ORIGINALS: StringName = &"fade_originals"

## [material, step] to its faded copy.
static var _cache: Dictionary = {}


## Draws `mesh` at `step` of `STEPS` (`STEPS`: its own materials). Only `BaseMaterial3D`s fade.
static func apply(mesh: MeshInstance3D, step: int) -> void:
	if mesh == null or mesh.mesh == null:
		return
	if not mesh.has_meta(ORIGINALS):
		if step >= STEPS:
			return
		var found: Array = [mesh.material_override]
		for surface: int in mesh.get_surface_override_material_count():
			found.append(mesh.get_surface_override_material(surface))
		mesh.set_meta(ORIGINALS, found)
	var originals: Array = mesh.get_meta(ORIGINALS)
	var whole: bool = step >= STEPS
	var override := originals[0] as Material
	if override != null:
		mesh.material_override = override if whole else _faded(override, step)
	else:
		for surface: int in originals.size() - 1:
			var own := originals[surface + 1] as Material
			if whole:
				mesh.set_surface_override_material(surface, own)
				continue
			var base: Material = own if own != null else mesh.mesh.surface_get_material(surface)
			mesh.set_surface_override_material(surface, _faded(base, step))
	if whole:
		mesh.remove_meta(ORIGINALS)


## Forgets the copies (the materials they were made from changed).
static func clear() -> void:
	_cache.clear()


static func _faded(material: Material, step: int) -> Material:
	var base := material as BaseMaterial3D
	if base == null:
		return material
	var key: Array = [base, step]
	if not _cache.has(key):
		var copy: BaseMaterial3D = base.duplicate()
		if copy.transparency == BaseMaterial3D.TRANSPARENCY_DISABLED:
			copy.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_HASH
		copy.albedo_color.a *= float(step) / STEPS
		_cache[key] = copy
	return _cache[key]
