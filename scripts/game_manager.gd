extends Node

signal score_updated(player_id, new_score)
signal lives_updated(player_id, new_lives)
signal game_over_signal(player_id)

@rpc("authority", "call_local")
func sync_score_update(player_id: int, new_score: int):
	if game_ending:
		return
	print("DEBUG GameManager: sync_score_update RPC received - player_id=%d, new_score=%d" % [player_id, new_score])
	scores[player_id] = new_score
	score_updated.emit(player_id, new_score)

@rpc("authority", "call_local")
func sync_coin_collected(coin_path: String):
	if game_ending:
		return
	collected_coins[coin_path] = true
	var coin_node = get_tree().get_current_scene().get_node_or_null(coin_path)
	if coin_node and coin_node.has_method("_handle_collection"):
		coin_node._handle_collection()

@rpc("authority", "call_local")
func sync_lives_update(player_id: int, new_lives: int):
	if game_ending:
		return		
	lives_updated.emit(player_id, new_lives)

var scores = {}
var lives = {}
var spectators = {}
var collected_coins = {}  # Track collected coins by their unique path
const MAX_LIVES = 3
var game_ending = false

func _ready():
	print("Game Manager: Starting with target server %s:%d" % [MultiplayerManager.target_server_host, MultiplayerManager.target_server_port])
	print("Game Manager: Multiplayer mode enabled: %s, Host mode enabled: %s" % [MultiplayerManager.multiplayer_mode_enabled, MultiplayerManager.host_mode_enabled])
	
	if OS.has_feature("dedicated_server"):
		print("Starting dedicated server...")
		MultiplayerManager.become_host()
	elif MultiplayerManager.target_server_host != MultiplayerManager.DEFAULT_SERVER_IP or MultiplayerManager.target_server_port != MultiplayerManager.BASE_PORT:
		# We're joining a specific server from the server browser
		print("Auto-joining server from browser: %s:%d" % [MultiplayerManager.target_server_host, MultiplayerManager.target_server_port])
		var success = MultiplayerManager.join_as_player_2()
		if not success:
			print("Failed to join server, returning to browser")
			MultiplayerManager.target_server_host = MultiplayerManager.DEFAULT_SERVER_IP
			MultiplayerManager.target_server_port = MultiplayerManager.BASE_PORT
			get_tree().change_scene_to_file("res://scenes/server_browser.tscn")
	elif MultiplayerManager.multiplayer_mode_enabled:
		if MultiplayerManager.host_mode_enabled:
			print("Auto-starting as host from server browser")
			var success = MultiplayerManager.become_host()
			if not success:
				print("Failed to start server, returning to browser")
				get_tree().change_scene_to_file("res://scenes/server_browser.tscn")
		else:
			print("Auto-joining game from server browser")
			var success = MultiplayerManager.join_as_player_2()
			if not success:
				print("Failed to join server, returning to browser")
				get_tree().change_scene_to_file("res://scenes/server_browser.tscn")
	else:
		print("Game Manager: No multiplayer mode set, running in single player")

func _input(event):
	if event.is_action_pressed("ui_cancel"):
		back_to_main_menu()

func add_point(player_id):
	if not scores.has(player_id):
		scores[player_id] = 0
	scores[player_id] += 1
	
	if MultiplayerManager.multiplayer_mode_enabled and multiplayer.is_server():
		sync_score_update.rpc(player_id, scores[player_id])
	else:
		emit_signal("score_updated", player_id, scores[player_id])

func get_score(player_id):
	return scores.get(player_id, 0)

func sync_initial_state_for_player(player_id: int):
	if not multiplayer.is_server():
		return
	
	print("DEBUG GameManager: Syncing initial state for player %d" % player_id)
	print("DEBUG GameManager: Current scores: %s" % scores)
	print("DEBUG GameManager: Current lives: %s" % lives)
	
	await get_tree().create_timer(0.5).timeout
	
	for pid in scores.keys():
		print("DEBUG GameManager: Sending score sync to player %d: player %d has %d points" % [player_id, pid, scores[pid]])
		sync_score_update.rpc_id(player_id, pid, scores[pid])
	
	for pid in lives.keys():
		print("DEBUG GameManager: Sending lives sync to player %d: player %d has %d lives" % [player_id, pid, lives[pid]])
		sync_lives_update.rpc_id(player_id, pid, lives[pid])
	
	for coin_path in collected_coins.keys():
		sync_coin_collected.rpc_id(player_id, coin_path)

func is_coin_collected(coin_path: String) -> bool:
	return collected_coins.has(coin_path)

func mark_coin_collected(coin_path: String):
	collected_coins[coin_path] = true
	if MultiplayerManager.multiplayer_mode_enabled and multiplayer.is_server():
		sync_coin_collected.rpc(coin_path)

func get_lives(player_id):
	if not lives.has(player_id):
		lives[player_id] = MAX_LIVES
	return lives[player_id]

func _show_game_over():	
	var pixel_font = load("res://assets/fonts/PixelOperator8-Bold.ttf")
	
	var canvas_layer = CanvasLayer.new()
	canvas_layer.name = "GameOverLayer"
	canvas_layer.layer = 100
	
	var game_over_label = Label.new()
	game_over_label.text = "GAME OVER"
	game_over_label.name = "GameOverLabel"
	
	if pixel_font:
		game_over_label.add_theme_font_override("font", pixel_font)
	game_over_label.add_theme_font_size_override("font_size", 18)
	game_over_label.add_theme_color_override("font_color", Color.WHITE)
	game_over_label.add_theme_color_override("font_shadow_color", Color.BLACK)
	game_over_label.add_theme_constant_override("shadow_offset_x", 1)
	game_over_label.add_theme_constant_override("shadow_offset_y", 1)
	game_over_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	game_over_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	
	game_over_label.anchors_preset = Control.PRESET_CENTER_LEFT
	game_over_label.anchor_left = 0.5
	game_over_label.anchor_right = 0.5
	game_over_label.anchor_top = 0.5
	game_over_label.anchor_bottom = 0.5
	game_over_label.offset_left = -40
	game_over_label.offset_right = 40
	game_over_label.offset_top = -9
	game_over_label.offset_bottom = 9
	
	canvas_layer.add_child(game_over_label)
	get_tree().current_scene.add_child(canvas_layer)
	
	print("GAME OVER displayed on CanvasLayer!")
	return game_over_label

func _handle_singleplayer_game_over():
	await get_tree().create_timer(3.0).timeout
	back_to_main_menu()

func lose_life(player_id):	
	if not lives.has(player_id):
		lives[player_id] = MAX_LIVES
		print("DEBUG GameManager: Initialized lives for player %d: %d" % [player_id, lives[player_id]])
	
	lives[player_id] -= 1
	print("DEBUG GameManager: Player %d lost a life! Remaining: %d" % [player_id, lives[player_id]])
	
	print("DEBUG GameManager: Emitting lives_updated signal for player %d with %d lives" % [player_id, lives[player_id]])
	lives_updated.emit(player_id, lives[player_id])
	
	print("DEBUG GameManager: Calling sync_lives_update RPC for all clients")
	if (multiplayer and 
		multiplayer.has_multiplayer_peer() and 
		multiplayer.multiplayer_peer != null and
		is_inside_tree()):
		sync_lives_update.rpc(player_id, lives[player_id])
	else:
		print("DEBUG GameManager: Multiplayer not available, skipping RPC")
	
	if lives[player_id] <= 0:
		print("Game Over for player %d!" % player_id)
		emit_signal("game_over_signal", player_id)
		
		if not MultiplayerManager.multiplayer_mode_enabled:
			print("Singleplayer game over - showing GAME OVER")
			game_ending = true
			_show_game_over()
			call_deferred("_handle_singleplayer_game_over")
			return false
		
		if MultiplayerManager.multiplayer_mode_enabled:
			call_deferred("handle_multiplayer_player_death", player_id)
			return false
	
	return true

func handle_multiplayer_player_death(dead_player_id):	
	spectators[dead_player_id] = true
	print("DEBUG: Player %d marked as spectator. Current spectators: %s" % [dead_player_id, str(spectators)])
	
	var living_players = _has_living_players()
	print("DEBUG: Has living players after player %d death: %s" % [dead_player_id, living_players])
	
	if (multiplayer.is_server() and 
		multiplayer.has_multiplayer_peer() and 
		multiplayer.multiplayer_peer != null and
		is_inside_tree()):
		update_spectator_status.rpc(dead_player_id, true)
		become_spectator.rpc_id(dead_player_id, dead_player_id)
	
	if dead_player_id == multiplayer.get_unique_id():
		_become_local_spectator()
	
	_check_all_spectators()

@rpc("authority", "call_local", "reliable")
func update_spectator_status(player_id: int, is_spectator: bool):
	if game_ending:
		print("DEBUG GameManager: Ignoring update_spectator_status - game is ending")
		return
		
	print("Received update_spectator_status RPC: Player %d is_spectator=%s" % [player_id, is_spectator])
	spectators[player_id] = is_spectator
	print("DEBUG: Updated spectators list: %s" % str(spectators))

@rpc("any_peer", "call_local", "reliable")
func become_spectator(dead_player_id):
	if game_ending:
		print("DEBUG GameManager: Ignoring become_spectator - game is ending")
		return
		
	print("Received become_spectator RPC for player %d" % dead_player_id)
	
	if (not is_inside_tree() or 
		not multiplayer.has_multiplayer_peer() or 
		multiplayer.multiplayer_peer == null):
		print("Multiplayer not available, skipping become_spectator")
		return
		
	if dead_player_id == multiplayer.get_unique_id():
		await get_tree().process_frame
		_become_local_spectator()

func _become_local_spectator():
	print("Becoming spectator...")
	
	var local_player = get_tree().get_first_node_in_group("players")
	if local_player:
		local_player.set_collision_mask_value(1, false)
		local_player.set_collision_layer_value(1, false)
		local_player.modulate = Color(1, 1, 1, 0.5)
		
		if local_player.has_method("set_can_move"):
			local_player.set_can_move(false)
	
	if _has_living_players():
		_show_spectator_message()

func _has_living_players() -> bool:
	if not MultiplayerManager.multiplayer_mode_enabled:
		return false
		
	var connected_players = []
	connected_players.append(1)
	
	if multiplayer.has_multiplayer_peer() and multiplayer.multiplayer_peer != null:
		for peer_id in multiplayer.get_peers():
			connected_players.append(peer_id)
	
	print("DEBUG: Checking living players. Connected: %s, Spectators: %s" % [str(connected_players), str(spectators)])
	
	for player_id in connected_players:
		var is_spectator = spectators.has(player_id) and spectators[player_id]
		if not is_spectator:
			print("DEBUG: Player %d is still alive (not spectator)" % player_id)
			return true
	return false

func _show_spectator_message():
	var pixel_font = load("res://assets/fonts/PixelOperator8-Bold.ttf")
	
	var canvas_layer = CanvasLayer.new()
	canvas_layer.name = "SpectatorLayer"
	canvas_layer.layer = 99
	
	var spectator_label = Label.new()
	spectator_label.text = "Spectating..."
	spectator_label.name = "SpectatorLabel"
	
	if pixel_font:
		spectator_label.add_theme_font_override("font", pixel_font)
	spectator_label.add_theme_font_size_override("font_size", 14)
	spectator_label.add_theme_color_override("font_color", Color.YELLOW)
	spectator_label.add_theme_color_override("font_shadow_color", Color.BLACK)
	spectator_label.add_theme_constant_override("shadow_offset_x", 1)
	spectator_label.add_theme_constant_override("shadow_offset_y", 1)
	spectator_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	spectator_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	
	spectator_label.anchors_preset = Control.PRESET_CENTER_LEFT
	spectator_label.anchor_left = 0.5
	spectator_label.anchor_right = 0.5
	spectator_label.anchor_top = 0.5
	spectator_label.anchor_bottom = 0.5
	spectator_label.offset_left = -45
	spectator_label.offset_right = 45
	spectator_label.offset_top = -25
	spectator_label.offset_bottom = -7
	
	canvas_layer.add_child(spectator_label)
	get_tree().current_scene.add_child(canvas_layer)
	
	var timer = get_tree().create_timer(3.0)
	timer.timeout.connect(_remove_spectator_label.bind(spectator_label, canvas_layer))

func _remove_spectator_label(label: Label, canvas_layer: CanvasLayer):
	if label and is_instance_valid(label) and label.is_inside_tree():
		label.queue_free()
	if canvas_layer and is_instance_valid(canvas_layer) and canvas_layer.is_inside_tree():
		canvas_layer.queue_free()
	print("Spectator message removed from CanvasLayer")

func _check_all_spectators():
	if not is_inside_tree():
		print("DEBUG: GameManager not in tree, skipping spectator check")
		return
	
	if (not multiplayer or 
		not multiplayer.has_multiplayer_peer() or 
		multiplayer.multiplayer_peer == null):
		return
	
	if not multiplayer.is_server():
		return
	
	var connected_players = []
	connected_players.append(1)
	
	for peer_id in multiplayer.get_peers():
		connected_players.append(peer_id)
	
	var all_spectators = true
	for player_id in connected_players:
		var is_spectator = spectators.has(player_id) and spectators[player_id]
		if not is_spectator:
			all_spectators = false
			break
	
	if all_spectators and connected_players.size() >= 2:
		_end_multiplayer_game()

func _end_multiplayer_game():
	if (not is_inside_tree() or 
		not multiplayer or 
		not multiplayer.has_multiplayer_peer() or 
		multiplayer.multiplayer_peer == null):
		print("Multiplayer not available, calling end_game_all_spectators locally")
		end_game_all_spectators()
		return
	
	game_ending = true
	print("Game ending flag set to true")
	
	end_game_all_spectators.rpc()
	
	await get_tree().create_timer(2.0).timeout
	
	if is_inside_tree():
		get_tree().change_scene_to_file("res://scenes/main_menu.tscn")

@rpc("authority", "call_local", "reliable")
func end_game_all_spectators():
	if not is_inside_tree():
		return
	game_ending = true
	print("Game ending flag set to true via RPC")
	
	_show_game_over()

	await get_tree().create_timer(3.0).timeout

	if is_inside_tree():
		get_tree().change_scene_to_file("res://scenes/main_menu.tscn")

func become_host():
	print("Become host pressed")
	MultiplayerManager.become_host()
	
func join_as_player_2():
	print("Join as player 2")
	MultiplayerManager.join_as_player_2()

func is_game_ending() -> bool:
	return game_ending

func back_to_main_menu():
	print("Returning to main menu")
	
	game_ending = true

	for child in get_children():
		if child is Timer:
			child.queue_free()
	
	if MultiplayerManager.multiplayer_mode_enabled:
		MultiplayerManager.shutdown_multiplayer()
	
	MultiplayerManager.target_server_host = MultiplayerManager.DEFAULT_SERVER_IP
	MultiplayerManager.target_server_port = MultiplayerManager.BASE_PORT

	await get_tree().process_frame
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
