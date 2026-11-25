extends Camera2D

@export_category("Handheld Sway")
## How fast the camera moves back and forth.
@export var sway_speed: float = 1.5

## The maximum translation offset (position shift) in pixels.
@export var max_position_sway: float = 20.0  # Increased for 2D pixels
## The maximum rotational offset (tilt) in degrees.
@export var max_rotation_sway: float = 40.0

# Noise generator for smooth, non-jerky movement
var noise: FastNoiseLite = FastNoiseLite.new()
var time_passed: float = 0.0

# Fixed for 2D: position is Vector2, rotation is a single float number
var base_position: Vector2
var base_rotation: float

func _ready() -> void:
	# Configure noise for organic, low-frequency movement
	noise.seed = randi()
	noise.noise_type = FastNoiseLite.TYPE_PERLIN
	noise.frequency = 0.5
	
	# Cache the initial starting values
	base_position = position
	base_rotation = rotation

func _process(delta: float) -> void:
	# Keep track of time to sample smoothly along the noise curve
	time_passed += delta * sway_speed
	
	# Sample different sections of the noise map using arbitrary coordinate offsets
	var n_x = noise.get_noise_1d(time_passed)
	var n_y = noise.get_noise_1d(time_passed + 100.0)
	var n_r = noise.get_noise_1d(time_passed + 200.0)
	
	# Apply translation sway (subtle drifting up/down and left/right)
	position.x = base_position.x + (n_x * max_position_sway)
	position.y = base_position.y + (n_y * max_position_sway)
	
	# Apply 2D rotation sway 
	rotation = base_rotation + deg_to_rad(n_r * max_rotation_sway)
