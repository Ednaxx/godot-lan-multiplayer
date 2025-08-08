extends CharacterBody2D

const SPEED = 130.0
const JUMP_VELOCITY = -300.0

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

var alive = true
var respawning = false
var can_move = true

func set_can_move(value: bool):
	can_move = value

func get_player_id():
	return 1

func mark_dead():
	print("[Player] mark_dead called!")
	
	if respawning:
		return
	
	alive = false
	$CollisionShape2D.set_deferred("disabled", true)
	
	var game_manager = get_tree().get_current_scene().get_node("GameManager")
	if game_manager:
		var still_alive = game_manager.lose_life(get_player_id())
		if not still_alive:
			print("Singleplayer Game Over - returning to menu")
			return
		else:
			respawning = true
			var respawn_timer = Timer.new()
			add_child(respawn_timer)
			respawn_timer.wait_time = 2.0
			respawn_timer.one_shot = true
			respawn_timer.timeout.connect(_singleplayer_respawn)
			respawn_timer.start()

func _singleplayer_respawn():	
	position = Vector2(50, -100)
	
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().process_frame
	
	alive = true
	$CollisionShape2D.set_deferred("disabled", false)
	Engine.time_scale = 1.0
	
	await get_tree().create_timer(0.5).timeout
	respawning = false

func _ready():
	if MultiplayerManager.multiplayer_mode_enabled:
		add_to_group("players")
		print("[Player] Added to 'players' group (multiplayer)")
	else:
		add_to_group("player")
		print("[Player] Added to 'player' group (singleplayer)")

@onready var animated_sprite = $AnimatedSprite2D

func _physics_process(delta):
	# Add the gravity.
	if not is_on_floor():
		velocity.y += gravity * delta

	# Handle jump.
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Get the input direction: -1, 0, 1
	var direction = Input.get_axis("move_left", "move_right")
	
	# Flip the Sprite
	if direction > 0:
		animated_sprite.flip_h = false
	elif direction < 0:
		animated_sprite.flip_h = true
	
	# Play animations
	if is_on_floor():
		if direction == 0:
			animated_sprite.play("idle")
		else:
			animated_sprite.play("run")
	else:
		animated_sprite.play("jump")
	
	# Apply movement
	if direction:
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)

	move_and_slide()
