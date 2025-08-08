extends Label

const MAX_LIVES = 3

var hearts_display = ""
var heart_textures = []

func _ready():
	_create_heart_textures()
	clip_contents = false

	if MultiplayerManager.multiplayer_mode_enabled:
		_wait_for_player()
	else:
		_initialize_lives_system()

func _wait_for_player():
	var attempts = 0
	while attempts < 300:
		await get_tree().process_frame
		var player = _get_local_player()
		if player and player.has_method("get_player_id"):
			_initialize_lives_system()
			return
		attempts += 1
	_initialize_lives_system()

func _initialize_lives_system():
	var gm = get_tree().get_current_scene().get_node("GameManager")
	var player = _get_local_player()
	var player_id = null
	
	if player and player.has_method("get_player_id"):
		player_id = player.get_player_id()
	
	if gm and player_id != null:
		gm.connect("lives_updated", Callable(self, "_on_lives_updated"))
		var current_lives = gm.get_lives(player_id)
		_on_lives_updated(player_id, current_lives)

func _create_heart_textures():
	var heart_full = ImageTexture.new()
	var img_full = Image.create(16, 16, false, Image.FORMAT_RGBA8)
	var red = Color.RED
	var black = Color.BLACK
	var transparent = Color.TRANSPARENT
	var heart_pattern = [
		[0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0],
		[0,1,1,1,1,0,0,0,0,0,1,1,1,1,0,0],
		[1,1,2,2,2,1,0,0,0,1,2,2,2,1,1,0],
		[1,2,2,2,2,2,1,0,1,2,2,2,2,2,1,0],
		[1,2,2,2,2,2,2,1,2,2,2,2,2,2,1,0],
		[1,2,2,2,2,2,2,2,2,2,2,2,2,2,1,0],
		[1,2,2,2,2,2,2,2,2,2,2,2,2,2,1,0],
		[0,1,2,2,2,2,2,2,2,2,2,2,2,1,0,0],
		[0,0,1,2,2,2,2,2,2,2,2,2,1,0,0,0],
		[0,0,1,2,2,2,2,2,2,2,2,2,1,0,0,0],
		[0,0,0,1,2,2,2,2,2,2,2,1,0,0,0,0],
		[0,0,0,0,1,2,2,2,2,2,1,0,0,0,0,0],
		[0,0,0,0,0,1,2,2,2,1,0,0,0,0,0,0],
		[0,0,0,0,0,0,1,2,1,0,0,0,0,0,0,0],
		[0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0],
		[0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0]
	]
	
	for y in range(16):
		for x in range(16):
			var pixel = heart_pattern[y][x]
			if pixel == 0:
				img_full.set_pixel(x, y, transparent)
			elif pixel == 1:
				img_full.set_pixel(x, y, black)
			elif pixel == 2:
				img_full.set_pixel(x, y, red)
	
	heart_full.set_image(img_full)

	var heart_empty = ImageTexture.new()
	var img_empty = Image.create(16, 16, false, Image.FORMAT_RGBA8)
	
	for y in range(16):
		for x in range(16):
			var pixel = heart_pattern[y][x]
			if pixel == 0:
				img_empty.set_pixel(x, y, transparent)
			elif pixel == 1:
				img_empty.set_pixel(x, y, black)
			elif pixel == 2:
				img_empty.set_pixel(x, y, transparent)
	
	heart_empty.set_image(img_empty)
	
	heart_textures = [heart_empty, heart_full]

func _get_local_player():
	if not MultiplayerManager.multiplayer_mode_enabled:
		return get_tree().get_current_scene().get_node_or_null("Player")
	else:
		var players = get_tree().get_nodes_in_group("players")
		var my_id = multiplayer.get_unique_id()
		
		for player in players:
			if player.has_method("get_player_id"):
				var pid = player.get_player_id()
				if pid == my_id:
					return player
		return get_tree().get_first_node_in_group("players")

func _on_lives_updated(player_id, new_lives):
	var player = _get_local_player()
	if player and player.has_method("get_player_id"):
		var my_player_id = player.get_player_id()
		if my_player_id == player_id:
			_update_hearts_display(new_lives)

func _update_hearts_display(lives_count: int):
	for child in get_children():
		if child is TextureRect:
			child.queue_free()
	
	for i in range(MAX_LIVES):
		var heart_sprite = TextureRect.new()
		heart_sprite.texture = heart_textures[1 if i < lives_count else 0]
		heart_sprite.position = Vector2(i * 36, 0)
		heart_sprite.size = Vector2(32, 32)
		heart_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		heart_sprite.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
		add_child(heart_sprite)
	text = ""
