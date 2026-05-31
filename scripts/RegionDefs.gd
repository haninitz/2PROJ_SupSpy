extends Node

const REGIONS : Dictionary = {
	0: [  # Beverly Hills
		{"id": 0, "name": "Main Island",    "bonus_gold": 30, "bonus_units": 1, "camp_ids": [0, 1, 2]},
		{"id": 1, "name": "North Islands",  "bonus_gold": 15, "bonus_units": 1, "camp_ids": [3, 4]},
		{"id": 2, "name": "South Islands",  "bonus_gold": 15, "bonus_units": 1, "camp_ids": [5, 6]},
	],
	1: [  # Jungle Techno
		{"id": 0, "name": "Central Zone",   "bonus_gold": 25, "bonus_units": 2, "camp_ids": [0, 1]},
		{"id": 1, "name": "North Sector",   "bonus_gold": 20, "bonus_units": 1, "camp_ids": [2, 3]},
		{"id": 2, "name": "South Sector",   "bonus_gold": 20, "bonus_units": 1, "camp_ids": [4, 5]},
	],
	2: [  # Île Tropicale
		{"id": 0, "name": "Main Island",    "bonus_gold": 35, "bonus_units": 2, "camp_ids": [0, 1, 2]},
		{"id": 1, "name": "North Outposts", "bonus_gold": 20, "bonus_units": 1, "camp_ids": [3, 4]},
		{"id": 2, "name": "East Outposts",  "bonus_gold": 20, "bonus_units": 1, "camp_ids": [5, 6]},
	],
}
static func get_regions(map_index: int) -> Array:
	if REGIONS.has(map_index):
		return REGIONS[map_index]
	return []