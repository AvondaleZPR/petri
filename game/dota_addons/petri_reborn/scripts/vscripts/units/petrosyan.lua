require('duels')

function BonusGoldFromWall(keys)
	local caster = keys.caster
	local target = keys.target
	local ability = keys.ability

	local bonusGold = ability:GetSpecialValueFor("bonus_gold_from_wall") or 1
	local bonusExp = ability:GetSpecialValueFor("bonus_exp_from_wall") or 0

	if (target:GetUnitName() == "npc_petri_wall" or target:GetUnitName() == "npc_petri_earth_wall") and target:GetModifierStackCount("modifier_hit_stacks",target) > bonusGold then
		AddCustomGold( caster:GetPlayerOwnerID(), bonusGold )
		caster:AddExperience(bonusExp,0,false,false)

		caster.petrosyanScore = (caster.petrosyanScore or 0) + 5

		PopupParticle(bonusGold, Vector(244,201,23), 3.0, caster)

		target:SetModifierStackCount("modifier_hit_stacks",target,target:GetModifierStackCount("modifier_hit_stacks",target) - bonusGold)
	end

	if target:HasAbility("petri_creep_pendant") == true 
	and caster:GetAverageTrueAttackDamage(caster) >= target:FindAbilityByName("petri_creep_pendant"):GetLevelSpecialValueFor( "damage", -1 ) and math.floor(GameMode.PETRI_TRUE_TIME/60) >= 48 then
		if caster:HasModifier("modifier_bonus_damage") then
			caster:RemoveModifierByName("modifier_bonus_damage")
		end

		AddCustomGold( caster:GetPlayerOwnerID(), 3500 )
		PopupParticle(3500, Vector(244,201,23), 1.0, caster)
	end
end

function ModifierSuperLifesteal(keys)
	if keys.target:HasAbility("petri_cop_trap") == false then
		if keys.target:HasAbility("petri_building") then
			keys.ability:ApplyDataDrivenModifier(keys.attacker, keys.attacker, "modifier_item_petri_uber_mask_of_laugh_datadriven_lifesteal_building", {duration = 0.03})
		else
			keys.ability:ApplyDataDrivenModifier(keys.attacker, keys.attacker, "modifier_item_petri_uber_mask_of_laugh_datadriven_lifesteal", {duration = 0.03})
		end
	end
end

function ModifierLifesteal(keys)
	if keys.target:HasAbility("petri_cop_trap") == false then
		if keys.target:HasAbility("petri_building") then
			keys.ability:ApplyDataDrivenModifier(keys.attacker, keys.attacker, "modifier_item_petri_mask_of_laugh_datadriven_lifesteal_building", {duration = 0.03})
		else
			keys.ability:ApplyDataDrivenModifier(keys.attacker, keys.attacker, "modifier_item_petri_mask_of_laugh_datadriven_lifesteal", {duration = 0.03})
		end
	end
end

--[[
	Author: Noya
	Date: 17.01.2015.
	Gives vision over an area and shows a particle to the team
]]
function FarSight( event )
	local caster = event.caster
	local ability = event.ability
	local level = ability:GetLevel()
	local reveal_radius = ability:GetLevelSpecialValueFor( "reveal_radius", level - 1 )
	local duration = ability:GetLevelSpecialValueFor( "duration", level - 1 )

	local particleName = "particles/items_fx/dust_of_appearance.vpcf"
	if tonumber(lvls[caster:GetPlayerOwnerID()]) >= 125000 then
	    particleName = "particles/econ/items/crystal_maiden/crystal_maiden_cowl_of_ice/maiden_crystal_nova_cowlofice.vpcf"
	end
	local target = event.target_points[1]

	EmitSoundOnLocationForAllies(target, "DOTA_Item.DustOfAppearance.Activate", caster)

    -- Particle for team
    local particle = ParticleManager:CreateParticle(particleName, PATTACH_WORLDORIGIN, caster)
    ParticleManager:SetParticleControl( particle, 0, target )
    ParticleManager:SetParticleControl( particle, 1, Vector(reveal_radius,1,reveal_radius) )
    ParticleManager:ReleaseParticleIndex( particle )

    local units = FindUnitsInRadius(caster:GetTeamNumber(), target, nil, reveal_radius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, FIND_ANY_ORDER,false)

	for i,v in ipairs(units) do
		if v:HasAbility("petri_building") == true then
			if not v.minimapIcon then
				v.minimapIcon = CreateUnitByName("npc_dummy_enemy_building_icon", v:GetAbsOrigin(), false, v, v, DOTA_TEAM_GOODGUYS)
			end
		end
	end
    
    -- Vision
    AddFOWViewer(caster:GetTeamNumber(), target, reveal_radius, duration, false)
end

function FlatJoke( keys )
	local caster = keys.caster
	local target = keys.target
	local ability = keys.ability

	local cooldown = ability:GetCooldown(ability:GetLevel()-1)

	if caster[ability:GetName()] then
		local void_pfx = ParticleManager:CreateParticle("particles/units/heroes/hero_antimage/antimage_manavoid.vpcf", PATTACH_POINT_FOLLOW, caster)
		ParticleManager:SetParticleControlEnt(void_pfx, 0, caster, PATTACH_POINT_FOLLOW, "attach_hitloc", caster:GetOrigin(), true)
		ParticleManager:SetParticleControl(void_pfx, 1, Vector(radius,0,0))
		ParticleManager:ReleaseParticleIndex(void_pfx)

		caster:EmitSound(caster[ability:GetName()].sound)
		
		StartAnimation(caster, {duration=0.5, activity=_G[caster[ability:GetName()].anim], rate=2.0, translate=caster[ability:GetName()].translate})
	end

	ability:StartCooldown(cooldown)
	Timers:CreateTimer(cooldown, function (  )
		ability:ApplyDataDrivenModifier(caster,caster,"modifier_flat_joke_datadriven",{})
	end)
end

function Sleep(keys)
	local caster = keys.caster
	local target = keys.target
	local ability = keys.ability
	
	RemoveGatheringAndRepairingModifiers(target)

	for i=0,target:GetAbilityCount()-1 do
		if target:GetAbilityByIndex(i) ~= nil and target:GetAbilityByIndex(i):GetToggleState() then
			target:GetAbilityByIndex(i):ToggleAbility()
		end
	end

	ability:ApplyDataDrivenModifier(caster, target, "sleep_modifier", {duration=ability:GetLevel()})

	if target:HasItemInInventory("item_alarm_clock") then
		for i = 0, 5 do
		    local item = target:GetItemInSlot(i)
			if item and item:GetAbilityName() == "item_alarm_clock" and item:IsCooldownReady() then
                target:RemoveModifierByName("sleep_modifier")
				item:StartCooldown(item:GetCooldown(item:GetLevel()))
				
				target:EmitSound("DOTA_Item.LinkensSphere.Target")
            end			
		end
	end
	
	-- for i=0,target:GetModifierCount() do
	-- 	local modifierName = target:GetModifierNameByIndex(i)
	-- 	target:RemoveModifierByName(modifierName)
	-- end
end

function Return( keys )
	local caster = keys.caster
	local target
	
	if caster.onduel == true then
	    if Duels.ison == false and Duels.pcount <= 1 then
	        Duels:ClearDuelists()
			Return(keys)
		end
	else
	
	if caster:GetUnitName() == "npc_dota_hero_brewmaster" then
		target = GameMode.villians["npc_dota_hero_death_prophet"]
	end
	if caster:GetUnitName() == "npc_dota_hero_death_prophet" then
		target = GameMode.villians["npc_dota_hero_brewmaster"]
	end

	if target and (caster:GetAbsOrigin() - target:GetAbsOrigin()):Length2D() <= 2950 then
	    local t=0
	    Timers:CreateTimer(function (  )
	    	target:RemoveModifierByName("modifier_petri_solo")
	    	t = t + 0.03
	    	if t < 15 then return 0.03 end
	    end)
	end

	caster.teleportationState = 0

	caster:Stop()
    PlayerResource:SetCameraTarget(caster:GetPlayerOwnerID(), caster)

	Timers:CreateTimer(0.1,
    function()
    	local particleName = "particles/econ/events/nexon_hero_compendium_2014/teleport_end_ground_flash_nexon_hero_cp_2014.vpcf"
		local particle = ParticleManager:CreateParticle( particleName, PATTACH_CUSTOMORIGIN, caster )
		ParticleManager:SetParticleControl( particle, 0, caster.spawnPosition )
		ParticleManager:ReleaseParticleIndex( particle )

		PlayerResource:SetCameraTarget(caster:GetPlayerOwnerID(), nil)
    end)

	FindClearSpaceForUnit(caster,caster.spawnPosition,true)

	caster:Stop()
	local newOrder = {
        UnitIndex       = caster:entindex(),
        OrderType       = DOTA_UNIT_ORDER_MOVE_TO_POSITION,
        Position        = caster:GetAbsOrigin(), 
        Queue           = 0
    }

  	ExecuteOrderFromTable(newOrder)
	
	end
end

function SpawnWard(keys)
	local point = keys.target_points[1]
	local caster = keys.caster

	local ward = CreateUnitByName("npc_petri_ward", point,  true, nil, caster, DOTA_TEAM_BADGUYS)

	keys.ability:ApplyDataDrivenModifier(caster, ward, "modifier_ward_invisibility", {})

	InitAbilities(ward)
	StartAnimation(ward, {duration=-1, activity=ACT_DOTA_IDLE , rate=1.5})
end

function SpawnJanitor( keys )
	local caster = keys.caster

	local janitor = CreateUnitByName("npc_petri_janitor", caster:GetAbsOrigin(), true, nil, caster, DOTA_TEAM_BADGUYS)
	janitor:SetControllableByPlayer(caster:GetPlayerOwnerID(), false)
	janitor:SetOwner(caster)

	-- UpdateModel(janitor, "models/heroes/death_prophet/death_prophet_ghost.vmdl", 1.0)
	-- for i=0,15 do
	-- 	if janitor:GetAbilityByIndex(i) ~= nil then janitor:RemoveAbility(janitor:GetAbilityByIndex(i):GetName())  end
	-- end

	--janitor:AddAbility("courier_transfer_items")

	--InitAbilities(janitor)

	janitor:SetHasInventory(true)
	janitor:SetMoveCapability(2)
	janitor.spawnPosition = caster.spawnPosition
end

function ReadBookOfLaugh( keys )
	local caster = keys.caster
	caster:HeroLevelUp(false)
	caster:HeroLevelUp(false)
	caster:HeroLevelUp(false)
	caster:HeroLevelUp(false)
	caster:HeroLevelUp(true)
end

function ReadBookOfExperience1( keys )
	local caster = keys.caster
	caster:AddExperience(3,0,false,false)
end

function ReadBookOfExperience2( keys )
	local caster = keys.caster
	caster:AddExperience(100,0,false,false)
end

function ReadBookOfExperience3( keys )
	local caster = keys.caster
	caster:AddExperience(1,0,false,false)
end

function ReadComedyStory( keys )
	local caster = keys.caster

	caster:SetBaseDamageMin(caster:GetBaseDamageMin() + 70000)
	caster:SetBaseDamageMax(caster:GetBaseDamageMax() + 70000)

	caster:CalculateStatBonus()
end

function ReadComedyBook( keys )
	local caster = keys.caster
	
	caster:SetBaseStrength(caster:GetBaseStrength() + 250)

	caster:CalculateStatBonus()
end

function BuySnares( keys )
	local caster = keys.caster
	local player = keys.caster:GetPlayerOwner()
	local pID = player:GetPlayerID()
	local ability = keys.ability

	caster = GameMode.assignedPlayerHeroes[pID]
	
	local sleep_ability = caster:FindAbilityByName("petri_petrosyan_sleep")
	if sleep_ability then
		caster:AddAbility("petri_petrosyan_snare_1")
		caster:FindAbilityByName("petri_petrosyan_snare_1"):UpgradeAbility(false)
		caster:SwapAbilities("petri_petrosyan_sleep", "petri_petrosyan_snare_1", false, true)
		caster:RemoveAbility("petri_petrosyan_sleep")
	else
		AddCustomGold( pID, keys.ItemCost )
	end
end

function BuyUpgradedSnares( keys )
	local caster = keys.caster
	local player = keys.caster:GetPlayerOwner()
	local pID = player:GetPlayerID()
	local ability = keys.ability

	caster = GameMode.assignedPlayerHeroes[pID]
	
	local snare_ability = caster:FindAbilityByName("petri_petrosyan_snare_1")
	if snare_ability then
		caster:AddAbility("petri_petrosyan_snare_2")
		caster:FindAbilityByName("petri_petrosyan_snare_2"):UpgradeAbility(false)
		caster:SwapAbilities("petri_petrosyan_snare_1", "petri_petrosyan_snare_2", false, true)
		caster:RemoveAbility("petri_petrosyan_snare_1")
	else
		AddCustomGold( pID, keys.ItemCost )
	end
end

function OnAwake( keys )
	local caster = keys.caster
	Notifications:Bottom(caster:GetPlayerOwnerID(), {text="#petri_start", duration=5, style={color="white", ["font-size"]="45px"}})
	if GameRules.firstPetrosyanIsAwake == nil then
		GameRules.firstPetrosyanIsAwake = true
		Notifications:TopToTeam(DOTA_TEAM_GOODGUYS, {text="#petrosyan_is_awake", duration=4, style={color="red", ["font-size"]="45px"}})
		print("First petrosyan is awake")
	end
end

function OnKill( keys )
	local caster = keys.caster
	local unit = keys.unit
	print("Asdasd")
	-- caster:AddExperience(unit:GetDeathXP(), DOTA_ModifyXP_CreepKill, false, true)
end

function JediAura( keys )
	local caster = keys.caster
	local target = keys.target

	if target:GetUnitName() == "npc_petri_trap" then
		DestroyEntityBasedOnHealth(caster, target)
	end
end

function CheckSolo( keys )
	local caster = keys.caster
	local ability = keys.ability
	local target

	if caster:GetUnitName() == "npc_dota_hero_brewmaster" then
		target = GameMode.villians["npc_dota_hero_death_prophet"]
	end
	if caster:GetUnitName() == "npc_dota_hero_death_prophet" then
		target = GameMode.villians["npc_dota_hero_brewmaster"]
	end

	local units = FindUnitsInRadius(caster:GetTeamNumber(),caster:GetAbsOrigin(),nil,500,DOTA_UNIT_TARGET_TEAM_BOTH,DOTA_UNIT_TARGET_ALL,DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES,0,false)

	for k,v in pairs(units) do
		if v:GetUnitName() == "npc_petri_creep_bad_actor" or
			v:GetUnitName() == "npc_petri_creep_kvn_actor" or
			v:GetUnitName() == "npc_petri_creep_dead_actor" or
			v:GetUnitName() == "npc_petri_creep_draconoid" or
			v:GetUnitName() == "npc_petri_creep_good_actor" or
			v:GetUnitName() == "npc_petri_creep_draconoid2" or
			v:GetUnitName() == "npc_petri_creep_humorist" or
			v:GetUnitName() == "npc_petri_creep_petro_assistant" or
			v:GetUnitName() == "npc_petri_creep_fat_troll" or
			v:GetUnitName() == "npc_petri_creep_mutant" or
			v:GetUnitName() == "npc_petri_creep_special1" or
			v:GetUnitName() == "npc_petri_creep_special2" or
			v:GetUnitName() == "npc_petri_creep_special3" or
			v:GetUnitName() == "npc_petri_creep_special4" or
			v:GetUnitName() == "npc_petri_creep_special5" or
			v:GetUnitName() == "npc_petri_creep_special6" or
			v:GetUnitName() == "npc_petri_creep_special7" or
			v:GetUnitName() == "npc_petri_creep_special8" or
			v:GetUnitName() == "npc_petri_creep_special9" or
			v:GetUnitName() == "npc_petri_creep_kivin" or
			v:GetUnitName() == "npc_dota_hero_storm_spirit" or
			v:GetUnitName() == "npc_petri_loose_trigger1" or
			v:GetUnitName() == "npc_petri_loose_trigger2" or
			v:GetUnitName() == "npc_petri_loose_trigger3" then
			caster:RemoveModifierByName("modifier_petri_solo")
			return
		end
	end

	if not target or (caster:GetAbsOrigin() - target:GetAbsOrigin()):Length2D() >= 2950 and caster:GetUnitName() ~= "npc_dota_hero_storm_spirit" then
		caster:RemoveModifierByName("modifier_petri_solo")

		ability:ApplyDataDrivenModifier(caster,caster,"modifier_petri_solo",{duration = 1.0})

		local time = math.floor(GameMode.PETRI_TRUE_TIME/60)

		local limit
		local multiplier

		if time >= 36 and time < 100 then
			limit = 10000000
			multiplier = 95
		elseif time >= 32 and time < 36 then
			limit = 10000000
			multiplier = 95
		elseif time >= 28 and time < 32 then
			limit = 10000000
			multiplier = 90
		elseif time >= 24 and time < 28 then
			limit = 10000000
			multiplier = 90
		elseif time >= 20 and time < 24 then
			limit = 10000000
			multiplier = 90
		elseif time >= 16 and time < 20 then
			limit = 10000000
			multiplier = 85
		elseif time >= 12 and time < 16 then
			limit = 10000000
			multiplier = 85
		elseif time >= 8 and time < 12 then
			limit = 10000000
			multiplier = 85
		elseif time >= 4 and time < 8 then
			limit = 10000000
			multiplier = 85
		else 
			limit = 200
			multiplier = 30
		end

		local damage = math.ceil((caster:GetAverageTrueAttackDamage(caster) / 100) * multiplier)
		damage = math.min(math.max(damage, 1), limit)

		caster:SetModifierStackCount("modifier_petri_solo",caster,damage)
	else
		caster:RemoveModifierByName("modifier_petri_solo")
	end
end