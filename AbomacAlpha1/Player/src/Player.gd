extends KinematicBody2D

export var JumpParticle : PackedScene
export(float) var TimeToJumpPeak = .3
export(int) var JumpHeight = 114

onready var JumpBufferTimer: = $JumpBufferTimer
onready var WallJumpBufferTimer: = $WallJumpBufferTimer
onready var CoyoteJumpTimer: = $CoyoteJumpTimer
onready var GravityOn: = $GravityOnTimer
onready var DashCast: = $DashCast
onready var IsDashingTimer: = $IsDashingTimer

var velocity = Vector2()
var input_vector = Vector2()
var gravity: float
var jump_speed: float
var buffered_jump = false
var coyote_jump = false
var is_wall_sliding = false
var gravity_on = false
var can_dash = false
var is_dashing = false

const MAXSPEED = 200
const ACCELERATION = 3000
const UP = Vector2(0, -1)
const WALL_JUMP_PUSHBACK = 333
const WALL_SLIDE_GRAVITY = 222
const DASH_DISTANCE = 900

func _ready():
	gravity_on = true
	can_dash = true
	gravity = (2*JumpHeight)/pow(TimeToJumpPeak,2)
	jump_speed = gravity * TimeToJumpPeak

func _physics_process(delta):
	if gravity_on:
		velocity.y += gravity * delta
	else:
		velocity.y = 0
	
	if velocity.y > 0:
		velocity.y += gravity * delta  * 0.5
	
	wall_slide(delta)
	dash(delta)
	input_movement(delta)

func input_movement(delta):
	
	input_vector.x = Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left")
	velocity.x = move_toward(velocity.x,input_vector.x*MAXSPEED, ACCELERATION*delta)
	
	if Input.is_action_pressed("ui_right") and is_on_floor():
		pass
	
	
	if Input.is_action_just_pressed("ui_accept") and not is_on_floor():
		if is_on_wall() and Input.is_action_pressed("ui_right"):
			velocity.y = -jump_speed - 20
			velocity.x = -WALL_JUMP_PUSHBACK
		if is_on_wall() and Input.is_action_pressed("ui_left"):
			velocity.y = -jump_speed - 20
			velocity.x = WALL_JUMP_PUSHBACK
	
	if is_on_floor() or coyote_jump:
		if Input.is_action_just_pressed("ui_accept") or buffered_jump:
			jump()
			buffered_jump = false
	else:
		if Input.is_action_just_released("ui_accept") and not is_on_floor() and velocity.y < 0:
			velocity.y /= -jump_speed
	
	if Input.is_action_just_pressed("ui_accept"):
		buffered_jump = true
		JumpBufferTimer.start()
	
	var was_on_floor = is_on_floor()
	var was_on_wall = is_on_wall()
	
	velocity = move_and_slide(velocity, UP)
	
	var just_left_ground = not is_on_floor() and was_on_floor
	if just_left_ground and velocity.y >= 0:
		coyote_jump = true
		CoyoteJumpTimer.start()
	var just_left_wall = not is_on_wall() and was_on_wall
	if just_left_wall:
		WallJumpBufferTimer.start()

func jump():
	var jump_particle = JumpParticle.instance()
	jump_particle.position = global_position
	jump_particle.rotation = global_rotation
	jump_particle.emitting = true
	get_tree().current_scene.add_child(jump_particle)
	velocity.y = -jump_speed - 70
	can_dash = true

func wall_slide(delta):
	if is_on_wall() and not is_on_floor():
		if Input.is_action_pressed("ui_right") or Input.is_action_pressed("ui_left"):
			is_wall_sliding = true
		else:
			is_wall_sliding = false
	else:
		is_wall_sliding = false
	
	if is_wall_sliding:
		velocity.y += (WALL_SLIDE_GRAVITY * delta)
		velocity.y = min(velocity.y, WALL_SLIDE_GRAVITY)

func dash(delta):
	if Input.is_action_pressed("ui_right"):
		DashCast.scale.x = 1
	if Input.is_action_pressed("ui_left"):
		DashCast.scale.x = -1
	
	if not is_dashing and is_on_floor() or not is_dashing and is_on_wall():
		can_dash = true
	
	if Input.is_action_just_pressed("dash") and can_dash and DashCast.scale.x == 1:
		GravityOn.start()
		IsDashingTimer.start()
		is_dashing = true
		can_dash = false
		gravity_on = false
		velocity.x = DASH_DISTANCE
	
	if Input.is_action_just_pressed("dash") and can_dash and DashCast.scale.x == -1:
		GravityOn.start()
		IsDashingTimer.start()
		is_dashing = true
		can_dash = false
		gravity_on = false
		velocity.x = -DASH_DISTANCE

func _on_JumpBufferTimer_timeout():
	buffered_jump = false

func _on_CoyoteJumpTimer_timeout():
	coyote_jump = false
	can_dash = true
	gravity_on = true

func _on_GravityOnTimer_timeout():
	gravity_on = true

func _on_IsDashingTimer_timeout():
	is_dashing = false
