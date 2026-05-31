extends Node

const MAPS : Array = [

	# Carte 1 : Beverly Hills (Clover)
	{
		"name"      : "Beverly Hills (Clover)",
		"has_water" : false,
		"land_zones": [],
		"camps": [
			{
				"name": "Villa Clover",       "pos": Vector2(120, 170),
				"owner": 1, "units": 6, "income": 10,
				"is_port": false, "is_neutral_hard": false,
				"territory": [Vector2(40,90), Vector2(210,90), Vector2(210,250), Vector2(40,250)]
			},
			{
				"name": "Boutique WOOHP",     "pos": Vector2(130, 520),
				"owner": 1, "units": 6, "income": 10,
				"is_port": false, "is_neutral_hard": false,
				"territory": [Vector2(45,440), Vector2(220,440), Vector2(220,610), Vector2(45,610)]
			},
			{
				"name": "Beverly Hills High", "pos": Vector2(340, 315),
				"owner": 0, "units": 4, "income": 15,
				"is_port": false, "is_neutral_hard": false,
				"territory": [Vector2(255,235), Vector2(430,235), Vector2(430,395), Vector2(255,395)]
			},
			{
				"name": "Sunset Mall",        "pos": Vector2(525, 130),
				"owner": 0, "units": 4, "income": 16,
				"is_port": false, "is_neutral_hard": false,
				"territory": [Vector2(445,60), Vector2(610,60), Vector2(610,210), Vector2(445,210)]
			},
			{
				"name": "Studio Espion",      "pos": Vector2(525, 500),
				"owner": 0, "units": 4, "income": 16,
				"is_port": false, "is_neutral_hard": false,
				"territory": [Vector2(440,420), Vector2(615,420), Vector2(615,590), Vector2(440,590)]
			},
			{
				"name": "Rodeo Drive",        "pos": Vector2(705, 315),
				"owner": 0, "units": 6, "income": 24,
				"is_port": false, "is_neutral_hard": true,
				"territory": [Vector2(625,235), Vector2(790,235), Vector2(790,395), Vector2(625,395)]
			},
			{
				"name": "Tour WOOHP",         "pos": Vector2(865, 145),
				"owner": 0, "units": 5, "income": 20,
				"is_port": false, "is_neutral_hard": true,
				"territory": [Vector2(790,70), Vector2(945,70), Vector2(945,220), Vector2(790,220)]
			},
			{
				"name": "Cachette Cyber",     "pos": Vector2(865, 515),
				"owner": 0, "units": 4, "income": 18,
				"is_port": false, "is_neutral_hard": false,
				"territory": [Vector2(785,435), Vector2(955,435), Vector2(955,600), Vector2(785,600)]
			},
			{
				"name": "QG de Mandy",        "pos": Vector2(1040, 245),
				"owner": 2, "units": 6, "income": 10,
				"is_port": false, "is_neutral_hard": false,
				"territory": [Vector2(965,170), Vector2(1125,170), Vector2(1125,320), Vector2(965,320)]
			},
			{
				"name": "Repaire LAMOS",      "pos": Vector2(1040, 565),
				"owner": 2, "units": 6, "income": 10,
				"is_port": false, "is_neutral_hard": false,
				"territory": [Vector2(960,490), Vector2(1130,490), Vector2(1130,650), Vector2(960,650)]
			},
			{
				"name": "Bunker Rose",        "pos": Vector2(695, 650),
				"owner": 0, "units": 5, "income": 18,
				"is_port": false, "is_neutral_hard": true,
				"territory": [Vector2(610,600), Vector2(780,600), Vector2(780,705), Vector2(610,705)]
			}
		],
		"forests": [
			Vector2(275, 148), Vector2(335, 292), Vector2(270, 442),
			Vector2(802, 148), Vector2(762, 418), Vector2(828, 452)
		],
		"river_x" : -1,
		"bridge_y": -1,
		"bridge_h": 0,
		"adjacency": [
			[0,2],[1,2],[2,3],[2,4],[3,5],[4,5],
			[5,6],[5,7],[6,8],[7,9],[4,10],[7,10],[8,9]
		],
		"regions": [
			{"name": "Quartier Clover", "camps": [0, 1, 2], "bonus": 15},
			{"name": "Centre Beverly",  "camps": [3, 4, 5], "bonus": 20},
			{"name": "Secteur WOOHP",   "camps": [6, 7, 10], "bonus": 20},
			{"name": "Secteur LAMOS",   "camps": [8, 9], "bonus": 10},
		]
	},

	# Carte 2 : Jungle Techno (Sam)
	{
		"name"      : "Jungle Techno (Sam)",
		"has_water" : false,
		"land_zones": [],
		"camps": [
			{
				"name": "Labo de Sam",          "pos": Vector2(135, 310),
				"owner": 1, "units": 6, "income": 10,
				"is_port": false, "is_neutral_hard": false,
				"territory": [Vector2(55,230), Vector2(220,230), Vector2(220,390), Vector2(55,390)]
			},
			{
				"name": "Relais Ouest",         "pos": Vector2(305, 160),
				"owner": 0, "units": 4, "income": 15,
				"is_port": false, "is_neutral_hard": false,
				"territory": [Vector2(235,90), Vector2(380,90), Vector2(380,235), Vector2(235,235)]
			},
			{
				"name": "Terminal Vert",        "pos": Vector2(315, 500),
				"owner": 0, "units": 4, "income": 15,
				"is_port": false, "is_neutral_hard": false,
				"territory": [Vector2(235,425), Vector2(395,425), Vector2(395,580), Vector2(235,580)]
			},
			{
				"name": "Nexus Techno",         "pos": Vector2(555, 320),
				"owner": 0, "units": 6, "income": 25,
				"is_port": false, "is_neutral_hard": true,
				"territory": [Vector2(470,240), Vector2(640,240), Vector2(640,400), Vector2(470,400)]
			},
			{
				"name": "Serre Connectée",      "pos": Vector2(665, 115),
				"owner": 0, "units": 5, "income": 20,
				"is_port": false, "is_neutral_hard": true,
				"territory": [Vector2(585,45), Vector2(750,45), Vector2(750,195), Vector2(585,195)]
			},
			{
				"name": "Base de Données",      "pos": Vector2(720, 525),
				"owner": 0, "units": 4, "income": 18,
				"is_port": false, "is_neutral_hard": false,
				"territory": [Vector2(640,445), Vector2(805,445), Vector2(805,610), Vector2(640,610)]
			},
			{
				"name": "Antenne Jungle",       "pos": Vector2(865, 305),
				"owner": 0, "units": 4, "income": 18,
				"is_port": false, "is_neutral_hard": false,
				"territory": [Vector2(790,230), Vector2(945,230), Vector2(945,385), Vector2(790,385)]
			},
			{
				"name": "Tour Caméléon",        "pos": Vector2(1030, 160),
				"owner": 2, "units": 6, "income": 10,
				"is_port": false, "is_neutral_hard": false,
				"territory": [Vector2(955,90), Vector2(1110,90), Vector2(1110,235), Vector2(955,235)]
			},
			{
				"name": "Base Ennemie",         "pos": Vector2(1030, 500),
				"owner": 2, "units": 6, "income": 10,
				"is_port": false, "is_neutral_hard": false,
				"territory": [Vector2(950,425), Vector2(1115,425), Vector2(1115,580), Vector2(950,580)]
			}
		],
		"forests": [
			Vector2(80,  120), Vector2(200, 200), Vector2(80,  320),
			Vector2(200, 450), Vector2(350,  80), Vector2(490, 180),
			Vector2(576, 520), Vector2(720, 180), Vector2(800, 410),
			Vector2(1060, 120), Vector2(1060, 530)
		],
		"river_x" : -1,
		"bridge_y": -1,
		"bridge_h": 0,
		"adjacency": [
			[0,1],[0,2],[1,3],[2,3],[3,4],[3,5],
			[4,6],[5,6],[6,7],[6,8],[7,8]
		],
		"regions": [
			{"name": "Secteur Sam",  "camps": [0, 1, 2], "bonus": 15},
			{"name": "Cœur Techno",  "camps": [3, 4, 5], "bonus": 20},
			{"name": "Jungle Est",   "camps": [6, 7, 8], "bonus": 15},
		]
	},

	#Carte 3 : Île Tropicale (Alex) 
	{
		"name"      : "Île Tropicale (Alex)",
		"has_water" : true,
		"land_zones": [
			{"x": 20,  "y": 50,  "w": 280, "h": 520},
			{"x": 420, "y": 30,  "w": 310, "h": 200},
			{"x": 440, "y": 300, "w": 270, "h": 200},
			{"x": 850, "y": 50,  "w": 280, "h": 520},
		],
		"camps": [
			{
				"name": "Plage d'Alex",    "pos": Vector2(120, 160),
				"owner": 1, "units": 6, "income": 10,
				"is_port": false, "is_neutral_hard": false,
				"territory": [Vector2(45,85), Vector2(205,85), Vector2(205,235), Vector2(45,235)]
			},
			{
				"name": "Port Aventure",   "pos": Vector2(210, 470),
				"owner": 1, "units": 4, "income": 10,
				"is_port": true,  "is_neutral_hard": false,
				"territory": [Vector2(120,395), Vector2(300,395), Vector2(300,545), Vector2(120,545)]
			},
			{
				"name": "Rocher Secret",   "pos": Vector2(500, 105),
				"owner": 0, "units": 4, "income": 16,
				"is_port": false, "is_neutral_hard": false,
				"territory": [Vector2(430,45), Vector2(575,45), Vector2(575,170), Vector2(430,170)]
			},
			{
				"name": "Marina HQ",       "pos": Vector2(650, 145),
				"owner": 0, "units": 4, "income": 16,
				"is_port": true,  "is_neutral_hard": false,
				"territory": [Vector2(585,70), Vector2(720,70), Vector2(720,220), Vector2(585,220)]
			},
			{
				"name": "Île aux Animaux", "pos": Vector2(500, 390),
				"owner": 0, "units": 4, "income": 18,
				"is_port": false, "is_neutral_hard": false,
				"territory": [Vector2(445,315), Vector2(575,315), Vector2(575,465), Vector2(445,465)]
			},
			{
				"name": "Temple Caché",    "pos": Vector2(650, 440),
				"owner": 0, "units": 6, "income": 25,
				"is_port": false, "is_neutral_hard": true,
				"territory": [Vector2(580,365), Vector2(710,365), Vector2(710,500), Vector2(580,500)]
			},
			{
				"name": "Fort Adverse",    "pos": Vector2(1015, 165),
				"owner": 2, "units": 6, "income": 10,
				"is_port": false, "is_neutral_hard": false,
				"territory": [Vector2(930,90), Vector2(1105,90), Vector2(1105,240), Vector2(930,240)]
			},
			{
				"name": "Dock Ennemi",     "pos": Vector2(970, 490),
				"owner": 2, "units": 4, "income": 10,
				"is_port": true,  "is_neutral_hard": false,
				"territory": [Vector2(890,415), Vector2(1060,415), Vector2(1060,565), Vector2(890,565)]
			},
			{
				"name": "Lagune LAMOS",    "pos": Vector2(1075, 335),
				"owner": 0, "units": 4, "income": 16,
				"is_port": false, "is_neutral_hard": false,
				"territory": [Vector2(1000,270), Vector2(1145,270), Vector2(1145,395), Vector2(1000,395)]
			}
		],
		"forests": [
			Vector2(75,  160), Vector2(220, 110), Vector2(95,  370), Vector2(225, 450),
			Vector2(490,  75), Vector2(625,  70), Vector2(555, 160),
			Vector2(510, 340), Vector2(605, 345), Vector2(555, 440),
			Vector2(900, 155), Vector2(1055, 110), Vector2(975, 375), Vector2(915, 450),
		],
		"river_x" : -1,
		"bridge_y": -1,
		"bridge_h": 0,
		"adjacency": [
			[0,1],[0,2],[1,4],[2,3],[2,4],[3,5],[4,5],
			[3,6],[5,8],[8,6],[8,7],[6,7]
		],
		"regions": [
			{"name": "Île Ouest",      "camps": [0, 1], "bonus": 10},
			{"name": "Îles Centrales", "camps": [2, 3, 4, 5], "bonus": 20},
			{"name": "Île Est",        "camps": [6, 7, 8], "bonus": 15},
		]
	}
]
