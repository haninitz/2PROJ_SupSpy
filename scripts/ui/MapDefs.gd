extends Node

# ─────────────────────────────────────────
#  MAP DEFINITIONS
#  "territory" on each camp = polygon vertices (PackedVector2Array-compatible)
#  "adjacency" on each map  = list of [i, j] pairs of adjacent camp indices
#  owner_id here are starting positions — GameManager redistributes them
# ─────────────────────────────────────────
const MAPS : Array = [

	# ── Carte 1 : Beverly Hills (Clover) ─────────────────────────────────────
	# River at x=576 divides map. 3 vertical bands: West(0-295), Center(295-870), East(870-1152)
	{
		"name"      : "Beverly Hills (Clover)",
		"has_water" : false,
		"land_zones": [],
		"camps": [
			{
				"name": "Villa Clover",       "pos": Vector2(150, 200),
				"owner": 1, "units": 5, "income": 10,
				"is_port": false, "is_neutral_hard": false,
				"territory": [Vector2(0,0), Vector2(295,0), Vector2(295,315), Vector2(0,315)]
			},
			{
				"name": "Boutique WOOHP",     "pos": Vector2(150, 430),
				"owner": 1, "units": 5, "income": 10,
				"is_port": false, "is_neutral_hard": false,
				"territory": [Vector2(0,315), Vector2(295,315), Vector2(295,620), Vector2(0,620)]
			},
			{
				"name": "Beverly Hills High", "pos": Vector2(440, 170),
				"owner": 0, "units": 2, "income": 15,
				"is_port": false, "is_neutral_hard": false,
				"territory": [Vector2(295,0), Vector2(558,0), Vector2(558,315), Vector2(295,315)]
			},
			{
				"name": "Sunset Mall",        "pos": Vector2(440, 460),
				"owner": 0, "units": 2, "income": 15,
				"is_port": false, "is_neutral_hard": false,
				"territory": [Vector2(295,315), Vector2(558,315), Vector2(558,620), Vector2(295,620)]
			},
			{
				"name": "Rodeo Drive",        "pos": Vector2(710, 310),
				"owner": 0, "units": 3, "income": 20,
				"is_port": false, "is_neutral_hard": true,
				"territory": [Vector2(558,0), Vector2(870,0), Vector2(870,620), Vector2(558,620)]
			},
			{
				"name": "QG de Mandy",        "pos": Vector2(1000, 200),
				"owner": 2, "units": 5, "income": 10,
				"is_port": false, "is_neutral_hard": false,
				"territory": [Vector2(870,0), Vector2(1152,0), Vector2(1152,315), Vector2(870,315)]
			},
			{
				"name": "Repaire LAMOS",      "pos": Vector2(1000, 430),
				"owner": 2, "units": 5, "income": 10,
				"is_port": false, "is_neutral_hard": false,
				"territory": [Vector2(870,315), Vector2(1152,315), Vector2(1152,620), Vector2(870,620)]
			},
			{
				"name": "Agence Sam",
				"pos": Vector2(910, 330),
				"owner": 0, "units": 5, "income": 10,
				"is_port": false, "is_neutral_hard": false,
				"territory": [Vector2(800,220), Vector2(1040,220), Vector2(1040,470), Vector2(800,470)]
			},
			{
				"name": "Cachette Cyber",
				"pos": Vector2(620, 630),
				"owner": 0, "units": 5, "income": 10,
				"is_port": false, "is_neutral_hard": false,
				"territory": [Vector2(500,540), Vector2(760,540), Vector2(760,710), Vector2(500,710)]
			},
			{
				"name": "Villa Beverly",
				"pos": Vector2(360, 620),
				"owner": 0, "units": 4, "income": 9,
				"is_port": false, "is_neutral_hard": false,
				"territory": [Vector2(260,520), Vector2(470,520), Vector2(470,710), Vector2(260,710)]
			},
			{
				"name": "Bunker Rose",
				"pos": Vector2(720, 85),
				"owner": 0, "units": 6, "income": 12,
				"is_port": false, "is_neutral_hard": true,
				"territory": [Vector2(610,20), Vector2(835,20), Vector2(835,200), Vector2(610,200)]
			},
			{
				"name": "Base Lunaire",
				"pos": Vector2(530, 560),
				"owner": 0, "units": 5, "income": 10,
				"is_port": false, "is_neutral_hard": false,
				"territory": [Vector2(415,475), Vector2(645,475), Vector2(645,670), Vector2(415,670)]
			},
			{
				"name": "Station Laser",
				"pos": Vector2(170, 330),
				"owner": 0, "units": 5, "income": 10,
				"is_port": false, "is_neutral_hard": false,
				"territory": [Vector2(60,245), Vector2(280,245), Vector2(280,440), Vector2(60,440)]
			},
			{
				"name": "Studio Espion",
				"pos": Vector2(115, 120),
				"owner": 0, "units": 4, "income": 8,
				"is_port": false, "is_neutral_hard": false,
				"territory": [Vector2(20,40), Vector2(220,40), Vector2(220,230), Vector2(20,230)]
			},
			{
				"name": "Centre WOOHP Nord",
				"pos": Vector2(390, 95),
				"owner": 0, "units": 5, "income": 10,
				"is_port": false, "is_neutral_hard": false,
				"territory": [Vector2(285,25), Vector2(500,25), Vector2(500,205), Vector2(285,205)]
			},
			{
				"name": "QG Fantôme",
				"pos": Vector2(610, 335),
				"owner": 0, "units": 8, "income": 15,
				"is_port": false, "is_neutral_hard": true,
				"territory": [Vector2(485,240), Vector2(735,240), Vector2(735,450), Vector2(485,450)]
			}
		],
		"forests": [
			Vector2(275, 148), Vector2(335, 292), Vector2(270, 442),
			Vector2(802, 148), Vector2(762, 418), Vector2(828, 452)
		],
		"river_x" : 576,
		"bridge_y": 258,
		"bridge_h": 92,
		"adjacency": [
			[0,1],[0,2],[1,3],[2,3],[2,4],[3,4],[4,5],[4,6],[5,6]
		],
		"regions": [
			{"name": "Quartier Ouest", "camps": [0, 1],    "bonus": 10},
			{"name": "Centre-Ville",   "camps": [2, 3, 4], "bonus": 15},
			{"name": "Quartier Est",   "camps": [5, 6],    "bonus": 10},
		]
	},

	# ── Carte 2 : Jungle Techno (Sam) ────────────────────────────────────────
	# No river. 3 vertical bands: West(0-230), Center(230-920), East(920-1152)
	{
		"name"      : "Jungle Techno (Sam)",
		"has_water" : false,
		"land_zones": [],
		"camps": [
			{
				"name": "Labo de Sam",          "pos": Vector2(150, 310),
				"owner": 1, "units": 5, "income": 10,
				"is_port": false, "is_neutral_hard": false,
				"territory": [Vector2(0,0), Vector2(230,0), Vector2(230,620), Vector2(0,620)]
			},
			{
				"name": "Bibliothèque Secrète", "pos": Vector2(310, 150),
				"owner": 0, "units": 3, "income": 20,
				"is_port": false, "is_neutral_hard": false,
				"territory": [Vector2(230,0), Vector2(460,0), Vector2(460,310), Vector2(230,310)]
			},
			{
				"name": "Terminal Vert",        "pos": Vector2(310, 470),
				"owner": 0, "units": 3, "income": 20,
				"is_port": false, "is_neutral_hard": false,
				"territory": [Vector2(230,310), Vector2(460,310), Vector2(460,620), Vector2(230,620)]
			},
			{
				"name": "Nexus Techno",         "pos": Vector2(576, 310),
				"owner": 0, "units": 4, "income": 25,
				"is_port": false, "is_neutral_hard": true,
				"territory": [Vector2(460,0), Vector2(695,0), Vector2(695,620), Vector2(460,620)]
			},
			{
				"name": "Base de Données",      "pos": Vector2(840, 150),
				"owner": 0, "units": 3, "income": 20,
				"is_port": false, "is_neutral_hard": false,
				"territory": [Vector2(695,0), Vector2(920,0), Vector2(920,310), Vector2(695,310)]
			},
			{
				"name": "Relais WOOHP",         "pos": Vector2(840, 470),
				"owner": 0, "units": 3, "income": 20,
				"is_port": false, "is_neutral_hard": false,
				"territory": [Vector2(695,310), Vector2(920,310), Vector2(920,620), Vector2(695,620)]
			},
			{
				"name": "Base Ennemie",         "pos": Vector2(1000, 310),
				"owner": 2, "units": 5, "income": 10,
				"is_port": false, "is_neutral_hard": false,
				"territory": [Vector2(920,0), Vector2(1152,0), Vector2(1152,620), Vector2(920,620)]
			},
		],
		"forests": [
			Vector2(80,  120), Vector2(200, 200), Vector2(80,  320),
			Vector2(200, 450), Vector2(80,  530), Vector2(350,  80),
			Vector2(350, 220), Vector2(350, 390), Vector2(350, 530),
			Vector2(490, 180), Vector2(490, 460), Vector2(576,  80),
			Vector2(576, 520), Vector2(660, 310), Vector2(720,  80),
			Vector2(720, 180), Vector2(720, 460), Vector2(720, 540),
			Vector2(800, 220), Vector2(800, 410), Vector2(900, 100),
			Vector2(900, 320), Vector2(900, 530), Vector2(1060, 120),
			Vector2(1060, 530)
		],
		"river_x" : -1,
		"bridge_y": -1,
		"bridge_h": 0,
		"adjacency": [
			[0,1],[0,2],[1,2],[1,3],[2,3],[3,4],[3,5],[4,5],[4,6],[5,6]
		],
		"regions": [
			{"name": "Secteur Ouest", "camps": [0, 1, 2], "bonus": 15},
			{"name": "Cœur Techno",   "camps": [3],       "bonus": 10},
			{"name": "Secteur Est",   "camps": [4, 5, 6], "bonus": 15},
		]
	},

	# ── Carte 3 : Île Tropicale (Alex) ───────────────────────────────────────
	# Water map. 4 islands: left, center-top, center-bottom, right.
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
				"name": "Plage d'Alex",    "pos": Vector2(130, 180),
				"owner": 1, "units": 5, "income": 10,
				"is_port": false, "is_neutral_hard": false,
				"territory": [Vector2(20,50), Vector2(300,50), Vector2(300,310), Vector2(20,310)]
			},
			{
				"name": "Port Aventure",   "pos": Vector2(200, 480),
				"owner": 1, "units": 3, "income": 10,
				"is_port": true,  "is_neutral_hard": false,
				"territory": [Vector2(20,310), Vector2(300,310), Vector2(300,570), Vector2(20,570)]
			},
			{
				"name": "Arène Tropicale", "pos": Vector2(575, 130),
				"owner": 0, "units": 3, "income": 20,
				"is_port": false, "is_neutral_hard": false,
				"territory": [Vector2(420,30), Vector2(730,30), Vector2(730,230), Vector2(420,230)]
			},
			{
				"name": "Île aux Animaux", "pos": Vector2(575, 400),
				"owner": 0, "units": 2, "income": 25,
				"is_port": false, "is_neutral_hard": true,
				"territory": [Vector2(440,300), Vector2(710,300), Vector2(710,500), Vector2(440,500)]
			},
			{
				"name": "Fort Adverse",    "pos": Vector2(1020, 180),
				"owner": 2, "units": 5, "income": 10,
				"is_port": false, "is_neutral_hard": false,
				"territory": [Vector2(850,50), Vector2(1130,50), Vector2(1130,310), Vector2(850,310)]
			},
			{
				"name": "Dock Ennemi",     "pos": Vector2(950, 480),
				"owner": 2, "units": 3, "income": 10,
				"is_port": true,  "is_neutral_hard": false,
				"territory": [Vector2(850,310), Vector2(1130,310), Vector2(1130,570), Vector2(850,570)]
			},
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
			[0,1],[2,3],[4,5],[0,2],[1,3],[2,4],[3,5]
		],
		"regions": [
			{"name": "Île Ouest",      "camps": [0, 1], "bonus": 10},
			{"name": "Îles Centrales", "camps": [2, 3], "bonus": 15},
			{"name": "Île Est",        "camps": [4, 5], "bonus": 10},
		]
	},

	# ── Carte 4 : QG WOOHP (Jerry) ───────────────────────────────────────────
	# No river. Same layout pattern as Map 2.
	{
		"name"      : "QG WOOHP (Jerry)",
		"has_water" : false,
		"land_zones": [],
		"camps": [
			{
				"name": "Bureau de Jerry",    "pos": Vector2(150, 310),
				"owner": 1, "units": 5, "income": 10,
				"is_port": false, "is_neutral_hard": false,
				"territory": [Vector2(0,0), Vector2(230,0), Vector2(230,620), Vector2(0,620)]
			},
			{
				"name": "Salle des Gadgets",  "pos": Vector2(310, 150),
				"owner": 0, "units": 3, "income": 20,
				"is_port": false, "is_neutral_hard": false,
				"territory": [Vector2(230,0), Vector2(460,0), Vector2(460,310), Vector2(230,310)]
			},
			{
				"name": "Armurerie WOOHP",    "pos": Vector2(310, 470),
				"owner": 0, "units": 3, "income": 20,
				"is_port": false, "is_neutral_hard": false,
				"territory": [Vector2(230,310), Vector2(460,310), Vector2(460,620), Vector2(230,620)]
			},
			{
				"name": "Centre de Contrôle", "pos": Vector2(576, 310),
				"owner": 0, "units": 4, "income": 25,
				"is_port": false, "is_neutral_hard": true,
				"territory": [Vector2(460,0), Vector2(695,0), Vector2(695,620), Vector2(460,620)]
			},
			{
				"name": "Salle d'Entraîn.",   "pos": Vector2(840, 150),
				"owner": 0, "units": 3, "income": 20,
				"is_port": false, "is_neutral_hard": false,
				"territory": [Vector2(695,0), Vector2(920,0), Vector2(920,310), Vector2(695,310)]
			},
			{
				"name": "Archives WOOHP",     "pos": Vector2(840, 470),
				"owner": 0, "units": 3, "income": 20,
				"is_port": false, "is_neutral_hard": false,
				"territory": [Vector2(695,310), Vector2(920,310), Vector2(920,620), Vector2(695,620)]
			},
			{
				"name": "Secteur LAMOS",      "pos": Vector2(1000, 310),
				"owner": 2, "units": 5, "income": 10,
				"is_port": false, "is_neutral_hard": false,
				"territory": [Vector2(920,0), Vector2(1152,0), Vector2(1152,620), Vector2(920,620)]
			},
		],
		"forests": [
			Vector2(80,   75), Vector2(240,  75), Vector2(470,  75),
			Vector2(680,  75), Vector2(880,  75), Vector2(1070,  75),
			Vector2(240, 230), Vector2(470, 230), Vector2(700, 230), Vector2(960, 230),
			Vector2(240, 395), Vector2(470, 395), Vector2(700, 395), Vector2(960, 395),
			Vector2(80,  550), Vector2(240, 550), Vector2(470, 550),
			Vector2(680, 550), Vector2(880, 550), Vector2(1070, 550),
		],
		"river_x" : -1,
		"bridge_y": -1,
		"bridge_h": 0,
		"adjacency": [
			[0,1],[0,2],[1,2],[1,3],[2,3],[3,4],[3,5],[4,5],[4,6],[5,6]
		],
		"regions": [
			{"name": "Aile WOOHP",   "camps": [0, 1, 2], "bonus": 15},
			{"name": "Commandement", "camps": [3],        "bonus": 10},
			{"name": "Aile LAMOS",   "camps": [4, 5, 6],  "bonus": 15},
		]
	}
]