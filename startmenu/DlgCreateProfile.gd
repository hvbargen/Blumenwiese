extends WindowDialog

var nw_player: NetworkPlayer = null

signal profile_created(nw_player)
signal profile_edited(nw_player)

func _on_BtnCancel_pressed():
	print("Cancel")
	hide()

func _on_BtnOK_pressed():
	print("OK")
	var is_new = (nw_player == null)
	if is_new:
		nw_player = NetworkPlayer.new()
		nw_player.global_id = "%s-%d-%d" % [OS.get_unique_id(), OS.get_ticks_msec(), OS.get_unix_time()]
	nw_player.nickname = $VBoxContainer/GridContainer/Nickname.text
	nw_player.fav_color1 = $VBoxContainer/GridContainer/FavCol1.color
	nw_player.fav_color2 = $VBoxContainer/GridContainer/FavCol2.color
	nw_player.save_local()
	if is_new:
		emit_signal("profile_created", nw_player)
	else:
		emit_signal("profile_edited", nw_player)
	hide()

func initialize(a_nw_player: NetworkPlayer)	:
	nw_player = a_nw_player
	if nw_player == null:
		window_title = "Create a new local profile"
		$VBoxContainer/GridContainer/Nickname.text = ""
		$VBoxContainer/GridContainer/FavCol1.color = Color.red
		$VBoxContainer/GridContainer/FavCol2.color = Color.yellow
	else:
		window_title = "Edit local profile %s" % nw_player.nickname
		$VBoxContainer/GridContainer/Nickname.text = nw_player.nickname
		$VBoxContainer/GridContainer/FavCol1.color = nw_player.fav_color1
		$VBoxContainer/GridContainer/FavCol2.color = nw_player.fav_color2
