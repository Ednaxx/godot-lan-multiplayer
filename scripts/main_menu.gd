extends Control

func _ready():
	pass

func _on_singleplayer_pressed():
	print("Starting singleplayer game")
	MultiplayerManager.multiplayer_mode_enabled = false
	MultiplayerManager.host_mode_enabled = false
	get_tree().change_scene_to_file("res://scenes/game.tscn")

func _on_host_pressed():
	print("Starting host game")
	MultiplayerManager.multiplayer_mode_enabled = true
	MultiplayerManager.host_mode_enabled = true
	get_tree().change_scene_to_file("res://scenes/game.tscn")

func _on_join_pressed():
	print("Joining multiplayer game")
	MultiplayerManager.multiplayer_mode_enabled = true
	MultiplayerManager.host_mode_enabled = false
	get_tree().change_scene_to_file("res://scenes/game.tscn")

func _on_quit_pressed():
	print("Quitting game")
	get_tree().quit()
