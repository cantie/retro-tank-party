extends "res://src/components/abilities/BaseAbility.gd"

const Tank = preload("res://src/objects/Tank.gd")
const ShadowTank = preload("res://mods/core/abilities/ShadowTank.tscn")

onready var timer = $Timer

const BOOST_SPEED := 3495251

var last_movement_direction := 65536
var boosting := false
var spawn_rate := 2
var spawn_counter := 0

func attach_ability() -> void:
	tank.hooks.subscribe("shoot", self, "_hook_tank_shoot", -100)
	tank.hooks.subscribe("calculate_movement_vector", self, "_hook_tank_calculate_movement_vector", 10)

func detach_ability() -> void:
	tank.hooks.unsubscribe("shoot", self, "_hook_tank_shoot")
	tank.hooks.unsubscribe("calculate_movement_vector", self, "_hook_tank_calculate_movement_vector")

func spawn() -> void:
	var tank_parent: Node2D = tank.get_parent()
	var shadow_tank = ShadowTank.instance()
	tank_parent.add_child(shadow_tank)
	tank_parent.move_child(shadow_tank, 0)
	shadow_tank.setup_shadow_tank(tank)

func _save_state() -> Dictionary:
	var state = ._save_state()
	state['boosting'] = boosting
	state['spawn_counter'] = spawn_counter
	return state

func _load_state(state: Dictionary) -> void:
	._load_state(state)
	boosting = state['boosting']
	spawn_counter = state['spawn_counter']

func _network_process(delta: float, input: Dictionary) -> void:
	if boosting:
		if spawn_counter <= 0:
			spawn_counter = spawn_rate
			spawn()
		
		spawn_counter -= 1

func use_ability() -> void:
	if charges > 0 and not boosting:
		charges -= 1
		tank.speed = BOOST_SPEED
		timer.start()
		boosting = true

func _hook_tank_shoot(event: Tank.TankEvent) -> void:
	if boosting:
		event.stop_propagation()

func _hook_tank_calculate_movement_vector(event: Tank.CalculateMovementVectorEvent) -> void:
	if boosting:
		event.movement_vector.x = last_movement_direction
	elif event.movement_vector.x != 0:
		last_movement_direction = -65536 if event.movement_vector.x < 0 else 65536

func mark_finished() -> void:
	if boosting:
		charges = 0
	else:
		.mark_finished()

func _on_Timer_timeout() -> void:
	tank.speed = tank.DEFAULT_SPEED
	boosting = false
	if charges == 0:
		emit_signal("finished")
