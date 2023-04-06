extends Spatial

const DAMAGE = 15 #The amount of damage a single bullet does
const CAN_RELOAD = true
const CAN_REFILL = true

const IDLE_ANIM_NAME = "Pistol_idle" #The name of the pistol’s idle animation.
const FIRE_ANIM_NAME = "Pistol_fire"#The name of the pistol’s fire animation.
const RELOADING_ANIM_NAME = "Pistol_reload"#The name of the pistols reload animation

var is_weapon_enabled = false #checking if we can use a weapon

var bullet_scene = preload("Bullet_Scene.tscn")

var player_node = null #used to hold the Player.gd
#most var are used so can call them in Player.gd

var ammo_in_weapon = 11 #The amount of ammo currently in the pistol
var spare_ammo = 33 #The amount of ammo we have left in reserve for the pistol
const AMMO_IN_MAG = 11 #The amount of ammo in a fully reloaded weapon/magazine
func _ready():
	pass

func fire_weapon():
	var clone = bullet_scene.instance()
	var scene_root = get_tree().root.get_children()[0]
	scene_root.add_child(clone)
	
	clone.global_transform = self.global_transform
	clone.scale = Vector3(4,4,4)
	clone.BULLET_DAMAGE = DAMAGE
	ammo_in_weapon -= 1
	player_node.create_sound("Pistol_shot", self.global_transform.origin)

func reload_weapon():
	var can_reload = false
	
	if player_node.animation_manager.current_state == IDLE_ANIM_NAME:
		can_reload = true
	
	if spare_ammo <= 0 or ammo_in_weapon == AMMO_IN_MAG:
		can_reload = false
	
	if can_reload == true:
		var ammo_needed = AMMO_IN_MAG - ammo_in_weapon
		
		if spare_ammo >= ammo_needed:
			spare_ammo -= ammo_needed
			ammo_in_weapon = AMMO_IN_MAG
		else:
			ammo_in_weapon += spare_ammo
			spare_ammo = 0
		player_node.animation_manager.set_animation(RELOADING_ANIM_NAME)
		player_node.create_sound("Gun_cock", player_node.camera.global_transform.origin)
		return true
	return false
	
func equip_weapon():
	if player_node.animation_manager.current_state == IDLE_ANIM_NAME:
		is_weapon_enabled = true
		return true
	
	if player_node.animation_manager.current_state == "Idle_unarmed":
		player_node.animation_manager.set_animation("Pistol_equip")
	
	return false

func unequip_weapon():
	if player_node.animation_manager.current_state == IDLE_ANIM_NAME:
		if player_node.animation_manager.current_state != "Pistol_unequip":
			player_node.animation_manager.set_animation("Pistol_unequip")
			
	if player_node.animation_manager.current_state == "Idle_unarmed":
		is_weapon_enabled = false
		return true
	else:
		return false

func reset_weapon():
	ammo_in_weapon = 10
	spare_ammo = 20
