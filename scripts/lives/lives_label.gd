extends Label

const MAX_LIVES = 3

var hearts_display = ""
var heart_textures = []

func _ready():
	# Criar texturas dos corações programaticamente
	_create_heart_textures()
	
	# Configurar label como container para sprites
	clip_contents = false
	
	print("DEBUG Lives: MultiplayerManager.multiplayer_mode_enabled = %s" % MultiplayerManager.multiplayer_mode_enabled)
	if MultiplayerManager.multiplayer_mode_enabled:
		print("DEBUG Lives: multiplayer.get_unique_id() = %s" % multiplayer.get_unique_id())
	
	# Para multiplayer, aguardar o player aparecer
	if MultiplayerManager.multiplayer_mode_enabled:
		_wait_for_player()
	else:
		_initialize_lives_system()

func _wait_for_player():
	print("DEBUG Lives: Waiting for player to be added...")
	# Tentar encontrar o player a cada frame até encontrar
	var attempts = 0
	while attempts < 300:  # 5 segundos no máximo (300 frames a 60fps)
		await get_tree().process_frame
		var player = _get_local_player()
		if player and player.has_method("get_player_id"):
			print("DEBUG Lives: Player found after %d attempts!" % attempts)
			_initialize_lives_system()
			return
		attempts += 1
	
	print("DEBUG Lives: Could not find player after 5 seconds, using fallback")
	_initialize_lives_system()

func _initialize_lives_system():
	var gm = get_tree().get_current_scene().get_node("GameManager")
	var player = _get_local_player()
	var player_id = null
	
	if player and player.has_method("get_player_id"):
		player_id = player.get_player_id()
		print("DEBUG Lives: Found player with ID = %s" % player_id)
	else:
		print("DEBUG Lives: No player found or player has no get_player_id method")
	
	if gm and player_id != null:
		gm.connect("lives_updated", Callable(self, "_on_lives_updated"))
		var current_lives = gm.get_lives(player_id)
		print("DEBUG Lives: Initial lives for player %s = %s" % [player_id, current_lives])
		_on_lives_updated(player_id, current_lives)

func _create_heart_textures():
	# Criar coração pixelado vermelho (cheio) com borda mais grossa
	var heart_full = ImageTexture.new()
	var img_full = Image.create(16, 16, false, Image.FORMAT_RGBA8)
	
	# Desenhar coração pixelado vermelho com borda preta mais grossa
	var red = Color.RED
	var black = Color.BLACK
	var transparent = Color.TRANSPARENT
	
	# Pattern do coração pixelado (16x16) com borda mais grossa
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
	
	# Aplicar pattern para coração cheio
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
	
	# Criar coração vazio (só borda preta)
	var heart_empty = ImageTexture.new()
	var img_empty = Image.create(16, 16, false, Image.FORMAT_RGBA8)
	
	# Aplicar pattern para coração vazio (só borda)
	for y in range(16):
		for x in range(16):
			var pixel = heart_pattern[y][x]
			if pixel == 0:
				img_empty.set_pixel(x, y, transparent)
			elif pixel == 1:
				img_empty.set_pixel(x, y, black)
			elif pixel == 2:
				img_empty.set_pixel(x, y, transparent)  # Interior transparente
	
	heart_empty.set_image(img_empty)
	
	heart_textures = [heart_empty, heart_full]

func _get_local_player():
	# Para singleplayer, pega o nó Player direto
	if not MultiplayerManager.multiplayer_mode_enabled:
		return get_tree().get_current_scene().get_node_or_null("Player")
	else:
		# Para multiplayer, pega o player que pertence a este cliente
		var players = get_tree().get_nodes_in_group("players")
		var my_id = multiplayer.get_unique_id()
		
		print("DEBUG Lives: Looking for player with ID %s among %d players" % [my_id, players.size()])
		
		for player in players:
			if player.has_method("get_player_id"):
				var pid = player.get_player_id()
				print("DEBUG Lives: Found player with ID %s" % pid)
				if pid == my_id:
					print("DEBUG Lives: This is my player!")
					return player
		
		print("DEBUG Lives: Could not find my player, using fallback")
		# Fallback: se não encontrar, pega o primeiro (para compatibilidade)
		return get_tree().get_first_node_in_group("players")

func _on_lives_updated(player_id, new_lives):
	print("DEBUG Lives: _on_lives_updated called - player_id=%s, new_lives=%s" % [player_id, new_lives])
	var player = _get_local_player()
	if player and player.has_method("get_player_id"):
		var my_player_id = player.get_player_id()
		print("DEBUG Lives: My player ID = %s, comparing with %s" % [my_player_id, player_id])
		if my_player_id == player_id:
			print("DEBUG Lives: Updating hearts display for my player")
			_update_hearts_display(new_lives)
		else:
			print("DEBUG Lives: Ignoring update for other player")
	else:
		print("DEBUG Lives: Could not get local player or player_id")

func _update_hearts_display(lives_count: int):
	# Limpar sprites existentes
	for child in get_children():
		if child is TextureRect:
			child.queue_free()
	
	# Criar sprites dos corações (100% maior - dobro do tamanho)
	for i in range(MAX_LIVES):
		var heart_sprite = TextureRect.new()
		heart_sprite.texture = heart_textures[1 if i < lives_count else 0]
		heart_sprite.position = Vector2(i * 36, 0)  # Espaçamento reduzido para 36 pixels (melhor diagramação)
		heart_sprite.size = Vector2(32, 32)  # Tamanho dobrado para 32x32 (100% maior que 16x16)
		heart_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST  # Manter pixelado
		heart_sprite.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL  # Manter proporção
		add_child(heart_sprite)
	
	# Esconder o texto do label
	text = ""
