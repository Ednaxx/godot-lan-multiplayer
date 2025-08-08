@tool  # Permite edição no editor
extends Control

var hearts = []
const MAX_LIVES = 3
const HEART_FULL = "♥"
const HEART_EMPTY = "♡"

@export var hearts_spacing: float = 30.0 : set = _set_hearts_spacing  # Espaçamento entre corações - editável no editor
@export var heart_size: int = 24 : set = _set_heart_size  # Tamanho da fonte - editável no editor

# Funções para atualizar em tempo real no editor
func _set_hearts_spacing(value: float):
	hearts_spacing = value
	if Engine.is_editor_hint():
		_create_hearts(MAX_LIVES)

func _set_heart_size(value: int):
	heart_size = value
	if Engine.is_editor_hint():
		_create_hearts(MAX_LIVES)

func _ready():
	# Definir um tamanho mínimo para visualização no editor
	custom_minimum_size = Vector2(120, 40)
	
	# No editor, criar corações de exemplo para visualização
	if Engine.is_editor_hint():
		_create_hearts(MAX_LIVES)
		return
	
	# Em runtime, NÃO forçar posição - usar a posição definida no editor
	# (Removido o código que forçava posição no canto superior direito)
	
	# Conectar aos sinais do GameManager
	var gm = get_tree().get_current_scene().get_node("GameManager")
	var player = _get_local_player()
	var player_id = null
	
	if player and player.has_method("get_player_id"):
		player_id = player.get_player_id()
	
	if gm and player_id != null:
		gm.connect("lives_updated", Callable(self, "_on_lives_updated"))
		# Inicializar corações
		_create_hearts(gm.get_lives(player_id))

func _get_local_player():
	# Para singleplayer, pega o nó Player direto
	if not MultiplayerManager.multiplayer_mode_enabled:
		return get_tree().get_current_scene().get_node_or_null("Player")
	else:
		# Para multiplayer, pega da group "players"
		return get_tree().get_first_node_in_group("players")

func _create_hearts(lives_count: int):
	# Limpar corações existentes
	for heart in hearts:
		if heart and is_instance_valid(heart):
			heart.queue_free()
	hearts.clear()
	
	# Criar novos corações como Labels
	for i in range(MAX_LIVES):
		var heart_label = Label.new()
		heart_label.text = HEART_FULL if i < lives_count else HEART_EMPTY
		heart_label.add_theme_color_override("font_color", Color.RED if i < lives_count else Color.GRAY)
		heart_label.add_theme_font_size_override("font_size", heart_size)
		# Usar o espaçamento configurável
		heart_label.position = Vector2(i * hearts_spacing, 0)
		
		add_child(heart_label)
		hearts.append(heart_label)
	
	if not Engine.is_editor_hint():
		print("Created %d hearts for %d lives" % [hearts.size(), lives_count])

func _on_lives_updated(player_id, new_lives):
	var player = _get_local_player()
	if player and player.has_method("get_player_id") and player.get_player_id() == player_id:
		_update_hearts_display(new_lives)

func _update_hearts_display(lives_count: int):
	print("Updating hearts display: %d lives" % lives_count)
	
	for i in range(hearts.size()):
		if hearts[i] and is_instance_valid(hearts[i]):
			if i < lives_count:
				# Coração cheio
				hearts[i].text = HEART_FULL
				hearts[i].add_theme_color_override("font_color", Color.RED)
			else:
				# Coração vazio
				hearts[i].text = HEART_EMPTY
				hearts[i].add_theme_color_override("font_color", Color.GRAY)
