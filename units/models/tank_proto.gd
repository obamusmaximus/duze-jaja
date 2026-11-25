class_name TankProto
extends Node3D
## Prototype main battle tank at true scale (about 7.2 m long over the hull, 3.6 m wide, 2.4 m tall, gun reaching
## 4 m further), on two tracks with a big turret and a long gun. Silhouette: wide and flat, tracks, one long barrel.
## Attachment point an artist's version must also provide: `Muzzle` (barrel tip).


func _init() -> void:
	for side: float in [-1.0, 1.0]:
		ProtoParts.box(self, "Track", Vector3(0.9, 1.1, 7.2), Vector3(side * 1.35, 0.55, 0.0), WorldMaterials.Role.HULL_DARK)
		ProtoParts.wedge(self, "TrackFront", Vector3(0.9, 0.6, 0.8), Vector3(side * 1.35, 0.8, -4.0), WorldMaterials.Role.HULL_DARK)
		ProtoParts.box(self, "Skirt", Vector3(0.12, 0.7, 5.6), Vector3(side * 1.85, 1.25, 0.3), WorldMaterials.Role.HULL_MID)
	ProtoParts.box(self, "Hull", Vector3(2.4, 0.9, 6.6), Vector3(0.0, 1.2, 0.0), WorldMaterials.Role.HULL_MID)
	ProtoParts.wedge(self, "Glacis", Vector3(2.4, 0.9, 1.4), Vector3(0.0, 1.2, -4.0), WorldMaterials.Role.HULL_MID)
	ProtoParts.box(self, "Turret", Vector3(2.5, 0.9, 3.0), Vector3(0.0, 2.1, 0.4), WorldMaterials.Role.HULL)
	ProtoParts.wedge(self, "Mantlet", Vector3(1.4, 0.8, 0.8), Vector3(0.0, 2.1, -1.5), WorldMaterials.Role.HULL)
	ProtoParts.barrel(self, "Gun", 0.17, 5.4, Vector3(0.0, 2.15, -4.2), WorldMaterials.Role.HULL_DARK)
	ProtoParts.livery_box(self, "Stripe", Vector3(0.6, 0.06, 2.4), Vector3(0.0, 2.58, 0.6))
	ProtoParts.marker(self, "Muzzle", Vector3(0.0, 2.15, -6.9))
