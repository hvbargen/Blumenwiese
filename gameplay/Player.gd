extends Node

const NetworkPlayer = preload("res://network/Player.gd")

var nw_player: NetworkPlayer

func initialize(a_nw_player: NetworkPlayer):
	nw_player = a_nw_player

