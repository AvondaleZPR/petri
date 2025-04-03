NO_MENU = 0
BASIC_MENU = 1
ADVANCED_MENU = 2

function Spawn( event )
	if not GameMode.buildingMenus["kvn_fan_abilities"] then
		GameMode.buildingMenus["kvn_fan_abilities"] = {}

		for i=0, thisEntity:GetAbilityCount()-1 do
			if thisEntity:GetAbilityByIndex(i) ~= nil then
				GameMode.buildingMenus["kvn_fan_abilities"][i+1] = thisEntity:GetAbilityByIndex(i):GetName()
			end
	    end
	end

	InitAbilities(thisEntity)
end

function SpawnTrap(keys)
	local point = keys.target_points[1]
	local caster = keys.caster

	if not IsInsideEntityBounds(Entities:FindByName(nil, "blocking_trigger_b"), point) then
		local trap = CreateUnitByName("npc_petri_trap", point,  true, nil, caster, caster:GetTeam())

		SetCustomBuildingModel(trap, PlayerResource:GetSteamAccountID(caster:GetPlayerOwnerID()))

		caster = GameMode.assignedPlayerHeroes[caster:GetPlayerOwnerID()]
		trap.owner = caster

		InitAbilities(trap)
		trap:AddNewModifier(trap, nil, "modifier_kill", {duration = 240})
		StartAnimation(trap, {duration=-1, activity=ACT_DOTA_IDLE , rate=1.5})
	
		keys.ability:SpendCharge(0.1)
	else
		keys.ability:EndCooldown()
	end
end

function GivePermissionToBuild( keys )
	local caster = keys.caster
	local target = keys.target
	local caster_team = caster:GetTeamNumber()
	local player = caster:GetPlayerOwnerID()
	local ability = keys.ability

	if target:HasItemInInventory(ability:GetName()) then
		if CheckAreaClaimers(target, caster.currentArea.claimers) == true then return false end

		if caster.currentArea ~= nil and caster.currentArea.claimers ~= nil then
			if target.currentArea == caster.currentArea then
				if caster.currentArea.claimers[0] == caster and GetTableLength( caster.currentArea.claimers ) < ability:GetSpecialValueFor("max") then
					print(GetTableLength( caster.currentArea.claimers ))
					caster.currentArea.claimers[GetTableLength( caster.currentArea.claimers ) + 1] = target
				end
			end
		end
	end
end

function CloseAllMenus(entity)
	local keys = {}
	keys.caster = entity
	if entity.currentMenu == 1 then
		CloseBasicBuildingsMenu(keys)
	elseif entity.currentMenu == 2 then
		CloseAdvancedBuildingsMenu(keys)
	elseif entity.currentMenu == 3 then
	    CloseBusMenu(keys)
	end
end

function OpenBasicBuildingsMenu(keys)
	local caster = keys.caster

	for i=1, table.getn(GameMode.buildingMenus["basic_building_menu"]) do
		caster:AddAbility(GameMode.buildingMenus["basic_building_menu"][i])
    end

	InitAbilities(caster)

	for i=1, table.getn(GameMode.buildingMenus["basic_building_menu"]) do
		caster:SwapAbilities(GameMode.buildingMenus["kvn_fan_abilities"][i], GameMode.buildingMenus["basic_building_menu"][i], false, true)
    end

    caster.currentMenu = 1
end

function CloseBasicBuildingsMenu(keys)
	local caster = keys.caster

	for i=1, table.getn(GameMode.buildingMenus["basic_building_menu"]) do
		caster:SwapAbilities(GameMode.buildingMenus["kvn_fan_abilities"][i], GameMode.buildingMenus["basic_building_menu"][i], true, false)
    end

	for i=1, table.getn(GameMode.buildingMenus["basic_building_menu"]) do
		caster:RemoveAbility(GameMode.buildingMenus["basic_building_menu"][i])
    end

    caster.currentMenu = 0
end

function OpenAdvancedBuildingsMenu(keys)
	local caster = keys.caster

	for i=1, table.getn(GameMode.buildingMenus["advanced_building_menu"]) do
		caster:AddAbility(GameMode.buildingMenus["advanced_building_menu"][i])
    end

	InitAbilities(caster)

    for i=1, table.getn(GameMode.buildingMenus["advanced_building_menu"]) do
		caster:SwapAbilities(GameMode.buildingMenus["kvn_fan_abilities"][i], GameMode.buildingMenus["advanced_building_menu"][i], false, true)
    end

    caster.currentMenu = 2
end

function CloseAdvancedBuildingsMenu(keys)
	local caster = keys.caster

	for i=1, table.getn(GameMode.buildingMenus["advanced_building_menu"]) do
		caster:SwapAbilities(GameMode.buildingMenus["kvn_fan_abilities"][i], GameMode.buildingMenus["advanced_building_menu"][i], true, false)
    end

	for i=1, table.getn(GameMode.buildingMenus["advanced_building_menu"]) do
		caster:RemoveAbility(GameMode.buildingMenus["advanced_building_menu"][i])
    end

    caster.currentMenu = 0
end

function OpenBusMenu(keys)
	local caster = keys.caster

	for i=1, table.getn(GameMode.buildingMenus["bus_menu"]) do
		caster:AddAbility(GameMode.buildingMenus["bus_menu"][i])
    end

	InitAbilities(caster)

	for i=1, table.getn(GameMode.buildingMenus["bus_menu"]) do
		caster:SwapAbilities(GameMode.buildingMenus["kvn_fan_abilities"][i], GameMode.buildingMenus["bus_menu"][i], false, true)
    end

    caster.currentMenu = 3
end

function CloseBusMenu(keys)
	local caster = keys.caster

	for i=1, table.getn(GameMode.buildingMenus["bus_menu"]) do
		caster:SwapAbilities(GameMode.buildingMenus["kvn_fan_abilities"][i], GameMode.buildingMenus["bus_menu"][i], true, false)
    end

	for i=1, table.getn(GameMode.buildingMenus["bus_menu"]) do
		caster:RemoveAbility(GameMode.buildingMenus["bus_menu"][i])
    end

    caster.currentMenu = 0
end

function SpawnGoldBag( keys )
	local caster = keys.caster:GetPlayerOwner():GetAssignedHero()
	local ability = keys.ability
	local pID = caster:GetPlayerOwnerID()
	
	if keys.pos == nil then
	    keys.pos = keys.caster:GetAbsOrigin()
	end

	GameMode.assignedPlayerHeroes[pID].goldBagStacks = GameMode.assignedPlayerHeroes[pID].goldBagStacks or 0

	local unit_name = "npc_petri_gold_bag"
	local upgrade_name = "petri_upgrade_gold_bag_to_2"
	if string.match(ability:GetName(), "2") then 
		unit_name = "npc_petri_gold_bag2"
		upgrade_name = "petri_upgrade_gold_bag_to_3"
	end
	if string.match(ability:GetName(), "3") then 
		unit_name = "npc_petri_gold_bag3"
		upgrade_name = "petri_upgrade_gold_bag_to_4"
	end
	if string.match(ability:GetName(), "4") then 
		unit_name = "npc_petri_gold_bag4"
	end

	local bag = CreateUnitByName(unit_name, keys.pos or caster:GetAbsOrigin(), true, nil, caster, DOTA_TEAM_GOODGUYS)
	SetCustomBuildingModel(bag, PlayerResource:GetSteamAccountID(pID))
	bag:SetControllableByPlayer(caster:GetPlayerOwnerID(), false)
	bag.spawnPosition = caster:GetAbsOrigin()

	bag:EmitSound("DOTA_Item.Hand_Of_Midas")

	if GameMode.assignedPlayerHeroes[pID].currentGoldBag and not GameMode.assignedPlayerHeroes[pID].currentGoldBag:IsNull() then
		DestroyEntityBasedOnHealth(caster, GameMode.assignedPlayerHeroes[pID].currentGoldBag)
	end
	GameMode.assignedPlayerHeroes[pID].currentGoldBag = bag

	bag:SetModifierStackCount("modifier_gold_bag", bag, GameMode.assignedPlayerHeroes[pID].goldBagStacks)

	local storeAbility = bag:FindAbilityByName("petri_upgrade_gold_bag") or bag:FindAbilityByName("petri_upgrade_gold_bag2") or bag:FindAbilityByName("petri_upgrade_gold_bag3") or bag:FindAbilityByName("petri_upgrade_gold_bag4")

	local upgradeRate = storeAbility:GetSpecialValueFor("upgrade_rate")
	local upgradeLimit = storeAbility:GetSpecialValueFor("upgrade_limit")

	if bag:GetModifierStackCount("modifier_gold_bag", bag) >= upgradeLimit then
		bag:SetModifierStackCount("modifier_gold_bag", bag,upgradeLimit)

		bag:SwapAbilities(storeAbility:GetName(), "petri_empty2", false, true)

		bag:AddAbility(upgrade_name):UpgradeAbility(false)

		bag:SwapAbilities("petri_empty1", upgrade_name, false, true)
	end

	return bag
end

function Deny(keys)
	local caster = keys.caster
	local target = keys.target

	local damageTable = {
		victim = target,
		attacker = caster,
		damage = target:GetMaxHealth(),
		damage_type = DAMAGE_TYPE_PURE,
	}
 
	if target:HasAbility("petri_building") == true and target:GetPlayerOwnerID() == caster:GetPlayerOwnerID() and target:HasAbility("petri_exit") ~= true and target:HasAbility("petri_cop_trap") ~= true then
		if not string.match(target:GetUnitName(), "npc_petri_bus") and not (string.match(target:GetUnitName(), "npc_petri_tent") and target:GetHealth() ~= target:GetMaxHealth()) then
		if caster:HasModifier("modifier_hunger") == true then
			caster:RemoveModifierByName("modifier_hunger")
		end
		ApplyDamage(damageTable)
		target:EmitSound("Hero_Techies.Suicide")
		end
	end
end