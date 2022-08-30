extends KinematicBody2D

export (int) var move_speed = 800
export (int) var jump_speed = -1600
export (int) var gravity = 4000
export (float,0,1.0) var friction = 0.15
export (float,0,1.0) var acceleration = 0.25

# Player States
enum state {IDLE, RUN, JUMP, FALL, ATTACK, HIT}

onready var sprite = $Sprite
onready var can_jump = true
onready var player_state = state.IDLE setget _set_state
onready var velocity = Vector2.ZERO
var previous_speed: Vector2
var hit_the_ground: bool = true
var prevState
var move_direction: Vector2 = Vector2.ZERO
var input: Vector2 = Vector2.ZERO
var is_grounded: bool = true

const DEADZONE: float = 0.25

func _ready():
	self.player_state = state.IDLE

func _set_state(new_state):
	player_state = new_state
	update_animation(state.keys()[new_state])

func _input(event):
	# RUN
	if get_move_direction().x != 0 && is_on_floor() && !str(state.keys()[player_state]) in ["JUMP"] && player_state != state.RUN:
		self.player_state = state.RUN

	# JUMP
	if event.is_action_pressed("jump") && can_jump:
		is_grounded = false
		self.player_state = state.JUMP
		
	if event.is_action_released("jump"):
		if player_state == state.JUMP && velocity.y <= jump_speed/2:
			velocity.y = jump_speed/2
			self.player_state = state.FALL

func get_move_direction():
	var move: Vector2 = Vector2.ZERO
	
	if Input.is_action_pressed("move_right" ):
		move.x = 1
	elif Input.is_action_pressed("move_left"):
		move.x = -1
	else: move.x = 0
	if Input.is_action_pressed("move_down"):
		move.y = 1
	elif Input.is_action_pressed("move_up"):
		move.y = -1
	else: move.y = 0
		
	return move

func manage_movement(delta):
	move_direction = get_move_direction()
	var _horizontal_velocity = move_direction.normalized().x * move_speed
	var snap = Vector2.DOWN * 32 if is_grounded else Vector2.ZERO
	previous_speed = Vector2(velocity.x, velocity.y) if velocity.y > 0 else previous_speed	
	is_grounded = true if is_on_floor() else false
	
	# Handle sprite direction
	if move_direction.x != 0:
		transform.x = Vector2(move_direction.x,0).normalized()
	##
	# ACTIVE STATES
	##
	match(player_state):
		state.IDLE:
			velocity.x = 0
		state.RUN:
			if move_direction.x == 0: self.player_state = state.IDLE
		state.JUMP:
			is_grounded = false
			if can_jump:
				velocity.y = jump_speed
			can_jump = false
			if velocity.y > 0: 
				self.player_state = state.FALL
		state.FALL:
			if move_direction.x == 0 and is_on_floor():
				self.player_state = state.IDLE
			elif move_direction.x != 0 and is_on_floor():
				self.player_state = state.RUN
	
#	# Running Dust
#	if player_state != state.RUN:
#		$RunDust.emitting = false
#	elif $RunDust.emitting == false:
#		$RunDust.emitting = true
#
#	# Sliding Dust
#	if player_state != state.WALLSLIDE:
#		$Sprite/RightArm/SlideDust.emitting = false
#	elif $Sprite/RightArm/SlideDust.emitting == false:
#		$Sprite/RightArm/SlideDust.emitting = true
	"""
	Landing particles and squash and stretch
	"""	
	if is_on_floor():
		if not hit_the_ground:
			$Sprite.scale.y = range_lerp(abs(previous_speed.y), 0, abs(1700), 0.3, 1.0)
			$Sprite.scale.x = range_lerp(abs(previous_speed.y), 0, abs(1700), 1.0, 2)
#			$LandingDust.emitting = true
			hit_the_ground = true
#	else:
#		if hit_the_ground:
#			$LandingDust.emitting = false
	"""
	Squash and stretch during jump
	"""		
	if not is_on_floor():
		if velocity.y < 0:
			$Sprite.scale.y = range_lerp(abs(velocity.y), 0, abs(jump_speed), 1.0, 1.75)
			$Sprite.scale.x = range_lerp(abs(velocity.y), 0, abs(jump_speed), 1.0, 0.75)
			
	"""
	Ease squash and stretch back to normal size
	"""
	$Sprite.scale.x = lerp($Sprite.scale.x, 1, 0.3)
	$Sprite.scale.y = lerp($Sprite.scale.y, 1, 0.3)

	# Reset jump
	if state.keys()[player_state] in ["IDLE", "RUN"]: 
		can_jump = true
	
	# Default Gravity
	velocity.y += gravity * delta
	
	# Horizontal Velocity
	velocity.x = lerp(velocity.x, _horizontal_velocity, acceleration)
	
	# Apply Movement
	velocity = move_and_slide_with_snap(velocity, snap, Vector2.UP, true, 4, deg2rad(52))
		
func update_animation(player_state):
	var sprite = $Sprite.get_animation_state()
	
	match(player_state):
		"IDLE":
			sprite.set_animation("idle", true, 0)
		"RUN":
			sprite.set_animation("run", true, 0)
		"JUMP":
			sprite.set_animation("jump", true, 0)
		"FALL":
			sprite.set_animation("fall", false,0)
#			sprite.add_animation("fall", 0.4, true)
	
func _physics_process(delta):
	manage_movement(delta)
