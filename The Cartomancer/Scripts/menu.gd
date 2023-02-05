extends Control

onready var Menu_Music = $Music
onready var sfx = $SFX
onready var animation = $Sprite6/AnimationPlayer

# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	Menu_Music.play(1)
	animation.play("Idle")
	$VBoxContainer/StartButton.grab_focus()


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass


func _on_StartButton_pressed():
	sfx.play()
	yield(sfx, "finished")
	get_tree().change_scene("res://Scenes/main.tscn")


func _on_OptionsButton_pressed():
	pass


func _on_QuitButton_pressed():
	sfx.play()
	yield(sfx, "finished")
	get_tree().quit()
