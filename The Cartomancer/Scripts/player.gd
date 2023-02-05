extends KinematicBody2D

var velocity : Vector2 = Vector2()
var direction : Vector2 = Vector2()
var speed = 300

onready var animation = $AnimationPlayer
onready var sprite = $PlayerSprite
onready var UI = $PlayUI
onready var music = $PlayerAudio
onready var damageSprite = $PlayUI.get_node("Major-Arcana/Damage")

var Arcana = preload("res://Scenes/arcana.tscn")

var majorarcana = 0
var minorarcana = []

var attacking = false
var taking_damage = false

var health = 5
var damage = 1

func _ready():
	animation.connect("animation_finished", self, "_on_animation_finished")

func take_damage(amount):
	if(!taking_damage):
		animation.play("Damage")
		music.play()
		taking_damage = true
		health -= amount
		update_UI()
	
func update_UI():
	if health >= 5:
		damageSprite.visible = false
	else:
		damageSprite.visible = true
		damageSprite.frame = 4-health
		

func _on_animation_finished(animation_name):
	print("animation done")
	if(animation_name == "FoolH"):
		attacking = false
	if(animation_name == "Damage"):
		taking_damage = false

func add_major_arcana(index):
	majorarcana = index
	UI.get_node("Major-Arcana").frame = index
	
func add_minor_arcana(index):
	resolve_stats(index)
	$CollectAudio.play()
	var arcana = Arcana.instance()
	arcana.frame = index
	arcana.position.x = -250 + minorarcana.size() * 53
	arcana.position.y = -174
	minorarcana.append(index)
	UI.get_node("HBoxContainer").add_child(arcana)
		
func resolve_stats(index):
	if index == 0:
		speed += 100
	elif index == 1:
		health += 2
		if (health > 5):
			health = 5
	elif index == 2:
		health += 1
	else:
		damage += 1
		
	update_UI()
		

func _physics_process(delta):
	
	velocity = Vector2()
	

	if Input.is_action_pressed("left"):
		if (!attacking && !taking_damage):
			animation.play("Walk")
			sprite.scale.x = -1
		
		velocity.x -= 1
		direction = Vector2(-1,0)

	if Input.is_action_pressed("right"):
		if (!attacking && !taking_damage):
			animation.play("Walk")
			sprite.scale.x = 1
		velocity.x += 1
		direction = Vector2(1,0)
		
	if Input.is_action_pressed("up"):
		if(velocity.x == 0 && !attacking && !taking_damage):
			animation.play("WalkUp")
		velocity.y -= 1
		direction = Vector2(0,-1)

	if Input.is_action_pressed("down") :
		if(velocity.x == 0 && !attacking&& !taking_damage):
			animation.play("WalkDown")
		velocity.y += 1
		direction = Vector2(0,1)
		
	if Input.is_action_pressed("dodge"):
		attacking = true
		taking_damage = false
		#velocity = Vector2()
		animation.play("FoolH")
		
	if velocity.x == 0 && velocity.y == 0 && !attacking && !taking_damage:
		animation.play("Idle")
		
	velocity = velocity.normalized() * speed
	velocity = move_and_slide(velocity)
	
	
	



func _on_AttackHit_area_entered(area):
	if area.is_in_group("ehurtbox") && area.get_parent().get_parent() != self:
		area.get_parent().get_parent().take_damage(damage)
