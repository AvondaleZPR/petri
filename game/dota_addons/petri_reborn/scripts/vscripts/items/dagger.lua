function Blink(keys)
	local point = keys.target_points[1]
	local caster = keys.caster
	local casterPos = caster:GetAbsOrigin()
	local difference = point - casterPos
	local ability = keys.ability
	local range = ability:GetLevelSpecialValueFor("blink_range", (ability:GetLevel() - 1))
	local hero = caster:GetPlayerOwner():GetAssignedHero()

	if caster:HasAbility("petri_upgrade_to_cop") then
		caster:FindAbilityByName("petri_upgrade_to_cop"):StartCooldown(1.0)
	end

	if difference:Length2D() > range then
		point = casterPos + (point - casterPos):Normalized() * range
	end
	
	if caster:IsRealHero() then
	caster.isblink = true
	local s = CreateUnitByName("npc_dummy_unit", point, false, nil, nil, DOTA_TEAM_GOODGUYS)
	local item = CreateItem("item_petri_jedi",nil,nil)
    item:ApplyDataDrivenModifier(s,s,"modifier_jedi_invu",{})
	Timers:CreateTimer(1, function()
	if (Entities:FindByName(nil, "blocking_trigger_b"):IsTouching(s)) then
        ability:EndCooldown()
    else
	
	if ability:IsItem() then
	    ability:Kill()
	end

	FindClearSpaceForUnit(caster, point, false)
	
	caster:SetRespawnPosition(point)
	caster.spawnPosition = point
	
	caster.isblink = false
	
	Timers:CreateTimer(1, function()
	print("CHEKAEM BLYAD")
	if caster.currentArea ~= nil and caster:IsRealHero() == true then
		if CheckAreaClaimers(hero, caster.currentArea.claimers) or caster.currentArea.claimers == nil then
			if caster.currentArea.claimers == nil or
				(caster.currentArea.claimers and caster.currentArea.claimers[0] and caster.currentArea.claimers[0]:IsAlive() == false
					and (not caster.currentArea.claimers[1] or caster.currentArea.claimers[1]:IsAlive() == false)) then 
				print("REGAEM BLYAD")
				Notifications:Top(caster:GetPlayerOwnerID(), {text="#area_claimed", duration=4, style={color="white"}, continue=false})
			end
				
			caster.currentArea.claimers = caster.currentArea.claimers or {}
			if caster.currentArea.claimers[0] ~= nil and caster.currentArea.claimers[0]:IsAlive() == false then
				if not caster.currentArea.claimers[1] or caster.currentArea.claimers[1]:IsAlive() == false then 
					caster.currentArea.claimers[0] = hero 
				end
			elseif caster.currentArea.claimers[0] == nil then 
			    caster.currentArea.claimers[0] = hero 
		    end
		end
	end
	end)
	
	end
	--Timers:CreateTimer(1, function()
	--end)
	s:ForceKill(false)
	end)
	else
	    if ability:IsItem() then
	        ability:Kill()
	    end

	    FindClearSpaceForUnit(caster, point, false)
	end
end

function OnTakeDamage(keys)
	local attacker_name = keys.attacker:GetName()

    if keys.Damage > 0 and (attacker_name == "npc_dota_roshan" or keys.attacker:IsControllableByAnyPlayer()) then  --If the damage was dealt by neutrals or lane creeps, essentially.
	    if keys.ability then
        if keys.ability:GetCooldownTimeRemaining() < keys.BlinkDamageCooldown then
            keys.ability:StartCooldown(keys.BlinkDamageCooldown)
        end
		end
    end
end