extends Node2D

const SPEED = 60

var direction = 1

@onready var ray_cast_right = $RayCastRight
@onready var ray_cast_left = $RayCastLeft
@onready var animated_sprite = $AnimatedSprite2D

var last_sent_position = Vector2.ZERO

func _process(delta):
	if not MultiplayerManager.multiplayer_mode_enabled or (multiplayer.has_multiplayer_peer() and multiplayer.is_server()):
		if ray_cast_right.is_colliding():
			direction = -1
			animated_sprite.flip_h = true
		if ray_cast_left.is_colliding():
			direction = 1
			animated_sprite.flip_h = false
		position.x += direction * SPEED * delta
		
		var game_manager = get_tree().get_current_scene().get_node("GameManager")
		if game_manager and game_manager.is_game_ending():
			return		

		if (MultiplayerManager.multiplayer_mode_enabled and 
			multiplayer.has_multiplayer_peer() and 
			multiplayer.multiplayer_peer != null and
			is_inside_tree()):
			if position.distance_to(last_sent_position) > 0.5:
				sync_position.rpc(position)
				last_sent_position = position

@rpc("any_peer", "call_local", "reliable")
func sync_position(new_pos: Vector2):
	var game_manager = get_tree().get_current_scene().get_node("GameManager")
	if game_manager and game_manager.is_game_ending():
		return

	if (MultiplayerManager.multiplayer_mode_enabled and 
		multiplayer.has_multiplayer_peer() and 
		multiplayer.multiplayer_peer != null and
		not multiplayer.is_server()):
		position = new_pos
