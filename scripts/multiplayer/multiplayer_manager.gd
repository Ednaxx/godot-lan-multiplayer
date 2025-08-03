extends Node

const BASE_PORT = 8080
const DEFAULT_SERVER_IP = "127.0.0.1"
const MAX_PLAYERS_PER_SERVER = 2

var multiplayer_scene = preload("res://scenes/multiplayer_player.tscn")

var _players_spawn_node
var host_mode_enabled = false
var multiplayer_mode_enabled = false
var respawn_point = Vector2(30, 20)

# Dynamic server connection info
var target_server_host = DEFAULT_SERVER_IP
var target_server_port = BASE_PORT

# Flag to indicate if multiplayer should start automatically when game scene loads
var auto_start_multiplayer = false

# Current server state
var current_player_count = 0

func become_host():
	print("Starting host on port %d!" % target_server_port)
	
	_players_spawn_node = get_tree().get_current_scene().get_node("Players")
	
	multiplayer_mode_enabled = true
	host_mode_enabled = true
	current_player_count = 0
	
	var server_peer = ENetMultiplayerPeer.new()
	var error = server_peer.create_server(target_server_port, MAX_PLAYERS_PER_SERVER)
	
	if error != OK:
		print("Failed to create server on port %d: %s" % [target_server_port, error])
		return false
	
	multiplayer.multiplayer_peer = server_peer
	
	multiplayer.peer_connected.connect(_add_player_to_game)
	multiplayer.peer_disconnected.connect(_del_player)
	
	_remove_single_player()
	
	if not OS.has_feature("dedicated_server"):
		_add_player_to_game(1)
	
	return true
	
func join_as_player_2():
	print("Joining server at %s:%d" % [target_server_host, target_server_port])
	
	multiplayer_mode_enabled = true
	
	var client_peer = ENetMultiplayerPeer.new()
	var error = client_peer.create_client(target_server_host, target_server_port)
	
	if error != OK:
		print("Failed to connect to server: %s" % error)
		return false
	
	multiplayer.multiplayer_peer = client_peer
	
	_remove_single_player()
	return true

func _add_player_to_game(id: int):
	if current_player_count >= MAX_PLAYERS_PER_SERVER:
		print("Server full! Cannot add player %d" % id)
		return
	
	print("Player %s joined the game!" % id)
	
	var player_to_add = multiplayer_scene.instantiate()
	player_to_add.player_id = id
	player_to_add.name = str(id)
	
	_players_spawn_node.add_child(player_to_add, true)
	current_player_count += 1
	
	print("Current players: %d/%d" % [current_player_count, MAX_PLAYERS_PER_SERVER])
	
func _del_player(id: int):
	print("Player %s left the game!" % id)
	if not _players_spawn_node.has_node(str(id)):
		return
	_players_spawn_node.get_node(str(id)).queue_free()
	current_player_count = max(0, current_player_count - 1)
	
	print("Current players: %d/%d" % [current_player_count, MAX_PLAYERS_PER_SERVER])
	
func _remove_single_player():
	print("Remove single player")
	var player_to_remove = get_tree().get_current_scene().get_node("Player")
	player_to_remove.queue_free()
	
	
	
	
	
	
	
	
	
	
	
