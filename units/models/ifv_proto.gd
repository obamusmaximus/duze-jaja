class_name IfvProto
extends Node3D
## Prototype infantry fighting vehicle at true scale (about 6.4 m long, 3 m wide, 2.7 m tall), six wheels under a
## boxy hull with a small turret and a cannon. Silhouette: low and long, three wheel pairs, short gun.
## Attachment point an artist's version must also provide: `Muzzle` (barrel tip).


func _init() -> void:
	for side: float in [-1.0, 1.0]:
		for z: float in [-2.2, 0.0, 2.2]:
			ProtoParts.wheel(self, "Wheel", 0.55, 0.5, Vector3(side * 1.35, 0.55, z), WorldMaterials.Role.HULL_DARK)
	ProtoParts.box(self, "Hull", Vector3(2.7, 1.2, 6.2), Vector3(0.0, 1.45, 0.0), WorldMaterials.Role.HULL_MID)
	ProtoParts.wedge(self, "Glacis", Vector3(2.7, 0.9, 1.2), Vector3(0.0, 1.45, -3.7), WorldMaterials.Role.HULL_MID)
	ProtoParts.box(self, "Deck", Vector3(2.5, 0.7, 3.6), Vector3(0.0, 2.4, 0.9), WorldMaterials.Role.HULL)
	ProtoParts.box(self, "Turret", Vector3(1.5, 0.7, 1.7), Vector3(0.0, 2.6, -1.4), WorldMaterials.Role.HULL)
	ProtoParts.barrel(self, "Cannon", 0.1, 2.0, Vector3(0.0, 2.65, -3.1), WorldMaterials.Role.HULL_DARK)
	ProtoParts.livery_box(self, "Stripe", Vector3(0.5, 0.06, 3.4), Vector3(0.0, 2.78, 0.9))
	ProtoParts.marker(self, "Muzzle", Vector3(0.0, 2.65, -4.1))
