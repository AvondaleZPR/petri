function ToWall(keys)
    local caster = keys.caster
	local target = keys.target
	local ability = keys.ability
	local duration = ability:GetSpecialValueFor("duration")
	
	if target:GetPlayerOwner() == caster:GetPlayerOwner() and target.blocks ~= false then
	if string.match(target:GetUnitName(), "wall") or target:GetUnitName() == "npc_petri_cop_trap" then
	    print("ToWall")
		--target:GetPlayerOwner():GetAssignedHero().canbuid = false
		if target.fpos == nil then
		    target.fpos = target:GetAbsOrigin()
		end
		local pos = target.fpos
		for k, v in pairs(target.blockers) do
            DoEntFireByInstanceHandle(v, "Disable", "1", 0, nil, nil)
            DoEntFireByInstanceHandle(v, "Kill", "1", 1, nil, nil)
        end
		target.blocks = false
		Timers:CreateTimer(duration, function()
		    if target then
		    if target:IsAlive() then
				for k, v in pairs(target.blockers) do
                    DoEntFireByInstanceHandle(v, "Disable", "1", 0, nil, nil)
                    DoEntFireByInstanceHandle(v, "Kill", "1", 1, nil, nil)
                end
		        target.blockers = BuildingHelper:BlockGridNavSquare(2, pos)
			    Timers:CreateTimer(0.01, function()
				    if target then
					if target:IsAlive() and target.blocks == false then
			        target:SetAbsOrigin(pos)
					--target:GetPlayerOwner():GetAssignedHero().canbuid = true
					target.blocks = true
					GameMode:SaveBuildingToPSO(target)
					end
					end
			    end)
			end
			end
		end)
	else
	    ability:EndCooldown()
	end
	else
	    ability:EndCooldown()
	end
end

function ToSelf(keys)
	--if keys.caster:GetTeam() == DOTA_TEAM_GOODGUYS then
	    --print("ToSelf")
        --keys.ability:ApplyDataDrivenModifier(keys.caster, keys.caster, "modifier_item_superkey", {})
	--end
end

function Aura(keys)
    local caster = keys.caster
	local ability = keys.ability
	local radius = ability:GetSpecialValueFor("radius")
	Timers:CreateTimer(0.1, function()
	    if caster:HasItemInInventory("item_petri_superkey") and caster:IsRealHero() and caster:GetTeam() == DOTA_TEAM_GOODGUYS and caster:IsAlive() then
		if ability.enabled ~= false then
		    local walls = findWalls(caster, radius)
			for _, wall in pairs(walls) do
			if wall then
			if string.match(wall:GetUnitName(), "wall") then --or wall:GetUnitName() == "npc_petri_cop_trap" then
			if wall.blocks ~= false and wall:IsAlive() and wall:GetPlayerOwner() == caster:GetPlayerOwner() then
			    if wall.fpos == nil then
				   wall.fpos = wall:GetAbsOrigin()
				end
				
				--wall:GetPlayerOwner():GetAssignedHero().canbuid = false
								
		        local pos = wall.fpos
				if wall.blockers then
			    for k, v in pairs(wall.blockers) do
                    DoEntFireByInstanceHandle(v, "Disable", "1", 0, nil, nil)
                    DoEntFireByInstanceHandle(v, "Kill", "1", 1, nil, nil)
                end
				end
				wall.blocks = false
				
				Timers:CreateTimer(0.1, function()
				--print(caster:GetPlayerOwner():GetAssignedHero():GetAbsOrigin())
		        local walls2 = findWalls(caster, radius)
					local bool = false
					for _, wall2 in pairs(walls2) do
					if wall == wall2 and wall:IsAlive() then
                        bool = true
					end
					end
					if not caster:HasItemInInventory("item_petri_superkey") or not caster:IsAlive() or ability.enabled == false then
					    bool = false
					end
					--print("bool "..tostring(bool))
					if bool == false then
					    print("blocking wall")
						wall.blocks = true
						if wall.blockers then
			            for k, v in pairs(wall.blockers) do
                            DoEntFireByInstanceHandle(v, "Disable", "1", 0, nil, nil)
                            DoEntFireByInstanceHandle(v, "Kill", "1", 1, nil, nil)
                        end
				        end
						if wall then
						if wall:IsAlive() then
			                wall.blockers = BuildingHelper:BlockGridNavSquare(2, pos)
					        Timers:CreateTimer(0.01, function()
			                wall:SetAbsOrigin(pos)
							GameMode:SaveBuildingToPSO(wall)
					      	--wall:GetPlayerOwner():GetAssignedHero().canbuid = true
			                end)
						end
						end
						return nil
					end
					return 0.1
		        end)
			end
			end
			end
			end
			end
			return 0.1
		else
		    print("superkey stop aura")
			ability.enabled = true
		    return nil
		end
	end)
end

function switchsuper(keys)
    local ability = keys.ability
	local caster = keys.caster
	local text = ""
	if ability.enabled == false then
	    ability.enabled = true
		text = "#superkey_enabled"
	else
	    ability.enabled = false
		text = "#superkey_disabled"
	end
	Notifications:Top(caster:GetPlayerOwnerID(), {text=text, duration=4, style={color="white"}, continue=false})
end

function findWalls(caster, radius)
	return FindUnitsInRadius(DOTA_TEAM_GOODGUYS,
                          caster:GetPlayerOwner():GetAssignedHero():GetAbsOrigin(),
                          nil,
                          radius,
                          DOTA_UNIT_TARGET_TEAM_FRIENDLY,
                          DOTA_UNIT_TARGET_ALL,
                          DOTA_UNIT_TARGET_FLAG_NONE,
                          FIND_ANY_ORDER,
                          false)
end