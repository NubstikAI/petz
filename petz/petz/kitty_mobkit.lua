--
--KITTY
--

petz.register("kitty", {
	description = "Kitty",
	scale_model = 2.0,
	scale_baby = 0.5,
	skin_colors = {"brown", "black", "dark_gray", "camel", "light_gray", "siamese"},
	collisionbox = {
		p1 = {x= -0.0625, y = -0.5, z = -0.25},
		p2 = {x= 0.125, y = -0.0625, z = 0.25}
	},
	has_affinity = true,
	is_pet = true,
	sleep_at_day = true,
	sleep_ratio = 0.3,
	max_hp = 18,
	give_orders = true,
	can_be_brushed = true,
	breed = true,
	init_tamagochi_timer = true,
	max_speed = 2,
	view_range = 10,
	capture_item = "net",
	jump_height = 3,

	logic = "herbivore",

	drops = {
		{name = "petz:bone", chance = 5, min = 1, max = 1,},
	},

	head = {
		position = vector.new(0, 0.2908, -0.2908),
		rotation_origin = vector.new(-90, 0, 0), --in degrees, normally values are -90, 0, 90
		eye_offset = -0.2,
	},

	animation = {
		idle = {range={x=0, y=0}, speed=25, loop=false},
		walk={range={x=1, y=12}, speed=25, loop=true},
		run={range={x=13, y=25}, speed=25, loop=true},
		stand={
			{range={x=26, y=46}, speed=5, loop=true},
			{range={x=47, y=59}, speed=5, loop=true},
		},
		sit = {range={x=60, y=65}, speed=5, loop=false},
		sleep = {range={x=81, y=93}, speed=10, loop=false},
	},

	sounds = {
		misc = {"petz_kitty_meow", "petz_kitty_meow2", "petz_kitty_meow3"},
		moaning = "petz_kitty_moaning",
	},
})
