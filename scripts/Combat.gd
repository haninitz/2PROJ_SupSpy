extends Node

func resolve(source, target) -> void:
	var att_units : int = source.units
	var def_units : int = target.units
	var att_type : String = source.unit_type if source.unit_type != "" else "infantry"
	var def_type : String = target.unit_type if target.unit_type != "" else "infantry"
	var att_stats : Dictionary = UnitDefs.TYPES.get(att_type, UnitDefs.TYPES["infantry"])
	var def_stats : Dictionary = UnitDefs.TYPES.get(def_type, UnitDefs.TYPES["infantry"])
	var force_att : int = att_units * att_stats["damage"] + randi() % (att_units * 4 + 1)
	var force_def : int = def_units * (def_stats["hp"] / 10) + randi() % (def_units * 3 + 1)

	if force_att >= force_def:
		var att_losses : int = maxi(1, att_units / 3)          
		var surviving  : int = maxi(1, att_units - att_losses) 

		target.owner_id = source.owner_id
		target.units     = surviving
		target.unit_type = source.unit_type
		target.production_queue = []
		source.units = 1

	else:
		var def_losses : int = maxi(0, att_units / 2 - 1)
		target.units = maxi(1, def_units - def_losses)
		source.units = 1
