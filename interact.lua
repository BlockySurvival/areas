local S = minetest.get_translator("areas")

local old_is_protected = minetest.is_protected
function minetest.is_protected(pos, name)
	if not areas:canInteract(pos, name) then
		return true
	end
	return old_is_protected(pos, name)
end

minetest.register_on_protection_violation(function(pos, name)
	if not areas:canInteract(pos, name) then
		local owners = areas:getNodeOwners(pos)
		minetest.chat_send_player(name,
			S("@1 is protected by @2.",
				minetest.pos_to_string(pos),
				table.concat(owners, ", ")))
		local player = minetest.get_player_by_name(name)
		if player and player:is_player() then
			-- invert the player's yaw/pitch on violation
			local yaw = player:get_look_horizontal() + math.pi
			if yaw > 2 * math.pi then
				yaw = yaw - 2 * math.pi
			end
			player:set_look_horizontal(yaw)
			player:set_look_vertical(-player:get_look_vertical())
			-- if the player digs a node below them, teleport 0.8 up
			local player_pos = player:get_pos()
			if pos.y < player_pos.y then
				player:set_pos({
					x = player_pos.x,
					y = player_pos.y + 0.8,
					z = player_pos.z
				})
			end
		end
	end
end)

minetest.register_on_punchplayer(function(player, hitter, time_from_last_punch, tool_capabilities, dir, damage)
	-- If it's a mob, deal damage as usual
	if not hitter:is_player() then
		return false
	end
	-- Check if the victim is in an area with allowed PvP or in an unprotected area
	local inAreas = areas:getAreasAtPos(hitter:getpos())
	-- If the table is empty, PvP is allowed
	if not next(inAreas) then
		return false
	end
	-- Do any of the areas have allowed PvP?
	for id, area in pairs(inAreas) do
		if area.canPvP then
			return false
		end
	end
	-- Otherwise, it doesn't do damage
	minetest.chat_send_player(hitter:get_player_name(), "PvP is not allowed in this area!")
	return true
end)
