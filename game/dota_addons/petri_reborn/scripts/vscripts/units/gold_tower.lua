local pN = "particles/units/heroes/hero_shadow_demon/shadow_demon_shadow_poison_stackui02.vpcf"
local pN2 = "particles/units/heroes/hero_shadow_demon/shadow_demon_shadow_poison_stackui.vpcf"


function GetGoldAutocast( event )
	local caster = event.caster
	local target = event.target
	local ability = event.ability

	caster:CastAbilityNoTarget(ability, caster:GetPlayerOwnerID())
end

function Spawn ( entityKeyValues  )
	Timers:CreateTimer(3.65,
    function()
    	if thisEntity:IsNull() == false and thisEntity:GetPlayerOwner() ~= nil then
			local particleName = pN
			local particleName2 = pN2
			
			if tonumber(lvls[thisEntity:GetPlayerOwnerID()]) >= 150000 then
			    particleName = "particles/units/heroes/hero_abaddon/abaddon_curse_counter_stack.vpcf"
				particleName2 = "particles/units/heroes/hero_abaddon/abaddon_curse_counter_stack.vpcf"
			end
		
    		thisEntity:GetAbilityByIndex(0):ToggleAutoCast()
			thisEntity.particle = ParticleManager:CreateParticle( particleName, PATTACH_OVERHEAD_FOLLOW, thisEntity )
			
			ParticleManager:SetParticleControl( thisEntity.particle, 1, Vector( 0, 1, 0) )	
		    ParticleManager:SetParticleControl( thisEntity.particle, 0, thisEntity:GetAbsOrigin() )
		    ParticleManager:SetParticleControl( thisEntity.particle, 2, Vector( 3, 999999, 0) )
    	end
    end)
end 

function GetGold( event )
	local caster = event.caster
	local ability = event.ability

	local pID = caster:GetPlayerOwnerID()
	if caster:IsSilenced() == false then
		AddCustomGold( pID, tonumber(event["gold"]) )
	end
end

function Upgrade ( event   )
	local caster = event.caster
	local ability = event.ability
	local particle = caster.particle

	local particleName = pN
	local particleName2 = pN2
	
	local tower_level = ability:GetLevel()

	SetCustomBuildingModel(caster, PlayerResource:GetSteamAccountID(caster:GetPlayerOwnerID()), tower_level+1)
	
	if tonumber(lvls[caster:GetPlayerOwnerID()]) >= 150000 then
	    particleName = "particles/units/heroes/hero_abaddon/abaddon_curse_counter_stack.vpcf"
		particleName2 = "particles/units/heroes/hero_abaddon/abaddon_curse_counter_stack.vpcf"
	end

	caster:GetAbilityByIndex(0):SetLevel(tower_level+1)

	print("GOLDTOWERPARTICLE: "..particle)
	
	ParticleManager:DestroyParticle(particle, true)	
	caster.particle = ParticleManager:CreateParticle( particleName, PATTACH_OVERHEAD_FOLLOW, caster )
	ParticleManager:SetParticleControl( caster.particle, 1, Vector( 0, ability:GetLevel()+1, 0) )	
	ParticleManager:SetParticleControl( caster.particle, 0, caster:GetAbsOrigin() )
	ParticleManager:SetParticleControl( caster.particle, 2, Vector( 3, 999999, 0) )
	
	if ability:GetLevel()+1 >= 10 then
		ParticleManager:DestroyParticle(caster.particle, true)	
	    caster.particle = ParticleManager:CreateParticle( particleName2, PATTACH_OVERHEAD_FOLLOW, caster )
	    ParticleManager:SetParticleControl( caster.particle, 1, Vector( 1, ability:GetLevel()-9, 0) )	
	    ParticleManager:SetParticleControl( caster.particle, 0, caster:GetAbsOrigin() )
	    ParticleManager:SetParticleControl( caster.particle, 2, Vector( 3, 999999, 0) )
	end
end