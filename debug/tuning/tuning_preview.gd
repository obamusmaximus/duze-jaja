class_name TuningPreview
extends VBoxContainer
## Debug: the tuning panel's preview column. Shows the tunable last hovered or focused: its name, an animated diagram
## of what it does (TuningVisuals) drawn from the live values, so dragging its slider changes the picture, and its
## full doc comment.

var _resource: Resource
var _prop: String = ""

@onready var _title: Label = %PreviewTitle
@onready var _holder: PanelContainer = %VisualHolder
@onready var _empty: Label = %NoVisual
@onready var _description: Label = %PreviewDescription


func _ready() -> void:
	_holder.custom_minimum_size = TuningVisual.SIZE
	clear()


## Shows the diagram and description for `prop` of `resource`.
func show_for(resource: Resource, prop: String, description: String) -> void:
	if resource == _resource and prop == _prop:
		return
	_resource = resource
	_prop = prop
	_title.text = prop.capitalize()
	_description.text = description
	_remove_visual()
	var visual: TuningVisual = TuningVisuals.create(resource, prop)
	_empty.visible = visual == null
	if visual != null:
		_holder.add_child(visual)


func clear() -> void:
	_resource = null
	_prop = ""
	_title.text = "Hover a setting"
	_description.text = "Its diagram and description show here. The diagram follows the slider live."
	_remove_visual()
	_empty.visible = true


func _remove_visual() -> void:
	for child: Node in _holder.get_children():
		if child is TuningVisual:
			_holder.remove_child(child)
			child.queue_free()
