@tool
extends Control

var hearts = []
const MAX_LIVES = 3
const HEART_FULL = "♥"
const HEART_EMPTY = "♡"

@export var hearts_spacing: float = 30.0 : set = _set_hearts_spacing
@export var heart_size: int = 24 : set = _set_heart_size

func _set_hearts_spacing(value: float):
	hearts_spacing = value
	if Engine.is_editor_hint():
		_create_hearts(MAX_LIVES)

func _set_heart_size(value: int):
	heart_size = value
	if Engine.is_editor_hint():
		_create_hearts(MAX_LIVES)

func _ready():
	custom_minimum_size = Vector2(120, 40)
	
	if Engine.is_editor_hint():
		_create_hearts(MAX_LIVES)
		return
	
	var gm = get_tree().get_current_scene().get_node("GameManager")
	var player = _get_local_player()
	var player_id = null
	
	if player and player.has_method("get_player_id"):
		player_id = player.get_player_id()
	
	if gm and player_id != null:
		gm.connect("lives_updated", Callable(self, "_on_lives_updated"))
		_create_hearts(gm.get_lives(player_id))

func _get_local_player():
	if not MultiplayerManager.multiplayer_mode_enabled:
		return get_tree().get_current_scene().get_node_or_null("Player")
	else:
		return get_tree().get_first_node_in_group("players")

func _create_hearts(lives_count: int):
	for heart in hearts:
		if heart and is_instance_valid(heart):
			heart.queue_free()
	hearts.clear()
	
	for i in range(MAX_LIVES):
		var heart_label = Label.new()
		heart_label.text = HEART_FULL if i < lives_count else HEART_EMPTY
		heart_label.add_theme_color_override("font_color", Color.RED if i < lives_count else Color.GRAY)
		heart_label.add_theme_font_size_override("font_size", heart_size)
		heart_label.position = Vector2(i * hearts_spacing, 0)
		
		add_child(heart_label)
		hearts.append(heart_label)

func _on_lives_updated(player_id, new_lives):
	var player = _get_local_player()
	if player and player.has_method("get_player_id") and player.get_player_id() == player_id:
		_update_hearts_display(new_lives)

func _update_hearts_display(lives_count: int):
	print("Updating hearts display: %d lives" % lives_count)
	
	for i in range(hearts.size()):
		if hearts[i] and is_instance_valid(hearts[i]):
			if i < lives_count:
				hearts[i].text = HEART_FULL
				hearts[i].add_theme_color_override("font_color", Color.RED)
			else:
				hearts[i].text = HEART_EMPTY
				hearts[i].add_theme_color_override("font_color", Color.GRAY)
