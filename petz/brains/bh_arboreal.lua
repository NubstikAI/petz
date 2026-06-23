--
-- ARBOREAL BRAIN
--

function petz.check_tree(self)
	local node_front_name, _, node = petz.node_name_in(self, "front")
	local node_top_name = petz.node_name_in(self, "top")

	local is_front_tree = false
	if node then
		is_front_tree = petz.is_tree_like(node)
	end

	-- If we are already climbing, we only require 'front' to be a tree to continue
	if self.status == "climb" then
		if node_front_name and minetest.registered_nodes[node_front_name]
			and node_top_name and minetest.registered_nodes[node_top_name]
			and is_front_tree then
				return true
		else
			return false
		end
	end

	-- To start climbing, both front and front_top must be tree-like.
	-- This prevents climbing logic from hijacking normal 1-block-high steps on the canopy.
	local node_front_top_name, _, node_front_top = petz.node_name_in(self, "front_top")
	local is_front_top_tree = false
	if node_front_top then
		is_front_top_tree = petz.is_tree_like(node_front_top)
	end

	if node_front_name and minetest.registered_nodes[node_front_name]
		and node_top_name and minetest.registered_nodes[node_top_name]
		and is_front_tree
		and is_front_top_tree then
			return true
	else
		return false
	end
end

function petz.is_tree_like(node)
	if not node or not node.name then return false end
	local def = minetest.registered_nodes[node.name]
	if not def or not def.groups then return false end

	if def.groups.leaves or def.groups.tree then
		return true
	else
		return false
	end
end

function petz.check_ground(self)
	local pos = kitz.get_stand_pos(self)
	if not pos then return false end

	-- Check node directly underneath us
	local pos_under = {x = pos.x, y = pos.y - 0.5, z = pos.z}
	local node_under = minetest.get_node_or_nil(pos_under)
	if not node_under or node_under.name == "air" then
		pos_under.y = pos_under.y - 0.5
		node_under = minetest.get_node_or_nil(pos_under)
	end

	if node_under and minetest.registered_nodes[node_under.name] then
		local name = node_under.name
		-- We reached the ground if the block below is solid/walkable and NOT tree-like
		if name ~= "air" and name ~= "ignore" and not petz.is_tree_like(node_under) then
			local def = minetest.registered_nodes[name]
			if def and def.walkable ~= false then
				return true
			end
		end
	end
	return false
end

function petz.bh_climb(self, pos, prty)
	-- If we are actively climbing or descending, immediately return true so the brain doesn't cancel our queues!
	if self.status == "climb" or self.status == "climb_down1" or self.status == "climb_down2" then
		return true
	end

	-- Check if we are already sitting in/on a tree canopy
	local pos_under = {x = pos.x, y = pos.y - 0.5, z = pos.z}
	local node_under = minetest.get_node_or_nil(pos_under)
	if not node_under or node_under.name == "air" then
		pos_under.y = pos_under.y - 0.5
		node_under = minetest.get_node_or_nil(pos_under)
	end

	if node_under and petz.is_tree_like(node_under) then
		-- We're currently in a tree. Give it a small chance per check to decide to climb down.
		if math.random(1, 100) <= 2 then
			petz.hq_climb_down(self, prty)
			kitz.animate(self, 'climb')
			return true
		end
		-- Return false so it stays on this tree and doesn't try to climb others
		return false
	end

	-- Normal climbing up logic
	if petz.check_tree(self) then
		petz.hq_climb(self, prty)
		kitz.animate(self, 'climb')
		return true
	else --search for a tree
		if kitz.timer(self, 60) then
			local view_range = self.view_range
			local nearby_wood = minetest.find_nodes_in_area(
				{x = pos.x - view_range, y = pos.y - view_range, z = pos.z - view_range},
				{x = pos.x + view_range, y = pos.y + view_range, z = pos.z + view_range},
				{"group:tree"})
			if #nearby_wood >= 1 then
				local tpos = nearby_wood[1]
				kitz.hq_goto(self, prty, tpos)
				return true
			end
		end
	end
	return false
end

function petz.hq_climb(self, prty)
	kitz.clear_queue_low(self) -- Force clear low queue to stop any normal walking immediately
	local func=function()
		if not petz.check_tree(self) then
			self.status = nil
			kitz.clear_queue_high(self)
			kitz.clear_queue_low(self)
			kitz.animate(self, 'stand')
			return true
		end
		if kitz.is_queue_empty_low(self) then
			self.status = "climb"
			petz.lq_climb(self)
		end
	end
	kitz.queue_high(self,func,prty)
end

function petz.hq_climb_down(self, prty)
	kitz.clear_queue_low(self) -- Force clear low queue so any active wander/idle is stopped
	local func = function()
		if petz.check_ground(self) then
			-- We touched the ground safely! End descent, face away from the tree to prevent immediate climb up.
			self.status = nil
			self.object:set_yaw((self.object:get_yaw() + math.pi) % (2 * math.pi))
			kitz.clear_queue_high(self)
			kitz.clear_queue_low(self)
			kitz.animate(self, 'stand')
			return true
		end
		if kitz.is_queue_empty_low(self) then
			self.status = "climb_down1"
			petz.lq_climb_down(self)
		end
	end
	kitz.queue_high(self, func, prty)
end

function petz.lq_climb(self)
	local func = function()
		local pos = self.object:get_pos()
		pos.y = pos.y + 1
		local node_top = minetest.get_node_or_nil(pos)
		if not(node_top) then
			return true
		end
		local node_top_name= node_top.name
		local node_front_top_name, front_top_pos, node = petz.node_name_in(self, "front_top")

		if node_top_name and minetest.registered_nodes[node_top_name]
			and node_front_top_name and (petz.is_tree_like(node)) then
				local climb = false
				local climb_pos
				local scan_pos = {x = pos.x, y = pos.y, z = pos.z}

				for i = 1, 8 do
					scan_pos.y = scan_pos.y + 1.1
					local scan_node = minetest.get_node_or_nil(scan_pos)
					if not scan_node then
						climb = false
						break
					end

					local def = minetest.registered_nodes[scan_node.name]
					local is_walkable = def and (def.walkable ~= false)

					if scan_node.name == "air" then
						climb = true
						scan_pos.y = scan_pos.y + 0.5
						climb_pos = {x = scan_pos.x, y = scan_pos.y, z = scan_pos.z}
						break
					elseif petz.is_tree_like(scan_node) then
						-- It's a trunk or leaf, keep scanning upwards
					elseif not is_walkable then
						-- Ignore non-walkable nodes (e.g. banana) and keep scanning
						climb = true
						scan_pos.y = scan_pos.y + 0.5
						climb_pos = {x = scan_pos.x, y = scan_pos.y, z = scan_pos.z}
						break
					else
						climb = false
						break
					end
				end

				if climb then
					self.object:set_velocity({x = 0, y = 1.5, z = 0})
					return false -- keep the low queue active to scale the trunk smoothly
				end

		elseif node_front_top_name == "air" then
			local prop = self.object:get_properties()
			local collisionbox = prop.collisionbox
			self.object:set_pos({
				x=math.floor(front_top_pos.x + 0.5),
				y=math.floor(front_top_pos.y + 0.5) + collisionbox[2],
				z=math.floor(front_top_pos.z + 0.5)
			})
			self.object:set_velocity({x = 0, y = 0, z = 0})

			self.status = nil
			kitz.clear_queue_high(self)
			kitz.clear_queue_low(self)
			kitz.animate(self, 'stand')
			return true
		end

		self.status = nil
		kitz.clear_queue_high(self)
		kitz.clear_queue_low(self)
		kitz.animate(self, 'stand')
		return true
	end
	kitz.queue_low(self, func)
end

function petz.lq_climb_down(self)
	local func = function()
		local pos = self.object:get_pos()
		if not pos then return true end

		local dir_x
		local dir_z

		local yaw = self.object:get_yaw()
		if yaw then dir_x = -math.sin(yaw); dir_z = math.cos(yaw)
		else return true
		end

		local node_front_below_name, front_below_pos, node_front_below = petz.node_name_in(self, "front_below")

		if self.status == "climb_down1" then
			local node_below_name, below_pos, node_below = petz.node_name_in(self, "below")

			if petz.is_tree_like(node_below) then
				if node_front_below and not node_front_below.walkable then
					local pos_below = { x = math.floor(pos.x + 0.5), y = pos.y - 1, z = math.floor(pos.z + 0.5) }
					local pos_front_below = { x = math.floor(pos.x + dir_x + 0.5), y = pos.y + 0.5, z = math.floor(pos.z + dir_z + 0.5) }

					self.status = "climb_down2"
					self.object:set_pos(pos_front_below)

					-- Rotate to face the tree trunk
					yaw = core.dir_to_yaw(vector.subtract(pos_below, pos_front_below))
					self.object:set_yaw(yaw)

					dir_x = -math.sin(yaw); dir_z = math.cos(yaw)
				else
					self.object:set_yaw((math.random(0, 360) - 180) / 180 * math.pi)
					return true -- abort climb down attempt as we're not on the edge
				end
			else
				return true -- abort climb down attempt as we're hanging half-in-air
			end
		else
			if not petz.is_tree_like(node_front_below) then
				return true -- no longer holding on to the tree trunk, fall off
			end
		end

		-- Slide down safely at -1.5 m/s while constantly pushing toward the trunk
		-- to physically hug the side of the wood
		self.object:set_velocity({
			x = 0,--dir_x * 0.8,
			y = -1.5,
			z = 0,--dir_z * 0.8
		})
		return false -- keep running until hq_climb_down clears the queue upon landing
	end
	kitz.queue_low(self, func)
end