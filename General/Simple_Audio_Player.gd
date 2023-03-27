extends Spatial
#This system is extremely simple and has some major flaws:
#
#One flaw is we have to pass in a string value to play a sound. While it is relatively simple to remember the names of the three sounds,
#it can be increasingly complex when you have more sounds. Ideally, we’d place these sounds in some sort of container with exposed variables 
#so we do not have to remember the name(s) of each sound effect we want to play.

#Another flaw is we cannot play looping sounds effects, nor background music, easily with this system. Because we cannot play looping sounds, certain effects,
# like footstep sounds, are harder to accomplish because we then have to keep track of whether or not there is a sound effect and whether or not we need to continue playing it.
#One of the biggest flaws with this system is we can only play sounds from Player.gd. Ideally we’d like to be able to play sounds from any script at any time.

#all audio files
var audio_pistol_shot = preload("res://assets/sounds/gun_revolver_pistol_shot_04.wav")
var audio_gun_cock = preload("res://assets/sounds/gun_semi_auto_rifle_cock_02.wav")
var audio_rifle_shot = preload("res://assets/sounds/gun_rifle_sniper_shot_01.wav")

var audio_node = null
# Called when the node enters the scene tree for the first time.
func _ready():
	audio_node = $AudioStreamPlayer
	audio_node.connect("finished", self, "destroy_self")
	audio_node.stop()

func play_sound(sound_name, position=null): # posisiton null because position isnt needed if not using a 3d player
	if audio_pistol_shot == null or audio_rifle_shot == null or audio_gun_cock == null:
		print ("Audio not set!")
		queue_free()
		return
	if sound_name == "Pistol_shot":
		audio_node.stream = audio_pistol_shot
	elif sound_name == "Rifle_shot":
		audio_node.stream = audio_rifle_shot
	elif sound_name == "Gun_cock":
		audio_node.stream = audio_gun_cock
	else:
		print ("UNKOWN STREAM")
		queue_free()
		return
	
	if audio_node is AudioStreamPlayer3D:
		if position != null:
			audio_node.global_transform.origin = position
	
	audio_node.play()
	
func destroy_self():
	audio_node.stop()
	queue_free()
# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
