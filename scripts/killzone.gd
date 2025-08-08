extends Area2D

@onready var timer = $Timer

func _on_body_entered(body: Node2D) -> void:
	print("[Killzone] Body entered: %s, in group 'player': %s, in group 'players': %s" % [body.name, body.is_in_group("player"), body.is_in_group("players")])
	
	# Multiplayer: notifica o servidor sobre a morte
	if body.is_in_group("players"):
		print("[Killzone] Multiplayer player detected! multiplayer.is_server(): %s" % multiplayer.is_server())
		if multiplayer.is_server():
			print("[Killzone] Server - calling _multiplayer_dead for: %s" % body.name)
			_multiplayer_dead(body)
		else:
			print("[Killzone] Client - notifying server about death of: %s" % body.name)
			# Cliente notifica o servidor sobre a morte
			request_player_death.rpc_id(1, body.name)
	# Singleplayer: processa localmente
	elif body.is_in_group("player"):
		print("[Killzone] Singleplayer player detected!")
		_singleplayer_dead(body)

func _singleplayer_dead(body):
	print("[Killzone] _singleplayer_dead called for: %s" % body.name)
	if body.has_method("mark_dead"):
		print("[Killzone] Calling mark_dead on: %s" % body.name)
		body.mark_dead()
	else:
		print("[Killzone] ERROR: Body %s does not have mark_dead method!" % body.name)

@rpc("any_peer")
func request_player_death(player_name):
	print("[Killzone] RPC request_player_death received! player_name: %s, is_server: %s" % [player_name, multiplayer.is_server()])
	if not multiplayer.is_server():
		print("[Killzone] ERROR: RPC received on client, should only be on server!")
		return
		
	var players_node = get_tree().get_current_scene().get_node("Players")
	print("[Killzone] Looking for player %s in Players node..." % player_name)
	var player_path = NodePath(player_name)
	if players_node.has_node(player_path):
		var player = players_node.get_node(player_path)
		print("[Killzone] Found player: %s, alive: %s" % [player.name, player.alive])
		if player and player.alive:
			print("[Killzone] Processing death for player: %s" % player.name)
			_multiplayer_dead(player)
		else:
			print("[Killzone] Player is null or already dead")
	else:
		print("[Killzone] ERROR: Player %s not found in Players node!" % player_name)

func _multiplayer_dead(body):
	print("[Killzone] _multiplayer_dead called for: %s" % body.name)
	print("[Killzone] Body alive: %s" % body.alive)
	print("[Killzone] Body has mark_dead method: %s" % body.has_method("mark_dead"))
	if body.alive:
		print("[Killzone] Body is alive, proceeding with death...")
		Engine.time_scale = 0.5
		print("[Killzone] Calling mark_dead on: %s" % body.name)
		body.mark_dead()
	else:
		print("[Killzone] Body is already dead, skipping...")

func _on_timer_timeout():
	Engine.time_scale = 1.0
	# Timer agora só é usado para multiplayer
	# Singleplayer gerencia respawn internamente
