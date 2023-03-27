extends AnimationPlayer

# Structure -> Animation name :[Connecting Animation states]
# kind of like a bunch of mini trees, it tells the program what animations can be played after a animation 
#if you try to jump to an animation not connected you will get a warning message and the anim doesnt play 
var states = {
	"Idle_unarmed":["Knife_equip", "Pistol_equip", "Rifle_equip", "Idle_unarmed"],
	
	"Pistol_equip":["Pistol_idle"],
	"Pistol_fire":["Pistol_idle"],
	"Pistol_idle":["Pistol_fire", "Pistol_reload", "Pistol_unequip", "Pistol_idle"],
	"Pistol_reload":["Pistol_idle"],
	"Pistol_unequip":["Idle_unarmed"],
	
	"Rifle_equip":["Rifle_idle"],
	"Rifle_fire":["Rifle_idle"],
	"Rifle_idle":["Rifle_fire", "Rifle_reload", "Rifle_unequip", "Rifle_idle"],
	"Rifle_reload":["Rifle_idle"],
	"Rifle_unequip":["Idle_unarmed"],
	
	"Knife_equip":["Knife_idle"],
	"Knife_fire":["Knife_idle"],
	"Knife_idle":["Knife_fire", "Knife_unequip", "Knife_idle"],
	"Knife_unequip":["Idle_unarmed"],
}

var animation_speeds = {
	#how fast each animation should play
	"Idle_unarmed": 1,
	
	"Pistol_equip": 1.4,
	"Pistol_fire": 1.8,
	"Pistol_idle":1,
	"Pistol_reload":1,
	"Pistol_unequip":1.4,
	
	"Rifle_equip":2,
	"Rifle_fire":6,
	"Rifle_idle":1,
	"Rifle_reload":1.45,
	"Rifle_unequip":2,
	
	"Knife_equip":1,
	"Knife_fire":1.35,
	"Knife_idle":1,
	"Knife_unequip":1,
}

var current_state = null #hold name of current animation
var callback_function = null # func ref so we can pass in a func as a argument so we can call func from
# a different script


func _ready():
	set_animation("Idle_unarmed") #make sure we start unarmed
	connect("animation_finished", self, "animation_ended") # call the end func when the animation finished

func set_animation(animation_name):
	if animation_name == current_state:#check to make sure we dont play same animation twice
		print("AnimationPlayer_Manager.gd -- Warning: Animation is already ", animation_name)
		return true
	
	
	if has_animation(animation_name):#checking if animation player has animation_name
		if current_state != null:#check to see if current state is set
			var possible_animations = states[current_state]
			if animation_name in possible_animations:#check to see if anim_name is a possible animation
				current_state = animation_name
				play(animation_name, -1, animation_speeds[animation_name])#-1 is blend time(blending animations)
				return true
			else:
				print("AnimationPlayer_Manager.gd -- Warning: Cannot change to ", animation_name, " From ", current_state)
		else:
			current_state = animation_name
			play(animation_name, -1, animation_speeds[animation_name])
			return true
	return false

func animation_ended(anim_name):
	#transtions from active transtions to idles
	#dont loop animations!!!!!!!!
	
	#usally be in states but hard coded for tutorial purposes
	
	#UNARMED transitions
	if current_state == "Idle_unarmed":
		pass
	#KNIFE transtions
	elif current_state == "Knife_equip":
		set_animation("Knife_idle")
	elif current_state == "Knife_idle":
		pass
	elif current_state == "Knife_fire":
		set_animation("Knife_idle")
	elif current_state == "Knife_unequip":
		set_animation("Idle_unarmed")
		
	#PISTOL transtitions
	elif current_state == "Pistol_equip":
		set_animation("Pistol_idle")
	elif current_state == "Pistol_idle":
		pass
	elif current_state == "Pistol_fire":
		set_animation("Pistol_idle")
	elif current_state == "Pistol_unequip":
		set_animation("Idle_unarmed")
	elif current_state == "Pistol_reload":
		set_animation("Pistol_idle")
		
	#RIFLE transitions
	elif current_state == "Rifle_equip":
		set_animation("Rifle_idle")
	elif current_state == "Rifle_idle":
		pass
	elif current_state == "Rifle_fire":
		set_animation("Rifle_idle")
	elif current_state == "Rifle_unequip":
		set_animation("Idle_unarmed")
	elif current_state == "Rifle_reload":
		set_animation("Rifle_idle")
		
		
func animation_callback(): # track animations
	if callback_function == null:
		print("AnimationPlayer_Manager.gd -- WARNING: No callback function for the animation to call!")
	else:
		callback_function.call_func()
# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
