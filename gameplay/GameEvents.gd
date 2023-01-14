extends Node

# class_name GameEvents

# When a player changes color
signal color_changed(global_id, color, second_color)

# When a player was added to the lobby
signal player_entered_lobby(ap)

# When a player was removed from the lobby
signal player_left_lobby(ap)

# When an existing player has changed some attributes
signal player_modified(ap)

# When this machine changed its network role, eg when it connects to a server.
signal ig_peer_id_changed(old_ig_peer_id, new_ig_peer_id)
