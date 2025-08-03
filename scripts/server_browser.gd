extends Control

const DISCOVERY_PORT = 8081
const BROADCAST_INTERVAL = 2.0
const SERVER_TIMEOUT = 10.0

var udp_socket: PacketPeerUDP
var discovered_servers = {}
var server_list_item_scene = preload("res://scenes/server_list_item.tscn")

@onready var server_list = %ServerList
@onready var no_servers_label = %NoServersLabel
@onready var status_label = %StatusLabel

func _ready():
	_setup_discovery()
	_refresh_servers()

func _setup_discovery():
	udp_socket = PacketPeerUDP.new()
	var bind_result = udp_socket.bind(DISCOVERY_PORT)
	
	if bind_result == OK:
		print("Server browser: Successfully bound to port %d for discovery" % DISCOVERY_PORT)
		status_label.text = "Searching for servers..."
	else:
		print("Server browser: Failed to bind to port %d: %s" % [DISCOVERY_PORT, bind_result])
		status_label.text = "Error: Failed to start server discovery"

func _process(_delta):
	_check_for_server_broadcasts()
	_cleanup_old_servers()

func _check_for_server_broadcasts():
	if udp_socket.get_available_packet_count() > 0:
		print("Server browser: Received %d packets" % udp_socket.get_available_packet_count())
		var packet = udp_socket.get_packet()
		var sender_ip = udp_socket.get_packet_ip()
		var sender_port = udp_socket.get_packet_port()
		
		var message = packet.get_string_from_utf8()
		print("Server browser: Received message from %s:%d: %s" % [sender_ip, sender_port, message])
		_process_server_broadcast(message, sender_ip, sender_port)

func _process_server_broadcast(message: String, ip: String, _port: int):
	print("Server browser: Processing broadcast: %s from %s" % [message, ip])
	# Expected format: "SERVER_AVAILABLE:port:player_count:max_players:server_name"
	var parts = message.split(":")
	if parts.size() >= 5 and parts[0] == "SERVER_AVAILABLE":
		var server_port = int(parts[1])
		var player_count = int(parts[2])
		var max_players = int(parts[3])
		var server_name = parts[4]
		
		print("Server browser: Parsed server - Port: %d, Players: %d/%d, Name: %s" % [server_port, player_count, max_players, server_name])
		
		# Only show servers that have available slots (less than max players)
		if player_count < max_players:
			# Use port as the unique key to avoid duplicates
			var server_key = str(server_port)
			
			# Check if we already have this server
			if server_key in discovered_servers:
				var existing_server = discovered_servers[server_key]
				# Prefer non-localhost IP addresses
				if ip != "127.0.0.1" and existing_server.ip == "127.0.0.1":
					print("Server browser: Updating server %s from localhost to %s" % [server_key, ip])
					existing_server.ip = ip
				# Update last seen time
				existing_server.last_seen = Time.get_unix_time_from_system()
				existing_server.player_count = player_count
			else:
				# New server
				discovered_servers[server_key] = {
					"ip": ip,
					"port": server_port,
					"player_count": player_count,
					"max_players": max_players,
					"server_name": server_name,
					"last_seen": Time.get_unix_time_from_system()
				}
				print("Server browser: Added new server %s to list" % server_key)
			
			_update_server_list()
		else:
			print("Server browser: Server is full (%d/%d), not adding to list" % [player_count, max_players])
	else:
		print("Server browser: Invalid broadcast format or not a server broadcast")

func _cleanup_old_servers():
	var current_time = Time.get_unix_time_from_system()
	var servers_to_remove = []
	
	for server_key in discovered_servers:
		var server = discovered_servers[server_key]
		if current_time - server.last_seen > SERVER_TIMEOUT:
			servers_to_remove.append(server_key)
	
	for server_key in servers_to_remove:
		discovered_servers.erase(server_key)
	
	if servers_to_remove.size() > 0:
		_update_server_list()

func _update_server_list():
	# Clear existing server list items
	for child in server_list.get_children():
		child.queue_free()
	
	# Show/hide no servers label
	if discovered_servers.is_empty():
		no_servers_label.visible = true
		status_label.text = "No available servers found."
	else:
		no_servers_label.visible = false
		status_label.text = "Found %d available server(s)" % discovered_servers.size()
		
		# Add server list items
		for server_key in discovered_servers:
			var server = discovered_servers[server_key]
			_add_server_list_item(server)

func _add_server_list_item(server_info: Dictionary):
	var item = server_list_item_scene.instantiate()
	server_list.add_child(item)
	
	# Configure the server list item
	item.setup_server_info(server_info)
	item.join_requested.connect(_on_join_server_requested)

func _on_join_server_requested(server_info: Dictionary):
	print("Attempting to join server: %s:%d" % [server_info.ip, server_info.port])
	
	# Set the target server info in MultiplayerManager
	MultiplayerManager.target_server_host = server_info.ip
	MultiplayerManager.target_server_port = server_info.port
	MultiplayerManager.multiplayer_mode_enabled = true
	MultiplayerManager.host_mode_enabled = false
	
	# Switch to game scene and join as player 2
	get_tree().change_scene_to_file("res://scenes/game.tscn")

func _refresh_servers():
	discovered_servers.clear()
	_update_server_list()
	status_label.text = "Refreshing server list..."

func _on_refresh_pressed():
	_refresh_servers()

func _on_host_pressed():
	print("Starting new server...")
	
	# Reset to default settings for hosting
	MultiplayerManager.target_server_host = MultiplayerManager.DEFAULT_SERVER_IP
	MultiplayerManager.target_server_port = MultiplayerManager.BASE_PORT
	MultiplayerManager.multiplayer_mode_enabled = true
	MultiplayerManager.host_mode_enabled = true
	
	# Switch to game scene and start as host
	get_tree().change_scene_to_file("res://scenes/game.tscn")

func _on_back_pressed():
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")

func _exit_tree():
	if udp_socket:
		udp_socket.close()
