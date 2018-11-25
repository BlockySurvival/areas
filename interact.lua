
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
			("%s is protected by %s."):format(
				minetest.pos_to_string(pos),
				table.concat(owners, ", ")))
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
   if next(inAreas) == nil then
      return false
   end
   -- Do any of the areas have allowed PvP?
   for a in pairs(inAreas) do
      if a.canPvP then
         return false
      end
   end
   -- Otherwise, it doesn't do damage
   minetest.chat_send_player(hitter:get_player_name(), "PvP is not allowed in this area!")
   return true
end)
