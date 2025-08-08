extends Area2D

@onready var game_manager = %GameManager
@onready var animation_player = $AnimationPlayer

func _ready():
	if (MultiplayerManager.multiplayer_mode_enabled and 
		game_manager and 
		game_manager.is_coin_collected(get_path())):
		_handle_collection()

func _on_body_entered(body):
	if game_manager and game_manager.is_coin_collected(get_path()):
		return
		
	if body.has_method("get_player_id"):
		var player_id = body.get_player_id()
		game_manager.add_point(player_id)
		
		game_manager.mark_coin_collected(get_path())
		
		_handle_collection()

func _handle_collection():
	animation_player.play("pickup")
