extends Area2D

@onready var timer = $Timer

func _on_body_entered(body: Node2D) -> void:	

	if body.is_in_group("players"):
		if multiplayer.is_server():
			_multiplayer_dead(body)
		else:
			request_player_death.rpc_id(1, body.name)
	elif body.is_in_group("player"):
		_singleplayer_dead(body)

func _singleplayer_dead(body):

	if body.has_method("mark_dead"):
		body.mark_dead()

@rpc("any_peer")
func request_player_death(player_name):

	if not multiplayer.is_server():
		return
		
	var players_node = get_tree().get_current_scene().get_node("Players")
	var player_path = NodePath(player_name)

	if players_node.has_node(player_path):
		var player = players_node.get_node(player_path)

		if player and player.alive:
			_multiplayer_dead(player)

func _multiplayer_dead(body):

	if body.alive:
		Engine.time_scale = 0.5
		body.mark_dead()

func _on_timer_timeout():
	Engine.time_scale = 1.0
