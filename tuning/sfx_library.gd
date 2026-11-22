class_name SfxLibrary
extends Resource
## Every cue the game can play, in one list (tuning/sfx_library.tres). A new sound is a new `SfxCue` .tres added here.

@export var cues: Array[SfxCue] = []
