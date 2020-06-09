require('duels')

function GameMode:FilterExecuteOrder( filterTable )

    if GameMode.PETRI_GAME_HAS_ENDED == true then return false end

    local units = filterTable["units"]
    local order_type = filterTable["order_type"]
    local issuer = filterTable["issuer_player_id_const"]

    local abilityIndex = filterTable["entindex_ability"]
    local targetIndex = filterTable["entindex_target"]
    local x = tonumber(filterTable["position_x"])
    local y = tonumber(filterTable["position_y"])
    local z = tonumber(filterTable["position_z"])
    local point = Vector(x,y,z)

    local issuerUnit
    if units["0"] then
      issuerUnit = EntIndexToHScript(units["0"])
      if issuerUnit then issuerUnit.lastOrder = order_type end
    end

    if issuerUnit and issuerUnit.skip then
      issuerUnit.skip = false
      return true
    end

    for n,unit_index in pairs(units) do
      local unit = EntIndexToHScript(unit_index)
      local ownerID = unit:GetPlayerOwnerID()

      if PlayerResource:GetConnectionState(ownerID) == 3 or
        PlayerResource:GetConnectionState(ownerID) == 4
        then
        return false
      end
    end

    if PlayerResource:GetTeam(issuer) == DOTA_TEAM_GOODGUYS then
      if abilityIndex and IsMultiOrderAbility(EntIndexToHScript(abilityIndex)) then
        local ability = EntIndexToHScript(abilityIndex)
        local abilityName = ability:GetAbilityName()

        if not GameMode.SELECTED_UNITS[issuerUnit:GetPlayerOwnerID()] then return false end

        local entityList = GameMode.SELECTED_UNITS[issuerUnit:GetPlayerOwnerID()]

        for _,entityIndex in pairs(entityList) do
          local caster = EntIndexToHScript(entityIndex)
          if caster:GetPlayerOwnerID() ~= issuerUnit:GetPlayerOwnerID() then

          elseif caster and caster:HasAbility(abilityName) then
            local abil = caster:FindAbilityByName(abilityName)
            if abil and abil:IsFullyCastable() then

              if issuerUnit ~= caster then caster.skip = true end

              if order_type == DOTA_UNIT_ORDER_CAST_POSITION then
                ExecuteOrderFromTable({ UnitIndex = entityIndex, OrderType = order_type, Position = point, AbilityIndex = abil:GetEntityIndex(), Queue = queue})
              elseif order_type == DOTA_UNIT_ORDER_CAST_TARGET or order_type == DOTA_UNIT_ORDER_CAST_TARGET_TREE then
                FakeStopOrder(caster)
                ExecuteOrderFromTable({ UnitIndex = entityIndex, OrderType = order_type, TargetIndex = targetIndex, AbilityIndex = abil:GetEntityIndex(), Queue = queue})
              else --order_type == DOTA_UNIT_ORDER_CAST_NO_TARGET or order_type == DOTA_UNIT_ORDER_CAST_TOGGLE or order_type == DOTA_UNIT_ORDER_CAST_TOGGLE_AUTO
                if order_type == DOTA_UNIT_ORDER_CAST_NO_TARGET then
                  Timers:CreateTimer(function()
                    caster:CastAbilityNoTarget(abil, caster:GetPlayerOwnerID())
                  end)
                else
                  ExecuteOrderFromTable({ UnitIndex = entityIndex, OrderType = order_type, AbilityIndex = abil:GetEntityIndex(), Queue = queue})
                end
              end
            end
          end
        end
        return false
      end
    end

    if order_type == DOTA_UNIT_ORDER_MOVE_ITEM then		
      if filterTable["entindex_target"] >= 6 and PlayerResource:GetTeam(issuer) ~= DOTA_TEAM_BADGUYS then
        return false
      elseif filterTable["entindex_target"] >= 6 and PlayerResource:GetTeam(issuer) == DOTA_TEAM_BADGUYS then
        local hero = EntIndexToHScript(filterTable["units"]["0"])

        local targetSlot = filterTable["entindex_target"]
        local heroSlot = 0

        for i=0,20 do
          if hero:GetItemInSlot(i) == EntIndexToHScript(filterTable["entindex_ability"]) then
            heroSlot = i
            break
          end
        end

		print("move item "..targetSlot.." "..heroSlot)
		
		if not Entities:FindByName(nil,"PetrosyanShopTrigger"):IsTouching(hero) and targetSlot > 8 or heroSlot > 8 then
          return false
        end
		
        hero:SwapItems(heroSlot, targetSlot)
        return false
      elseif PlayerResource:GetTeam(issuer) == DOTA_TEAM_BADGUYS then
        local hero = EntIndexToHScript(filterTable["units"]["0"])
        local ent = hero

        -- if EntIndexToHScript(filterTable["entindex_ability"]):GetPurchaser() ~= hero then
        --   return false
        -- end

		local stashSlot = 6

        for i=0,20 do
            if hero:GetItemInSlot(i) == EntIndexToHScript(filterTable["entindex_ability"]) then
              stashSlot = i
              break
            end
        end
		
        if Entities:FindByName(nil,"PetrosyanShopTrigger"):IsTouching(hero) then
          if hero:GetItemInSlot(stashSlot) and hero:GetItemInSlot(stashSlot):GetPurchaser() ~= hero then
            return false
          elseif not hero:GetItemInSlot(stashSlot) then
            return false
          end

          local oldItem = hero:GetItemInSlot(stashSlot)


          ent:DropItemAtPositionImmediate(oldItem, Vector(10000,10000,10000))

          ent:AddItem(oldItem)

          UTIL_Remove(oldItem:GetContainer())
        elseif stashSlot > 8 then
			return false
		end
      end
    elseif order_type == DOTA_UNIT_ORDER_GIVE_ITEM then
      local item = EntIndexToHScript(filterTable["entindex_ability"])

      local purchaser = EntIndexToHScript(filterTable["entindex_target"])

      if check2(purchaser) and check1(item:GetName()) then
        return false
      end

      if purchaser:GetUnitName() ~= "npc_dota_courier" and purchaser ~= item:GetPurchaser() and purchaser:GetTeamNumber() == DOTA_TEAM_BADGUYS and item:GetName() ~= "item_petri_grease" then
        return false
      end

      if issuerUnit:GetUnitName() == "npc_dota_courier" and purchaser:IsHero() == true
        and (issuerUnit:GetAbsOrigin() - purchaser:GetAbsOrigin()):Length() < 400 then

        local hasSpace = false
        for i=0,5 do
          if purchaser:GetItemInSlot(i) == nil then
            hasSpace = true
            break
          end
        end

        if hasSpace == false then
          local oldItem = purchaser:GetItemInSlot(0)

          purchaser:DropItemAtPositionImmediate(oldItem, purchaser:GetAbsOrigin())

          issuerUnit:DropItemAtPositionImmediate(item, issuerUnit:GetAbsOrigin())

          purchaser:AddItem(item)

          issuerUnit:AddItem(oldItem)

          UTIL_Remove(item:GetContainer())
          UTIL_Remove(oldItem:GetContainer())
        end
      end
    elseif order_type == DOTA_UNIT_ORDER_PICKUP_ITEM then
      if not EntIndexToHScript(filterTable["entindex_target"]) then return false end

      local item = EntIndexToHScript(filterTable["entindex_target"]):GetContainedItem()

      local purchaser = EntIndexToHScript(units["0"])
	  
	  if GetMapName() == "petri_0_frostivus" then
	    return true
	  end
	  
      if item:GetName() == "item_petri_candy" then return true end
      if check2(purchaser) and check1(item:GetName()) then
        return false
      end

      if purchaser:GetUnitName() ~= "npc_dota_courier" and purchaser ~= item:GetPurchaser() and purchaser:GetTeamNumber() == DOTA_TEAM_BADGUYS and item:GetName() ~= "item_petri_grease" then
        return false
      end

      if item:IsCastOnPickup() == true then
        if EntIndexToHScript(units["0"]):GetUnitName() == "npc_petri_cop" then
          return true
        else
          return false
        end
      end

      if purchaser:GetTeam() == DOTA_TEAM_GOODGUYS then
        if CheckShopType(item:GetName(), "SideShop") == false then
          return false
        end
      end
      if purchaser:GetTeam() == DOTA_TEAM_BADGUYS then
        if CheckShopType(item:GetName(), "SecretShop") == false then
          return false
        end
      end
    elseif order_type == DOTA_UNIT_ORDER_PURCHASE_ITEM then
      local purchaser = EntIndexToHScript(units["0"])
      if true then return false end
      if purchaser:GetUnitName() == "npc_petri_janitor" then
        filterTable["units"]["0"] = purchaser:GetOwnerEntity():entindex()
      end

      local item = GetItemByID(filterTable["entindex_ability"])

      if item and check2(purchaser) and check1(item["name"]) then
        return false
      end

      if PlayerResource:GetTeam(issuer) == DOTA_TEAM_GOODGUYS and (filterTable["entindex_ability"] == 45 or filterTable["entindex_ability"] == 84) then return false end

      if item then
        if purchaser:GetUnitName() == "npc_dota_hero_storm_spirit" and item["SideShop"] then
          return false
        end
        if OnEnemyShop(purchaser) then
          Notifications:Bottom(issuer, {text="#cant_buy_pudge", duration=2, style={color="red", ["font-size"]="35px"}})
          return false
        elseif PlayerResource:GetTeam(issuer) == DOTA_TEAM_GOODGUYS then
          if item["SideShop"] ~= 1 or OnKVNSideShop( purchaser ) == false then return false end
        elseif PlayerResource:GetTeam(issuer) == DOTA_TEAM_BADGUYS then
          if item["SideShop"] then return false end
        end
      end
    elseif order_type == DOTA_UNIT_ORDER_SELL_ITEM then
      local purchaser = EntIndexToHScript(units["0"])

      if OnEnemyShop(purchaser) then
        return false
      end

      local item = EntIndexToHScript(filterTable.entindex_ability)
      local item_name = item:GetName()
      local time = item.purchaseTime
      Timers:CreateTimer(function (  )
        if not IsValidEntity(item) and GameMode.ItemKVs[item_name].ItemSellable ~= "0" then
          if (time and time + 10 > GameMode.PETRI_TRUE_TIME) or GameMode.ItemKVs[item_name].ItemSellFullPrice == 1 then
            AddCustomGold( issuer, math.floor(GameMode.ItemKVs[item_name].ItemCost) )
          else
            local zero = GameMode.ItemKVs[item_name].ItemCost / 2.0
            if zero < 1.0 then
              zero = 0.0
            end
            AddCustomGold( issuer, math.floor(zero))
          end

          EmitSoundOnClient("Quickbuy.Confirmation", PlayerResource:GetPlayer(issuer))
        end        
      end)
    elseif order_type == DOTA_UNIT_ORDER_GLYPH then
      return false
    elseif order_type == DOTA_UNIT_ORDER_CAST_TARGET_TREE then
      local ability = EntIndexToHScript(abilityIndex)
      if ability and ability.GetAbilityName then
        local abilityName = ability:GetAbilityName()

        if abilityName == "gather_lumber" then
          if issuerUnit:FindModifierByName("modifier_returning_resources") then
            issuerUnit:RemoveModifierByName("modifier_chopping_wood")

            issuerUnit:CastAbilityNoTarget(issuerUnit:FindAbilityByName("return_resources"), issuer)

            return false
          end
          return true
        end
      end
    elseif order_type == DOTA_UNIT_ORDER_CAST_NO_TARGET then
      local ability = EntIndexToHScript(abilityIndex)
      if ability and ability.GetAbilityName then
        local abilityName = ability:GetAbilityName()

        if abilityName == "petri_open_basic_buildings_menu" or abilityName == "petri_open_advanced_buildings_menu"
          or abilityName == "petri_close_basic_buildings_menu" or abilityName == "petri_close_advanced_buildings_menu" then
          issuerUnit.lastOrder = DOTA_UNIT_ORDER_MOVE_ITEM
        end
      else return false end
    elseif order_type == DOTA_UNIT_ORDER_ATTACK_TARGET then
      local target = EntIndexToHScript(targetIndex)
       
      if string.match(target:GetClassname(), "rune") then return false end

      for n, unit_index in pairs(units) do
        local unit = EntIndexToHScript(unit_index)
        if UnitCanAttackTarget(unit, target) then
          unit.skip = true
          ExecuteOrderFromTable({ UnitIndex = unit_index, OrderType = DOTA_UNIT_ORDER_ATTACK_TARGET, TargetIndex = targetIndex, Queue = queue})
        end
      end
      return false
    elseif order_type == DOTA_UNIT_ORDER_MOVE_TO_TARGET then
      local target = EntIndexToHScript(targetIndex)

      if target:HasAbility("petri_building") == true then
        issuerUnit:MoveToPosition(GetMoveToBuildingPosition(issuerUnit,target))

        return false
      end
    end
	
	if order_type ~= DOTA_UNIT_ORDER_CAST_NO_TARGET then
        local hero = EntIndexToHScript(filterTable["units"]["0"])
		if hero then
		if hero:IsRealHero() then
		    if hero.onduel == true and Duels.ison == false then
			    print(hero:GetUnitName().." is waiting for duel opponent, cant move")
			    return false
			end
		end
		end
	end
	
	if order_type == DOTA_UNIT_ORDER_CAST_NO_TARGET or order_type == DOTA_UNIT_ORDER_CAST_POSITION or order_type == DOTA_UNIT_ORDER_CAST_TARGET or order_type == DOTA_UNIT_ORDER_CAST_TARGET_TREE or order_type == DOTA_UNIT_ORDER_CAST_TOGGLE then
	    if abilityIndex then
		    local ability = EntIndexToHScript(abilityIndex)
			if ability then
			    local hero = EntIndexToHScript(filterTable["units"]["0"])
			    if ability:GetAbilityName() ~= "petri_petrosyan_return" and hero.onduel then
				    return false
				end
			end
		end
	end
	
	if order_type == DOTA_UNIT_ORDER_EJECT_ITEM_FROM_STASH and EntIndexToHScript(filterTable["entindex_ability"]) then
		local item = EntIndexToHScript(filterTable["entindex_ability"])
		if item:IsDroppable() == false then
		    local cost = item:GetCost()
			local pid = EntIndexToHScript(filterTable["units"]["0"]):GetPlayerOwnerID()
			if pid and cost then
			    AddCustomGold(pid, cost)
			end
			
			UTIL_Remove(item)
		    return false
		end
	end
	
	if order_type == DOTA_UNIT_ORDER_PICKUP_RUNE and EntIndexToHScript(filterTable["units"]["0"]) and EntIndexToHScript(filterTable["units"]["0"]):GetUnitName() == "npc_petri_cop" then
	    return false
	end
    return true
end

GOLD_FILTERS = {}
GOLD_FILTERS[3950] = 1
GOLD_FILTERS[19866] = 1
GOLD_FILTERS[50000] = 1
GOLD_FILTERS[100000] = 1
GOLD_FILTERS[300000] = 1

function GameMode:ModifyGoldFilter(event)
  -- local hero = GameMode.assignedPlayerHeroes[event.player_id_const]
  return false
  -- if event.reason_const == DOTA_ModifyGold_CreepKill or event.reason_const == 0 then
  --   event["gold"] = math.floor(event["gold"])

  --   if GOLD_FILTERS[event["gold"]] then

  --   else
  --     AddCustomGold( event.player_id_const, event["gold"] )
  --     PopupParticle(event["gold"], Vector(244,201,23), 3.0, GameMode.assignedPlayerHeroes[event.player_id_const])
  --   end
  -- end

  -- return false
end

DAMAGE_FILTERS = {}
if GameMode.UseMiracles == true then
DAMAGE_FILTERS["npc_petri_loose_trigger1"] = 1000
DAMAGE_FILTERS["npc_petri_loose_trigger2"] = 7500
DAMAGE_FILTERS["npc_petri_loose_trigger3"] = 100000
end

function GameMode:DamageFilter( filter_table )
    local victim = EntIndexToHScript(filter_table["entindex_victim_const"])

    local attacker
    if not filter_table["entindex_attacker_const"] then
        attacker = victim
        filter_table["entindex_attacker_const"] = filter_table["entindex_victim_const"]
    else
        attacker = EntIndexToHScript(filter_table["entindex_attacker_const"])
    end

	if attacker:GetTeam() == DOTA_TEAM_GOODGUYS and victim:GetTeam() == DOTA_TEAM_NEUTRALS then
		return false
	end
	
    local damage = filter_table["damage"]
    local damage_type = filter_table["damagetype_const"]

    if damage_type ~= DAMAGE_TYPE_PHYSICAL then
	  damage_type = DAMAGE_TYPE_PURE
    end
	
	if damage_type == DAMAGE_TYPE_PHYSICAL then
	  local armor = victim:GetPhysicalArmorValue(false)
	  if armor ~= 0 then
	  local damage = attacker:GetAverageTrueAttackDamage(attacker)
	  local damagemultiplier = 1 - 0.05 * armor / (1 + (0.05 * math.abs(armor)))
	  print('damagemultiplier:')
	  print(damagemultiplier)
	  print(armor)
	  print(damage)
	  print(damage * damagemultiplier)
	  filter_table["damage"] = damage * damagemultiplier
	  end
	  
	  if armor > 224 then
	        if victim:IsBuilding() == false then
			    if not string.match(victim:GetUnitName(), "wall") then
	            print('heal')
			--if attacker:HasModifier("modifier_item_petri_mask_of_laugh_datadriven_lifesteal") then
				local healpercent = 0
				if attacker:HasItemInInventory("item_petri_mask_of_laugh") then
                    healpercent = 5
                elseif attacker:HasItemInInventory("item_petri_uber_mask_of_laugh") then
				    healpercent = 10
				elseif attacker:HasItemInInventory("item_petri_uber_mask_of_laugh_level2") then
				    healpercent = 25
				elseif attacker:HasItemInInventory("item_petri_uber_mask_of_laugh_level3") then
				    healpercent = 50
				elseif attacker:HasItemInInventory("item_petri_uber_mask_of_laugh_level4") then
				    healpercent = 100
				elseif attacker:HasItemInInventory("item_petri_jedi") then
				    healpercent = 150
				end
				if healpercent ~= 0 then
				    local heal = filter_table["damage"] * healpercent
					attacker:Heal(heal, attacker)
				end
			--end
			    end
			end
	  end
	end

	if victim:GetUnitName() == "npc_petri_creep_kivin" then
		local damage = attacker:GetAverageTrueAttackDamage(attacker)
		if GameRules:GetDOTATime(false, false) < 2880 then
		    attacker:CastAbilityNoTarget(attacker:FindAbilityByName("petri_petrosyan_return"), attacker:GetPlayerOwnerID())
            Notifications:Bottom(attacker:GetPlayerOwnerID(), {text="#too_early_kivin", duration=5, style={color="red", ["font-size"]="45px"}})
            Timers:CreateTimer(0.04,
            function()
                MoveCamera(attacker:GetPlayerOwnerID(), attacker)
            end)
	    elseif damage > 605000 then
		    local playerid = attacker:GetPlayerOwnerID()
			AddCustomGold( playerid, 3500)
			attacker:AddExperience(500000, DOTA_ModifyXP_CreepKill, false, false)
		else
		    Notifications:Bottom(attacker:GetPlayerOwnerID(), {text="#kivin_low_dmg", duration=5, style={color="red", ["font-size"]="45px"}})
		end
		
		return false
	else
	if attacker:GetTeam() == DOTA_TEAM_BADGUYS then
	    if string.match(victim:GetUnitName (), "npc_petri_creep_") then
		    --if victim:GetUnitName() ~= "npc_petri_creep_kivin" then
	        if GameMode:isdaydumb() == false then
			    print('noch nelzya farmitb')
                attacker:CastAbilityNoTarget(attacker:FindAbilityByName("petri_petrosyan_return"), attacker:GetPlayerOwnerID())
                Notifications:Bottom(attacker:GetPlayerOwnerID(), {text="#no_farm_tonight", duration=5, style={color="red", ["font-size"]="45px"}})
                Timers:CreateTimer(0.04,
                function()
                    MoveCamera(attacker:GetPlayerOwnerID(), attacker)
                end)
            end
			--end
		end
	end
	end
	
    if DAMAGE_FILTERS[victim:GetUnitName()] then
      if damage < DAMAGE_FILTERS[victim:GetUnitName()] then
        return false
      end
    end
	
	if victim:GetUnitName() == "npc_petri_sawmill" and damage >= victim:GetHealth() then
	    for j = 0, 6 do
	    for i = 0, 6 do
		    local item = victim:GetItemInSlot(i)
			if item then
			    item:CastAbility()
			end
		end
		end
	end

    return true
end

function GameMode:ModifyExperienceFilter(filterTable)
  if filterTable["reason_const"] == 2 then
    filterTable["experience"] = 0
  end

  --if not filterTable["player_id_const"] or not PlayerResource:GetPlayer(filterTable["player_id_const"]) then return false end
  --if PlayerResource:GetPlayer(filterTable["player_id_const"]):GetTeam() == DOTA_TEAM_GOODGUYS
  --or PlayerResource:GetPlayer(filterTable["player_id_const"]):GetTeam() == DOTA_TEAM_BADGUYS
  --then return false end
  return true
end

function OnEnemyShop( unit )
  local teamID = unit:GetTeamNumber()
  local position = unit:GetAbsOrigin()
  local own_base_name = "team_"..teamID
  local nearby_entities = Entities:FindAllByNameWithin("team_*", position, 300)

  if (#nearby_entities > 0) then
    for k,ent in pairs(nearby_entities) do
      if not string.match(ent:GetName(), own_base_name) then
        return true
      end
    end
  end
  return false
end

function OnKVNSideShop( unit )
  local teamID = unit:GetTeamNumber()
  local position = unit:GetAbsOrigin()
  local own_base_name = "team_"..teamID
  local nearby_entities = Entities:FindAllByNameWithin("team_*", position, 300)

  if (#nearby_entities > 0) then
    for k,ent in pairs(nearby_entities) do
      if string.match(ent:GetName(), own_base_name) then
        return true
      end
    end
  end
  return false
end

local runeSpawners = {}

function GameMode:FilterRuneSpawn(filter_table)
    return true
end
