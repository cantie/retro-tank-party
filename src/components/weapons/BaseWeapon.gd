extends Reference

var tank
var weapon_type
var bullet_spawn_pool

func setup_weapon(_tank, _weapon_type) -> void:
	tank = _tank
	weapon_type = _weapon_type
	
	bullet_spawn_pool = SyncManager.get_spawn_pool("Bullet--" + str(tank.player_index))
	bullet_spawn_pool.connect("spawn", self, "_on_bullet_spawn_pool_spawn")

func teardown_weapon() -> void:
	bullet_spawn_pool.disconnect("spawn", self, "_on_bullet_spawn_pool_spawn")

func attach_weapon() -> void:
	pass

func detach_weapon() -> void:
	pass

func create_bullet(bullet_name: String = ''):
	var bullet = weapon_type.bullet_scene.instance()
	tank.get_parent().add_child(bullet)
	bullet.setup_bullet(tank, weapon_type)
	if bullet_name != '':
		bullet.name = bullet_name
	bullet_spawn_pool.track_node(bullet, (bullet_name == ''))
	return bullet

func _on_bullet_spawn_pool_spawn(bullet_name):
	create_bullet(bullet_name)

func fire_weapon() -> void:
	create_bullet()
