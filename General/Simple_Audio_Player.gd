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
var audio_node = null
var should_loop = false
var globals = null

# Called when the node enters the scene tree for the first time.
func _ready():
	audio_node = $AudioStreamPlayer
	audio_node.connect("finished", self, "sound_finished")
	audio_node.stop()
	
	globals = get_node("/root/Globals")

func play_sound(audio_stream, position=null): # posisiton null because position isnt needed if not using a 3d player
	if audio_stream == null:
		print ("No audio stream passedd; cannot play sound")
		globals.created_audio.remove(globals.created_audio.find(self))
		queue_free()
		return
	audio_node.stream = audio_stream
	
	if audio_node is AudioStreamPlayer3D:
		if position != null:
			audio_node.global_transform.origin = position
	
	audio_node.play(0.0)
	
func sound_finished():
	if should_loop:
		audio_node.play(0.0)
	else:
		globals.created_audio.remove(globals.created_audio.find(self))
		queue_free()


func _on_Turret_turret_fire():
	pass
