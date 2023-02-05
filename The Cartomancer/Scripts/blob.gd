extends KinematicBody2D

onready var music = $BlobAudio
onready var sprite = $Sprite
# Declare member variables here. Examples:
# var a = 2
# var b = "text"
var health = 3

var speed = 100

var targeted_entity = null

var state = "wander"

var is_damaging = false

onready var animation = $AnimationPlayer


# Called when the node enters the scene tree for the first time.
func _ready():
	health = 3 # Replace with function body.
	animation.connect("animation_finished", self, "_on_animation_finished")


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if !is_damaging:
		animation.play("Hop")
		

func _physics_process(delta):
	if targeted_entity:
		var velocity = global_position.direction_to(targeted_entity.global_position)
		if velocity.x < 0:
			sprite.set_flip_h(false)
		else:
			sprite.set_flip_h(true)
		move_and_collide(velocity * speed * delta)

func _on_animation_finished(animation_name):
	if (animation_name == "Damage"):
		is_damaging = false
		speed = 100
		if(health <= 0):
			self.queue_free()
	
func take_damage(amount):
	animation.play("Damage")
	music.play()
	is_damaging = true
	speed = -300
	health-=amount
	


func _on_Area2D2_area_entered(area):
	if area.is_in_group("hurtbox") && area.get_parent().get_parent() != self:
		area.get_parent().get_parent().take_damage(1)


func _on_alert_area_entered(area):
	if(area.name == "PlayerHurtbox"):
		targeted_entity = area


func _on_alert_area_exited(area):
	if(area.name == "PlayerHurtbox"):
		targeted_entity = null
