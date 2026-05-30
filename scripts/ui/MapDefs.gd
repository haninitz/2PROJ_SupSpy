extends Node

const MAPS : Array = [

	{
		"name"      : "Beverly Hills (Clover)",
		"has_water" : false,
		"land_zones": [],
		"camps": [
			{
				"name": "Villa Clover",       "pos": Vector2(70, 360),
				"owner": 1, "units": 5, "income": 10,
				"is_port": false, "is_neutral_hard": false,
				"territory": [Vector2(20,300), Vector2(135,300), Vector2(135,430), Vector2(20,430)]
			},
			{
				"name": "Maison Clover",      "pos": Vector2(150, 520),
				"owner": 1, "units": 4, "income": 10,
				"is_port": false, "is_neutral_hard": false,
				"territory": [Vector2(70,455), Vector2(235,455), Vector2(235,610), Vector2(70,610)]
			},
			{
				"name": "Piscine du Quartier", "pos": Vector2(245, 420),
				"owner": 0, "units": 3, "income": 12,
				"is_port": false, "is_neutral_hard": false,
				"territory": [Vector2(170,350), Vector2(315,350), Vector2(315,500), Vector2(170,500)]
			},
			{
				"name": "Beverly Hills High", "pos": Vector2(370, 220),
				"owner": 0, "units": 3, "income": 15,
				"is_port": false, "is_neutral_hard": false,
				"territory": [Vector2(300,150), Vector2(445,150), Vector2(445,295), Vector2(300,295)]
			},
			{
				"name": "Boutique WOOHP",     "pos": Vector2(405, 370),
				"owner": 0, "units": 4, "income": 16,
				"is_port": false, "is_neutral_hard": false,
				"territory": [Vector2(335,305), Vector2(480,305), Vector2(480,445), Vector2(335,445)]
			},
			{
				"name": "Studio Espion",      "pos": Vector2(385, 545),
				"owner": 0, "units": 3, "income": 14,
				"is_port": false, "is_neutral_hard": false,
				"territory": [Vector2(310,485), Vector2(465,485), Vector2(465,620), Vector2(310,620)]
			},
			{
				"name": "Entrée WOOHP",       "pos": Vector2(555, 180),
				"owner": 0, "units": 4, "income": 16,
				"is_port": false, "is_neutral_hard": false,
				"territory": [Vector2(500,120), Vector2(625,120), Vector2(625,245), Vector2(500,245)]
			},
			{
				"name": "Place Centrale",     "pos": Vector2(555, 335),
				"owner": 0, "units": 5, "income": 22,
				"is_port": false, "is_neutral_hard": true,
				"territory": [Vector2(490,275), Vector2(630,275), Vector2(630,410), Vector2(490,410)]
			},
			{
				"name": "Salle des Gadgets",  "pos": Vector2(555, 520),
				"owner": 0, "units": 4, "income": 18,
				"is_port": false, "is_neutral_hard": false,
				"territory": [Vector2(490,460), Vector2(630,460), Vector2(630,595), Vector2(490,595)]
			},
			{
				"name": "Rodeo Drive",        "pos": Vector2(700, 335),
				"owner": 0, "units": 4, "income": 18,
				"is_port": false, "is_neutral_hard": false,
				"territory": [Vector2(640,275), Vector2(770,275), Vector2(770,410), Vector2(640,410)]
			},
			{
				"name": "Agence Sam",         "pos": Vector2(705, 520),
				"owner": 0, "units": 3, "income": 15,
				"is_port": false, "is_neutral_hard": false,
				"territory": [Vector2(640,460), Vector2(775,460), Vector2(775,595), Vector2(640,595)]
			},
			{
				"name": "Tour WOOHP",         "pos": Vector2(830, 185),
				"owner": 0, "units": 5, "income": 22,
				"is_port": false, "is_neutral_hard": true,
				"territory": [Vector2(760,120), Vector2(900,120), Vector2(900,255), Vector2(760,255)]
			},
			{
				"name": "Cachette Cyber",     "pos": Vector2(835, 385),
				"owner": 0, "units": 4, "income": 17,
				"is_port": false, "is_neutral_hard": false,
				"territory": [Vector2(770,320), Vector2(910,320), Vector2(910,455), Vector2(770,455)]
			},
			{
				"name": "Villa Beverly",      "pos": Vector2(840, 560),
				"owner": 0, "units": 3, "income": 14,
				"is_port": false, "is_neutral_hard": false,
				"territory": [Vector2(770,500), Vector2(910,500), Vector2(910,625), Vector2(770,625)]
			},
			{
				"name": "QG de Mandy",        "pos": Vector2(1015, 315),
				"owner": 2, "units": 5, "income": 10,
				"is_port": false, "is_neutral_hard": false,
				"territory": [Vector2(945,255), Vector2(1105,255), Vector2(1105,385), Vector2(945,385)]
			},
			{
				"name": "Repaire LAMOS",      "pos": Vector2(1030, 470),
				"owner": 2, "units": 5, "income": 10,
				"is_port": false, "is_neutral_hard": false,
				"territory": [Vector2(950,405), Vector2(1115,405), Vector2(1115,540), Vector2(950,540)]
			},
			{
				"name": "Station Laser",      "pos": Vector2(880, 665),
				"owner": 0, "units": 4, "income": 16,
				"is_port": false, "is_neutral_hard": false,
				"territory": [Vector2(800,625), Vector2(965,625), Vector2(965,705), Vector2(800,705)]
			},
			{
				"name": "Bunker Rose",        "pos": Vector2(665, 660),
				"owner": 0, "units": 5, "income": 20,
				"is_port": false, "is_neutral_hard": true,
				"territory": [Vector2(590,620), Vector2(745,620), Vector2(745,705), Vector2(590,705)]
			}
		],
		"forests": [
			Vector2(138, 398), Vector2(512, 180), Vector2(545, 575),
			Vector2(735, 330), Vector2(805, 585), Vector2(1010, 470)
		],
		"river_x" : -1,
		"bridge_y": -1,
		"bridge_h": 0,
		"adjacency": [
			[0,1],[0,2],[1,2],[1,5],
			[2,3],[2,4],[3,4],[4,5],
			[3,6],[4,7],[5,8],
			[6,7],[7,8],[7,9],[8,10],
			[9,10],[9,12],[10,13],
			[11,12],[12,13],[12,14],[13,15],
			[14,15],[13,16],[10,17],[16,17]
		],
		"regions": [
			{"name": "Quartier Clover",  "camps": [0, 1, 2],        "bonus": 15},
			{"name": "Centre Beverly",   "camps": [3, 4, 5, 7],     "bonus": 20},
			{"name": "Secteur WOOHP",    "camps": [6, 8, 9, 10],    "bonus": 20},
			{"name": "Zone Cyber",       "camps": [11, 12, 13],     "bonus": 15},
			{"name": "Secteur LAMOS",    "camps": [14, 15, 16],     "bonus": 15},
			{"name": "Zone Sud",         "camps": [17],             "bonus": 10},
		]
	},

	{
		"name"      : "Jungle Techno (Sam)",
		"has_water" : false,
		"land_zones": [],
		"camps": [
			{
				"name": "Labo de Sam",          "pos": Vector2(165, 255),
				"owner": 1, "units": 5, "income": 10,
				"is_port": false, "is_neutral_hard": false,
				"territory": [Vector2(105,200), Vector2(225,200), Vector2(225,315), Vector2(105,315)]
			},
			{
				"name": "Relais Ouest",         "pos": Vector2(205, 430),
				"owner": 1, "units": 4, "income": 10,
				"is_port": false, "is_neutral_hard": false,
				"territory": [Vector2(145,370), Vector2(270,370), Vector2(270,490), Vector2(145,490)]
			},
			{
				"name": "Pont de Bambou",       "pos": Vector2(300, 335),
				"owner": 0, "units": 3, "income": 12,
				"is_port": false, "is_neutral_hard": false,
				"territory": [Vector2(245,280), Vector2(355,280), Vector2(355,395), Vector2(245,395)]
			},
			{
				"name": "Ruines Vertes",        "pos": Vector2(405, 250),
				"owner": 0, "units": 3, "income": 15,
				"is_port": false, "is_neutral_hard": false,
				"territory": [Vector2(350,195), Vector2(465,195), Vector2(465,310), Vector2(350,310)]
			},
			{
				"name": "Terminal Vert",        "pos": Vector2(430, 455),
				"owner": 0, "units": 3, "income": 16,
				"is_port": false, "is_neutral_hard": false,
				"territory": [Vector2(370,395), Vector2(495,395), Vector2(495,515), Vector2(370,515)]
			},
			{
				"name": "Base de Recherche",    "pos": Vector2(535, 335),
				"owner": 0, "units": 4, "income": 18,
				"is_port": false, "is_neutral_hard": false,
				"territory": [Vector2(480,280), Vector2(595,280), Vector2(595,395), Vector2(480,395)]
			},
			{
				"name": "Nexus Techno",         "pos": Vector2(610, 245),
				"owner": 0, "units": 5, "income": 25,
				"is_port": false, "is_neutral_hard": true,
				"territory": [Vector2(550,185), Vector2(675,185), Vector2(675,310), Vector2(550,310)]
			},
			{
				"name": "Serre Connectée",      "pos": Vector2(615, 495),
				"owner": 0, "units": 4, "income": 20,
				"is_port": false, "is_neutral_hard": true,
				"territory": [Vector2(555,435), Vector2(680,435), Vector2(680,555), Vector2(555,555)]
			},
			{
				"name": "Antenne Jungle",       "pos": Vector2(720, 335),
				"owner": 0, "units": 3, "income": 16,
				"is_port": false, "is_neutral_hard": false,
				"territory": [Vector2(665,280), Vector2(780,280), Vector2(780,395), Vector2(665,395)]
			},
			{
				"name": "Relais WOOHP",         "pos": Vector2(805, 250),
				"owner": 0, "units": 3, "income": 18,
				"is_port": false, "is_neutral_hard": false,
				"territory": [Vector2(750,195), Vector2(865,195), Vector2(865,310), Vector2(750,310)]
			},
			{
				"name": "Cachette Toxique",     "pos": Vector2(825, 455),
				"owner": 0, "units": 4, "income": 18,
				"is_port": false, "is_neutral_hard": false,
				"territory": [Vector2(765,395), Vector2(890,395), Vector2(890,515), Vector2(765,515)]
			},
			{
				"name": "Tour Caméléon",        "pos": Vector2(980, 335),
				"owner": 2, "units": 5, "income": 10,
				"is_port": false, "is_neutral_hard": false,
				"territory": [Vector2(920,280), Vector2(1045,280), Vector2(1045,395), Vector2(920,395)]
			},
			{
				"name": "Base Ennemie",         "pos": Vector2(1030, 470),
				"owner": 2, "units": 5, "income": 10,
				"is_port": false, "is_neutral_hard": false,
				"territory": [Vector2(965,410), Vector2(1100,410), Vector2(1100,530), Vector2(965,530)]
			},
			{
				"name": "Station Racines",      "pos": Vector2(335, 585),
				"owner": 0, "units": 3, "income": 14,
				"is_port": false, "is_neutral_hard": false,
				"territory": [Vector2(275,530), Vector2(400,530), Vector2(400,645), Vector2(275,645)]
			},
			{
				"name": "Bassin Secret",        "pos": Vector2(820, 125),
				"owner": 0, "units": 4, "income": 17,
				"is_port": false, "is_neutral_hard": false,
				"territory": [Vector2(760,70), Vector2(890,70), Vector2(890,185), Vector2(760,185)]
			},
			{
				"name": "Poste Sud",           "pos": Vector2(705, 620),
				"owner": 0, "units": 3, "income": 14,
				"is_port": false, "is_neutral_hard": false,
				"territory": [Vector2(640,565), Vector2(775,565), Vector2(775,680), Vector2(640,680)]
			}
		],
		"forests": [
			Vector2(105, 110), Vector2(225, 165), Vector2(315, 135),
			Vector2(410, 90), Vector2(505, 470), Vector2(710, 155),
			Vector2(790, 350), Vector2(965, 355), Vector2(1030, 520)
		],
		"river_x" : -1,
		"bridge_y": -1,
		"bridge_h": 0,
		"adjacency": [
			[0,1],[0,2],[1,2],[1,13],
			[2,3],[2,4],[3,5],[4,5],[4,13],
			[5,6],[5,7],[6,8],[7,8],[7,15],
			[8,9],[8,10],[9,10],[9,14],
			[10,11],[11,12],[10,12],[14,9],[15,10]
		],
		"regions": [
			{"name": "Secteur Sam",    "camps": [0, 1, 2],        "bonus": 15},
			{"name": "Jungle Ouest",   "camps": [3, 4, 13],       "bonus": 15},
			{"name": "Cœur Techno",    "camps": [5, 6, 7, 8],     "bonus": 20},
			{"name": "Jungle Est",     "camps": [9, 10, 14, 15],  "bonus": 20},
			{"name": "Zone Ennemie",   "camps": [11, 12],         "bonus": 10},
		]
	},

	{
		"name"      : "Île Tropicale (Alex)",
		"has_water" : true,
		"land_zones": [
			{"x": 0,   "y": 25,  "w": 75,  "h": 140},
			{"x": 65,  "y": 140, "w": 230, "h": 190},
			{"x": 125, "y": 435, "w": 235, "h": 215},
			{"x": 430, "y": 30,  "w": 210, "h": 110},
			{"x": 410, "y": 165, "w": 255, "h": 175},
			{"x": 450, "y": 350, "w": 225, "h": 190},
			{"x": 445, "y": 585, "w": 290, "h": 110},
			{"x": 725, "y": 50,  "w": 210, "h": 170},
			{"x": 715, "y": 340, "w": 250, "h": 175},
			{"x": 985, "y": 210, "w": 165, "h": 145},
		],
		"camps": [
			{
				"name": "Poste Nord-Ouest", "pos": Vector2(40, 85),
				"owner": 0, "units": 3, "income": 12,
				"is_port": false, "is_neutral_hard": false,
				"territory": [Vector2(5,35), Vector2(75,35), Vector2(75,145), Vector2(5,145)]
			},
			{
				"name": "Plage d'Alex",    "pos": Vector2(165, 170),
				"owner": 1, "units": 5, "income": 10,
				"is_port": false, "is_neutral_hard": false,
				"territory": [Vector2(90,130), Vector2(245,130), Vector2(245,235), Vector2(90,235)]
			},
			{
				"name": "Cabane WOOHP",    "pos": Vector2(115, 285),
				"owner": 1, "units": 4, "income": 10,
				"is_port": false, "is_neutral_hard": false,
				"territory": [Vector2(65,240), Vector2(170,240), Vector2(170,330), Vector2(65,330)]
			},
			{
				"name": "Port Aventure",   "pos": Vector2(225, 285),
				"owner": 0, "units": 3, "income": 12,
				"is_port": true,  "is_neutral_hard": false,
				"territory": [Vector2(180,235), Vector2(285,235), Vector2(285,330), Vector2(180,330)]
			},
			{
				"name": "Récif Ouest",     "pos": Vector2(210, 515),
				"owner": 0, "units": 3, "income": 14,
				"is_port": true,  "is_neutral_hard": false,
				"territory": [Vector2(145,455), Vector2(280,455), Vector2(280,575), Vector2(145,575)]
			},
			{
				"name": "Forêt de Palmiers", "pos": Vector2(315, 560),
				"owner": 0, "units": 3, "income": 15,
				"is_port": false, "is_neutral_hard": false,
				"territory": [Vector2(260,500), Vector2(360,500), Vector2(360,635), Vector2(260,635)]
			},
			{
				"name": "Marina HQ",       "pos": Vector2(515, 95),
				"owner": 0, "units": 3, "income": 16,
				"is_port": true,  "is_neutral_hard": false,
				"territory": [Vector2(455,40), Vector2(580,40), Vector2(580,140), Vector2(455,140)]
			},
			{
				"name": "Rocher Secret",   "pos": Vector2(605, 105),
				"owner": 0, "units": 3, "income": 16,
				"is_port": false, "is_neutral_hard": false,
				"territory": [Vector2(550,45), Vector2(640,45), Vector2(640,140), Vector2(550,140)]
			},
			{
				"name": "Arène Tropicale", "pos": Vector2(510, 215),
				"owner": 0, "units": 5, "income": 24,
				"is_port": false, "is_neutral_hard": true,
				"territory": [Vector2(435,165), Vector2(580,165), Vector2(580,275), Vector2(435,275)]
			},
			{
				"name": "Dock Central",    "pos": Vector2(610, 270),
				"owner": 0, "units": 3, "income": 14,
				"is_port": true,  "is_neutral_hard": false,
				"territory": [Vector2(570,215), Vector2(665,215), Vector2(665,335), Vector2(570,335)]
			},
			{
				"name": "Île aux Animaux", "pos": Vector2(515, 415),
				"owner": 0, "units": 4, "income": 18,
				"is_port": false, "is_neutral_hard": false,
				"territory": [Vector2(455,360), Vector2(575,360), Vector2(575,475), Vector2(455,475)]
			},
			{
				"name": "Temple Caché",    "pos": Vector2(635, 445),
				"owner": 0, "units": 5, "income": 25,
				"is_port": false, "is_neutral_hard": true,
				"territory": [Vector2(580,380), Vector2(675,380), Vector2(675,520), Vector2(580,520)]
			},
			{
				"name": "Baie Sud",       "pos": Vector2(565, 640),
				"owner": 0, "units": 3, "income": 15,
				"is_port": true,  "is_neutral_hard": false,
				"territory": [Vector2(475,595), Vector2(655,595), Vector2(655,695), Vector2(475,695)]
			},
			{
				"name": "Camp Corail",     "pos": Vector2(805, 110),
				"owner": 0, "units": 3, "income": 15,
				"is_port": false, "is_neutral_hard": false,
				"territory": [Vector2(735,60), Vector2(875,60), Vector2(875,165), Vector2(735,165)]
			},
			{
				"name": "Port Corail",     "pos": Vector2(885, 175),
				"owner": 0, "units": 3, "income": 12,
				"is_port": true,  "is_neutral_hard": false,
				"territory": [Vector2(820,130), Vector2(935,130), Vector2(935,220), Vector2(820,220)]
			},
			{
				"name": "Grande Lagune",   "pos": Vector2(815, 395),
				"owner": 0, "units": 3, "income": 16,
				"is_port": false, "is_neutral_hard": false,
				"territory": [Vector2(740,340), Vector2(890,340), Vector2(890,455), Vector2(740,455)]
			},
			{
				"name": "Dock Sauvage",    "pos": Vector2(900, 475),
				"owner": 0, "units": 3, "income": 12,
				"is_port": true,  "is_neutral_hard": false,
				"territory": [Vector2(845,425), Vector2(955,425), Vector2(955,515), Vector2(845,515)]
			},
			{
				"name": "Fort Adverse",    "pos": Vector2(1050, 250),
				"owner": 2, "units": 5, "income": 10,
				"is_port": false, "is_neutral_hard": false,
				"territory": [Vector2(990,205), Vector2(1120,205), Vector2(1120,315), Vector2(990,315)]
			},
			{
				"name": "Dock Ennemi",     "pos": Vector2(1085, 330),
				"owner": 2, "units": 4, "income": 10,
				"is_port": true,  "is_neutral_hard": false,
				"territory": [Vector2(1025,285), Vector2(1145,285), Vector2(1145,355), Vector2(1025,355)]
			}
		],
		"forests": [
			Vector2(105, 200), Vector2(220, 185), Vector2(245, 560), Vector2(315, 585),
			Vector2(505, 95), Vector2(610, 105), Vector2(520, 420), Vector2(635, 445),
			Vector2(805, 110), Vector2(880, 175), Vector2(815, 395), Vector2(1050, 250)
		],
		"river_x" : -1,
		"bridge_y": -1,
		"bridge_h": 0,
		"adjacency": [
			[0,1],[1,2],[1,3],[2,3],[2,4],[4,5],
			[3,6],[6,7],[6,8],[7,8],[8,9],
			[8,10],[9,11],[10,11],[10,12],[11,12],
			[9,13],[13,14],[14,15],[15,16],[16,17],[17,18],
			[5,12],[12,16],[4,10],[3,8]
		],
		"regions": [
			{"name": "Île Ouest",      "camps": [0, 1, 2, 3],      "bonus": 20},
			{"name": "Récif Sud",      "camps": [4, 5],            "bonus": 10},
			{"name": "Île Centrale",   "camps": [6, 7, 8, 9],      "bonus": 20},
			{"name": "Île Sauvage",    "camps": [10, 11, 12],      "bonus": 15},
			{"name": "Archipel Est",   "camps": [13, 14, 15, 16],  "bonus": 20},
			{"name": "Île Ennemie",    "camps": [17, 18],          "bonus": 10},
		]
	},

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
			}
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