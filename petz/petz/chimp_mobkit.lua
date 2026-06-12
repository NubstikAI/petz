--
--CHIMP
--

petz.register("chimp", {
	description = "Chimp",
	scale_model = 2.0,
	skin_colors = {"dark_brown"},
	collisionbox = {
		p1 = {x= -0.1425, y = -0.5, z = -0.07},
		p2 = {x= 0.10, y = -0.125, z = 0.175}
	},
	has_affinity = true,
	is_arboreal = true,
	is_wild = false,
	is_pet = true,
	max_hp = 8,
	give_orders = true,
	can_be_brushed = true,
	init_tamagochi_timer = true,
	max_speed = 2,
	view_range = 10,
	capture_item = "lasso",
	jump_height = 5.0,
	makes_footstep_sound = true,

	logic = "herbivore",

	drops = {
		{name = "petz:bone", chance = 4, min = 1, max = 1,},
	},
	--head = {
		--position = vector.new(0, 0.5, 0.2908),
		--rotation_origin = vector.new(-90, 0, 0), --in degrees, normally values are -90, 0, 90
		--eye_offset = -0.2,
	--},
	animation = {
		walk={range={x=1, y=12}, speed=25, loop=true},
		run={range={x=1, y=12}, speed=25, loop=true},
		stand={
			{range={x=12, y=24}, speed=5, loop=true},
			{range={x=24, y=36}, speed=10, loop=true},
			{range={x=36, y=48}, speed=10, loop=true},
		},
		sit = {range={x=51, y=60}, speed=5, loop=true},
		hang = {range={x=63, y=75}, speed=5, loop=true},
		climb= {range={x=78, y=90}, speed=5, loop=true},
	},
	sounds = {
		misc = {"petz_chimp_hoo", "petz_chimp_hoo_2"},
		moaning = "petz_chimp_moaning",
	},
})
