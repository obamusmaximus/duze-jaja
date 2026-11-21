class_name TuningVisuals
extends RefCounted
## Debug: finds the animated diagram (a TuningVisual) for a tunable. Each diagram script says which tunables it covers
## (`covers()`); list a new diagram in SCRIPTS. A tunable inherited from a base stats class
## is found under the base class's name.

const SCRIPTS: Array[Script] = [
]

## "Class.prop" to the diagram script, built on first use.
static var _lookup: Dictionary = {}


## A new diagram for `prop` of `resource`, or null when it has none.
static func create(resource: Resource, prop: String) -> TuningVisual:
	var script: Script = find(resource, prop)
	if script == null:
		return null
	var visual: TuningVisual = script.new()
	visual.stats = resource
	visual.prop = prop
	return visual


## The diagram script for `prop` of `resource`, or null.
static func find(resource: Resource, prop: String) -> Script:
	if _lookup.is_empty():
		_build()
	var current: Script = resource.get_script() as Script
	while current != null:
		var key: String = "%s.%s" % [current.get_global_name(), prop]
		if _lookup.has(key):
			return _lookup[key]
		current = current.get_base_script()
	return null


static func _build() -> void:
	for script: Script in SCRIPTS:
		var covered: Dictionary = script.call("covers")
		for stats_class: String in covered:
			for name: String in covered[stats_class]:
				_lookup["%s.%s" % [stats_class, name]] = script
