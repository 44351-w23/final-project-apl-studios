extends Spatial
#Any node with Respawn_Point_Setter.gd has to be above the player in 
#the SceneTree so the respawn points are set before the player needs them 
#in the player’s _ready function.


func _ready():
	var globals = get_node("/root/Globals")
	globals.respawn_points = get_children()
	
