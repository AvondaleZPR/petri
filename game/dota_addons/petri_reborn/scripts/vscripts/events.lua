-- This file contains all barebones-registered events and has already set up the passed-in parameters for your use.
-- Do not remove the GameMode:_Function calls in these events as it will mess with the internal barebones systems.

require('duels')

-- Cleanup a player when they leave
function GameMode:OnDisconnect(keys)
    local status, retval = pcall(OnDisconnectDebug, keys)
    if not status then
        GameMode:DEBUGMSG("OnDisconnect ERROR: ", retval)
    end	
end

function OnDisconnectDebug(keys)
  print('[BAREBONES] Player Disconnected ' .. tostring(keys.userid))

  local name = keys.name
  local networkid = keys.networkid
  local reason = keys.reason
  local userid = keys.userid

  -- FireGameEvent('petri_scaleform_revert', { player_ID = userid })

    --local player = PlayerResource:GetPlayer(userid)
	--if player ~= nil then
    --local hero = player:GetAssignedHero()
	--if hero:GetTeam() == DOTA_TEAM_BADGUYS then
        --hero:RespawnHero(false, false) 
	--end
	--end
	
  	local everyone = FindUnitsInRadius(DOTA_TEAM_BADGUYS, Vector(0, 0, 0), nil, FIND_UNITS_EVERYWHERE, DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_ALL, DOTA_UNIT_TARGET_FLAG_NONE, FIND_ANY_ORDER, false)
	for _,unit in pairs(everyone) do
	    if unit:IsRealHero() then
		    local pid = unit:GetPlayerID()
		    if pid ~= nil then
		        if PlayerResource:GetConnectionState(pid) ~= DOTA_CONNECTION_STATE_CONNECTED then
		            if unit:GetTeam() == DOTA_TEAM_BADGUYS then
                        unit:RespawnHero(false, false) 
	                end 
		        end
		    end
		end
	end
  
  Timers:CreateTimer(2.0, function (  )
    local everyoneLeft = true 

    for playerID = 0, DOTA_MAX_PLAYERS do
      if PlayerResource:IsValidPlayerID(playerID) then
        if not PlayerResource:IsBroadcaster(playerID) then
          if PlayerResource:GetConnectionState(playerID) == DOTA_CONNECTION_STATE_CONNECTED then
            everyoneLeft = false   
		  end
        end
      end
    end

    if everyoneLeft then
      --GameRules.Winner = DOTA_TEAM_GOODGUYS
      --GameRules:SetGameWinner(DOTA_TEAM_GOODGUYS)
    end
  end)
end

--isLost = {false,false,false,false,false,false,false,false,false,false,false,false,false,false}
--isLost[0] = false

-- The overall game state has changed
function GameMode:OnGameRulesStateChange(keys)
    local status, err = pcall(OnGameRulesStateChangeDebug, keys)
    if not status then
        GameMode:DEBUGMSG("OnGameRulesStateChange ERROR: ", err)	
	end
end

function OnGameRulesStateChangeDebug(keys)
  DebugPrint("[BAREBONES] GameRules State Changed")
  DebugPrintTable(keys)

  -- This internal handling is used to set up main barebones functions
  GameMode:_OnGameRulesStateChange(keys)
  
  if GameRules:State_Get() == DOTA_GAMERULES_STATE_POST_GAME then
    
	--[[
	for i = 0, 12 do
	    if PlayerRT[i] ~= nil and PlayerRT[i].team ~= nil then
		print("SAVERATING: sss: "..PlayerRT[i].score.." "..PlayerRT[i].team)
		local plus = 0
		if PlayerRT[i].team == GameRules.Winner then
		    plus = 25
			if PlayerRT[i].team == DOTA_TEAM_BADGUYS then
			    plus = 100
			end
		else
		    plus = -25
		end
		    local rating = (GameMode.ratingArr[i])+(plus)
		    GameMode:DEBUGMSG("SAVERATING: SAVED: ", i)
	        print("saverating: "..PlayerRT[i].steamID.." "..rating)
		    saverating(PlayerRT[i].steamID, rating, i)
		end
		GameMode:DEBUGMSG("SAVERATING: ", i)
	end
	]]
	
    Timers:CreateTimer(1.0,
    function()
	    CustomGameEventManager:Send_ServerToAllClients( "players_can_leave", nil )
  	    return nil
	end)
  end
end

function GameMode:OnPause(data)
  --local pID = data.PlayerId
  
  --if pID ~= 0 then
  --print(GameMode.canPlayerPause[pID+1])
  --if(GameMode.canPlayerPause[pID+1] == true) then
    --GameMode.canPlayerPause[pID+1] = false
	--Timers:CreateTimer(300.0,
        --function()
                --GameMode.canPlayerPause[pID+1] = true
  		    --return nil
	    --end
	--)
  --else
    --PauseGame(false)
  --end
  --end
  PrintTable(data)
end

-- An NPC has spawned somewhere in game.  This includes heroes
function GameMode:OnNPCSpawned(keys)
    local status, retval = pcall(OnNPCSpawnedDebug, keys)
    if not status then
        GameMode:DEBUGMSG("OnNPCSpawned ERROR: ", retval)
    end	
end

function OnNPCSpawnedDebug(keys)
  DebugPrint("[BAREBONES] NPC Spawned")
  DebugPrintTable(keys)

  -- This internal handling is used to set up main barebones functions
  GameMode:_OnNPCSpawned(keys)

  local npc = EntIndexToHScript(keys.entindex)
  if npc:GetUnitName() == "npc_dota_courier" then
    npc:SetMoveCapability(DOTA_UNIT_CAP_MOVE_FLY)
    UpdateModel(npc, "models/creeps/neutral_creeps/n_creep_ghost_a/n_creep_ghost_a.vmdl", 0.8)
    npc:AddAbility("petri_janitor_invisibility")
    InitAbilities( npc )
	
	npc:SetBaseMoveSpeed(600)
  end
  
  print(npc:GetTeam())
  
  --local item = CreateItem("item_armor_fix",npc,npc)
  --item:ApplyDataDrivenModifier(npc, npc, "modifier_armor_fix",{})  
  
	--local armor = npc:GetPhysicalArmorValue() + npc:GetPhysicalArmorBaseValue()	
	--if armor > 0 then
		--local minus = armor / 100 * 30
		--npc:SetPhysicalArmorBaseValue(-minus)
	--end
	
	--if npc:IsRealHero() then
	    --npc:GetPlayerOwner().score = 0
	--end
	
	if npc:IsRealHero() and npc:GetTeam() == DOTA_TEAM_BADGUYS and npc.onduel == nil then
        npc.onduel = false	    
	end
	
	if npc:IsRealHero() and npc:GetUnitName() ~= npc_dota_hero_storm_spirit and npc:GetPlayerOwner() and npc.alreadyspawned ~= true then
	    npc.alreadyspawned = true
		local player = npc:GetPlayerOwner()
		player.ch = {"","",""}
		player.pr = {0,0,0}
		player.tar = {0,0,0}
		player.lvl = 0
		
		pp[player:GetPlayerID()].ch = {"","",""}
		pp[player:GetPlayerID()].pr = {0,0,0}
		pp[player:GetPlayerID()].tar = {0,0,0}
		pp[player:GetPlayerID()].lvl = 0
		
		pp[player:GetPlayerID()].score = 0
		
		npc.bus = {nil,nil,nil,nil}
	end
	
	if npc:IsRealHero() and npc:GetTeam() == DOTA_TEAM_GOODGUYS then
	    npc.canbuid = true
	end
	
	npc.isblink = false
end

-- An entity somewhere has been hurt.  This event fires very often with many units so don't do too many expensive
-- operations here
function GameMode:OnEntityHurt(keys)
  --DebugPrint("[BAREBONES] Entity Hurt")
  --DebugPrintTable(keys)

  local damagebits = keys.damagebits -- This might always be 0 and therefore useless
  if keys.entindex_attacker ~= nil and keys.entindex_killed ~= nil then
    local entCause = EntIndexToHScript(keys.entindex_attacker)
    local entVictim = EntIndexToHScript(keys.entindex_killed)
  end
end

-- An item was picked up off the ground
function GameMode:OnItemPickedUp(keys)
    local status, retval = pcall(OnItemPickedUpDebug, keys)
    if not status then
        GameMode:DEBUGMSG("OnItemPickedUp ERROR: ", retval)	
	end
end

function OnItemPickedUpDebug(keys)
  DebugPrint( '[BAREBONES] OnItemPickedUp' )
  DebugPrintTable(keys)

  local itemname = keys.itemname
  local itemEntity = EntIndexToHScript(keys.ItemEntityIndex)

  if keys.HeroEntityIndex then
    local heroEntity = EntIndexToHScript(keys.HeroEntityIndex)
    local player = PlayerResource:GetPlayer(keys.PlayerID)

    if player:GetTeam() == DOTA_TEAM_GOODGUYS then 
      if CheckShopType(itemname, "SideShop") == false then
        heroEntity:DropItemAtPositionImmediate(itemEntity, heroEntity:GetAbsOrigin())
      end
    end
    if player:GetTeam() == DOTA_TEAM_BADGUYS then 
      if CheckShopType(itemname, "SecretShop") == false then
        heroEntity:DropItemAtPositionImmediate(itemEntity, heroEntity:GetAbsOrigin())
      end
    end
  end
end

-- A player has reconnected to the game.  This function can be used to repaint Player-based particles or change
-- state as necessary
function GameMode:OnPlayerReconnect(keys)
    local status, retval = pcall(OnPlayerReconnectDebug, keys)
    if not status then
        GameMode:DEBUGMSG("OnPlayerReconnect ERROR: ", retval)	
	end
end

function OnPlayerReconnectDebug(keys)
  DebugPrint( '[BAREBONES] OnPlayerReconnect' )
  --PrintTable(keys) 

  local player = PlayerResource:GetPlayer(keys.PlayerID)
  local hero = GameMode.assignedPlayerHeroes[keys.PlayerID]

  for k,v in pairs(hero:GetChildren()) do
    if v:GetClassname() == "dota_item_wearable" then
      v:AddEffects(EF_NODRAW) 
    end
  end

  if hero ~= nil then
  
  Timers:CreateTimer(0, function()
    if PlayerResource:GetConnectionState(keys.PlayerID) == DOTA_CONNECTION_STATE_CONNECTED then
      Timers:CreateTimer(2.25,
      function()
        --Send lumber and food info to users
        CustomGameEventManager:Send_ServerToPlayer( player, "petri_set_builds", GameMode.ItemBuilds )

        --Send lumber and food info to users
        CustomGameEventManager:Send_ServerToPlayer( player, "petri_set_shops", GameMode.shopsKVs )
        
        --Send lumber and food info to users
        CustomGameEventManager:Send_ServerToPlayer( player, "petri_set_ability_layouts", GameMode.abilityLayouts )

        --Send gold costs
        CustomGameEventManager:Send_ServerToPlayer( player, "petri_set_gold_costs", GameMode.abilityGoldCosts )

        --Send xp table
        CustomGameEventManager:Send_ServerToPlayer( player, "petri_set_xp_table", XP_PER_LEVEL_TABLE )

        --Send dependencies
        CustomGameEventManager:Send_ServerToPlayer( player, "petri_set_dependencies_table", GameMode.DependenciesKVs )

        --Send special values
        CustomGameEventManager:Send_ServerToPlayer( player, "petri_set_special_values_table", GameMode.specialValues )

        CustomGameEventManager:Send_ServerToPlayer( player, "petri_close_spawning", { state = false } )
		
        --Set correct team
        if hero:GetUnitName() == "npc_dota_hero_storm_spirit" then
          player:SetTeam(hero:GetTeamNumber())
        end
		
		--Set camera
		GameMode:SetAllPlayersCameraYaw()
		
		--Set variables
		player.ch = pp[player:GetPlayerID()].ch
		player.pr = pp[player:GetPlayerID()].pr
		player.tar = pp[player:GetPlayerID()].tar
		player.lvl = pp[player:GetPlayerID()].lvl
		player.score = pp[player:GetPlayerID()].score
		
		--Send score
		GameMode:addScore(hero, 0)
		
		--Send challenges
		GameMode:ChProgress(player:GetPlayerID(), "KILL", 0)
		GameMode:ChProgress(player:GetPlayerID(), "BUILD", 0)
		GameMode:ChProgress(player:GetPlayerID(), "DESTROY", 0)
		GameMode:ChProgress(player:GetPlayerID(), "MIRACLE", 0)
		GameMode:ChProgress(player:GetPlayerID(), "BOSS", 0)
		GameMode:ChProgress(player:GetPlayerID(), "GOLD", 0)
		GameMode:ChProgress(player:GetPlayerID(), "LUMBER", 0)
		GameMode:ChProgress(player:GetPlayerID(), "CREEPS", 0)
		
		for i = 1, 3 do 
			local event_data =
            {
                text = tostring("#CH_"..player.ch[i]),
				chid = tostring(i),
				lvl = lvls[player:GetPlayerID()],
            }
			CustomGameEventManager:Send_ServerToPlayer( player, "send_ch_desc", event_data )
		end
      end)
    else
      return 0.03
    end
  end)
  
  end
end

-- An item was purchased by a player
function GameMode:OnItemPurchased( keys )
  DebugPrint( '[BAREBONES] OnItemPurchased' )
  DebugPrintTable(keys)

  -- The playerID of the hero who is buying something
  local plyID = keys.PlayerID
  if not plyID then return end

  -- The name of the item purchased
  local itemName = keys.itemname 
  
  -- The cost of the item purchased
  local itemcost = keys.itemcost
end

-- An ability was used by a player
function GameMode:OnAbilityUsed(keys)
  DebugPrint('[BAREBONES] AbilityUsed')
  DebugPrintTable(keys)

  local player = PlayerResource:GetPlayer(keys.PlayerID)
  local abilityname = keys.abilityname

  if player.cursorStream ~= nil then
    if not (string.len(abilityname) > 14 and string.sub(abilityname,1,14) == "move_to_point_") then
      if not DontCancelBuildingGhostAbils[abilityname] then
        player:CancelGhost()
      else
        print(abilityname .. " did not cancel building ghost.")
      end
    end
  end
end

-- A non-player entity (necro-book, chen creep, etc) used an ability
function GameMode:OnNonPlayerUsedAbility(keys)
  DebugPrint('[BAREBONES] OnNonPlayerUsedAbility')
  DebugPrintTable(keys)

  local abilityname=  keys.abilityname
end

-- A player changed their name
function GameMode:OnPlayerChangedName(keys)
  DebugPrint('[BAREBONES] OnPlayerChangedName')
  DebugPrintTable(keys)

  local newName = keys.newname
  local oldName = keys.oldName
end

-- A player leveled up an ability
function GameMode:OnPlayerLearnedAbility( keys)
  DebugPrint('[BAREBONES] OnPlayerLearnedAbility')
  DebugPrintTable(keys)

  local player = EntIndexToHScript(keys.player)
  local abilityname = keys.abilityname
end

-- A channelled ability finished by either completing or being interrupted
function GameMode:OnAbilityChannelFinished(keys)
  DebugPrint('[BAREBONES] OnAbilityChannelFinished')
  DebugPrintTable(keys)

  local abilityname = keys.abilityname
  local interrupted = keys.interrupted == 1
end

-- A player leveled up
function GameMode:OnPlayerLevelUp(keys)
  DebugPrint('[BAREBONES] OnPlayerLevelUp')
  DebugPrintTable(keys)

  local player = EntIndexToHScript(keys.player)
  local level = keys.level
end

-- A player last hit a creep, a tower, or a hero
function GameMode:OnLastHit(keys)
  DebugPrint('[BAREBONES] OnLastHit')
  DebugPrintTable(keys)

  local isFirstBlood = keys.FirstBlood == 1
  local isHeroKill = keys.HeroKill == 1
  local isTowerKill = keys.TowerKill == 1
  local player = PlayerResource:GetPlayer(keys.PlayerID)
  local killedEnt = EntIndexToHScript(keys.EntKilled)
end

-- A tree was cut down by tango, quelling blade, etc
function GameMode:OnTreeCut(keys)
  DebugPrint('[BAREBONES] OnTreeCut')
  DebugPrintTable(keys)

  local treeX = keys.tree_x
  local treeY = keys.tree_y
end

-- A rune was activated by a player
function GameMode:OnRuneActivated (keys)
  DebugPrint('[BAREBONES] OnRuneActivated')
  DebugPrintTable(keys)

  local player = PlayerResource:GetPlayer(keys.PlayerID)
  local rune = keys.rune

  --[[ Rune Can be one of the following types
  DOTA_RUNE_DOUBLEDAMAGE
  DOTA_RUNE_HASTE
  DOTA_RUNE_HAUNTED
  DOTA_RUNE_ILLUSION
  DOTA_RUNE_INVISIBILITY
  DOTA_RUNE_BOUNTY
  DOTA_RUNE_MYSTERY
  DOTA_RUNE_RAPIER
  DOTA_RUNE_REGENERATION
  DOTA_RUNE_SPOOKY
  DOTA_RUNE_TURBO
  ]]
end

-- A player took damage from a tower
function GameMode:OnPlayerTakeTowerDamage(keys)
  DebugPrint('[BAREBONES] OnPlayerTakeTowerDamage')
  DebugPrintTable(keys)

  local player = PlayerResource:GetPlayer(keys.PlayerID)
  local damage = keys.damage
end

-- A player picked a hero
function GameMode:OnPlayerPickHero(keys)
  DebugPrint('[BAREBONES] OnPlayerPickHero')
  DebugPrintTable(keys)

  local heroClass = keys.hero
  local heroEntity = EntIndexToHScript(keys.heroindex)
  local player = EntIndexToHScript(keys.player)
end

-- A player killed another player in a multi-team context
function GameMode:OnTeamKillCredit(keys)
  DebugPrint('[BAREBONES] OnTeamKillCredit')
  DebugPrintTable(keys)

  local killerPlayer = PlayerResource:GetPlayer(keys.killer_userid)
  local victimPlayer = PlayerResource:GetPlayer(keys.victim_userid)
  local numKills = keys.herokills
  local killerTeamNumber = keys.teamnumber
end

-- An entity died
function GameMode:OnEntityKilled(keys)
    local status, retval = pcall(OnEntityKilledDebug, keys)
    if not status then
        GameMode:DEBUGMSG("OnEntityKilled ERROR: ", retval)
    end	
end

function OnEntityKilledDebug( keys )
  DebugPrint( '[BAREBONES] OnEntityKilled Called' )

  GameMode:_OnEntityKilled( keys )
  
  -- The Unit that was Killed
  local killedUnit = EntIndexToHScript( keys.entindex_killed )
  -- The Killing entity
  local killerEntity = nil

  if keys.entindex_attacker ~= nil then
    killerEntity = EntIndexToHScript( keys.entindex_attacker )
  end

  -- Section A

  local damagebits = keys.damagebits -- This might always be 0 and therefore useless

  if not GameMode.assignedPlayerHeroes then
    return 
  end

  local hero = GameMode.assignedPlayerHeroes[killedUnit:GetPlayerOwnerID()]

  if killedUnit.hasNumber == true then
    hero.numberOfUnits = hero.numberOfUnits - 1
  end

  if killedUnit:GetUnitName() == "npc_petri_mega_peasant" then
    hero.numberOfMegaWorkers = hero.numberOfMegaWorkers - 1
  end

  if killedUnit.sandstormFX then
    ParticleManager:DestroyParticle(killedUnit.sandstormFX, false)
  end

  UnfreezeAnimation(killedUnit)
  
  if killedUnit:IsRealHero() and PlayerResource:IsValidPlayer(killerEntity:GetPlayerOwnerID()) then
    GameMode:ChProgress(killerEntity:GetPlayerOwnerID(), "KILL", 1)
  end
  
  if killerEntity:GetTeam() == DOTA_TEAM_BADGUYS then
    GameMode:BusPayOut(3)
  end

  -- KVN fan is killed
  if killedUnit:GetUnitName() == "npc_dota_hero_rattletrap" then
    --GameMode:addScore(killedUnit, GameRules:GetGameTime()/10)
	--isLost[killedUnit:GetPlayerOwnerID()+1] = true
	GameMode:addScore(killerEntity, 100)
	
	--GameMode:sayScore(killedUnit:GetPlayerOwner())
  
    killedUnit:SetTimeUntilRespawn(9999.0)
    GiveSharedGoldToTeam(math.floor(90 * GetGoldModifier()), DOTA_TEAM_BADGUYS)

    if killerEntity:IsRealHero() and killerEntity.AddExperience then
      killerEntity:AddExperience(XP_PER_LEVEL_TABLE_OLD[killerEntity:GetLevel()] / 10,0,false,false)
    end

    Timers:CreateTimer(1.0,
    function()
      if CheckKVN() and GameMode.PETRI_GAME_HAS_ENDED == false then
        GameMode.PETRI_GAME_HAS_ENDED = true

        Timers:CreateTimer(2.0,
          function()
            GameRules.Winner = DOTA_TEAM_BADGUYS
            GameRules:SetGameWinner(DOTA_TEAM_BADGUYS) 
          end)

        Notifications:TopToAll({text="#petrosyan_win", duration=10, style={color="RED"}, continue=false})

        for i=0,DOTA_MAX_PLAYERS do
          if PlayerResource:IsValidPlayerID(i) then
            PlayerResource:SetCameraTarget(i, killerEntity)
          end
        end
      end
    end)

    local allBuildings = Entities:FindAllByClassname("npc_dota_base_additive")
    local allCreeps = Entities:FindAllByClassname("npc_dota_creature")

    local buildingsCount = 0
    local creepsCount = 0

    for k,v in pairs(allBuildings) do
      if v:GetPlayerOwnerID() == killedUnit:GetPlayerOwnerID() then
        buildingsCount = buildingsCount + 1
        Timers:CreateTimer(buildingsCount / 4, function()
          DestroyEntityBasedOnHealth(killerEntity, v)
        end)
      end
    end

    for k,v in pairs(allCreeps) do
      if v:GetPlayerOwnerID() == killedUnit:GetPlayerOwnerID() then
        creepsCount = creepsCount + 1
        Timers:CreateTimer((buildingsCount / 4) + 0.25, function()
          DestroyEntityBasedOnHealth(killerEntity, v)
        end)
      end
    end

    if PlayerResource:GetConnectionState(killedUnit:GetPlayerOwnerID()) == DOTA_CONNECTION_STATE_CONNECTED then
      print(((buildingsCount + creepsCount) / 4) + 0.5)
      Timers:CreateTimer(((buildingsCount + creepsCount) / 4) + 0.5, function ()
        GameMode:ReplaceWithMiniActor(killedUnit:GetPlayerOwner(), killedUnit:GetGold())
      end)
    end
  end

  if killedUnit:GetUnitName() == "npc_petri_exit" or string.match(killedUnit:GetUnitName(), "miracle") then
    GameMode.EXIT_COUNT = GameMode.EXIT_COUNT - 1
    if GameMode.EXIT_COUNT == 0 then
      GameMode.PETRI_ADDITIONAL_EXIT_GOLD_GIVEN = false
    end
  end

  if killedUnit:GetUnitName() == "npc_petri_sawmill" and killedUnit.queueFood then
    hero.food = hero.food - killedUnit.queueFood
  end

  if GameMode.UnitKVs[killedUnit:GetUnitName()] and GameMode.UnitKVs[killedUnit:GetUnitName()]["Unique"] and GameMode.UnitKVs[killedUnit:GetUnitName()]["Unique"] == 1 then
    hero.uniqueUnitList[killedUnit:GetUnitName()] = false
  end

  -- Idol is killed
  if killedUnit:GetUnitName() == "npc_petri_idol" then
    if killedUnit.newShopTarget then UTIL_Remove(killedUnit.newShopTarget) end
    if killedUnit.newShop then UTIL_Remove(killedUnit.newShop) end
  end

  -- Wall is killed
  if killedUnit:GetUnitName() == "npc_petri_wall" or killedUnit:GetUnitName() == "npc_petri_earth_wall" then
    local units = FindUnitsInRadius(killedUnit:GetTeamNumber(), killedUnit:GetAbsOrigin(), nil, 500, DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_ALL, 0, 0, false)
    local stacks = ((killedUnit.maxHitStacks or 0) - (killedUnit:GetModifierStackCount("modifier_hit_stacks",killedUnit) or 0))

    for k,v in pairs(units) do
      if v:GetUnitName() == "npc_petri_wall" or v:GetUnitName() == "npc_petri_earth_wall" then
        v:SetModifierStackCount("modifier_hit_stacks", v, (v:GetModifierStackCount("modifier_hit_stacks",v) or 0) - stacks)
      end
    end
  end
  
  -- Remove building
  if killedUnit:HasAbility("petri_building") then
    GameMode:ChProgress(killerEntity:GetPlayerOwnerID(), "DESTROY", 1)
  
    if GameRules:GetDOTATime(false, false) >= 120 then 
      local bounty = RandomInt(killedUnit:GetMinimumGoldBounty(),killedUnit:GetMaximumGoldBounty())
      GiveSharedGoldToTeam(math.floor(bounty * GetGoldModifier()), DOTA_TEAM_BADGUYS)
    end

    if killedUnit.RemoveBuilding ~= nil then killedUnit:RemoveBuilding(true) end
    local hero = GameMode.assignedPlayerHeroes[killedUnit:GetPlayerOwnerID()]
    if hero then
      hero.buildingCount = hero.buildingCount - 1
    end

    if killedUnit.minimapIcon then
      UTIL_Remove(killedUnit.minimapIcon)
    end

    AddKeyToNetTable(killedUnit:entindex(), "gridnav", "building", {})

    if killedUnit.RemoveFromGNV then
      killedUnit.RemoveFromGNV()
    end
  
    local chance = math.random(1, 100)
    if killerEntity then
      if killerEntity:GetTeam() ~= killedUnit:GetTeam() then
        if chance > GameRules.EVASION_SCROLL_CHANCE then
          CreateItemOnPositionSync(killedUnit:GetAbsOrigin(), CreateItem("item_petri_evasion_scroll", killerEntity, killerEntity)) 
        elseif chance > GameRules.ATTACK_SCROLL_CHANCE then
          CreateItemOnPositionSync(killedUnit:GetAbsOrigin(), CreateItem("item_petri_attack_scroll", killerEntity, killerEntity)) 
        elseif chance > GameRules.GOLD_COIN_CHANCE then
          CreateItemOnPositionSync(killedUnit:GetAbsOrigin(), CreateItem("item_petri_gold_coin", killerEntity, killerEntity)) 
        -- elseif chance > GameRules.WOOD_CHANCE then
        --   CreateItemOnPositionSync(killedUnit:GetAbsOrigin(), CreateItem("item_petri_pile_of_wood", killerEntity, killerEntity)) 
        end
      end
    end

    -- chance = math.random(1, 100)
    -- if killerEntity:GetTeam() ~= killedUnit:GetTeam() then
    --   if chance <= 50 then
    --     CreateItemOnPositionSync(killedUnit:GetAbsOrigin() + Vector(math.random(-30, 30), math.random(-30, 30), math.random(-30, 30)), CreateItem("item_petri_candy", killerEntity, killerEntity)) 
    --   end
    -- end
  end

  if killedUnit.childEntity then
    UTIL_Remove(killedUnit.childEntity)
  end

  -- Petrosyn is killed
  if killedUnit:GetUnitName() == "npc_dota_hero_brewmaster" or
  killedUnit:GetUnitName() == "npc_dota_hero_death_prophet" or
  killedUnit:GetUnitName() == "npc_dota_hero_storm_spirit"  then
    -- if killerEntity:GetPlayerOwnerID() ~= nil then
    --   Notifications:TopToAll({text="#petrosyan_is_killed" .. PlayerResource:GetPlayerName(killerEntity:GetPlayerOwnerID()), duration=4, style={color="yellow"}, continue=false})
    -- end
	if killedUnit.onduel == true then
	    Duels:EndDuelLose(killedUnit:GetPlayerOwnerID())
	else
    
	killedUnit.teleportationState = 0
    killedUnit:SetTimeUntilRespawn(10.0)
    Timers:CreateTimer(10.0,
    function()
      if killedUnit:IsNull() == false then
        killedUnit:RespawnHero(false, false)
      end
    end)
	
	if killerEntity:GetTeam() == DOTA_TEAM_GOODGUYS and killerEntity:GetPlayerOwner():GetAssignedHero() then
	    GameMode:addScore(killerEntity:GetPlayerOwner():GetAssignedHero(), 8)
	end
    
	end
  end

  if killedUnit.foodProvided ~= nil then
    local hero = GameMode.assignedPlayerHeroes[killedUnit:GetPlayerOwnerID()]

    hero.maxFood = hero.maxFood - killedUnit.foodProvided
  end

  if killedUnit.foodSpent ~= nil then
    local hero = GameMode.assignedPlayerHeroes[killedUnit:GetPlayerOwnerID()]

    hero.food = hero.food - killedUnit.foodSpent
  end

  if killedUnit:GetUnitName () == "npc_petri_cop_trap" then
    local level = killedUnit:FindAbilityByName("petri_cop_trap"):GetLevel()
    local dmg = 100
    if level == 2 then dmg = 350 end
    local damageTable = {
        victim = killerEntity,
        attacker = killedUnit,
        damage = dmg,
        damage_type = DAMAGE_TYPE_PURE,
    }
    ApplyDamage(damageTable)
  end

  if killedUnit:GetUnitName () == "npc_petri_cop" then
    GameMode.assignedPlayerHeroes[killedUnit:GetPlayerOwnerID()].copIsPresent = false
  end

  if string.match(killedUnit:GetUnitName (), "peasant") then
    killedUnit:RemoveModifierByName("modifier_chopping_wood")
    killedUnit:RemoveModifierByName("modifier_gathering_lumber")
    killedUnit:RemoveModifierByName("modifier_chopping_wood_animation")

    killedUnit:RemoveModifierByName("modifier_repairing")
    killedUnit:RemoveModifierByName("modifier_chopping_building")
    killedUnit:RemoveModifierByName("modifier_chopping_building_animation")
  end

  -- Respawn creep
  local bounty = RandomInt(killedUnit:GetMinimumGoldBounty(),killedUnit:GetMaximumGoldBounty())

  if killerEntity:GetTeamNumber() == DOTA_TEAM_BADGUYS and GameMode.UnitKVs[killedUnit:GetUnitName()] and GameMode.UnitKVs[killedUnit:GetUnitName()]["vscripts"] == "units/peasant.lua" then
    AddCustomGold( killerEntity:GetPlayerOwnerID(), bounty)
  end

  if string.match(killedUnit:GetUnitName (), "npc_petri_creep_") or string.match(killedUnit:GetUnitName (), "boss") then
    killerEntity:AddExperience(killedUnit:GetDeathXP() * GameRules.PETRI_EXPERIENCE_MULTIPLIER, 0, false, true)
	GameMode:ChProgress(killerEntity:GetPlayerOwnerID(), "CREEPS", 1)
    if killerEntity:GetTeamNumber() == DOTA_TEAM_BADGUYS and string.match(killedUnit:GetUnitName (), "boss") then -- boss
	  GameMode:ChProgress(killerEntity:GetPlayerOwnerID(), "BOSS", 1)
      Notifications:TopToAll({text="#boss_is_killed_1", duration=4, style={color="red"}, continue=false})
      Notifications:TopToAll({text=tostring(bounty/2).." ", duration=4, style={color="red"}, continue=true})
      Notifications:TopToAll({text="#boss_is_killed_2", duration=4, style={color="red"}, continue=true})
	  GameMode:addScore(killerEntity, 100)
      if bounty >= 9866 then
       CreateItemOnPositionSync(killerEntity:GetAbsOrigin(), CreateItem("item_petri_grease", killerEntity, killerEntity)) 
       Notifications:TopToAll({text="#grease_has_been_dropped", duration=4, style={color="red"}, continue=false})
      end
      if bounty >= 40000 then
        for i=1,5 do
          CreateItemOnPositionSync(killerEntity:GetAbsOrigin(), CreateItem("item_petri_grease", killerEntity, killerEntity)) 
        end
      end
      bounty = bounty/2
      GiveSharedGoldToTeam(bounty, DOTA_TEAM_BADGUYS)
      return false
    else
      AddCustomGold( killerEntity:GetPlayerOwnerID(), bounty)

      if GameMode.isday == false then

	    killerEntity:FindAbilityByName("petri_petrosyan_return"):EndCooldown()
        killerEntity:CastAbilityNoTarget(killerEntity:FindAbilityByName("petri_petrosyan_return"), killerEntity:GetPlayerOwnerID())
        Notifications:Bottom(killerEntity:GetPlayerOwnerID(), {text="#no_farm_tonight", duration=5, style={color="red", ["font-size"]="45px"}})
        
        Timers:CreateTimer(0.04,
        function()
          MoveCamera(killerEntity:GetPlayerOwnerID(), killerEntity)
        end)
        
      end
      
      Timers:CreateTimer(0.4,
      function()
        local particleName = "particles/items2_fx/shadow_amulet_activate_runes.vpcf"
        local particle = ParticleManager:CreateParticle( particleName, PATTACH_CUSTOMORIGIN, killedUnit )
        ParticleManager:SetParticleControl( particle, 0, killedUnit:GetAbsOrigin() )
        ParticleManager:ReleaseParticleIndex( particle )
      end)

      local pos = killedUnit:GetAbsOrigin()
      Timers:CreateTimer(0.37,
      function()
        local newUnit = CreateUnitByName(killedUnit:GetUnitName(), pos, true, nil, nil,DOTA_TEAM_NEUTRALS)

      end)
    end
  end
end

-- This function is called 1 to 2 times as the player connects initially but before they 
-- have completely connected
function GameMode:PlayerConnect(keys)
  DebugPrint('[BAREBONES] PlayerConnect')
  DebugPrintTable(keys)
end

local fply = 0

-- This function is called once when the player fully connects and becomes "Ready" during Loading
function GameMode:OnConnectFull(keys)
  DebugPrint('[BAREBONES] OnConnectFull')

  GameMode:_OnConnectFull(keys)
  
  local entIndex = keys.index+1
  -- The Player entity of the joining user
  local ply = EntIndexToHScript(entIndex)

  -- The Player ID of the joining player
  local playerID = ply:GetPlayerID()
  --[[
  	if PlayerResource:IsValidPlayer(playerID) then
  	fply = fply + 1
    if fply == PlayerResource:GetPlayerCount() then
	if not GameRules:IsCheatMode() and PlayerResource:GetPlayerCount() >= 6 or IsInToolsMode() then
	    IS_RANKED_GAME = true
	end
    loadrating()
	end
	end
	]]--
end

-- This function is called whenever illusions are created and tells you which was/is the original entity
function GameMode:OnIllusionsCreated(keys)
  DebugPrint('[BAREBONES] OnIllusionsCreated')
  DebugPrintTable(keys)

  local originalEntity = EntIndexToHScript(keys.original_entindex)
end

-- This function is called whenever an item is combined to create a new item
function GameMode:OnItemCombined(keys)
  DebugPrint('[BAREBONES] OnItemCombined')
  DebugPrintTable(keys)

  -- The playerID of the hero who is buying something
  local plyID = keys.PlayerID
  if not plyID then return end
  local player = PlayerResource:GetPlayer(plyID)

  -- The name of the item purchased
  local itemName = keys.itemname 
  
  -- The cost of the item purchased
  local itemcost = keys.itemcost
end

-- This function is called whenever an ability begins its PhaseStart phase (but before it is actually cast)
function GameMode:OnAbilityCastBegins(keys)
  DebugPrint('[BAREBONES] OnAbilityCastBegins')
  DebugPrintTable(keys)

  local player = PlayerResource:GetPlayer(keys.PlayerID)
  local abilityName = keys.abilityname
end

-- This function is called whenever a tower is killed
function GameMode:OnTowerKill(keys)
  DebugPrint('[BAREBONES] OnTowerKill')
  DebugPrintTable(keys)

  local gold = keys.gold
  local killerPlayer = PlayerResource:GetPlayer(keys.killer_userid)
  local team = keys.teamnumber
end

-- This function is called whenever a player changes there custom team selection during Game Setup 
function GameMode:OnPlayerSelectedCustomTeam(keys)
  DebugPrint('[BAREBONES] OnPlayerSelectedCustomTeam')
  DebugPrintTable(keys)

  local player = PlayerResource:GetPlayer(keys.player_id)
  local success = (keys.success == 1)
  local team = keys.team_id
end

-- This function is called whenever an NPC reaches its goal position/target
function GameMode:OnNPCGoalReached(keys)
  DebugPrint('[BAREBONES] OnNPCGoalReached')
  DebugPrintTable(keys)

  local goalEntity = EntIndexToHScript(keys.goal_entindex)
  local nextGoalEntity = EntIndexToHScript(keys.next_goal_entindex)
  local npc = EntIndexToHScript(keys.npc_entindex)
end

function GameMode:OnPlayerSelectedEntities( event )
  local pID = event.pID

  GameMode.SELECTED_UNITS[pID] = event.selected_entities
end

function GameMode:OnPlayerSendName( event )
  local pID = event.pID
  local name = event.name

  GameMode.PETRI_NAME_LIST[pID] = name
end

function GameMode:OnPlayerMakeBet( event )
  local pID = event.pID
  local bet = event.bet
  local option = event.option

  if GameMode.LOTTERY_STATE == 0 then
    return false
  end

  GameMode.CURRENT_BANK = GameMode.CURRENT_BANK + bet

  if not GameMode.CURRENT_LOTTERY_PLAYERS[tostring(pID)] then 
    GameMode.CURRENT_LOTTERY_PLAYERS[tostring(pID)]           = {}
    GameMode.CURRENT_LOTTERY_PLAYERS[tostring(pID)]["option"] = option
    GameMode.CURRENT_LOTTERY_PLAYERS[tostring(pID)]["bet"]    = bet
  end

  local g = bet
  local free = ((GameMode.LOTTERY_PLAY_COUNT or 0)+1) * 20

  if g <= free then
    g = 0
  else
    g = g - free
  end

  SpendCustomGold( pID, g )
  GameMode.assignedPlayerHeroes[pID]:EmitSound("DOTA_Item.Hand_Of_Midas")

  CustomGameEventManager:Send_ServerToAllClients("petri_bank_updated", {["bank"] = GameMode.CURRENT_BANK} )
end

function GameMode:OnPlayerSay( event )
  local pID = event.userid - 1
  local text = event.text
  local player = PlayerResource:GetPlayer(pID)
  local hero = player:GetAssignedHero()
  
  print(text)
  
  if text == "-disablehints" then
    table.insert(DISABLED_HINTS_PLAYERS, pID)
  end
  
  if text == "-sobaka" then
    local sobakarandom = math.random(0, PlayerResource:GetPlayerCount())
    Say(PlayerResource:GetPlayer(sobakarandom),"SOBAKA", false)
  end
  
  if text == "!spectate" then
    --HostSpectate(player)
  end
  
  --CustomGameEventManager:Send_ServerToPlayer( player, "chat_fix", {})  
  
  --hero:SwapItems( DOTA_ITEM_SLOT_1, DOTA_STASH_SLOT_1 )
  --Timers:CreateTimer(0.1, function()
      --hero:SwapItems( DOTA_ITEM_SLOT_1, DOTA_STASH_SLOT_1 )
      --return nil
  --end
  --)
end

function HostSpectate(pID)
    local player = PlayerResource:GetPlayer(pID)
    local hero = player:GetAssignedHero()
    if GameRules:PlayerHasCustomGameHostPrivileges(player) then
	if player:GetTeam() == DOTA_TEAM_GOODGUYS then
	    player:SetTeam(DOTA_TEAM_CUSTOM_1)
		
		Timers:CreateTimer(1.0,
        function()
		print("SPECATE "..player:GetTeam())
	    AddFOWViewer(player:GetTeam(), hero:GetAbsOrigin(), 999999, 999999, false)
		UTIL_Remove(hero)
		
        if CheckKVN() and GameMode.PETRI_GAME_HAS_ENDED == false then
        GameMode.PETRI_GAME_HAS_ENDED = true

        Timers:CreateTimer(2.0,
          function()
            GameRules.Winner = DOTA_TEAM_BADGUYS
            GameRules:SetGameWinner(DOTA_TEAM_BADGUYS) 
          end)

        Notifications:TopToAll({text="#petrosyan_win", duration=10, style={color="RED"}, continue=false})

        for i=0,DOTA_MAX_PLAYERS do
          if PlayerResource:IsValidPlayerID(i) then
            PlayerResource:SetCameraTarget(i, killerEntity)
          end
        end
        end
        end)
		
		direUnits = FindUnitsInRadius(DOTA_UNIT_TARGET_TEAM_NONE,
                              Vector(0, 0, 0),
                              nil,
                              FIND_UNITS_EVERYWHERE,
                              DOTA_UNIT_TARGET_TEAM_BOTH,
                              DOTA_UNIT_TARGET_ALL,
                              DOTA_UNIT_TARGET_FLAG_NONE,
                              FIND_ANY_ORDER,
                              false)

        for _,unit in pairs(direUnits) do
            AddFOWViewer(player:GetTeam(), unit:GetAbsOrigin(), 999999, 999999, false)
        end
	end
	end
end

function OnHostSpectate(source, data)
    --HostSpectate(data["pid"])
end

CustomGameEventManager:RegisterListener( "petri_host_spectate", OnHostSpectate )