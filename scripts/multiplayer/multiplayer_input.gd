extends MultiplayerSynchronizer

@onready var player = $".."

var input_direction 

func _ready():
	
	if get_multiplayer_authority() != multiplayer.get_unique_id():
		set_process(false)
		set_physics_process(false)
	
	input_direction = Input.get_axis("move_left", "move_right")

func _physics_process(_delta):
	if player.can_move:
		input_direction = Input.get_axis("move_left", "move_right")
	else:
		input_direction = 0

func _process(_delta):
	if player.can_move and Input.is_action_just_pressed("jump"):
		jump.rpc()

@rpc("call_local")
func jump():
	if multiplayer.is_server():
		player.do_jump = true
