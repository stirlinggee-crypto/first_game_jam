extends CharacterBody2D

const NORMAL_SPEED = 200.0
const GOD_SPEED = 800.0

var gravity_direction = 1 
var base_gravity = 980.0
var god_mode = false

# Countdown starting time set to 50 seconds
var time_left = 50.0
# Tracks how long the player has been falling without touching a surface or swapping gravity
var fall_timer = 0.0

func _ready() -> void:
	# Check the current scene path and lower gravity if we are on World 2
	var current_scene = get_tree().current_scene
	if current_scene and current_scene.scene_file_path == "res://world2.tscn":
		base_gravity = 450.0 # Lower gravity for World 2 (default is 980.0)

func _physics_process(delta: float) -> void:
	# 1. Calculate speed multiplier so distance covered matches time remaining
	var current_speed = GOD_SPEED if god_mode else NORMAL_SPEED
	var speed_multiplier = current_speed / NORMAL_SPEED

	# 2. Update Countdown Timer (Ticks faster in God Mode)
	if time_left > 0.0:
		time_left -= delta * speed_multiplier
		if time_left <= 0.0:
			time_left = 0.0
			# Advance to World 2 when the timer hits 0
			get_tree().change_scene_to_file("res://world2.tscn")
			return
	
	# Display clean whole number without ".0" at the end
	$Label.text = str(int(ceil(time_left)))



	# 4. Constant Rightward Movement
	velocity.x = current_speed

	# 5. Gravity Swap Logic (Also resets the airborne fall timer)
	if Input.is_action_just_pressed("ui_shift") or Input.is_action_just_pressed("gravity_toggle"):
		gravity_direction *= -1
		fall_timer = 0.0
		$AnimatedSprite2D.flip_v = (gravity_direction == -1)

	# 6. Apply Gravity
	if god_mode:
		velocity.y = 0.0
	else:
		velocity.y += base_gravity * gravity_direction * delta

	# 7. Move the Character
	move_and_slide()

	# 8. Update Animations
	update_animations()

	# 9. Only check for death and fall duration if God Mode is OFF
	if not god_mode:
		# Reset fall timer when touching floor or ceiling; count up while airborne
		if is_on_floor() or is_on_ceiling():
			fall_timer = 0.0
		else:
			fall_timer += delta
			if fall_timer >= 10.0:
				game_over()
				return

		if is_on_wall() and abs(get_real_velocity().x) < 1.0:
			game_over()
		check_tilemap_interactions()
	else:
		fall_timer = 0.0

func update_animations() -> void:
	if god_mode:
		$AnimatedSprite2D.play("run")
	elif is_on_floor() or is_on_ceiling():
		$AnimatedSprite2D.play("run")
	else:
		$AnimatedSprite2D.play("fall")



# Switches back to the main menu scene on death
func game_over() -> void:
	get_tree().change_scene_to_file("res://main_menu.tscn")

func check_tilemap_interactions() -> void:
	for i in get_slide_collision_count():
		var collision = get_slide_collision(i)
		var collider = collision.get_collider()
		
		if collider is TileMap or collider is TileMapLayer:
			var tile_position = collider.local_to_map(collider.to_local(collision.get_position() - collision.get_normal()))
			var tile_data = collider.get_cell_tile_data(0, tile_position) if collider is TileMap else collider.get_cell_tile_data(tile_position)
			
			if tile_data:
				var is_hazard = tile_data.get_custom_data("hazard_type") == "red"
				var function_value = tile_data.get_custom_data("tile_function")
				
				if is_hazard or function_value == "die" or function_value == "game_over":
					game_over()
					return
