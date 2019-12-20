function CancelBuilding(caster, ability, pID, reason)
	if reason ~= "" then Notifications:Top(caster:GetPlayerOwnerID(),{text=reason, duration=4, style={color="red"}, continue=false}) end
	return false
end

function build( keys )
	local player = keys.caster:GetPlayerOwner()
	local hero = player:GetAssignedHero()
	local pID = player:GetPlayerID()
	local caster = keys.caster

	local hero = GameMode.assignedPlayerHeroes[caster:GetPlayerOwnerID()]

	local ability = keys.ability
	
	local gold_cost = GetAbilityGoldCost( ability )

	if GetCustomGold( pID ) < gold_cost then
		return
	end

	local lumber_cost = ability:GetLevelSpecialValueFor("lumber_cost", ability:GetLevel()-1)
	local food_cost = ability:GetLevelSpecialValueFor("food_cost", ability:GetLevel()-1)

	local ability_name = ability:GetName()

	local unit_name
	if GameMode.AbilityKVs[ability_name] then
		unit_name = GameMode.AbilityKVs[ability_name]["UnitName"]
	else
		unit_name = GameMode.ItemKVs[ability_name]["UnitName"]
		ability:EndCooldown()
	end

	EndCooldown(caster, ability_name)

	local dependency = ability_name
	if ability_name == "item_petri_pocketexit" then
		dependency = "build_petri_exit"
	end

	if not CheckBuildingDependencies(pID, dependency) then
		return false
	end

	if not CheckLumber(player, lumber_cost,true) or not CheckFood(player, food_cost,true) or GetCustomGold( pID ) < gold_cost then
		return CancelBuilding(caster, ability, pID, "")
	end

	--Build exit only after 16 min
	if ability:GetName() == "build_petri_exit" or ability_name == "item_petri_pocketexit"  then
		if GameRules.PETRI_EXIT_ALLOWED == false then
			return CancelBuilding(caster, ability, pID, "#too_early_for_exit")
		end
	end

		if ability:GetName() == "build_petri_miracle1" or ability_name == "item_petri_pocketmiracle1"  then
		if GameRules.PETRI_MIRACLE1_ALLOWED == false then
			return CancelBuilding(caster, ability, pID, "#too_early_for_miracle1")
		end
	end

		if ability:GetName() == "build_petri_miracle2" or ability_name == "item_petri_pocketmiracle2"  then
		if GameRules.PETRI_MIRACLE2_ALLOWED == false then
			return CancelBuilding(caster, ability, pID, "#too_early_for_miracle2")
		end
	end

		if ability:GetName() == "build_petri_miracle3" or ability_name == "item_petri_pocketmiracle3"  then
		if GameRules.PETRI_MIRACLE3_ALLOWED == false then
			return CancelBuilding(caster, ability, pID, "#too_early_for_miracle3")
		end
	end
	
	if ability:GetName() == "build_petri_bus_1" and GameMode.busData[1][1] == false then
	    return CancelBuilding(caster, ability, pID, "#already_builded")
	end
	
	if ability:GetName() == "build_petri_bus_2" and GameMode.busData[2][1] == false then
	    return CancelBuilding(caster, ability, pID, "#already_builded")
	end
	
	if ability:GetName() == "build_petri_bus_3" and GameMode.busData[3][1] == false then
	    return CancelBuilding(caster, ability, pID, "#already_builded")
	end
	
	if ability:GetName() == "build_petri_bus_4" and GameMode.busData[4][1] == false then
	    return CancelBuilding(caster, ability, pID, "#already_builded")
	end

	-- Cancel building if limit is reached
	if hero.buildingCount >= GameRules.PETRI_MAX_BUILDING_COUNT_PER_PLAYER then
		return CancelBuilding(caster, ability, pID, "#building_limit_is_reached")
	end

	-- Cancel building if eye was already built
	for k,v in pairs(hero.uniqueUnitList) do
		if k == unit_name and v == true then
			return CancelBuilding(caster, ability, pID, "")
		end
	end

	player.waitingForBuildHelper = true
	
	local returnTable = BuildingHelper:AddBuilding(keys)

	keys:OnBuildingPosChosen(function(vPos)

	end)

	hero.buildingCount = hero.buildingCount + 1

	keys:OnPreConstruction(function ()
        if not CheckLumber(player, lumber_cost,true) or not CheckFood(player, food_cost,true) or GetCustomGold( pID ) < gold_cost or hero.canbuid == false then
        	return false
		else
			if caster.currentArea ~= nil then
				if CheckAreaClaimers(hero, caster.currentArea.claimers) or caster.currentArea.claimers == nil then

					if caster.currentArea.claimers == nil or
						(caster.currentArea.claimers and caster.currentArea.claimers[0] and caster.currentArea.claimers[0]:IsAlive() == false
							and (not caster.currentArea.claimers[1] or caster.currentArea.claimers[1]:IsAlive() == false)) then 
						Notifications:Top(pID, {text="#area_claimed", duration=4, style={color="white"}, continue=false})
					end

					caster.currentArea.claimers = caster.currentArea.claimers or {}
					if caster.currentArea.claimers[0] ~= nil and caster.currentArea.claimers[0]:IsAlive() == false then
						if not caster.currentArea.claimers[1] or caster.currentArea.claimers[1]:IsAlive() == false then 
							caster.currentArea.claimers[0] = hero 
						end
					elseif caster.currentArea.claimers[0] == nil then 
						caster.currentArea.claimers[0] = hero 
					end

				else
					Notifications:Top(pID, {text="#you_cant_build", duration=4, style={color="white"}, continue=false})
					return false
				end
			end

			SpendLumber(player, lumber_cost)
			SpendFood(player, food_cost)
			SpendCustomGold( pID, gold_cost )

			StartCooldown(caster, ability_name)
		end
    end)

	keys:OnConstructionStarted(function(unit)
		local gnvTable = {}
		gnvTable["size"] = returnTable:GetVal("BuildingSize", "number")
		gnvTable["pos"] = unit:GetAbsOrigin() + Vector(gnvTable["size"] / -2, gnvTable["size"] / -2, 0)
		AddKeyToNetTable(unit:entindex(), "gridnav", "building", gnvTable)
		--PrintTable(GetKeyInNetTable(unit:entindex(), "gridnav", "building"))

		if GameMode.UnitKVs[unit_name]["Unique"] == 1 then
			hero.uniqueUnitList[unit_name] = true
		end
		
		if unit:GetUnitName() == "npc_petri_bus_1" then
			Notifications:TopToAll({text="#kvn_build_bus_1", duratione=10, style={color="blue"}, continue=false})
	        GameMode.busData[1][1] = false
			GameMode.busData[1][2] = hero:GetPlayerOwnerID()
			hero.bus[1] = unit
	    end
		
		if unit:GetUnitName() == "npc_petri_bus_2" then
			Notifications:TopToAll({text="#kvn_build_bus_2", duratione=10, style={color="blue"}, continue=false})
	        GameMode.busData[2][1] = false
			GameMode.busData[2][2] = hero:GetPlayerOwnerID()
			hero.bus[2] = unit			
	    end
		
		if unit:GetUnitName() == "npc_petri_bus_3" then
			Notifications:TopToAll({text="#kvn_build_bus_3", duratione=10, style={color="blue"}, continue=false})
	        GameMode.busData[3][1] = false
			GameMode.busData[3][2] = hero:GetPlayerOwnerID()
			hero.bus[3] = unit
	    end
		
		if unit:GetUnitName() == "npc_petri_bus_4" then
			Notifications:TopToAll({text="#kvn_build_bus_4", duratione=10, style={color="blue"}, continue=false})
	        GameMode.busData[4][1] = false
			GameMode.busData[4][2] = hero:GetPlayerOwnerID()
			hero.bus[4] = unit
	    end
		
		if string.match(unit:GetUnitName(), "npc_petri_bus_") then
	        local ditem = CreateItem("item_armor_fix", nil, nil)
            ditem:ApplyDataDrivenModifier(unit, unit, "modifier_bus_total_income", {})	
            unit:SetModifierStackCount("modifier_bus_total_income", unit, 0)			
		end

		if unit:GetUnitName() == "npc_petri_exit" then
		    if hero.boolexit == nil then
			    GameMode:addScore(hero, 1000)
				hero.boolexit = true
			end
			hero.exit = hero.exit or {}
			
			if hero.exit[unit:GetUnitName()] and hero.exit[unit:GetUnitName()]:IsNull() == false and hero.exit[unit:GetUnitName()]:IsAlive() then
				Timers:CreateTimer(0.03, function ()
					unit:ForceKill(false)
				end)
			else
				Notifications:TopToAll({text="#exit_construction_is_started", duratione=10, style={color="blue"}, continue=false})

				GameMode.EXIT_COUNT = GameMode.EXIT_COUNT + 1

				hero.exit[unit:GetUnitName()] = unit

				unit.childEntity = CreateUnitByName("petri_dummy_1400vision", keys.caster:GetAbsOrigin(), false, nil, nil, DOTA_TEAM_BADGUYS)
				-- Timers:CreateTimer(GameMode.PETRI_ADDITIONAL_EXIT_GOLD_TIME, 
				-- 	function() 
				-- 		if unit:IsNull() == false and unit:IsAlive() == true and GameMode.EXIT_COUNT > 1 then
				-- 			if GameMode.PETRI_ADDITIONAL_EXIT_GOLD_GIVEN == true then
				-- 				GiveSharedGoldToHeroes(GameMode.PETRI_ADDITIONAL_EXIT_GOLD, "npc_dota_hero_brewmaster")
				-- 				GiveSharedGoldToHeroes(GameMode.PETRI_ADDITIONAL_EXIT_GOLD, "npc_dota_hero_death_prophet")
				-- 				Notifications:TopToAll({text="#additional_exit_gold", duration=5, style={color="white"}, continue=false})
				-- 			else
				-- 				GameMode.PETRI_ADDITIONAL_EXIT_GOLD_GIVEN = true
				-- 			end
				-- 		end
				-- 	end)
			end
		end

		if unit:GetUnitName() == "npc_petri_miracle1" then
		    if hero.boolmiracle1 == nil then
			GameMode:addScore(hero, 50)
			hero.boolmiracle1 = true
			end
			
			GameMode:ChProgress(hero:GetPlayerOwnerID(), "MIRACLE", 1)
			
			hero.miracle1 = hero.miracle1 or {}
			
			if hero.miracle1[unit:GetUnitName()] and hero.miracle1[unit:GetUnitName()]:IsNull() == false and hero.miracle1[unit:GetUnitName()]:IsAlive() then
				Timers:CreateTimer(0.03, function ()
					unit:ForceKill(false)
				end)
			else
				Notifications:TopToAll({text="#miracle1_construction_is_started", duratione=10, style={color="blue"}, continue=false})

				hero.miracle1[unit:GetUnitName()] = unit

				unit.childEntity = CreateUnitByName("petri_dummy_100vision", keys.caster:GetAbsOrigin(), false, nil, nil, DOTA_TEAM_BADGUYS)
			end
		end

		if unit:GetUnitName() == "npc_petri_miracle2" then
		    if hero.boolmiracle2 == nil then
			GameMode:addScore(hero, 50)
			hero.boolmiracle2 = true
			end
			
			GameMode:ChProgress(hero:GetPlayerOwnerID(), "MIRACLE", 1)			
			
			hero.miracle2 = hero.miracle2 or {}
			
			if hero.miracle2[unit:GetUnitName()] and hero.miracle2[unit:GetUnitName()]:IsNull() == false and hero.miracle2[unit:GetUnitName()]:IsAlive() then
				Timers:CreateTimer(0.03, function ()
					unit:ForceKill(false)
				end)
			else
				Notifications:TopToAll({text="#miracle2_construction_is_started", duratione=10, style={color="blue"}, continue=false})

				hero.miracle2[unit:GetUnitName()] = unit

				unit.childEntity = CreateUnitByName("petri_dummy_300vision", keys.caster:GetAbsOrigin(), false, nil, nil, DOTA_TEAM_BADGUYS)
			end
		end

		if hero:GetUnitName() == "npc_petri_miracle3" then
		    if unit.boolmiracle3 == nil then
			GameMode:addScore(hero, 50)
			hero.boolmiracle3 = true
			end
			
			GameMode:ChProgress(hero:GetPlayerOwnerID(), "MIRACLE", 1)
			
			hero.miracle3 = hero.miracle3 or {}
			
			if hero.miracle3[unit:GetUnitName()] and hero.miracle3[unit:GetUnitName()]:IsNull() == false and hero.miracle3[unit:GetUnitName()]:IsAlive() then
				Timers:CreateTimer(0.03, function ()
					unit:ForceKill(false)
				end)
			else
				Notifications:TopToAll({text="#miracle3_construction_is_started", duratione=10, style={color="blue"}, continue=false})

				hero.miracle3[unit:GetUnitName()] = unit

				unit.childEntity = CreateUnitByName("petri_dummy_500vision", keys.caster:GetAbsOrigin(), false, nil, nil, DOTA_TEAM_BADGUYS)
			end
		end

		caster:EmitSound("ui.inv_pickup_wood")

		FindClearSpaceForUnit(keys.caster, keys.caster:GetAbsOrigin(), true)
		unit.foodSpent = food_cost

		local building_ability = unit:FindAbilityByName("petri_building")
		if building_ability then building_ability:SetLevel(1) end

		if caster:GetUnitName() == "npc_dota_hero_rattletrap" then
			if caster.currentMenu == 1 then
				caster:CastAbilityNoTarget(caster:FindAbilityByName("petri_close_basic_buildings_menu"), pID)
			elseif caster.currentMenu == 2 then
				caster:CastAbilityNoTarget(caster:FindAbilityByName("petri_close_advanced_buildings_menu"), pID)
			end
		end

		unit:SetMana(0)
		unit.tempManaRegen = unit:GetManaRegen()
		unit:SetBaseManaRegen(0.0)
	end)
	keys:OnConstructionCompleted(function(unit)
		InitAbilities(unit)

		AddEntryToDependenciesTable(pID, ability_name, 1)

		if unit.onBuildingCompleted then
			unit.onBuildingCompleted(unit)
		end

		unit:SetMana(unit:GetMaxMana())
		unit:SetBaseManaRegen(unit.tempManaRegen)
		unit.tempManaRegen = nil

		if unit.controllableWhenReady then
			unit:SetControllableByPlayer(keys.caster:GetPlayerOwnerID(), true)
		end
		
		--GridNav:DestroyTreesAroundPoint( unit:GetAbsOrigin(), 150, false )
		
		if unit:GetUnitName() == "npc_petri_tower_of_evil" then
		    if tonumber(lvls[unit:GetPlayerOwnerID()]) >= 10 then
			    unit:SetRangedProjectileName("particles/units/heroes/hero_lina/lina_base_attack.vpcf")
			end
		end
		
		GameMode:ChProgress(unit:GetPlayerOwnerID(), "BUILD", 1)
	end)

	-- These callbacks will only fire when the state between below half health/above half health changes.
	-- i.e. it won't unnecessarily fire multiple times.
	keys:OnBelowHalfHealth(function(unit)
	end)

	keys:OnAboveHalfHealth(function(unit)

	end)

	keys:OnConstructionFailed(function( building )
	    --hero.buildingCount = hero.buildingCount - 1
		Timers:CreateTimer(0.03, function()
	    local allBuildings = Entities:FindAllByClassname("npc_dota_base_additive")

		hero.buildingCount = 0
		for k,v in pairs(allBuildings) do
            if v:GetPlayerOwnerID() == caster:GetPlayerOwnerID() then
                hero.buildingCount = hero.buildingCount + 1
            end
        end
		return 1.0
        end)
	end)

	keys:OnConstructionCancelled(function( building )
		--hero.buildingCount = hero.buildingCount - 1
		Timers:CreateTimer(0.03, function()
	    local allBuildings = Entities:FindAllByClassname("npc_dota_base_additive")

		hero.buildingCount = 0
		for k,v in pairs(allBuildings) do
            if v:GetPlayerOwnerID() and v:GetPlayerOwnerID() == caster:GetPlayerOwnerID() then
                hero.buildingCount = hero.buildingCount + 1
            end
        end
		return 1.0
        end)
	end)

	-- Have a fire effect when the building goes below 50% health.
	-- It will turn off it building goes above 50% health again.
	keys:EnableFireEffect("modifier_jakiro_liquid_fire_burn")

  	if caster:GetUnitName() == "npc_dota_hero_rattletrap" then
		local basicMenu = caster:FindAbilityByName("petri_close_basic_buildings_menu")
		local advancedMenu = caster:FindAbilityByName("petri_close_advanced_buildings_menu")

		if basicMenu ~= nil then
			caster:CastAbilityNoTarget(basicMenu, pID)
		else
			caster:CastAbilityNoTarget(advancedMenu, pID)
		end
	end
end

function building_canceled( keys )
	BuildingHelper:CancelBuilding(keys)
end

function create_building_entity( keys )
	BuildingHelper:InitializeBuildingEntity(keys)
end

function builder_queue( keys )
    local ability = keys.ability
    local caster = keys.caster  
    
    if caster.ProcessingBuilding ~= nil
    and caster.lastOrder ~= DOTA_UNIT_ORDER_STOP
    and caster.lastOrder ~= DOTA_UNIT_ORDER_CAST_NO_TARGET
    and caster.lastOrder ~= DOTA_UNIT_ORDER_PICKUP_ITEM
    and caster.lastOrder ~= DOTA_UNIT_ORDER_MOVE_ITEM
     then
        -- caster is probably a builder, stop them
        player = PlayerResource:GetPlayer(caster:GetMainControllingPlayer())
        --player.activeBuilding = nil
        if player.activeBuilder and player.activeBuilder ==caster and IsValidEntity(player.activeBuilder) then
            player.activeBuilder:ClearQueue()
            player.activeBuilder:Stop()
            player.activeBuilder.ProcessingBuilding = false
        end
    end
end