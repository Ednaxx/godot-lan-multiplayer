extends CharacterBody2D

const SPEED = 130.0
const JUMP_VELOCITY = -300.0

@onready var animated_sprite = $AnimatedSprite2D

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

var direction = 1
var do_jump = false
var _is_on_floor = true
var alive = true
var can_move = true  # Controle para espectador

@export var player_id := 1:
	set(id):
		player_id = id
		%InputSynchronizer.set_multiplayer_authority(id)

func set_can_move(value: bool):
	can_move = value
	if not can_move:
		direction = 0
		do_jump = false

func _ready():

	if multiplayer.get_unique_id() == player_id:
		add_to_group("players")
		$Camera2D.make_current()

		if not get_tree().get_current_scene().has_node("Hud"):
			var hud_scene = preload("res://scenes/HUD.tscn").instantiate()
			get_tree().get_current_scene().call_deferred("add_child", hud_scene)
	else:
		$Camera2D.enabled = false

func _apply_animations(_delta):
	# Flip the Sprite
	if direction > 0:
		animated_sprite.flip_h = false
	elif direction < 0:
		animated_sprite.flip_h = true
	
	if _is_on_floor:
		if direction == 0:
			animated_sprite.play("idle")
		else:
			animated_sprite.play("run")
	else:
		animated_sprite.play("jump")

func _apply_movement_from_input(delta):
	# Add the gravity.
	if not is_on_floor():
		velocity.y += gravity * delta

	# Handle jump.
	if do_jump and is_on_floor():
		velocity.y = JUMP_VELOCITY
		do_jump = false

	# Get the input direction: -1, 0, 1
	direction = %InputSynchronizer.input_direction
	
	# Apply movement
	if direction:
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)

	move_and_slide()

func _physics_process(delta):
	if multiplayer.is_server():
		if not alive && is_on_floor():
			_set_alive()
		
		_is_on_floor = is_on_floor()
		_apply_movement_from_input(delta)
		
	if not multiplayer.is_server() || MultiplayerManager.host_mode_enabled:
		_apply_animations(delta)

func mark_dead():
	alive = false
	$CollisionShape2D.set_deferred("disabled", true)

	if multiplayer.is_server():
		var game_manager = get_tree().get_current_scene().get_node("GameManager")
		if game_manager:
			var still_alive = game_manager.lose_life(player_id)
			if not still_alive:
				return
	
	$RespawnTimer.start()

func _respawn():	
	var game_manager = get_tree().get_current_scene().get_node("GameManager")
	if game_manager and game_manager.is_game_ending():
		return
	
	if (multiplayer.is_server() and 
		multiplayer.has_multiplayer_peer() and 
		multiplayer.multiplayer_peer != null and
		is_inside_tree()):
		sync_respawn_position.rpc(MultiplayerManager.respawn_point)
	
	position = MultiplayerManager.respawn_point
	$CollisionShape2D.set_deferred("disabled", false)

@rpc("any_peer", "call_local")
func sync_respawn_position(respawn_pos: Vector2):
	if not is_inside_tree():
		return
	
	var game_manager = get_tree().get_current_scene().get_node("GameManager")
	if game_manager and game_manager.is_game_ending():
		return
	position = respawn_pos

func _set_alive():
	alive = true
	Engine.time_scale = 1.0

func get_player_id():
	return player_id
