function Spawn ( entityKeyValues  )
	Timers:CreateTimer(2.1,
    function()
    	if thisEntity:IsNull() == false and thisEntity:GetPlayerOwner() ~= nil then

			thisEntity:GetPlayerOwner():GetAssignedHero().maxFood = thisEntity:GetPlayerOwner():GetAssignedHero().maxFood + 30
	    	thisEntity.foodProvided = 30
		end
    end)
end

function Upgrade ( event   )
	local caster = event.caster
	local ability = event.ability
	local player = caster:GetPlayerOwner()

	local tent_level = ability:GetLevel()

	if tent_level == 1 then
		caster:SetModelScale(0.4)
	elseif tent_level == 2 then 
		UpdateModel(caster, "models/props_structures/tent_dk_med", 0.45)
	elseif tent_level == 3 then
		UpdateModel(caster, "models/props_structures/tent_dk_large.vmdl", 0.24)
	end

	SetCustomBuildingModel(caster, PlayerResource:GetSteamAccountID(player:GetPlayerID()), tent_level+1)

	local hero = player:GetAssignedHero()

	hero.maxFood = hero.maxFood + 30
	caster.foodProvided = caster.foodProvided  + 30
end