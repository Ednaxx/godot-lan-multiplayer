extends Node

var score = 0

func _ready():
	if OS.has_feature("dedicated_server"):
		print("Starting dedicated server...")
		MultiplayerManager.become_host()
	elif MultiplayerManager.multiplayer_mode_enabled:
		if MultiplayerManager.host_mode_enabled:
			print("Auto-starting as host from main menu")
			MultiplayerManager.become_host()
		else:
			print("Auto-joining game from main menu")
			MultiplayerManager.join_as_player_2()

func _input(event):
	if event.is_action_pressed("ui_cancel"):
		back_to_main_menu()

func add_point():
	score += 1

func become_host():
	print("Become host pressed")
	MultiplayerManager.become_host()
	
func join_as_player_2():
	print("Join as player 2")
	MultiplayerManager.join_as_player_2()

func back_to_main_menu():
	print("Returning to main menu")
	if MultiplayerManager.multiplayer_mode_enabled:
		multiplayer.multiplayer_peer = null
		MultiplayerManager.multiplayer_mode_enabled = false
		MultiplayerManager.host_mode_enabled = false
	
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
