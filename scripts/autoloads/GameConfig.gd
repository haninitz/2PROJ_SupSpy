extends Node

var mode:       String = ""
var format:     String = "1v1"
var diff:       String = "med"
var map:        String = "clover"
var room_name:  String = ""
var steam_name: String = ""
var steam_id:   int    = 0
var my_peer_id: int    = 0
var is_host:    bool   = false
var server_ip:  String = "127.0.0.1"
var players:    Dictionary = {}
var selected_team_ids: Array[int] = [0, 1]
var token:    String = ""
var username: String = ""
var wins:     int    = 0
var losses:   int    = 0
var gold:     int    = 300
var initial_state: Dictionary = {}

func get_max_players() -> int:
	if format.is_valid_int():
		return clamp(int(format), 2, 8)
	match format:
		"1v1": return 2
		"2v2": return 4
		"3v3": return 6
		"4v4": return 8
	return 2

func get_players_per_team() -> int:
	return get_max_players() / 2

func reset() -> void:
	mode       = ""
	format     = "1v1"
	diff       = "med"
	map        = "clover"
	room_name  = ""
	is_host    = false
	my_peer_id = 0
	players.clear()
	selected_team_ids = [0, 1]
	gold = 300
	initial_state.clear()