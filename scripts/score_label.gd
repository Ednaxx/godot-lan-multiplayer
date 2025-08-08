extends Label    

func _ready():
    if MultiplayerManager.multiplayer_mode_enabled:
        _wait_for_player()
    else:
        _initialize_score_system()

func _wait_for_player():
    var attempts = 0
    while attempts < 300:
        await get_tree().process_frame
        var player = _get_local_player()
        if player and player.has_method("get_player_id"):
            _initialize_score_system()
            return
        attempts += 1
    
    _initialize_score_system()

func _initialize_score_system():
    var gm = get_tree().get_current_scene().get_node("GameManager")
    var player = _get_local_player()
    var player_id = null
    
    if player and player.has_method("get_player_id"):
        player_id = player.get_player_id()
    
    if gm and player_id != null:
        gm.connect("score_updated", Callable(self, "_on_score_updated"))
        _on_score_updated(player_id, gm.get_score(player_id))

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

func _on_score_updated(player_id, new_score):
    var player = _get_local_player()
    if player and player.has_method("get_player_id") and player.get_player_id() == player_id:
        text = str(new_score) + " Points"
