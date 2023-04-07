extends KinematicBody

const GRAVITY = -24.8 # gravity
var vel = Vector3() #ref for kinematicbody velocity
const MAX_SPEED = 20 # fastest speed we can go
const JUMP_SPEED = 18 #jump height
const ACCEL = 4.5 # how fast we get to max speed

var dir = Vector3() 

const DEACCEL = 16 # how fast we come to a stop
const MAX_SLOPE_ANGLE = 40 # the angle considered floor 

var camera # ref to camera node
var rotation_helper # ref to spatial node holdong all the things we need to rotate on x axis

var MOUSE_SENSITIVITY = 0.20 # how sensitive the mouse is (add option to change later)

const MAX_SPRINT_SPEED = 30
const SPRINT_ACCEL = 18
var is_sprinting = false


var flashlight

var animation_manager

var current_weapon_name = "UNARMED"
var weapons = {"UNARMED":null, "KNIFE":null, "PISTOL":null,"PISTOL2":null, "RIFLE":null}
const WEAPON_NUMBER_TO_NAME = {0: "UNARMED", 1:"KNIFE", 2:"PISTOL", 3:"RIFLE", 4:"PISTOL2"}
const WEAPON_NAME_TO_NUMBER = {"UNARMED":0, "KNIFE":1, "PISTOL":2, "RIFLE":3, "PISTOL2":4}
var changing_weapon = false
var changing_weapon_name = "UNARMED"
var reloading_weapon = false

var health = 100

var UI_status_label



#controller stuff - may need to adjust #s
var JOYPAD_SENSITIVITY = 2
const JOYPAD_DEADZONE = 0.15

var mouse_scroll_value = 0
const MOUSE_SENSITIVITY_SCROLL_WHEEL = 0.08

#grenade stuff 
var grenade_amount = {"Grenade":2, "Sticky Grenade":2}
var current_grenade = "Grenade"
var grenade_scene = preload("res://General/Grenade.tscn")
var sticky_grenade_scene = preload("res://General/Sticky_Grenade.tscn")
const GRENADE_THROW_FORCE = 50

const MAX_HEALTH = 150

var grabbed_object = null
const OBJECT_THROW_FORCE = 120
const OBJECT_GRAB_DISTANCE = 7
const OBJECT_GRAB_RAY_DISTANCE = 10

const RESPAWN_TIME = 4
var dead_time = 0
var is_dead = false

var globals


func _ready():
	camera = $Rotation_Helper/Camera
	rotation_helper = $Rotation_Helper
	
	animation_manager = $Rotation_Helper/Model/Animation_Player
	animation_manager.callback_function = funcref(self, "fire_bullet")

	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED) #this will hide the mouse and center it
	
	weapons["KNIFE"] = $Rotation_Helper/Gun_Fire_Points/Knife_Point
	weapons["PISTOL"] = $Rotation_Helper/Gun_Fire_Points/Pistol_Point
	weapons["RIFLE"] = $Rotation_Helper/Gun_Fire_Points/Rifle_Point
	weapons["PISTOL2"] =  $Rotation_Helper/Gun_Fire_Points/Pistol_Point2
	
	var gun_aim_point_pos = $Rotation_Helper/Gun_Aim_Point.global_transform.origin
	
	for weapon in weapons:
		var weapon_node = weapons[weapon]
		if weapon_node != null:
			weapon_node.player_node = self
			weapon_node.look_at(gun_aim_point_pos,Vector3(0,1,0))
			weapon_node.rotate_object_local(Vector3(0,1,0), deg2rad(180))
	current_weapon_name = "UNARMED"
	changing_weapon_name = "UNARMED"
	
	UI_status_label = $HUD/Panel/Gun_label
	flashlight = $Rotation_Helper/Flashlight
	globals = get_node("/root/Globals")
	global_transform.origin = globals.get_respawn_position()

func _physics_process(delta):
	if !is_dead:
		process_input(delta) # handles all the input
		process_view_input(delta)
		process_movement(delta)# sending the data to the kinematic body to move
	if grabbed_object == null:
		process_changing_weapons(delta)
		process_reloading(delta)
	
	process_UI(delta)
	process_respawn(delta)

func process_input(_delta):
	if is_dead:
		return
	#--------------------------------------------
	#walking
	dir = Vector3() # used for storing the direction the player is mocing toward
	var cam_xform = camera.get_global_transform()
	
	var input_movement_vector = Vector2()
	
	#detecting which way tp move
	if Input.is_action_pressed("movement_forward"):
		input_movement_vector.y += 1
	if Input.is_action_pressed("movement_backward"):
		input_movement_vector.y -= 1
	if Input.is_action_pressed("movement_right"):
		input_movement_vector.x -= 1
	if Input.is_action_pressed("movement_left"):
		input_movement_vector.x += 1
	
	if Input.get_connected_joypads().size() > 0:
		var joypad_vec = Vector2(0,0)
		
		if OS.get_name() == "Windows" or OS.get_name() == "X11":
			joypad_vec = Vector2(Input.get_joy_axis(0,0), -Input.get_joy_axis(0,1))
		elif OS.get_name() == "OSX":
			joypad_vec = Vector2(Input.get_joy_axis(0,1), Input.get_joy_axis(0,2))
		
		if joypad_vec.length() < JOYPAD_DEADZONE:
			joypad_vec = Vector2(0,0)
		else:
			joypad_vec = joypad_vec.normalized()* ((joypad_vec.length()- JOYPAD_DEADZONE)/ (1 - JOYPAD_DEADZONE))
		
		input_movement_vector += joypad_vec
	
	input_movement_vector = input_movement_vector.normalized()
	
	# basis vectors are already normalized
	dir += -cam_xform.basis.z * input_movement_vector.y #this is so that when the player moves foward and back it does so relative to the camera
	dir += -cam_xform.basis.x * input_movement_vector.x # same thing but left and right relative to camera
	#---------------------------------------------------
	
	#------------------------------------------------
	#jumping
	if is_on_floor():
		if Input.is_action_just_pressed("movement_jump"):
			vel.y = JUMP_SPEED
	#------------------------------------------------
	
	#-------------------------------------------------
	# Capturing/Freeing the cursor
		if Input.get_mouse_mode() == Input.MOUSE_MODE_VISIBLE:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	#-------------------------------------------------
	
	#--------------------------------------------------
	#sprint
	if Input.is_action_pressed("movement_sprint"):
		is_sprinting = true
	else:
		is_sprinting = false
	#--------------------------------------------------
	
	#--------------------------------------------------
	#changing weapons
	var weapon_change_number = WEAPON_NAME_TO_NUMBER[current_weapon_name]
	
	if Input.is_key_pressed(KEY_1):
		weapon_change_number = 0
	if Input.is_key_pressed(KEY_2):
		weapon_change_number = 1
	if Input.is_key_pressed(KEY_3):
		weapon_change_number = 2
	if Input.is_key_pressed(KEY_4):
		weapon_change_number = 3
	if Input.is_key_pressed(KEY_5):
		weapon_change_number = 4
		
	if Input.is_action_just_pressed("shift_weapon_positive"):
		weapon_change_number += 1
	if Input.is_action_just_pressed("shift_weapon_negative"):
		weapon_change_number -= 1
	
	weapon_change_number = clamp(weapon_change_number, 0, WEAPON_NUMBER_TO_NAME.size() -1)
	if changing_weapon == false:
		if reloading_weapon == false:
			if WEAPON_NUMBER_TO_NAME[weapon_change_number] != current_weapon_name:
				changing_weapon_name = WEAPON_NUMBER_TO_NAME[weapon_change_number]
				changing_weapon = true
				mouse_scroll_value = weapon_change_number
	#-------------------------------------------------
	#changing and throwing grenades
	var grenade_Name = "Grenade"
	var sticky_Name = "Sticky Grenade"
	if Input.is_action_just_pressed("change_grenade"):
		if current_grenade == grenade_Name:
			current_grenade = sticky_Name
		elif current_grenade == sticky_Name:
			current_grenade = grenade_Name
		
	if Input.is_action_just_pressed("fire_grenade"):
		if grenade_amount[current_grenade]  > 0:
			grenade_amount[current_grenade] -= 1
			
			var grenade_clone
			if current_grenade == grenade_Name:
				grenade_clone = grenade_scene.instance()
			elif current_grenade == sticky_Name:
				grenade_clone = sticky_grenade_scene.instance()
				# Sticky grenades will stick to the player if we do not pass ourselves
				grenade_clone.player_body = self
			
			get_tree().root.add_child(grenade_clone)
			grenade_clone.global_transform = $Rotation_Helper/Grenade_Toss_Pos.global_transform
			grenade_clone.apply_impulse(Vector3(0,0,0), grenade_clone.global_transform.basis.z * GRENADE_THROW_FORCE)
			
	#--------------------------------------------------
	#Firing the weapons
	#implement triggers later rn its the bumper
	if Input.is_action_pressed("fire"):
		if reloading_weapon == false:
			if changing_weapon == false:
				var current_weapon = weapons[current_weapon_name]
				if current_weapon != null:
					if current_weapon.ammo_in_weapon > 0: #check for auto reload when mag empty
						if animation_manager.current_state == current_weapon.IDLE_ANIM_NAME:
							animation_manager.set_animation(current_weapon.FIRE_ANIM_NAME)
					else:
						reloading_weapon = true
					
	#--------------------------------------------------
	#reloading 
	if reloading_weapon == false: #check to make sure player isnt already reloading
		if changing_weapon == false:  #check make sure player isnt switching weapons
			if Input.is_action_just_pressed("reload"):
				var current_weapon = weapons[current_weapon_name]
				if current_weapon != null: #check if unarmed
					if current_weapon.CAN_RELOAD == true: #check for a reloadable weapon
						var current_anim_state = animation_manager.current_state
						var is_reloading = false
						for weapon in weapons:
							var weapon_node = weapons[weapon]
							if weapon_node != null:
								if current_anim_state == weapon_node.RELOADING_ANIM_NAME:
									is_reloading = true
						if is_reloading == false:
							reloading_weapon = true
	
	#--------------------------------------------------
	# Turning the flashlight on and off
	if Input.is_action_just_pressed("flashlight"):
		if flashlight.is_visible_in_tree():
			flashlight.hide()
		else:
			flashlight.show()
	#-------------------------------------------------
	#grabbing and throwing objects
	
	if Input.is_action_just_pressed("fire") and current_weapon_name == "UNARMED":
		if grabbed_object == null:
			var state = get_world().direct_space_state
			
			var center_position = get_viewport().size/2
			var ray_from = camera.project_ray_origin(center_position)
			var ray_to = ray_from + camera.project_ray_normal(center_position) * OBJECT_GRAB_DISTANCE
			
			var ray_result = state.intersect_ray(ray_from, ray_to, [self, $Rotation_Helper/Gun_Fire_Points/Knife_Point/Area])
			if ray_result:
				if ray_result["collider"] is RigidBody:
					grabbed_object = ray_result["collider"]
					grabbed_object.mode = RigidBody.MODE_STATIC
					
					grabbed_object.collision_layer = 0
					grabbed_object.collision_mask = 0
		else:
			grabbed_object.mode = RigidBody.MODE_RIGID
					
			grabbed_object.apply_impulse(Vector3(0,0,0), -camera.global_transform.basis.z.normalized() * OBJECT_THROW_FORCE)
					
			grabbed_object.collision_layer = 1
			grabbed_object.collision_mask = 1
					
			grabbed_object = null
				
	if grabbed_object != null:
		grabbed_object.global_transform.origin = camera.global_transform.origin + (-camera.global_transform.basis.z.normalized() * OBJECT_GRAB_DISTANCE)

func process_movement(delta):
	dir.y = 0 #making sure that dir doesn't have any movement on the y axis by setting to zero
	dir = dir.normalized() # normailzed so that it is within a 1 radius unit circle
	# so that when moving in directions other than straight we stay the same speed would move fast diagnially if not
	
	vel.y += delta * GRAVITY #adding gravity to player
	
	var hvel = vel
	hvel.y = 0 # remove movement on y axis
	
	var target = dir
	if is_sprinting:
		target*= MAX_SPRINT_SPEED
	else:
		target *= MAX_SPEED
	
	var accel
	if dir.dot(hvel) > 0: # seeing if the player is moving (foward, back, left, right)
		if is_sprinting:
			accel = SPRINT_ACCEL
		else:
			accel = ACCEL
	else:
		accel = DEACCEL
	
	hvel = hvel.linear_interpolate(target, accel*delta) #interpolate horzontal velocity to handle movement
	vel.x = hvel.x
	vel.z = hvel.z
	vel = move_and_slide(vel, Vector3(0,1,0), 0.05, 4, deg2rad(MAX_SLOPE_ANGLE))

func process_view_input(_delta):
	if Input.get_mouse_mode() != Input.MOUSE_MODE_CAPTURED:
		# NOTE: Until some bugs relating to captured mice are fixed, we cannot put the mouse view
		# rotation code here. Once the bug(s) are fixed, code for mouse view rotation code will go here!
		# ----------------------------------
		#joypad rotation
		var joypad_vec = Vector2()
		if Input.get_connected_joypads().size() > 0:
			if OS.get_name() == "Windows" or OS.get_name() == "X11":
				joypad_vec = Vector2(Input.get_joy_axis(0,2), Input.get_joy_axis(0,3))
			elif OS.get_name() == "OSX":
				joypad_vec = Vector2(Input.get_joy_axis(0,3), Input.get_joy_axis(0,4))
			
			if joypad_vec.length() < JOYPAD_DEADZONE:
				joypad_vec = Vector2(0,0)
			else:
				joypad_vec = joypad_vec.normailzed()*((joypad_vec.length() - JOYPAD_DEADZONE) / (1 - JOYPAD_DEADZONE))
			rotation_helper.rotate_x(deg2rad(joypad_vec.y* JOYPAD_SENSITIVITY))
			rotate_y(deg2rad(joypad_vec.x* JOYPAD_SENSITIVITY* -1))
			
			var camera_rot = rotation_helper.rotation_degrees
			camera_rot.x = clamp(camera_rot.x, -70, 70)
			rotation_helper.rotation_degrees = camera_rot
			
			#-------------------------------------------------

func process_changing_weapons(_delta):
	if changing_weapon == true:
		var weapon_unequipped = false
		var current_weapon = weapons[current_weapon_name]
		
		if current_weapon == null:
			weapon_unequipped = true
		else:
			if current_weapon.is_weapon_enabled == true:
				weapon_unequipped = current_weapon.unequip_weapon()
			else:
				weapon_unequipped = true
		if weapon_unequipped == true:
			var weapon_equipped = false
			var weapon_to_equip = weapons[changing_weapon_name]
			
			if weapon_to_equip == null:
				weapon_equipped = true
			else:
				if weapon_to_equip.is_weapon_enabled == false:
					weapon_equipped = weapon_to_equip.equip_weapon()
				else:
					weapon_equipped = true
			
			if weapon_equipped == true:
				changing_weapon = false
				current_weapon_name = changing_weapon_name
				changing_weapon_name = ""

func fire_bullet():
	if changing_weapon == true:
		return
	weapons[current_weapon_name].fire_weapon()

func _input(event):
	#don't rotate player when mouse isn't captured
	if event is InputEventMouseButton and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		# We can ONLY access the scroll wheel in _input. Because of this,
		# we have to process changing weapons with the scroll wheel here.
		if event.button_index == BUTTON_WHEEL_UP or event.button_index == BUTTON_WHEEL_DOWN:
			# Add/Remove MOUSE_SENSITIVITY_SCROLL_WHEEL based on which direction we are scrolling
			if event.button_index == BUTTON_WHEEL_UP:
				mouse_scroll_value += MOUSE_SENSITIVITY_SCROLL_WHEEL
			elif event.button_index == BUTTON_WHEEL_DOWN:
				mouse_scroll_value -= MOUSE_SENSITIVITY_SCROLL_WHEEL
			
			# Make sure we are using a valid number by clamping the value
			mouse_scroll_value = clamp(mouse_scroll_value, 0, WEAPON_NUMBER_TO_NAME.size()-1)
			
			# Make sure we are not already changing weapons, or reloading.
			if changing_weapon == false:
				if reloading_weapon == false:
					# Round mouse_scroll_view so we get a full number and convert it from a float to a int
					var round_mouse_scroll_value = int(round(mouse_scroll_value))
					# If we are not already using the weapon at that position, then change to it.
					if WEAPON_NUMBER_TO_NAME[round_mouse_scroll_value] != current_weapon_name:
						changing_weapon_name = WEAPON_NUMBER_TO_NAME[round_mouse_scroll_value]
						changing_weapon = true
						# Set mouse scroll value to the rounded value so the amount of time it takes to change weapons
						# is consistent.
						mouse_scroll_value = round_mouse_scroll_value
						
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		rotation_helper.rotate_x(deg2rad(event.relative.y * MOUSE_SENSITIVITY))
		self.rotate_y(deg2rad(event.relative.x * MOUSE_SENSITIVITY * -1))
		
		var camera_rot = rotation_helper.rotation_degrees
		camera_rot.x = clamp(camera_rot.x, -70, 70) # player can't rotate themselves upside down
		rotation_helper.rotation_degrees = camera_rot

func process_UI(_delta):
	if current_weapon_name == "UNARMED" or current_weapon_name == "KNIFE":
		#first line health, second grenade
		UI_status_label.text = "Health: " + str(health) + \
			"\n" + current_grenade + ": " + str(grenade_amount[current_grenade])
	else:
		#first line health, seconnd weapon ammo, third grenade
		var current_weapon = weapons[current_weapon_name]
		UI_status_label.text = "Health: " + str(health) + \
		"\nAmmo: " + str(current_weapon.ammo_in_weapon) + "/" + str(current_weapon.spare_ammo) + \
		"\n" + current_grenade + ": " + str(grenade_amount[current_grenade])

func process_reloading(_delta):
	if reloading_weapon == true:# player is trying to reload
		var current_weapon = weapons[current_weapon_name]
		if current_weapon != null: #check to see if unarmed
			current_weapon.reload_weapon()
		reloading_weapon = false

func create_sound(sound_name, position=null):
	globals.play_sound(sound_name, false, position)

func add_health(additional_health):
	health += additional_health
	health = clamp(health, 0, MAX_HEALTH)

func add_ammo(additional_ammo):
	if(current_weapon_name != "UNARMED"):
		if (weapons[current_weapon_name].CAN_REFILL == true):
			weapons[current_weapon_name].spare_ammo += weapons[current_weapon_name].AMMO_IN_MAG * additional_ammo

func add_grenade(additional_grenade):
	grenade_amount[current_grenade] += additional_grenade
	grenade_amount[current_grenade] = clamp(grenade_amount[current_grenade], 0, 4)

func bullet_hit(damage, _bullet_hit_pos):
	health -= damage

func process_respawn(delta):
	#if just died
	if health<= 0 and !is_dead:
		$Body_CollisionShape.disabled = true
		$Feet_CollisionShape.disabled = true
		
		changing_weapon = true
		changing_weapon_name = "UNARMED"
		
		$HUD/Death_Screen.visible = true
		
		$HUD/Panel.visible = false
		$HUD/Crosshair.visible = false
		
		dead_time = RESPAWN_TIME
		is_dead = true
		if grabbed_object != null:
			grabbed_object.mode = RigidBody.MODE_RIGID
			grabbed_object.apply_inpulse(Vector3(0,0,0), - camera.global_transform.basis.z.normalized() * OBJECT_THROW_FORCE / 2)
			
			grabbed_object.collision_layer = 1
			grabbed_object.collision_mask = 1
			
			grabbed_object = null
		
	if is_dead:
		dead_time -= delta
		
		var dead_time_pretty = str(dead_time).left(3)
		$HUD/Death_Screen/Label.text = "You died\n" + dead_time_pretty + " seconds until respawn"
		
		if dead_time <= 0:
			global_transform.origin = globals.get_respawn_position()
			
			$Body_CollisionShape.disabled = false
			$Feet_CollisionShape.disabled = false
			
			$HUD/Death_Screen.visible = false
			
			$HUD/Panel.visible = true
			$HUD/Crosshair.visible = true
			
			for weapon in weapons:
				var weapon_node = weapons[weapon]
				if weapon_node != null:
					weapon_node.reset_weapon()
			health = 100
			grenade_amount = {"Grenade":2, "Sticky Grenade":2}
			current_grenade = "Grenade"
			
			is_dead = false
