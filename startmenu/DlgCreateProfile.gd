extends WindowDialog

var player_profile: PlayerProfile = null

signal profile_created(player_profile)
signal profile_edited(player_profile)

func _on_BtnCancel_pressed():
	print("Cancel")
	hide()

func _on_BtnOK_pressed():
	print("OK")
	var is_new = (player_profile == null)
	if is_new:
		player_profile = PlayerProfile.new()
		player_profile.global_id = "%s-%d-%d" % [OS.get_unique_id(), OS.get_ticks_msec(), OS.get_unix_time()]
	player_profile.nickname = $VBoxContainer/GridContainer/Nickname.text
	player_profile.fav_color1 = $VBoxContainer/GridContainer/FavCol1.color
	player_profile.fav_color2 = $VBoxContainer/GridContainer/FavCol2.color
	player_profile.save_local()
	if is_new:
		emit_signal("profile_created", player_profile)
	else:
		emit_signal("profile_edited", player_profile)
	hide()

func initialize(a_player_profile: PlayerProfile)	:
	player_profile = a_player_profile
	if player_profile == null:
		window_title = "Create a new local profile"
		$VBoxContainer/GridContainer/Nickname.text = ""
		$VBoxContainer/GridContainer/FavCol1.color = Color.red
		$VBoxContainer/GridContainer/FavCol2.color = Color.yellow
	else:
		window_title = "Edit local profile %s" % player_profile.nickname
		$VBoxContainer/GridContainer/Nickname.text = player_profile.nickname
		$VBoxContainer/GridContainer/FavCol1.color = player_profile.fav_color1
		$VBoxContainer/GridContainer/FavCol2.color = player_profile.fav_color2
