function Interrogation(keys) 
    local caster = keys.caster
	local target = keys.target
	
	if target and target:GetPlayerOwner() and target:GetPlayerOwner():GetAssignedHero() then
	    local hero = target:GetPlayerOwner():GetAssignedHero()
		local origin = hero:GetAbsOrigin()
		MinimapEvent(caster:GetTeam(), caster, origin.x, origin.y, DOTA_MINIMAP_EVENT_HINT_LOCATION, 15 )
	else
	    keys.ability:EndCooldown()
	end
end
