extends Node2D

var Room = preload("res://Scenes/room.tscn")
var Player = preload("res://Scenes/player.tscn")
var Blob = preload("res://Scenes/melee_enemy.tscn")
var Arcana = preload("res://Scenes/arcana.tscn")

onready var Map = $TileMap
onready var Camera = $MainCamera
onready var Chooser = $ArcanaChooser
onready var Menu_Music = $Menu
onready var button_sfx = $ArcanaChooser/SFX
onready var Combat_Music = $Combat

var tile_size = 64
var num_rooms = 30
var min_size = 6
var max_size = 8
var hspread = 200
var cull = 0.5
var cam_start = .5
var cam_out = 15

var unlocked = [1,1,1,1,1,1,1,1,1,1,1,1]

var path # A Star pathfinding object
var start_room = null
var end_room = null
var play_mode = false
var player = null

var has_chosen = false

var card_pos = 0


func _ready():
	Menu_Music.play(1)
	choose_arcana()
	while !has_chosen:
		yield(get_tree(), "idle_frame")
	randomize()
	make_rooms()
	yield(get_tree().create_timer(2), 'timeout')
	make_map()
	
	yield(get_tree().create_timer(1), 'timeout')
	Menu_Music.stop()
	Combat_Music.play(.5)
	spawn_enemies()
	player = Player.instance()
	$player.add_child(player)
	player.position = start_room.position
	player.add_major_arcana(card_pos+1)
	play_mode = true
	
func choose_arcana():
	Camera.zoom.x = cam_start
	Camera.zoom.y = cam_start
	
	var cnt = 0
	for card in Chooser.get_node("Cards").get_children():
		if (unlocked[cnt] == 0):
			card.frame = 0
		cnt += 1
	
	
	
	
func make_rooms():
	Camera.zoom.x = cam_out
	Camera.zoom.y = cam_out
	for i in range(num_rooms):
		var pos = Vector2(rand_range(-hspread,hspread),0)
		var r = Room.instance()
		var w = min_size + randi() % (max_size-min_size)
		var h = min_size + randi() % (max_size-min_size)
		r.make_room(pos, Vector2(w,h) * tile_size)
		$rooms.add_child(r)
	# wait for rooms
	yield(get_tree().create_timer(1.1), 'timeout')
	# cull rooms
	var room_positions = []
	for room in $rooms.get_children():
		if randf() < cull:
			room.queue_free()
		else:
			room.mode = RigidBody2D.MODE_STATIC
			room_positions.append(Vector3(room.position.x,room.position.y,0))
	yield(get_tree(), "idle_frame")
	path = find_mst(room_positions)
	

func make_map():
	# Create Tilemap from Generated Rooms and Path
	Map.clear()
	find_start_room()
	find_end_room()
	var full_rect = Rect2()
	for room in $rooms.get_children():
		var r = Rect2(room.position-room.size, room.get_node("CollisionShape2D").shape.extents*2)
		full_rect = full_rect.merge(r)
	var topleft = Map.world_to_map(full_rect.position)
	var bottomright = Map.world_to_map(full_rect.end)
	for x in range(topleft.x,bottomright.x):
		for y in range(topleft.y,bottomright.y):
			Map.set_cell(x,y,random_wall())
	
	var corridors = [] # one corridor per connection
	for room in $rooms.get_children():
		var s = (room.size / tile_size).floor()
		var pos = Map.world_to_map(room.position)
		var ul = (room.position / tile_size).floor() - s
		for x in range (2,s.x*2-1):
			for y in range(2,s.y*2-1):
				Map.set_cell(ul.x+x,ul.y+y,random_floor())
		
		# carve connection
		var p = path.get_closest_point(Vector3(room.position.x, room.position.y, 0))
		for conn in path.get_point_connections(p):
			if not conn in corridors:
				var start = Map.world_to_map(Vector2(path.get_point_position(p).x, path.get_point_position(p).y))
				var end = Map.world_to_map(Vector2(path.get_point_position(conn).x, path.get_point_position(conn).y))
				
				carve_path(start,end)
		corridors.append(p)
	for room in $rooms.get_children():
		room.get_child(0).disabled = true
	
func carve_path(pos1, pos2):
	var x_diff = sign(pos2.x - pos1.x)
	var y_diff = sign(pos2.y - pos1.y)
	
	if x_diff == 0: x_diff = pow(-1.0, randi() % 2)
	if y_diff == 0: y_diff = pow(-1.0, randi() % 2)
	
	# choose either x then y, or y then x
	var x_y = pos1
	var y_x = pos2
	if(randi()%2) > 0:
		x_y = pos2
		y_x = pos1
	
	for x in range (pos1.x, pos2.x, x_diff):
		Map.set_cell(x,x_y.y,random_floor())
		Map.set_cell(x,x_y.y + y_diff,random_floor())
	for y in range (pos1.y, pos2.y, y_diff):
		Map.set_cell(y_x.x,y, random_floor())
		Map.set_cell(y_x.x + x_diff,y, random_floor())
	
func spawn_enemies():
	for room in $rooms.get_children():
		if(room.position != start_room.position):
			var room_type = randi() % 10 + 1
			if (room_type > 3):
				var random_num = randi() % 3 + 1
				var offset = 80
				for i in range(random_num):
					var b = Blob.instance()
					b.position.x = room.position.x - 80 + i * offset
					b.position.y = room.position.y - 80 + i * offset
					$enemies.add_child(b)
			else:
				var c = Arcana.instance()
				c.initialize(randi()%4)
				c.position = room.position
				$pickups.add_child(c)
		

func _draw():
	if play_mode:
		return
	for room in $rooms.get_children():
		draw_rect(Rect2(room.position - room.size, room.size * 2),
		Color(1,1,1),false)
	
	if path:
		for p in path.get_points():
			for c in path.get_point_connections(p):
				var pp = path.get_point_position(p)
				var cp = path.get_point_position(c)
				draw_line(Vector2(pp.x,pp.y), Vector2(cp.x, cp.y), Color(1,1,1), 15, true)
		
func _process(delta):
	update()
	
	
	
	
	
	
	

func find_mst(nodes):
	# Prims
	var path = AStar.new()
	path.add_point(path.get_available_point_id(), nodes.pop_front())
	
	# repeat until no more nodes remain
	while nodes:
		var min_dist = INF # min distance so far
		var min_p = null # position of that node
		var p = null # current position
		
		#loop through all notes
		for p1 in path.get_points():
			p1 = path.get_point_position(p1)
			# loop through remaining nodes
			
			for p2 in nodes:
				if p1.distance_to(p2) < min_dist:
					min_dist = p1.distance_to(p2)
					min_p = p2
					p = p1
		
		var n = path.get_available_point_id()
		path.add_point(n,min_p)
		path.connect_points(path.get_closest_point(p),n)
		nodes.erase(min_p)
	return path

func find_start_room():
	var min_x = INF
	for room in $rooms.get_children():
		if room.position.x < min_x:
			start_room = room
			min_x = room.position.x

func find_end_room():
	var max_x = -INF
	for room in $rooms.get_children():
		if room.position.x > max_x:
			end_room = room
			max_x = room.position.x


func _on_Button_pressed():
	button_sfx.play()
	yield(button_sfx,"finished")
	if(unlocked[card_pos] == 1):
		Chooser.visible = false;
		has_chosen = true


func _on_Right_pressed():
	button_sfx.play()
	if (card_pos < 11):
		card_pos +=1
		for card in Chooser.get_node("Cards").get_children():
			card.position.x -= 100


func _on_Left_pressed():
	button_sfx.play()
	if (card_pos > 0):
		card_pos -= 1
		for card in Chooser.get_node("Cards").get_children():
			card.position.x += 100
			
func random_floor():
	# 0, 25%
	# 1, 12.5%
	# 2, 12.5%
	# 3, 50%
	
	var num = randi() % 16 + 1
	
	if (num == 1):
		return 1
	elif (num == 2):
		return 2
	elif (num <= 4):
		return 0
	else:
		return 3
	
func random_wall():
	
	var num = randi() % 4 + 1
	
	if (num == 1):
		return 5
	elif (num == 2):
		return 6
	else:
		return 4
