extends "res://src/objects/tank/BaseTank.gd"

const BaseWeaponType = preload("res://mods/core/weapons/base.tres")
const Explosion = preload("res://src/objects/Explosion.tscn")
const EventDispatcher = preload("res://src/utils/EventDispatcher.gd")

export (bool) var player_controlled = false

signal player_dead (killer_id)
signal shoot ()
signal hurt (damage, attacker_id, attack_vector)
signal weapon_type_changed (weapon_type)
signal ability_type_changed (ability_type)
signal ability_recharged (ability)

onready var player_info_node := $PlayerInfo
onready var player_info_offset: Vector2 = player_info_node.position

onready var shoot_cooldown_timer := $ShootCooldownTimer
onready var animation_player := $AnimationPlayer
onready var shoot_sound := $ShootSound
onready var engine_sound := $EngineSound

const DEFAULT_TURN_SPEED := 10923
const DEFAULT_SPEED := 873726

var turn_speed := DEFAULT_TURN_SPEED
var speed := DEFAULT_SPEED
var velocity: SGFixedVector2 = SGFixed.vector2(0, 0)

var health := 100
var dead := false
var invincible := false

var can_shoot := true
var shoot_rumble := 0.025

# Flags set via _unhandled_input() that are used in gathering input.
var _input_shoot := false
var _input_use_ability := false
var _input_mouse_control := true

var hooks := EventDispatcher.new()

var game
var camera: Camera2D = null

var weapon_type: WeaponType
var weapon
var held_ability_type: AbilityType
var ability_charges := 1

var player_index: int

class TankEvent extends EventDispatcher.Event:
	var tank
	
	func _init(_tank) -> void:
		tank = _tank

class PickupWeaponEvent extends TankEvent:
	var weapon_type: WeaponType
	
	func _init(_tank, _weapon_type: WeaponType).(_tank) -> void:
		weapon_type = _weapon_type

class PickupAbilityEvent extends TankEvent:
	var ability_type: AbilityType
	
	func _init(_tank, _ability_type: AbilityType).(_tank) -> void:
		ability_type = _ability_type

class TakeDamageEvent extends TankEvent:
	var damage: int
	var attacker_id: int
	var attack_vector: SGFixedVector2
	
	func _init(_tank, _damage: int, _attacker_id: int, _attack_vector: SGFixedVector2).(_tank) -> void:
		damage = _damage
		attacker_id = _attacker_id
		attack_vector = _attack_vector

class RestoreHealthEvent extends TankEvent:
	var health: int
	
	func _init(_tank, _health: int).(_tank) -> void:
		health = _health

class DieEvent extends TankEvent:
	var killer_id: int
	
	func _init(_tank, _killer_id: int).(_tank) -> void:
		killer_id = _killer_id

class GatherInputEvent extends TankEvent:
	var input: Dictionary
	
	func _init(_tank, _input: Dictionary).(_tank) -> void:
		input = _input

class CalculateMovementVectorEvent extends TankEvent:
	var input: Dictionary
	var movement_vector: SGFixedVector2
	
	func _init(_tank, _input: Dictionary, _movement_vector: SGFixedVector2).(_tank) -> void:
		input = _input
		movement_vector = _movement_vector

enum PlayerInput {
	TURRET_ROTATION = -1,
	
	CONTROL_SCHEME = 0,
	INPUT_VECTOR,
	SHOOTING,
	USING_ABILITY,
}

func _ready():
	hooks.subscribe("pickup_ability", self, "_hook_default_pickup_ability", 0)
	hooks.subscribe("pickup_weapon", self, "_hook_default_pickup_weapon", 0)
	hooks.subscribe("shoot", self, "_hook_default_shoot", 0)
	hooks.subscribe("use_ability", self, "_hook_default_use_ability", 0)
	hooks.subscribe("take_damage", self, "_hook_default_take_damage", 0)
	hooks.subscribe("restore_health", self, "_hook_default_restore_health", 0)
	hooks.subscribe("die", self, "_hook_default_die", 0)
	hooks.subscribe("gather_input", self, "_hook_default_gather_input", 0)
	hooks.subscribe("calculate_movement_vector", self, "_hook_default_calculate_movement_vector", 0)
	
	player_info_node.set_as_toplevel(true)
	player_info_node.position = global_position + player_info_offset
	
	var sprite_material = body_sprite.material.duplicate()
	body_sprite.material = sprite_material
	turret_sprite.material = sprite_material
	
	set_weapon_type(BaseWeaponType)
	
	SyncManager.connect("scene_spawned", self, "_on_SyncManager_scene_spawned")
	
	# If testing tank on its own, make player controlled
	if get_tree().current_scene == self:
		player_controlled = true
	
	if player_controlled:
		Globals.my_player_position = global_position

func _notification(what) -> void:
	if what == NOTIFICATION_PREDELETE:
		hooks.clear()

func _network_spawn_preprocess(data: Dictionary) -> Dictionary:
	data['game'] = data['game'].get_path()
	var player = data['player']
	data.erase('player')
	data['player_index'] = player.index
	data['peer_id'] = player.peer_id
	data['player_name'] = player.name
	data['team'] = player.team
	return data

func _on_SyncManager_scene_spawned(spawned_name, spawned_node, scene, data):
	if spawned_name == name + 'Ability':
		_setup_and_use_ability(spawned_node, data['ability_type'])

func _network_spawn(data: Dictionary) -> void:
	game = get_node(data['game'])
	
	set_global_fixed_transform(data['start_transform'])
	
	player_index = data['player_index']
	set_network_master(data['peer_id'])
	player_info_node.set_player_name(data['player_name'])
	set_tank_color(data['player_index'])
	
	if data['team'] != -1:
		player_info_node.set_team(data['team'])

func pickup_weapon(_weapon_type: WeaponType) -> void:
	hooks.dispatch_event("pickup_weapon", PickupWeaponEvent.new(self, _weapon_type))

func _hook_default_pickup_weapon(event: PickupWeaponEvent) -> void:
	set_weapon_type(event.weapon_type)

func set_weapon_type(_weapon_type: WeaponType) -> void:
	if _weapon_type == null:
		_weapon_type = BaseWeaponType
	
	if weapon_type != _weapon_type:
		weapon_type = _weapon_type
		
		if weapon:
			weapon.detach_weapon()
			weapon.teardown_weapon()
		
		weapon = weapon_type.weapon_script.new()
		weapon.setup_weapon(self, weapon_type)
		weapon.attach_weapon()
		
		if game and player_controlled:
			if weapon_type.resource_path == "res://mods/core/weapons/base.tres":
				game.hud.clear_weapon_label()
			else:
				game.hud.set_weapon_label(weapon_type.name)
		
		emit_signal("weapon_type_changed", weapon_type)

func pickup_ability(_ability_type: AbilityType) -> void:
	hooks.dispatch_event("pickup_ability", PickupAbilityEvent.new(self, _ability_type))

func _hook_default_pickup_ability(event: PickupAbilityEvent) -> void:
	set_held_ability_type(event.ability_type)

func get_ability():
	return $Ability if has_node('Ability') else null

func set_held_ability_type(_ability_type: AbilityType) -> void:
	var ability = get_ability()
	if _ability_type != null and ability and ability.ability_type == _ability_type:
		ability_charges = _ability_type.charges
		_update_ability_label()
		emit_signal("ability_recharged", ability)
	else:
		held_ability_type = _ability_type
		if held_ability_type:
			ability_charges = held_ability_type.charges
		
		_update_ability_label()
		emit_signal("ability_type_changed", held_ability_type)

func _update_ability_label() -> void:
	if game and player_controlled:
		if held_ability_type:
			game.hud.set_ability_label(held_ability_type.name, ability_charges)
		else:
			game.hud.clear_ability_label()



func _get_local_input() -> Dictionary:
	var event = GatherInputEvent.new(self, {})
	hooks.dispatch_event("gather_input", event)
	return event.input

func _hook_default_gather_input(event: GatherInputEvent) -> void:
	var input = event.input
	
	if GameSettings.control_scheme != GameSettings.ControlScheme.MODERN:
		input[PlayerInput.CONTROL_SCHEME] = GameSettings.control_scheme
	
	var input_vector: Vector2
	if Input.is_action_pressed("player1_turn_left"):
		input_vector.x -= min(Input.get_action_strength("player1_turn_left") + 0.5, 1.0)
	if Input.is_action_pressed("player1_turn_right"):
		input_vector.x += min(Input.get_action_strength("player1_turn_right") + 0.5, 1.0)
	if Input.is_action_pressed("player1_forward"):
		input_vector.y -= min(Input.get_action_strength("player1_forward") + 0.5, 1.0)
	if Input.is_action_pressed("player1_backward"):
		input_vector.y += min(Input.get_action_strength("player1_backward") + 0.5, 1.0)
	
	if input_vector != Vector2.ZERO:
		input[PlayerInput.INPUT_VECTOR] = SGFixed.from_float_vector2(input_vector)
	
	if _input_mouse_control:
		input[PlayerInput.TURRET_ROTATION] = SGFixed.from_float((get_global_mouse_position() - turret_pivot.global_position).angle())
	else:
		if Input.is_action_pressed("player1_aim_up") or Input.is_action_pressed("player1_aim_down") or Input.is_action_pressed("player1_aim_left") or Input.is_action_pressed("player1_aim_right"):
			var joy_vector = Vector2()
			joy_vector.x = Input.get_action_strength("player1_aim_right") - Input.get_action_strength("player1_aim_left")
			joy_vector.y = Input.get_action_strength("player1_aim_down") - Input.get_action_strength("player1_aim_up")
			input[PlayerInput.TURRET_ROTATION] = SGFixed.from_float(joy_vector.angle())
	
	if _input_shoot:
		input[PlayerInput.SHOOTING] = true
	if _input_use_ability:
		input[PlayerInput.USING_ABILITY] = true
	
	_input_shoot = false
	_input_use_ability = false

func _calculate_movement_vector(input: Dictionary) -> SGFixedVector2:
	var event = CalculateMovementVectorEvent.new(self, input, SGFixed.vector2(0, 0))
	hooks.dispatch_event("calculate_movement_vector", event)
	return event.movement_vector
	
func _hook_default_calculate_movement_vector(event: CalculateMovementVectorEvent) -> void:
	var input: Dictionary = event.input
	if not input.has(PlayerInput.INPUT_VECTOR):
		return
	
	if input.get(PlayerInput.CONTROL_SCHEME, GameSettings.ControlScheme.MODERN) == GameSettings.ControlScheme.RETRO:
		var input_vector = input[PlayerInput.INPUT_VECTOR]
		# Movement is relative to a tank facing to the right, so Y turns to the
		# left/right, and X moves forward backward.
		event.movement_vector.x = -input_vector.y
		event.movement_vector.y = input_vector.x
		return
	
	#var movement_vector: Vector2
	#var current_vector = SGFixed.vector2(65536, 0)
	#current_vector.rotate(fixed_rotation)
	
#	var desired_vector: Vector2 = input.get(PlayerInput.INPUT_VECTOR, Vector2.ZERO)
#	if desired_vector.length() > 0.85:
#		desired_vector = desired_vector.normalized()
#
#	# If going backwards is a shorter rotation, move backwards.
#	if abs(current_vector.angle_to(desired_vector)) > PI / 2.0:
#		# Flip the vector for the angle calculations.
#		current_vector = current_vector.rotated(PI)
#
#		# Set us moving backwards ...
#		movement_vector.x = -desired_vector.length()
#	else:
#		# ... or forwards
#		movement_vector.x = desired_vector.length()
#
#	# Normalize the angle to the desired vector
#	var angle_to = current_vector.angle_to(desired_vector)
#	if abs(angle_to) > PI / 2.0:
#		angle_to = TAU - angle_to
#
#	movement_vector.y = clamp(angle_to / (turn_speed * get_physics_process_delta_time()), -1.0, 1.0)
#
#	return movement_vector

func _predict_remote_input(previous_input: Dictionary, ticks_since_real_input: int) -> Dictionary:
	var input = previous_input.duplicate()
	if ticks_since_real_input > 5:
		input.erase(PlayerInput.INPUT_VECTOR)
	
	# We get turrent input from the most recent input.
	var latest_input: Dictionary = SyncManager.get_latest_input_for_node(self)
	if latest_input.has(PlayerInput.TURRET_ROTATION):
		input[PlayerInput.TURRET_ROTATION] = latest_input[PlayerInput.TURRET_ROTATION]
	
	return input

func _network_process(delta: float, input: Dictionary) -> void:
	var movement_vector = _calculate_movement_vector(input)
	
	engine_sound.turning = false
	if movement_vector.y < 0:
		engine_sound.turning = true
	if movement_vector.y > 0:
		engine_sound.turning = true
	
	if movement_vector.y != 0:
		rotate_and_slide(SGFixed.mul(movement_vector.y, turn_speed))

	if movement_vector.x != 0:
		velocity.clear()
		#velocity.y = 0
		velocity.x = movement_vector.x
		velocity.rotate(fixed_rotation)
		velocity.imul(speed)
		move_and_slide(velocity)
	
	Globals.my_player_position = global_position
	
	if movement_vector.x >= 0.1 or movement_vector.x <= -0.1:
		engine_sound.engine_state = engine_sound.EngineState.DRIVING
	else:
		engine_sound.engine_state = engine_sound.EngineState.IDLE
	
	if input.has(PlayerInput.TURRET_ROTATION):
		turret_pivot.set_global_fixed_rotation(input[PlayerInput.TURRET_ROTATION])
	else:
		turret_pivot.fixed_rotation = 0
	
	if input.get(PlayerInput.SHOOTING, false) and can_shoot:
		can_shoot = false
		shoot_cooldown_timer.start()
		shoot()
		Globals.rumble.add_weak_rumble(shoot_rumble)

	if input.get(PlayerInput.USING_ABILITY, false):
		use_ability()
	
	_after_update_position()

func _after_update_position() -> void:
	# Make info follow the tank
	player_info_node.position = global_position + player_info_offset
	
	if camera:
		camera.global_position = global_position

func _save_state() -> Dictionary:
	return {
		fixed_transform = fixed_transform.copy(),
		turret_rotation = turret_pivot.get_global_fixed_rotation(),
		can_shoot = can_shoot,
		health = health,
		speed = speed,
		weapon_type = weapon_type.resource_path,
		held_ability_type = held_ability_type.resource_path if held_ability_type else null,
		ability_charges = ability_charges,
	}

func _load_state(state: Dictionary) -> void:
	fixed_transform = state['fixed_transform']
	
	turret_pivot.set_global_fixed_rotation(state['turret_rotation'])
	can_shoot = state['can_shoot']
	update_health(state['health'])
	speed = state['speed']
	set_weapon_type(load(state['weapon_type']))
	set_held_ability_type(load(state['held_ability_type']) if state['held_ability_type'] else null)
	ability_charges = state['ability_charges']
	
	sync_to_physics_engine()
	_after_update_position()
	_update_ability_label()

func _interpolate_state(old_state: Dictionary, new_state: Dictionary, weight: float) -> void:
	position = lerp(old_state['fixed_transform'].origin.to_float(), new_state['fixed_transform'].origin.to_float(), weight)
	scale = lerp(old_state['fixed_transform'].get_scale().to_float(), new_state['fixed_transform'].get_scale().to_float(), weight)
	rotation = lerp_angle(SGFixed.to_float(old_state['fixed_transform'].get_rotation()), SGFixed.to_float(new_state['fixed_transform'].get_rotation()), weight)
	turret_pivot.global_rotation = lerp_angle(SGFixed.to_float(old_state['turret_rotation']), SGFixed.to_float(new_state['turret_rotation']), weight)
	_after_update_position()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		_input_mouse_control = true
	if event is InputEventJoypadButton or event is InputEventJoypadMotion:
		_input_mouse_control = false
	if event.is_action_pressed("player1_shoot"):
		_input_shoot = true
	if event.is_action_pressed("player1_use_ability"):
		_input_use_ability = true

func shoot() -> void:
	hooks.dispatch_event("shoot", TankEvent.new(self))

func _hook_default_shoot(event: TankEvent) -> void:
	if not get_parent():
		return
	
	emit_signal("shoot")
	shoot_sound.play()
	weapon.fire_weapon()

func use_ability() -> void:
	hooks.dispatch_event("use_ability", TankEvent.new(self))

func _hook_default_use_ability(event: TankEvent):
	if not get_parent():
		return
	
	if held_ability_type:
		var ability = get_ability()
		if ability:
			_on_ability_finished(ability)
		
		ability = SyncManager.spawn('Ability', self, held_ability_type.ability_scene, {
			ability_type = held_ability_type,
		}, false, name + 'Ability')
		
		ability.use_ability()
		
		ability_charges -= 1
		if ability_charges == 0:
			held_ability_type = null
		_update_ability_label()

# Called via the 'scene_spawned' signal when the ability is created.
func _setup_and_use_ability(ability, ability_type):
	ability.connect("finished", self, "_on_ability_finished", [ability])
	ability.setup_ability(self, ability_type)
	ability.attach_ability()

func _on_ability_finished(old_ability) -> void:
	old_ability.disconnect("finished", self, "_on_ability_finished")
	
	old_ability.detach_ability()
	remove_child(old_ability)
	old_ability.queue_free()

func _on_ShootCooldownTimer_timeout() -> void:
	can_shoot = true

func take_damage(damage: int, attacker_id: int = -1, attack_vector: SGFixedVector2 = SGFixed.vector2(0, 0)) -> void:
	hooks.dispatch_event("take_damage", TakeDamageEvent.new(self, damage, attacker_id, attack_vector))

func _hook_default_take_damage(event: TakeDamageEvent) -> void:
	if dead:
		return
	if player_controlled:
		if GameSettings.use_screenshake and camera:
			# Between 0.25 and 0.5 seems good
			camera.add_trauma(0.5)
		
		Globals.rumble.add_rumble(0.25)
	
	animation_player.play("Flash")
	
	emit_signal("hurt", event.damage, event.attacker_id, event.attack_vector)
	
	if not invincible:
		health -= event.damage
		if health <= 0:
			die(event.attacker_id)
		else:
			update_health(health)

func restore_health(_health: int) -> void:
	hooks.dispatch_event("restore_health", RestoreHealthEvent.new(self, _health))

func _hook_default_restore_health(event: RestoreHealthEvent) -> void:
	if is_network_master():
		health += event.health
		if health > 100:
			health = 100
		update_health(health)

remotesync func update_health(_health) -> void:
	health = clamp(_health, 0, 100)
	player_info_node.update_health(health)

remotesync func die(killer_id: int = -1) -> void:
	hooks.dispatch_event("die", DieEvent.new(self, killer_id))

func _hook_default_die(event: DieEvent) -> void:
	if not dead:
		dead = true
		
		SyncManager.spawn("Explosion", get_parent(), Explosion, {
			position = global_position,
			scale = 1.5,
			type = "fire",
		})
		
		queue_free()
		
		emit_signal("player_dead", event.killer_id)
