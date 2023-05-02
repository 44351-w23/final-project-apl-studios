extends Spatial

var BULLET_SPEED = 120 #how fast the bullet is
var BULLET_DAMAGE = 20# the damage the bullet will do or how far it will move the object

const KILL_TIMER = 4
var timer = 0

var hit_something = false
var spread = 0

# Called when the node enters the scene tree for the first time.
func _ready():
	$Area.connect("body_entered", self, "collided") 
	# connecting the body entered signal and the collided


func _process(delta):
	var forward_dir = global_transform.basis.z.normalized()#finding the bullets local z axis (foward)
	global_translate(forward_dir * BULLET_SPEED * delta) #moving the bullet in the direction we just found
	
	timer += delta 
	if timer >= KILL_TIMER: #kill the bullet 
		queue_free()


func collided(body): #checking wether we hit something or not
	if hit_something == false: # if the bullet hasnt collided with something already
		if body.has_method("bullet_hit"):
			body.bullet_hit(BULLET_DAMAGE, global_transform)
	
	hit_something = true#make sure the bullet doesn't hit anything else
	queue_free()
