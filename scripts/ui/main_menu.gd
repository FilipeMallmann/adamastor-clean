extends Control


func _on_btn_new_button_down() -> void:
	get_tree().change_scene_to_file("res://scenes/main_game.tscn")


func _on_btn_quit_button_down() -> void:
	get_tree().quit()
