BAREBONES_DEBUG_SPEW = true

IS_RANKED_GAME = false

if GameMode == nil then
    DebugPrint( '[BAREBONES] creating barebones game mode' )
    _G.GameMode = class({})
end

GameMode.cameraYaw = 0

pp = {}

GameMode.allowkivin = false

GameMode.isday = nil
time_flow = 0.0020833333

GameMode.UseMiraclesTrueK = 0
GameMode.UseMiraclesFalseK = 0
GameMode.UseMiracles = true

GameMode.DISABLED_HINTS_PLAYERS = {}

GameMode.PETRI_GAME_HAS_STARTED = false
GameMode.PETRI_GAME_HAS_ENDED = false

GameMode.PETRI_NO_END = false

GameMode.PETRI_NAME_LIST = {}
GameMode.PETRI_LANG_LIST = {}

GameMode.KVN_BONUS_ITEM = {}
for i=0,DOTA_MAX_PLAYERS do
  GameMode.KVN_BONUS_ITEM[i] = {}
  table.insert(GameMode.KVN_BONUS_ITEM[i], {item = "item_petri_kvn_bag_1", count = 1})
  table.insert(GameMode.KVN_BONUS_ITEM[i], {item = "item_petri_kvn_bag_2", count = 1})
  table.insert(GameMode.KVN_BONUS_ITEM[i], {item = "item_petri_kvn_bag_3", count = 1})
  table.insert(GameMode.KVN_BONUS_ITEM[i], {item = "item_petri_kvn_bag_4", count = 1})
end

GameMode.EXIT_COUNT = 0

GameMode.PETRI_ADDITIONAL_EXIT_GOLD_GIVEN = false
GameMode.PETRI_ADDITIONAL_EXIT_GOLD_TIME = 300
GameMode.PETRI_ADDITIONAL_EXIT_GOLD = 10000

GameMode.villians = {}
GameMode.kvns = {}

FUCKSCALEFORM = false

GameRules.Winner = GameRules.Winner or DOTA_TEAM_BADGUYS

check1 = (function(name) 
            for i=1,7 do
              if GameRules.PETRI_LOCK_ITEMS[i] == name then
                return true
              end
            end
            return false
          end)

check2 = (function(purchaser) 
            for i=0,5 do
              if purchaser:GetItemInSlot(i) and check1(purchaser:GetItemInSlot(i):GetName()) then
                return true
              end
            end
            return false
          end)

require('libraries/util/split')
require('libraries/chatcommand')
		  
require('libraries/physics')
require('libraries/projectiles')
require('libraries/notifications')
require('libraries/attachments')
require('libraries/animations')
require('libraries/GameSetup')
require('libraries/KickSystem')
require('libraries/CustomBuildings')
-- require('libraries/StatUploaderFunctions')

require('libraries/buildinghelper')
require('libraries/dependencies')

require('units/kvn_fan')

require('buildings/bh_abilities')

require('balance')

require('settings')
require('internal/events')
require('events')

require('lottery')
require('scores')
require('autogold')
require('shop')

--require('rating')
require('newrating')

require('duels')

require('randommap')

require('classes')

require('filters')
require('commands')
require('internal/gamemode')

require('easytimers')

require('internal/modifier_model_change')
require('internal/modifier_bonus_life')
require('internal/modifier_tribune')

function GameMode:PostLoadPrecache()
  DebugPrint("[BAREBONES] Performing Post-Load precache")
end

function GameMode:OnFirstPlayerLoaded()
  DebugPrint("[BAREBONES] First Player has loaded")
end

function GameMode:OnAllPlayersLoaded()
  DebugPrint("[BAREBONES] All Players have loaded into the game")
end

function GameMode:AddItems( newHero )
  for steamid,t in pairs(GameMode.StartItemsKVs) do
    if tonumber(steamid) == PlayerResource:GetSteamAccountID(newHero:GetPlayerOwnerID()) then
      for k,v in pairs(t) do
        if k == newHero:GetUnitName() then
          for k1,v1 in pairs(v) do
            newHero:AddItemByName(v1)
          end
          break
        end
      end
    end
  end
end

function GameMode:CreateHero(pID, callback)
  GameMode.assignedPlayerHeroes = GameMode.assignedPlayerHeroes or {}
  
  local player = PlayerResource:GetPlayer(pID)
  if not player then
    callback()
    return
  end
  local team = player:GetTeam()
  local wisp = player:GetAssignedHero()
  if not IsValidEntity(wisp) then
    print("asadasd")
    callback()
    return
  end

  local newHero

  InitAbilities(wisp)
  print(wisp:GetAbilityByIndex(0):GetName())

   -- Init kvn fan
  if team == 2 then
    -- UTIL_Remove(hero) 
    PrecacheUnitByNameAsync("npc_dota_hero_rattletrap",
      function() 
        player = PlayerResource:GetPlayer(pID)
        if not player then
          callback()
        end
        -- self.playerQueue()
        Notifications:Top(pID, {text="#start_game", duration=5, style={color="white", ["font-size"]="45px"}})

        newHero = PlayerResource:ReplaceHeroWith(pID,"npc_dota_hero_rattletrap",0,0)
        -- UTIL_Remove(wisp)

        InitAbilities(newHero)

        -- newHero:SetAbilityPoints(0)
        -- local item = CreateItem("item_petri_hp_fix",newHero,newHero)
        -- item:ApplyDataDrivenModifier(newHero,newHero,"modifier_hp_hack",{})

        -- PrintTable(GameMode.KVN_BONUS_ITEM[pID])

        if GameMode.KVN_BONUS_ITEM[pID] then
          for k,v in pairs(GameMode.KVN_BONUS_ITEM[pID]) do
            for i=1,tonumber(v["count"]) do
              newHero:AddItemByName(v["item"])
            end  
          end
        end

        newHero.spawnPosition = newHero:GetAbsOrigin()
        
        InitHeroValues(newHero, pID)
        newHero.lumber = GameRules.START_KVN_LUMBER

        newHero.uniqueUnitList = {}

        SetupUI(pID)
        SetupUpgrades(pID)
        SetupDependencies(pID)

        GameMode.assignedPlayerHeroes[pID] = newHero

        SetCustomGold( pID, GameRules.START_KVN_GOLD )

        newHero.kvnScore = 0

        Timers:CreateTimer(function (  )
          newHero.key = "kvn"
          GameMode:SetupCustomSkin(newHero, PlayerResource:GetSteamAccountID(pID), newHero.key)
          GameMode:SetupVIPItems(newHero, PlayerResource:GetSteamAccountID(pID))
        end)

        if newHero then
          EasyTimers:CreateTimer(function()
            local abilities = newHero:GetAbilityCount() - 1
            for i = 0, abilities do
              if newHero:GetAbilityByIndex(i) then
                if string.find(newHero:GetAbilityByIndex(i):GetAbilityName(), "special") then
                    newHero:GetAbilityByIndex(i):SetAbilityIndex(14+i)
                    newHero:RemoveAbility(newHero:GetAbilityByIndex(i):GetAbilityName())
                end
              end
            end
          end, DoUniqueString('fixHotKey'), 2)
        end

        table.insert(GameMode.kvns, newHero)

        GameMode:AddItems( newHero )

        callback()
        CustomGameEventManager:Send_ServerToPlayer( player, "petri_close_spawning", { state = false } )
      end, 
    pID)

    return
  end

  local petrosyanHeroName = "npc_dota_hero_brewmaster"
  if pID == PlayerResource:GetNthPlayerIDOnTeam(DOTA_TEAM_BADGUYS, 2) then
    petrosyanHeroName = "npc_dota_hero_death_prophet"
  end

   -- Init petrosyan
  if team == 3 then
    -- UTIL_Remove(hero) 
    PrecacheUnitByNameAsync(petrosyanHeroName,
     function() 
        player = PlayerResource:GetPlayer(pID)
        if not player then
          callback()
        end
        -- self.playerQueue()
        newHero = PlayerResource:ReplaceHeroWith(pID,petrosyanHeroName,0,0)
        -- UTIL_Remove(wisp)

        -- It's dangerous to go alone, take this
        newHero:SetAbilityPoints(4)
        newHero:UpgradeAbility(newHero:FindAbilityByName("petri_petrosyan_return"))
        newHero:UpgradeAbility(newHero:FindAbilityByName("petri_petrosyan_passive"))
        newHero:UpgradeAbility(newHero:FindAbilityByName("petri_exploration_tower_explore_world"))
        newHero:UpgradeAbility(newHero:FindAbilityByName("petri_petrosyan_flat_joke"))

        newHero:FindAbilityByName("petri_petrosyan_passive"):ApplyDataDrivenModifier(newHero, newHero, "dummy_sleep_modifier", {})

        newHero.spawnPosition = newHero:GetAbsOrigin()

        InitHeroValues(newHero, pID)

        SetupUI(pID)

        GameMode.assignedPlayerHeroes[pID] = newHero

        Timers:CreateTimer(function (  )
          GameMode:SetupVIPItems(newHero, PlayerResource:GetSteamAccountID(pID))
        end)

        SetCustomGold( pID, GameRules.START_PETROSYANS_GOLD )

        newHero.petrosyanScore = 0

        GameMode.villians[petrosyanHeroName] = newHero

        Timers:CreateTimer(function (  )
          if petrosyanHeroName ~= "npc_dota_hero_death_prophet" then
            newHero.key = "petrosyan"
            GameMode:SetupCustomSkin(newHero, PlayerResource:GetSteamAccountID(pID), newHero.key)
          else
            newHero.key = "elena"
            GameMode:SetupCustomSkin(newHero, PlayerResource:GetSteamAccountID(pID), newHero.key)
          end
        end)

        if GameRules.explorationTowerCreated == nil then
          GameRules.explorationTowerCreated = true
          Timers:CreateTimer(0.2,
          function()
            GameMode.explorationTower = CreateUnitByName( "npc_petri_exploration_tower" , Entities:FindAllByName("exploration_tower_position")[1]:GetAbsOrigin() , true, newHero, nil, DOTA_TEAM_BADGUYS )
            end)
        end

        if newHero then
          EasyTimers:CreateTimer(function()
            local abilities = newHero:GetAbilityCount() - 1
            for i = 0, abilities do
              if newHero:GetAbilityByIndex(i) then
                if string.find(newHero:GetAbilityByIndex(i):GetAbilityName(), "special") then
                    newHero:GetAbilityByIndex(i):SetAbilityIndex(14+i)
                    newHero:RemoveAbility(newHero:GetAbilityByIndex(i):GetAbilityName())
                end
              end
            end
          end, DoUniqueString('fixHotKey'), 2)
        end

        GameMode:AddItems( newHero )

        callback()
        CustomGameEventManager:Send_ServerToPlayer( player, "petri_close_spawning", { state = false } )
     end, pID)
    return
  end
end

function InitHeroValues(hero, pID)
  hero.lumber = 0
  hero.bonusLumber = 0
  hero.food = 0
  hero.maxFood = 10
  hero.allEarnedGold = 0
  hero.allGatheredLumber = 0
  hero.numberOfUnits = 0
  hero.numberOfMegaWorkers = 0
  hero.buildingCount = 0

  GameMode.SELECTED_UNITS[pID] = {}
  GameMode.SELECTED_UNITS[pID]["0"] = hero:entindex()
end

function SetupDependencies(pID)
  CustomNetTables:SetTableValue( "players_dependencies", tostring(pID), {} );
end

function SetupUpgrades(pID)
  local upgradeAbilities = {}

  for ability_name,ability_info in pairs(GameMode.AbilityKVs) do
    if type(ability_info) == "table" then
      if string.match(ability_name, "petri_upgrade") then 
         upgradeAbilities[ability_name] = 0
      end  
    end
  end

  CustomNetTables:SetTableValue( "players_upgrades", tostring(pID), upgradeAbilities );

  --PrintTable(CustomNetTables:GetTableValue("players_upgrades", tostring(pID)))
end

function SetupUI(pID)
  local player = PlayerResource:GetPlayer(pID)
  if not player then return end

  --Send lumber and food info to users
  CustomGameEventManager:Send_ServerToPlayer( player, "petri_set_items", GameMode.ItemKVs )

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

  --Send lumber and food info to users
  CustomGameEventManager:Send_ServerToPlayer( player, "petri_set_builds", GameMode.ItemBuilds )

  --Send lumber and food info to users
  CustomGameEventManager:Send_ServerToPlayer( player, "petri_set_shops", GameMode.shopsKVs )
end

function checkarenatriggers()
	--[[
	for i = 0, PlayerResource:GetPlayerCount() do
		if PlayerResource:IsValidPlayer(i) and PlayerResource:GetPlayer(i):GetAssignedHero() and PlayerResource:GetPlayer(i):GetAssignedHero():GetTeam() == DOTA_TEAM_BADGUYS then
			local hero = PlayerResource:GetPlayer(i):GetAssignedHero()
			local nTrigg = Entities:FindByClassnameNearest("trigger_dota", hero:GetAbsOrigin(), 500)
			print("POSHEL NAHOOY "..nTrigg:GetName() )
			if nTrigg and nTrigg:IsTouching(hero) and string.match(nTrigg:GetName(), "space") then
				print("POSHEL NAHOOY found touching portal trigger")
				nTrigg:Disable()
				nTrigg:Enable()
			end
		end
	end
	]]
	
	local trigs = Entities:FindAllByClassname("trigger_dota")
	for k,v in pairs(trigs) do
		print(v:GetName())
		if v and (string.match(v:GetName(), "space") or string.match(v:GetName(), "portal")) then
			print("poshel nahooy")
			v:Disable()
			v:Enable()
		end
	end
end

function daynight(time_elapsed, start_time_of_day, end_time_of_day)
	print('noch')
	EmitAnnouncerSound('announcer_ann_custom_time_alert_02')
	GameMode.isday = false
	GameRules:SetTimeOfDay(0)
	Timers:CreateTimer(0.03, function()
	    if time_elapsed < 240 then
		    GameRules:SetTimeOfDay(0)
		    time_elapsed = time_elapsed + 1
		    return 1
	    else
		    time_elapsed = 0
			print('denb')
			EmitAnnouncerSound('announcer_ann_custom_time_alert_06')
			GameMode.isday = true
		   -- GameRules:SetTimeOfDay(end_time_of_day)
		    GameRules:SetTimeOfDay(0.26)
			
			checkarenatriggers()
		    return nil
	    end
	end)
end

function GameMode:isdaydumb()
    local t = GameRules:GetDOTATime(false, false)
    --print("DUMBTIME: "..t)
	--GameMode:DEBUGMSG("DUMBTIME: ", t)
	if t <= 240 or t >= 480 and t <= 720 or t >= 960 and t <= 1200 or t >= 1440 and t <= 1680 or t >= 1920 and t <= 2160 or t >= 2400 and t <= 2640 or t >= 2880 and t <= 3120 or t >= 3360 and t <= 3600 or t >= 3840 and t <= 4080 then
        return true
    else 
	    return false
	end
end

local pauseCount = 0

function fixPause()
	Timers:CreateTimer({
    useGameTime = false,
    endTime = 1, -- when this timer should first execute, you can omit this if you want it to run first on the next frame
    callback = function()
        if GameRules:IsGamePaused() then
		    pauseCount = pauseCount + 1
			print(pauseCount)
			if pauseCount >= 120 then
			    print("CANT PAUSE GAME NOW")
			    PauseGame(false)
			    GameRules:GetGameModeEntity():SetPauseEnabled(false)
				return nil
			end
		end
 		return 1
    end
    })
end

function GiveCh()
  Timers:CreateTimer(3, function()
    for i = 0, PlayerResource:GetPlayerCount() do
	if PlayerResource:IsValidPlayer(i) then
	    for j = 1, 3 do
		    local rand = math.random(1, 5)
			local ChDesc = ""
			local ChTar = ""
			local player = PlayerResource:GetPlayer(i)
			local team = player:GetAssignedHero():GetTeam()
			if rand == 1 then
			    ChDesc = "#CH_KILL"
				player.ch[j] = "KILL"
				pp[i].ch[j] = "KILL"
				ChTar = math.random(1, j*2)
			elseif rand == 2 then
                if team == DOTA_TEAM_GOODGUYS then
                    ChDesc = "#CH_BUILD"
				    player.ch[j] = "BUILD"
					pp[i].ch[j] = "BUILD"
				    ChTar = math.random(5, j*10)
                elseif team == DOTA_TEAM_BADGUYS then
                    ChDesc = "#CH_DESTROY"
				    player.ch[j] = "DESTROY"
					pp[i].ch[j] = "DESTROY"
				    ChTar = math.random(5, j*5)
                end				
			elseif rand == 3 then
                if team == DOTA_TEAM_GOODGUYS then
                    ChDesc = "#CH_MIRACLE"
				    player.ch[j] = "MIRACLE"
					pp[i].ch[j] = "MIRACLE"
				    ChTar = j
                elseif team == DOTA_TEAM_BADGUYS then
                    ChDesc = "#CH_BOSS"
				    player.ch[j] = "BOSS"
					pp[i].ch[j] = "BOSS"
				    ChTar = j
                end				    
			elseif rand == 4 then
				ChDesc = "#CH_GOLD"
				player.ch[j] = "GOLD"
				pp[i].ch[j] = "GOLD"
				ChTar = math.random(j*1000, j*15000)
			elseif rand == 5 then
                if team == DOTA_TEAM_GOODGUYS then
                    ChDesc = "#CH_LUMBER"
				    player.ch[j] = "LUMBER"
					pp[i].ch[j] = "LUMBER"
				    ChTar = math.random(j*500, j*15000)
                elseif team == DOTA_TEAM_BADGUYS then
                    ChDesc = "#CH_CREEPS"
				    player.ch[j] = "CREEPS"
					pp[i].ch[j] = "CREEPS"
				    ChTar = math.random(j*100, j*1000)
                end		
			end
			player.tar[j] = ChTar
			pp[i].tar[j] = ChTar
			print("CHALLENGE: "..i.." "..j.." "..rand.." "..ChDesc.." "..ChTar)
			local event_data =
            {
                text = ChDesc,
				chid = tostring(j),
            }
			CustomGameEventManager:Send_ServerToPlayer( player, "send_ch_desc", event_data )
			event_data =
            {
                chid = tostring(j),
				cur = 0,
				tar = ChTar,
            }
			CustomGameEventManager:Send_ServerToPlayer( player, "send_ch_pr", event_data )
		end
	--GameMode:DEBUGMSG("GIVECH: ", i)
	GameMode:ChUpdateLvl(PlayerResource:GetPlayer(i))
	end
	end
  return nil
  end
  )
end

function GameMode:ChUpdateLvl(player)
    local event_data =
    {
		lvl = lvls[player:GetPlayerID()],
    }
	CustomGameEventManager:Send_ServerToPlayer( player, "send_ch_lvl", event_data)
end

function GameMode:ChProgress(pid, chtype, progress)
    local data = {pid, chtype, progress}
    local status, retval = pcall(ChProgressDebug, data)
    if not status then
        GameMode:DEBUGMSG("ChProgress ERROR: ", retval)
    end	
end

function ChProgressDebug(data)
    local pid = data[1]
    local chtype = data[2]
    local progress = data[3]
    local player = PlayerResource:GetPlayer(pid)
	for i = 1, 3 do
	    if PlayerResource:GetConnectionState(pid) == DOTA_CONNECTION_STATE_CONNECTED then
	    if player.ch[i] and player.ch[i] == chtype and player.pr[i] and player.tar[i] and player.pr[i] < player.tar[i] then
		    player.pr[i] = player.pr[i] + progress
			event_data =
            {
                chid = i,
				cur = player.pr[i],
				tar = player.tar[i],
            }
			CustomGameEventManager:Send_ServerToPlayer( player, "send_ch_pr", event_data )
			if player.pr[i] >= player.tar[i] then
			    print("CHALLENGE COMPLETED "..pid.." "..i)
				local addExp = i * 100
				player.lvl = player.lvl + addExp
                if pp[pid] and pp[pid].lvl then				
					pp[pid].lvl = pp[pid].lvl + addExp
				end
				lvls[pid] = lvls[pid] + addExp
				
				GameMode:ChUpdateLvl(player)
				
				--EmitAnnouncerSoundForPlayer("announcer_ann_custom_adventure_alerts_11", pid)
			end
			if pp[pid] and pp[pid].pr[i] then
			    pp[pid].pr[i] = pp[pid].pr[i] + progress
			end
		end
		end
	end
end

function GameMode:SetAllPlayersCameraYaw()
    print("set cameraYaw server")
    local event_data = {yaw = GameMode.cameraYaw,}
    --CustomGameEventManager:Send_ServerToAllClients( "set_camera_yaw", event_data )
end

GameMode.MINUSTIME = 0

PlayerRT = {}

function GameMode:SpawnCouriers()
    for i = 0, PlayerResource:GetPlayerCount() do
	    if PlayerResource:IsValidPlayer(i) == true then
		    local hero = PlayerResource:GetPlayer(i):GetAssignedHero()
			if hero and hero:IsRealHero() == true and hero:GetTeam() == DOTA_TEAM_BADGUYS and hero.petriCourier == nil then
			    hero.petriCourier = CreateUnitByName("npc_dota_courier", hero:GetAbsOrigin(), false, hero, hero, DOTA_TEAM_BADGUYS)
				hero.petriCourier:SetControllableByPlayer(hero:GetPlayerOwnerID(), true)
				hero.petriCourier:SetOwner(hero)
			end
		end
	end
end

function GameMode:GetRandomMapPosition()
    return Vector(math.random(GetWorldMinX(),GetWorldMaxX()),math.random(GetWorldMinY(),GetWorldMaxY()),0)
end

function GameMode:FrostivusGifts()
    Timers:CreateTimer(3, function()
	    GameMode:FrostivusSpawnGifts()
        return 60.0
    end)
end

function GameMode:FrostivusSpawnGifts()
    local count = math.random(10, 50)
	print("gifts "..count)
	GameRules:SendCustomMessage("#petrt_gift_spawn", 0, count)
	for i = 1, count do
	    GameMode:FrostivusSpawnGift(GameMode:GetRandomMapPosition())
	end
end

function GameMode:FrostivusSpawnGift(vector)
    CreateUnitByName("npc_petri_gift", vector, true, nil, nil, DOTA_TEAM_NEUTRALS)
end

--dlya rune posuti
function GameMode:ApplyModifierAtAllBuldings(mname, item, hero)
	item:ApplyDataDrivenModifier(hero, hero, mname, {Duration = GameRules.PETRI_RUNE_DURATION})
	if hero.cop and hero.cop:IsAlive() then
		item:ApplyDataDrivenModifier(hero, hero.cop, mname, {Duration = GameRules.PETRI_RUNE_DURATION})
    end	

    local allBuildings = Entities:FindAllByClassname("npc_dota_base_additive")
	for k,v in pairs(allBuildings) do
        if v:GetPlayerOwnerID() == hero:GetPlayerOwnerID() then
			item:ApplyDataDrivenModifier(hero, v, mname, {Duration = GameRules.PETRI_RUNE_DURATION})
		end
	end
end

function GameMode:ApplyModifierAtAllPetroses(mname, item, hero)
    for i = 0, 20 do
	    if PlayerResource:IsValidPlayer(i) then
		    local player = PlayerResource:GetPlayer(i)
			local petro = player:GetAssignedHero()
			if player and petro and petro:GetTeam() == DOTA_TEAM_BADGUYS then
			    item:ApplyDataDrivenModifier(hero, petro, mname, {Duration = GameRules.PETRI_RUNE_DURATION/2})
			end
		end
	end
end
--

function GameMode:PetriElenaDamage()
    GameMode.elenaInGame = GameMode:IsElenaInGame()

	local item = CreateItem("item_petri_key",nil,nil)
	
    local status, retval = pcall(
	function()
	    Timers:CreateTimer(1.0,
        function()
		    if GameMode.elenaInGame == true then
			    local allBuildings = Entities:FindAllByClassname("npc_dota_base_additive")
				
				for k,v in pairs(allBuildings) do
				    if v:GetBaseDamageMax() > 0 then
					    item:ApplyDataDrivenModifier(v, v, "modifier_elena_buff",{})     
					end
				end
				
				return 5.0		
            else 
			    item = nil
			    return nil
			end
		end)
	end
	
	, keys)
    if not status then
        GameMode:DEBUGMSG("PetriElenaDamage ERROR: ", retval)
    end
end

function GameMode:IsElenaInGame()
    for i = 0, PlayerResource:GetPlayerCount() do
	    if PlayerResource:IsValidPlayer(i) then
		    print('elena '..i)
		    local player = PlayerResource:GetPlayer(i)
			if player and player:GetAssignedHero() and player:GetAssignedHero():GetUnitName() == "npc_dota_hero_death_prophet" then
			    print('elena in game')
			    return true
			end
		end
	end
	
	return false
end

function GameMode:KivinTimer()
    Timers:CreateTimer(GameRules.PETRI_KIVIN_TIMING,
        function()
		    GameMode.allowkivin = true
		    return nil
	    end
	)
end

--[[
function GameMode:PlayerBoundsTimer()
    Timers:CreateTimer(1.0, 
	    function()
		    for i = 0, PlayerResource:GetPlayerCount() do
			    if PlayerResource:IsValidPlayer(i) == true then
				    local player = PlayerResource:GetPlayer(i)
					local hero = player:GetAssignedHero()
					if hero then
					if GameMode:IsInWorldBounds(hero) == false or and hero:GetTeam() == DOTA_TEAM_GOODGUYS and Entities:FindByName(nil, "blocking_trigger_b"):IsTouching(hero) == true then
					    print("DASDSACXZCASDAS")
						if hero.spiderpos then
						    FindClearSpaceForUnit(hero, hero.spiderpos, false)
						elseif hero.spawnPosition then
						    FindClearSpaceForUnit(hero, hero.spawnPosition, false)
						else
						    hero:RespawnHero(false, false)
						end
						
						Timers:CreateTimer(0.03, function()
	 	                    MoveCamera(hero:GetPlayerOwnerID(),hero)
	 	                    hero:Stop()
                        end)
					end
					end
				end
			end
			
	        return 1.0	
		end
	)	
end
]]

function GameMode:IsInWorldBounds(hero)
    local hO = hero:GetAbsOrigin()
	local wO = {}
	wO.minX = GetWorldMinX()
	wO.maxX = GetWorldMaxX()
	wO.minY = GetWorldMinY()
	wO.maxY = GetWorldMaxY()
	
	print(hO.y)
	print(hO.x)
	
	if hO.y >= wO.minY and hO.y <= wO.maxY and hO.x >= wO.minX and hO.x <= wO.maxX then
	    print("is in world bounds")
	    return true
	end
	
	print("isnt in world bounds")
	return false
end

function GameSetupDropFix()
    local bool = false

	for i = 0, PlayerResource:GetPlayerCount() do
	    if PlayerResource:IsValidPlayer(i) then
			local player = PlayerResource:GetPlayer(i)
			if player and player:GetAssignedHero() and player:GetAssignedHero():GetTeam() == DOTA_TEAM_BADGUYS then
			    bool = true
			end
		end		
	end
	
	if bool == false and PlayerResource:GetPlayerCount() > 1 then
	    IS_RANKED_GAME = false
		Rating.isRankedGame = false
		GameRules.Winner = DOTA_TEAM_GOODGUYS
        GameRules:SetGameWinner(DOTA_TEAM_GOODGUYS)
		--SendToServerConsole("script_reload")
		--SendToServerConsole("cl_script_reload")
		--SendToServerConsole("cl_script_reload_code libraries/gamesetup.lua")
		--GameMode:RestartGameSetup()
		--GameRules:ResetDefeated()
	end
end

function GameMode:LoadHelpersCosts()
	local item = CreateItem("item_petri_key",nil,nil)
	local allcreats = Entities:FindAllByClassname("npc_dota_creature")
    for k,v in pairs(allcreats) do
		if IsValidEntity(v) and string.match(v:GetUnitName(), "helper") then
			item:ApplyDataDrivenModifier(v, v, "modifier_helper_gold", {})
			v:SetModifierStackCount("modifier_helper_gold", v, v:GetMaximumGoldBounty())
			
			item:ApplyDataDrivenModifier(v, v, "modifier_helper_exp", {})
			v:SetModifierStackCount("modifier_helper_exp", v, v:GetDeathXP() * GameRules.PETRI_EXPERIENCE_MULTIPLIER)
		end
	end
	UTIL_Remove(item)
end

function GameMode:SaveBuildingToPSO(unit)
	for k,v in pairs(unit.blockers) do
		v.IsBuildingPso = true
		v.BuildingUnit = unit
	end
end

function GameMode:NoInvWallsTimer()
	local status, retval = pcall(NoInvWalls, keys)
    if not status then
        GameMode:DEBUGMSG("NoInvWalls ERROR: ", retval)	
	end
end

function NoInvWalls()
	Timers:CreateTimer(1.0, function()
		local PSOs = Entities:FindAllByClassname("point_simple_obstruction")
		for k,v in pairs(PSOs) do
			if v and v:IsEnabled() and v.IsBuildingPso then
				if not v.BuildingUnit or not v.BuildingUnit:IsAlive() then
					print(v:GetAbsOrigin())
					UTIL_Remove(v)
				end
			end
		end
		return 10.0
	end)
end

function GameMode:UpdatePlayerChatIcons()
	for i = 0, PlayerResource:GetPlayerCount() do
		if PlayerResource:IsValidPlayer(i) then
			local data = {id = i, name = PlayerResource:GetPlayerName(i), status = GetPlayerStatus(PlayerResource:GetSteamAccountID(i)), rank = Rating.rangs[i]}
			CustomGameEventManager:Send_ServerToAllClients( "petri_chat_player_icon", data )
		end
	end
end

function GameMode:OnGameInProgress()
  
  DebugPrint("[BAREBONES] The game has officially begun")
  
    Timers:CreateTimer(0.3,
    function()
	
	Classes:LoadAndSend()
    Classes:RandomClassTimer()
	
	GameMode:LoadHelpersCosts()
	--GameMode:NoInvWallsTimer()
	
	GameMode:UpdatePlayerChatIcons()
	
	--GameMode:SpawnCouriers()
	
    --GameMode.MINUSTIME = math.floor(GameRules:GetGameTime()-0.3)
	--GameMode:DEBUGMSG("MINUSTIME: ", GameMode.MINUSTIME)
    --print("BEGUN"..GameRules:GetGameTime())
	--GameMode:SetAllPlayersCameraYaw()
	
    for i = 0, PlayerResource:GetPlayerCount() do
	    if PlayerResource:IsValidPlayer(i) then
		    PlayerRT[i] = {team = nil, score = 0, steamID = 0}
			print("idi nahooy"..PlayerRT[i].score)
			if PlayerResource:GetPlayer(i):GetAssignedHero() ~= nil and PlayerResource:GetConnectionState(i) == 2 then
			    PlayerRT[i].team = PlayerResource:GetPlayer(i):GetAssignedHero():GetTeam()
				PlayerRT[i].steamID = PlayerResource:GetSteamAccountID(i)
			end
		end
	end
	
	return nil
	end
	)
    Timers:CreateTimer(3.0,
        function()
		    Rating:SetPlayerProfiles()
            GameRules:SendCustomMessage("#feedback_reminder", 0, 0)
			--fixPause()
			
			if GetMapName() == "petri_0_frostivus" then
			    Rating.isRankedGame = false
	            GameMode:FrostivusGifts()
	        end
			
			if Rating.isRankedGame == true then
                GameRules:SendCustomMessage("#ranked_game", 0, 0)    
			else
                GameRules:SendCustomMessage("#unranked_game", 0, 0)
			end
			
			GameMode:PetriElenaDamage()
			
			GameSetupDropFix()
			
  		    return nil
	    end
	)
	GameMode:KivinTimer()
	--GameMode:PlayerBoundsTimer()
	
	GiveCh()
	
	--if IS_RANKED_GAME == true then
	    --GiveCh()
	--else
	    --CustomGameEventManager:Send_ServerToAllClients( "hide_ch", nil )
	--end
	--GameMode.canPlayerPause = {true, true, true, true, true, true, true, true, true, true, true, true}
	
	goldOma = {}
    Timers:CreateTimer(1.0, function()
	    for i = 0, PlayerResource:GetPlayerCount() do
	    if PlayerResource:IsValidPlayer(i) then
			if goldOma[i] == nil then
			    --goldOma[i] = GetCustomGold(i)
				goldOma[i] = 0
			else                                             
			    --local gldOma = goldOma[i]
			    --goldOma[i] = GetCustomGold(i)
				--local gpm = goldOma[i] - gldOma
				
				local gpm = goldOma[i]
				goldOma[i] = 0
				print("gpm:", i, gpm)
				
				local minus = nil
				--if(goldOma[i] > gldOma) then
				    --minus = false
				--elseif(goldOma[i] < gldOma) then
                    --minus = true
				--end
				
				if gpm ~= 0 then
				    minus = false
				end
				
				local event_data = {key1 = gpm, key2 = minus,}
				CustomGameEventManager:Send_ServerToPlayer( PlayerResource:GetPlayer(i), "update_gpm", event_data )
			end
		end
	    end
		return 60.0
	end)
   
   --[[
   Timers:CreateTimer(2880.0,
        function()
		    GameMode.allowkivin = true
		    return nil
	    end
	)
	]]
	
	--Timers:CreateTimer(60.0,
        --function()
		    --local units = FindUnitsInRadius(DOTA_TEAM_GOODGUYS,
                              --Vector(0, 0, 0),
                              --nil,
                              --FIND_UNITS_EVERYWHERE,
                              --DOTA_UNIT_TARGET_TEAM_BOTH,
                              --DOTA_UNIT_TARGET_ALL,
                              --DOTA_UNIT_TARGET_FLAG_NONE,
                              --FIND_ANY_ORDER,
                              --false)
							  

			--for i=0,PlayerResource:GetPlayerCount() do
			    --local player = PlayerResource:GetPlayer(i)
				--local bool = false
				--for _,unit in pairs(units) do
					--if unit:GetUnitName() == "npc_petri_wall" or unit:GetUnitName() == "npc_petri_earth_wall" then
                        --if unit:GetPlayerOwner() == player then
						    --bool = true
						--end
					--end
                --end
			    --if bool == true then
			        --GameMode:addScore(player:GetAssignedHero(), 6)
			    --end
			--end
		    --return 60.0
	    --end
	--)
   
   local time_elapsed = 0
   local start_time_of_day = GameRules:GetTimeOfDay()
   local end_time_of_day = start_time_of_day + 240 * time_flow
   Timers:CreateTimer(240.0,
    function()
	    daynight(time_elapsed, start_time_of_day, end_time_of_day)
		return 480.0
    end)
	
		--fix_armor()
	--[[	
	if GameMode.UseMiracles == false then
	    print('chuda sosatb')
        for _,v in pairs(Entities:FindAllByName("npc_dota_creature")) do	
		    if string.match(v:GetUnitName(), "npc_petri_loose_") then
			    v:ForceKill(false)
			end
        end		
	end
	]]
  
  Timers:CreateTimer(30.0,
    function()
      for k,v in pairs(GameMode.villians) do
        v:RemoveModifierByName("dummy_sleep_modifier")
      end
    end)
	
	Timers:CreateTimer(60.0,
    function()
		Notifications:BottomToTeam(DOTA_TEAM_GOODGUYS, {text="#class_pick_reminder", duration=7, style={color="purple", ["font-size"]="45px"}})
    end)

  Shop:Init()
  
  GameMode.PETRI_GAME_HAS_STARTED = true

  -- PauseGame(true)

  GameRules:SetCustomGameTeamMaxPlayers(DOTA_TEAM_BADGUYS, DOTA_MAX_PLAYERS)

  GameMode:TimingScores( )
  GameMode:RegisterAutoGold( )

  local creepID = 1
  Timers:CreateTimer(6 * 60,
    function()
      if creepID == 8 then
        return
      end

      local ents = Entities:FindAllByName("npc_dota_creature")

      for k,v in pairs(ents) do
        if v.GetUnitName and v:GetUnitName() == "npc_petri_creep_special"..tostring(creepID) then
          local pos = v:GetAbsOrigin()

          UTIL_Remove(v)

          local unit = CreateUnitByName("npc_petri_creep_special"..tostring(creepID  + 1),pos,true,nil,nil,DOTA_TEAM_NEUTRALS)
        end
      end

      creepID = creepID + 1

      return 8.0 * 60
    end)

    local creepID = 1
  Timers:CreateTimer(6 * 60,
    function()
      if creepID == 8 then
        return
      end

      local ents = Entities:FindAllByName("npc_dota_creature")

      for k,v in pairs(ents) do
        if v.GetUnitName and v:GetUnitName() == "npc_petri_creep_special_arena_helper"..tostring(creepID) then
          local pos = v:GetAbsOrigin()

          UTIL_Remove(v)

          local unit = CreateUnitByName("npc_petri_creep_special_arena_helper"..tostring(creepID  + 1),pos,true,nil,nil,DOTA_TEAM_BADGUYS)
        end
      end

      creepID = creepID + 1

	  GameMode:LoadHelpersCosts()
	  
      return 8.0 * 60
    end)

  Timers:CreateTimer(1.0,
    function()
      GameMode.PETRI_TRUE_TIME = GameMode.PETRI_TRUE_TIME + 1
      return 1.0
    end)

  Timers:CreateTimer((PETRI_FIRST_LOTTERY_TIME * 60),
    function()
      InitLottery()

      Timers:CreateTimer((PETRI_LOTTERY_TIME * 60),
      function()
        InitLottery()

        return (PETRI_LOTTERY_TIME * 60)
      end)
    end)
  
  Timers:CreateTimer((GameRules.PETRI_EXIT_MARK * 60),
    function()
      GameRules.PETRI_EXIT_ALLOWED = true
      Notifications:TopToTeam(DOTA_TEAM_GOODGUYS, {text="#exit_notification", duration=4, style={color="white", ["font-size"]="45px"}})
    end)

  Timers:CreateTimer((GameRules.PETRI_EXIT_WARNING * 60),
    function()
      Notifications:TopToTeam(DOTA_TEAM_GOODGUYS, {text="#exit_warning", duration=4, style={color="red", ["font-size"]="45px"}})
    end)

    Timers:CreateTimer((GameRules.PETRI_MIRACLE1_MARK * 60),
    function()
      GameRules.PETRI_MIRACLE1_ALLOWED = true
      Notifications:TopToTeam(DOTA_TEAM_GOODGUYS, {text="#miracle1_notification", duration=4, style={color="white", ["font-size"]="45px"}})
    end)

  Timers:CreateTimer((GameRules.PETRI_MIRACLE1_WARNING * 60),
    function()
      Notifications:TopToTeam(DOTA_TEAM_GOODGUYS, {text="#miracle1_warning", duration=4, style={color="red", ["font-size"]="45px"}})
    end)

      Timers:CreateTimer((GameRules.PETRI_MIRACLE2_MARK * 60),
    function()
      GameRules.PETRI_MIRACLE2_ALLOWED = true
      Notifications:TopToTeam(DOTA_TEAM_GOODGUYS, {text="#miracle2_notification", duration=4, style={color="white", ["font-size"]="45px"}})
    end)

  Timers:CreateTimer((GameRules.PETRI_MIRACLE2_WARNING * 60),
    function()
      Notifications:TopToTeam(DOTA_TEAM_GOODGUYS, {text="#miracle2_warning", duration=4, style={color="red", ["font-size"]="45px"}})
    end)

      Timers:CreateTimer((GameRules.PETRI_MIRACLE3_MARK * 60),
    function()
      GameRules.PETRI_MIRACLE3_ALLOWED = true
      Notifications:TopToTeam(DOTA_TEAM_GOODGUYS, {text="#miracle3_notification", duration=4, style={color="white", ["font-size"]="45px"}})
    end)

  Timers:CreateTimer((GameRules.PETRI_MIRACLE3_WARNING * 60),
    function()
      Notifications:TopToTeam(DOTA_TEAM_GOODGUYS, {text="#miracle3_warning", duration=4, style={color="red", ["font-size"]="45px"}})
    end)

  Timers:CreateTimer((GameRules.PETRI_TIME_LIMIT * 60),
    function()
      PetrosyanWin()
    end)

  -- Tips
  Timers:CreateTimer(((PETRI_FIRST_LOTTERY_TIME - 2) * 60),
    function()
      Notifications:TopToTeam(DOTA_TEAM_GOODGUYS, {text="#lottery_notification", duration=4, style={color="white", ["font-size"]="45px"}})
    end)

  -- Petrosyan tutorial
  tutorial_time = 5
  Timers:CreateTimer(
    function()
      Notifications:TopToTeam(DOTA_TEAM_BADGUYS, {disabled_players = GameMode.DISABLED_HINTS_PLAYERS, loc_check = true, text="#petrosyans_tip_"..tostring(tutorial_time), duration=10, style={color="white", ["font-size"]="45px"}})

      tutorial_time = tutorial_time + 5
	  
	  if tutorial_time == 90 then
	    return nil
	  else
	    return 5
	  end
    end)
end

function SobakaTest()
    --local sobakarandom = math.random(0, PlayerResource:GetPlayerCount())
    --Say(PlayerResource:GetPlayer(sobakarandom),"SOBAKA", false)
end

function GameMode:IsBanned(sid)
    for k,v in pairs(GameMode.BanKVs) do
	    if v == sid then	   
	        print("pidoras nayden")
		    return true
	    end
	end
	return false
end

function GameMode:Ban(player)
    if player and player:GetPlayerID() then
	    local pid = player:GetPlayerID()
	    if GameMode:IsBanned(PlayerResource:GetSteamAccountID(pid)) == true then
		    print("ban "..PlayerResource:GetSteamAccountID(pid))
			GameMode:ActuallyBan(player)
		end
	end
end

function GameMode:ActuallyBan(player)
    Timers:CreateTimer(1, function()
        local hero = player:GetAssignedHero()
		
	    if hero then
            local item = CreateItem("item_petri_key",nil,nil)
            item:ApplyDataDrivenModifier(hero, hero, "modifier_ban_govna",{})
			
			PlayerResource:SetCameraTarget(player:GetPlayerID(), hero)
        end
		
		CustomGameEventManager:Send_ServerToPlayer( player, "petri_ban_player", nil )
		
		return 1.0
    end)
end

function GameMode:InitGameMode()
  GameMode = self
  
  GameMode:_InitGameMode()
  
  math.randomseed(RandomFloat(0,1))
  
  Rating:init()
  Duels:InitDuels()
  Classes:init()
  if GetMapName() == "random" then
    RandomMap:Init()
  end
  
  GameRules:GetGameModeEntity():SetUseDefaultDOTARuneSpawnLogic(false)
  GameRules:GetGameModeEntity():SetPowerRuneSpawnInterval(300.0)
  
  --//chat commands
  --ChatCommand:LinkCommand("-sobaka", "SobakaTest")
  --\\
  
  local camera_yaw_variables = {0, 90, 180, 270}
  GameMode.cameraYaw = camera_yaw_variables[math.random(1, 4)]
  print("cameraYaw: "..GameMode.cameraYaw)
  
  GameMode.DependenciesKVs = LoadKeyValues("scripts/kv/dependencies.kv")
  
  GameMode.BanKVs = LoadKeyValues("scripts/kv/ban.kv")

  GameMode.BuildingMenusKVs = LoadKeyValues("scripts/kv/building_menus.kv")

  GameMode.WallsKVs = LoadKeyValues("scripts/kv/walls.kv")

  GameMode.CustomSkinsKVs = LoadKeyValues("scripts/kv/custom_skins.kv")
  GameMode.CustomBuildingsKVs = LoadKeyValues("scripts/kv/custom_buildings.kv")
  GameMode.VIPItemsKVs = LoadKeyValues("scripts/kv/vip_items.kv")

  GameMode.DevKVs = LoadKeyValues("scripts/kv/status.kv")
  
  GameMode.ShopKVs = LoadKeyValues("scripts/shops/petri_1_radiant_shops.txt")

  GameMode.UnitKVs = LoadKeyValues("scripts/npc/npc_units_custom.txt")
  GameMode.HeroKVs = LoadKeyValues("scripts/npc/npc_heroes_custom.txt")
  GameMode.AbilityKVs = LoadKeyValues("scripts/npc/npc_abilities_custom.txt")
  GameMode.ItemKVs = LoadKeyValues("scripts/npc/npc_items_custom.txt")

  GameMode.StartItemsKVs = LoadKeyValues("scripts/kv/start_items.kv")

  GameMode.shopsKVs = LoadKeyValues("scripts/shops/petri_1_radiant_shops.txt")

  GameMode.ItemBuilds = {}
  GameMode.ItemBuilds["npc_dota_hero_brewmaster"] = LoadKeyValues("itembuilds/default_brewmaster.txt")
  GameMode.ItemBuilds["npc_dota_hero_death_prophet"] = LoadKeyValues("itembuilds/default_death_prophet.txt")
  GameMode.ItemBuilds["npc_dota_hero_rattletrap"] = LoadKeyValues("itembuilds/default_rattletrap.txt")

  GameMode.abilityLayouts = {}
  GameMode.abilityGoldCosts = {}
  GameMode.specialValues = {}
  GameMode.buildingMenus = {}

  GameMode.SELECTED_UNITS = {}
  
  GameMode.ratingArr = {1000,1000,1000,1000,1000,1000,1000,1000,1000,1000,1000,1000,1000,1000}
  GameMode.ratingArr[0] = 1000
  
  for i=0,20 do
    pp[i] = class({})
	pp[i].ch = {"","",""}
	pp[i].pr = {0,0,0}
	pp[i].tar = {0,0,0}
	pp[i].lvl = 0
	pp[i].score = 0
  end
  
  GameMode.busData = {{true, nil},{true, nil},{true, nil},{true, nil}}
  
  GameMode.busPO = {3, 10, 1, 5}
  
  --armorfix
    ListenToGameEvent('dota_inventory_item_added', Dynamic_Wrap(GameMode, 'OnInventoryChanged'), self)

  -- KVN Building menus
  for k,menu in pairs(GameMode.BuildingMenusKVs) do
    if type(menu) == "table" then
      GameMode.buildingMenus[k] = {}
      local i = 1
      for k1,v1 in pairs(menu) do
        GameMode.buildingMenus[k][i] = menu[tostring(i)]
        i = i + 1
      end
    end
  end

  -- Ability layouts
  for i=1,2 do
    local t = GameMode.UnitKVs
    if i == 2 then
      t = GameMode.HeroKVs
    end
    for unit_name,unit_info in pairs(t) do
      if type(unit_info) == "table" then
        if i == 2 then
          GameMode.abilityLayouts[unit_info["override_hero"]] = unit_info["AbilityLayout"]
        else
          GameMode.abilityLayouts[unit_name] = unit_info["AbilityLayout"]
        end
      end
    end
  end

  -- Gold costs
  for ability_name,ability_info in pairs(GameMode.AbilityKVs) do
    if type(ability_info) == "table" then
      if ability_info["AbilityGoldCost"] ~= nil then
        GameMode.abilityGoldCosts[ability_name] = Split(ability_info["AbilityGoldCost"], " ")
      end  
    end
  end

  -- Special values
  for ability_name,ability_info in pairs(GameMode.AbilityKVs) do
    if type(ability_info) == "table" then
      if ability_info["AbilitySpecial"] ~= nil then
        GameMode.specialValues[ability_name] = {}
        for k,v in pairs(ability_info["AbilitySpecial"]) do
          for k1,v1 in pairs(v) do
            if k1 ~= "var_type" and k1 ~= "lumber_cost" and k1 ~= "food_cost" then
              table.insert(GameMode.specialValues[ability_name], {name = k1, value = v1})
            end
          end
        end
      end  
    end
  end

  --bounty
  GameRules:GetGameModeEntity():SetBountyRunePickupFilter( Dynamic_Wrap(GameMode, "FilterBountyRunePickup" ), self )
  
  -- Filter orders
  GameRules:GetGameModeEntity():SetExecuteOrderFilter( Dynamic_Wrap( GameMode, "FilterExecuteOrder" ), self )

  -- Filter runes
  GameRules:GetGameModeEntity():SetRuneSpawnFilter( Dynamic_Wrap( GameMode, "FilterRuneSpawn" ), self )

  -- Fix gold bounties
  GameRules:GetGameModeEntity():SetModifyGoldFilter(Dynamic_Wrap(GameMode, "ModifyGoldFilter"), self)

  -- Fix xp bounties
  GameRules:GetGameModeEntity():SetModifyExperienceFilter(Dynamic_Wrap(GameMode, "ModifyExperienceFilter"), GameMode)

  -- Fix up damage
  GameRules:GetGameModeEntity():SetDamageFilter(Dynamic_Wrap(GameMode, "DamageFilter"), GameMode)
  
  --couriers
  GameRules:GetGameModeEntity():SetFreeCourierModeEnabled(true)

  -- Commands
  Convars:RegisterCommand( "lumber", Dynamic_Wrap(GameMode, 'LumberCommand'), "Gives you lumber", FCVAR_CHEAT )
  Convars:RegisterCommand( "lag", Dynamic_Wrap(GameMode, 'LumberAndGoldCommand'), "Gives you lumber and gold", FCVAR_CHEAT )
  Convars:RegisterCommand( "taeg", Dynamic_Wrap(GameMode, 'TestAdditionalExitGold'), "Test for additional exit gold", FCVAR_CHEAT )
  Convars:RegisterCommand( "tspu", Dynamic_Wrap(GameMode, 'TestStaticPopup'), "Test static popup", FCVAR_CHEAT )
  Convars:RegisterCommand( "deg", Dynamic_Wrap(GameMode, 'DontEndGame'), "Dont end game", FCVAR_CHEAT )
  Convars:RegisterCommand( "getgold", Dynamic_Wrap(GameMode, 'GetGold'), "Get all gold", FCVAR_CHEAT )
  Convars:RegisterCommand( "tc", Dynamic_Wrap(GameMode, 'TestCommand'), "TestCommand", FCVAR_CHEAT )
  Convars:RegisterCommand( "fgs", Dynamic_Wrap(GameMode, 'FinishGameSetup'), "FinishGameSetup", FCVAR_CHEAT )
  Convars:RegisterCommand( "st", Dynamic_Wrap(GameMode, 'SetTime'), "SetTime", FCVAR_CHEAT )
  Convars:RegisterCommand( "terr", Dynamic_Wrap(GameMode, 'TestError'), "TestError", FCVAR_CHEAT )
  Convars:RegisterCommand( "trec", Dynamic_Wrap(GameMode, 'TestReconnect'), "Test Reconnect", FCVAR_CHEAT )
  Convars:RegisterCommand( "cr", Dynamic_Wrap(GameMode, 'ClassReload'), "Class Reload", FCVAR_CHEAT )
  Convars:RegisterCommand( "rgs", Dynamic_Wrap(GameMode, 'GameSetupDropFix'), "Restart Game Setup", FCVAR_CHEAT )
  Convars:RegisterCommand( "mi", Dynamic_Wrap(GameMode, 'ModifierInfo'), "get names of all hero modifiers", FCVAR_CHEAT )
  Convars:RegisterCommand( "joke", Dynamic_Wrap(GameMode, 'PlayRandomJoke'), "test jokes", FCVAR_CHEAT )

  BuildingHelper:Init()

  --Update player's UI
  Timers:CreateTimer(0.03,
  function()
    
    if GameMode.assignedPlayerHeroes then
      for k,v in pairs(GameMode.assignedPlayerHeroes) do
        if GameMode.assignedPlayerHeroes[k] and v:IsNull() == false then
          AddKeyToNetTable(k, "players_resources", "lumber", v.lumber)
          AddKeyToNetTable(k, "players_resources", "food", v.food)
          AddKeyToNetTable(k, "players_resources", "maxFood", v.maxFood)
          AddKeyToNetTable(k, "players_resources", "gold", GetCustomGold( v:GetPlayerOwnerID() ))
          AddKeyToNetTable(k, "players_resources", "building", v.buildingCount)
        end
      end
    end

    return 0.03
  end)
end

function GameMode:ReplaceWithMiniActor(player, gold)
  if GameMode.UseMiracles == true then

  PrecacheUnitByNameAsync("npc_dota_hero_storm_spirit",
    function() 
      -- GameRules:SetCustomGameTeamMaxPlayers(DOTA_TEAM_GOODGUYS, PlayerResource:GetPlayerCountForTeam(DOTA_TEAM_GOODGUYS)-1)

      player:SetTeam(DOTA_TEAM_BADGUYS)
      CustomGameEventManager:Send_ServerToPlayer(player,"petri_team",{team = DOTA_TEAM_BADGUYS, hero = "npc_dota_hero_storm_spirit"})
      local newHero = PlayerResource:ReplaceHeroWith(player:GetPlayerID(), "npc_dota_hero_storm_spirit", GameRules.START_MINI_ACTORS_GOLD + gold, 0)
      if GameMode.assignedPlayerHeroes[player:GetPlayerID()] then
        UTIL_Remove(GameMode.assignedPlayerHeroes[player:GetPlayerID()])
      end

      GameMode.assignedPlayerHeroes[player:GetPlayerID()] = newHero
      
      newHero:SetTeam(DOTA_TEAM_BADGUYS)

      local pos = Entities:FindByClassname(nil, "info_courier_spawn_dire"):GetAbsOrigin()
      newHero:SetRespawnPosition(pos)
      newHero.spawnPosition = pos
      newHero:RespawnHero(false, false)

      newHero:AddAbility("petri_petrosyan_flat_joke")

      newHero:SetAbilityPoints(4)
      newHero:UpgradeAbility(newHero:FindAbilityByName("petri_petrosyan_return"))
      newHero:UpgradeAbility(newHero:FindAbilityByName("petri_mini_actor_phase"))
      newHero:UpgradeAbility(newHero:FindAbilityByName("petri_petrosyan_passive"))
      newHero:UpgradeAbility(newHero:FindAbilityByName("petri_petrosyan_flat_joke"))

	  for k,v in pairs(newHero:GetChildren()) do
        if v:GetClassname() == "dota_item_wearable" then
          v:AddEffects(EF_NODRAW) 
        end
      end
	  
      newHero.key = "miniactors"
      GameMode:SetupCustomSkin(newHero, PlayerResource:GetSteamAccountID(player:GetPlayerID()), newHero.key)

      if newHero then
        EasyTimers:CreateTimer(function()
          local abilities = newHero:GetAbilityCount() - 1
          for i = 0, abilities do
            if newHero:GetAbilityByIndex(i) then
              if string.find(newHero:GetAbilityByIndex(i):GetAbilityName(), "special") then
                  newHero:GetAbilityByIndex(i):SetAbilityIndex(14+i)
                  newHero:RemoveAbility(newHero:GetAbilityByIndex(i):GetAbilityName())
              end
            end
          end
        end, DoUniqueString('fixHotKey'), 2)
      end

      Timers:CreateTimer(0.03, function ()
        newHero.spawnPosition = newHero:GetAbsOrigin()
      end)
    end
    , 
  player:GetPlayerID())
  
  end
end

function GameMode:SetupCustomSkin(hero, steamID, key)
  --//
  PETRI_SKINS_URL = "https://pastebin.com/raw/zrKW1gYk"
  
  --local req = CreateHTTPRequestScriptVM("GET", PETRI_SKINS_URL)
  --req:Send(function(result)
    --local resultstring = tostring(result.Body)
    --GameMode.CustomSkinsKVs = LoadKeyValuesFromString(resultstring)
	--PrintTable(GameMode.CustomSkinsKVs)
	
  --end)
  --\\
  --Timers:CreateTimer(1, function()
  
  if IsInToolsMode() then
    GameMode.CustomSkinsKVs = LoadKeyValues("scripts/kv/custom_skins.kv")
  end
  for k,v in pairs(GameMode.CustomSkinsKVs[key]) do
    local id = tonumber(k)

    if steamID == id then
      for k2,v2 in pairs(v) do
        if v2 == "model" then
          UpdateModel(hero, k2, 1)
          hero.model = k2
          hero:AddNewModifier(hero,nil,"modifier_model_change",{})
        end
      end

      for k2,v2 in pairs(v) do
        if type(v2) == "table" then
          hero[k2] = v2
        end
        if v2 == "wearable" then
          local m = Wearables:AttachWearable(hero, k2)
          if v[k2.."_mg"] then
            m:SetMaterialGroup(tostring(v[k2.."_mg"]))
          end
          if k2 == "models/items/terrorblade/terrorblade_ti8_immortal_back/terrorblade_ti8_immortal_back.vmdl" then
            local p = ParticleManager:CreateParticle("particles/tb_ti8.vpcf",PATTACH_POINT_FOLLOW,m)
            ParticleManager:SetParticleControl(p, 15, Vector(215,22,22))
          end
        end
        if v2 == "scale" then
          hero:SetModelScale(tonumber(k2))
        end
        if v2 == "hero" then
          CustomGameEventManager:Send_ServerToAllClients("petri_set_icon",{hero = k2, pID = hero:GetPlayerID()})
        end
        if string.match(k2, "particle") then
          local attach = _G[v2.attach]
          if v2.attach == -1 then
            attach = -1
          end
          local p = ParticleManager:CreateParticle(v2.particle, attach, hero)
          if v.color then
            print(v.color["1"], v.color["2"], v.color["3"], v.color.cp)
            ParticleManager:SetParticleControl(p,tonumber(v.color.cp),Vector(v.color["1"], v.color["2"], v.color["3"]))
          end
        end
        if v2 == "translate" then
          AddAnimationTranslate(hero, k2)
        end
        if v2 == "animation" then
          StartAnimation(hero, {duration=-1, activity=_G[k2], rate=1})
        end
        if v2 == "material_group" then
          hero:SetMaterialGroup(k2)
        end
      end

      -- for k1,v1 in pairs(hero:GetChildren()) do
      --   if v1:GetClassname() == "dota_item_wearable" then
      --     v1:AddEffects(EF_NODRAW) 
      --   end
      -- end

      return true
    end
  end
  local localization = GameMode.PETRI_LANG_LIST[hero:GetPlayerID()]

  if localization and GameMode.CustomSkinsKVs[key][localization] then
    for k2,v2 in pairs(GameMode.CustomSkinsKVs[key][localization]) do
      if v2 == "model" then
        UpdateModel(hero, k2, 1)
      end
    end

    for k2,v2 in pairs(GameMode.CustomSkinsKVs[key][localization]) do
      if v2 == "wearable" then
        Wearables:AttachWearable(hero, k2)
      end
    end

    -- for k2,v2 in pairs(hero:GetChildren()) do
    --   if v2:GetClassname() == "dota_item_wearable" then
    --     v2:AddEffects(EF_NODRAW) 
    --   end
    -- end
  end

  hero:MoveToPosition(hero:GetAbsOrigin())
  
      --  return nil
    --end
  --)
end

function GameMode:SetupVIPItems(hero, steamID)
  for k,v in pairs(GameMode.VIPItemsKVs) do
    if k == tostring(steamID) then
      for item,count in pairs(v) do
        hero:AddItemByName(item)
      end
    end
  end
end

function KVNWin(keys)
  local caster = keys.caster
  local ability = keys.ability

  local s = true

  if ability:GetName() == "petri_miracle1" then
    s = false
    for _,v in pairs(Entities:FindAllByName("npc_dota_creature")) do
      if IsValidEntity(v) and v:IsAlive() and v:IsNull() == false and v:GetUnitName() == "npc_petri_loose_trigger1" then
        print("111111111111111111")
        s = true
        break
      end
    end
  elseif ability:GetName() == "petri_miracle2" then
    s = false
    for _,v in pairs(Entities:FindAllByName("npc_dota_creature")) do
      if IsValidEntity(v) and v:IsAlive() and v:IsNull() == false and v:GetUnitName() == "npc_petri_loose_trigger2" then
        print("22222222222222222")
        s = true
        break
      end
    end
  elseif ability:GetName() == "petri_miracle3" then
    s = false
    for _,v in pairs(Entities:FindAllByName("npc_dota_creature")) do
      if IsValidEntity(v) and v:IsAlive() and v:IsNull() == false and v:GetUnitName() == "npc_petri_loose_trigger3" then
        print("333333333333333")
        s = true
        break
      end
    end
  end

  if GameMode.PETRI_NO_END == false and s then
    print("aaaaaaaaaaaaaaaaaa")
    if GameMode.PETRI_GAME_HAS_ENDED == false then
      print("bbbbbbbbbbbbbbbbbbbb")
      GameMode.PETRI_GAME_HAS_ENDED = true

      Notifications:TopToAll({text="#kvn_win", duration=100, style={color="green"}, continue=false})

      for i=1,12 do
        PlayerResource:SetCameraTarget(i-1, caster)
      end

      Timers:CreateTimer(5.0,
        function()
          GameRules.Winner = DOTA_TEAM_GOODGUYS
          GameRules:SetGameWinner(DOTA_TEAM_GOODGUYS) 
        end)
    end
  end
end

function PetrosyanWin()
  if GameMode.PETRI_NO_END == false then
    if GameMode.PETRI_GAME_HAS_ENDED == false then
      GameMode.PETRI_GAME_HAS_ENDED = true

      Notifications:TopToAll({text="#petrosyan_limit", duration=100, style={color="red"}, continue=false})
      Timers:CreateTimer(5.0,
        function()
          GameRules.Winner = DOTA_TEAM_BADGUYS
          GameRules:SetGameWinner(DOTA_TEAM_BADGUYS) 
        end)
    end
  end
end

function GameMode:ReApplySkin( keys )
  local steamID = PlayerResource:GetSteamAccountID(keys.PlayerID)
  local hero = PlayerResource:GetPlayer(keys.PlayerID):GetAssignedHero()

  if steamID and hero and hero.key then
    GameMode:SetupCustomSkin(hero, steamID, hero.key)
    -- EndAnimation(hero)
  end
end

if Wearables == nil then
    _G.Wearables = class({})
end

function Wearables:AttachWearable(unit, modelPath)
    local wearable = SpawnEntityFromTableSynchronous("prop_dynamic", {model = modelPath, DefaultAnim=animation, targetname=DoUniqueString("prop_dynamic")})

    wearable:FollowEntity(unit, true)

    unit.wearables = unit.wearables or {}
    table.insert(unit.wearables, wearable)

    return wearable
end

function Wearables:Remove(unit)
    if not unit.wearables or #unit.wearables == 0 then
        return
    end

    for _, part in pairs(unit.wearables) do
        part:RemoveSelf()
    end

    unit.wearables = {}
end

function fix_armor()
    Timers:CreateTimer(function()
		local everyone = FindUnitsInRadius(DOTA_TEAM_BADGUYS,
                              Vector(0, 0, 0),
                              nil,
                              FIND_UNITS_EVERYWHERE,
                              DOTA_UNIT_TARGET_TEAM_FRIENDLY,
                              DOTA_UNIT_TARGET_ALL,
                              DOTA_UNIT_TARGET_FLAG_NONE,
                              FIND_ANY_ORDER,
                              false)
		for k,v in pairs(everyone) do
		    local armor = v:GetPhysicalArmorValue()	
			if armor > 0 then
			    local minus = armor / 100 * 30
				v:SetPhysicalArmorBaseValue(-minus)
			else
			    v:SetPhysicalArmorBaseValue(0)
			end
		end
		local everyone = FindUnitsInRadius(DOTA_TEAM_GOODGUYS,
                              Vector(0, 0, 0),
                              nil,
                              FIND_UNITS_EVERYWHERE,
                              DOTA_UNIT_TARGET_TEAM_FRIENDLY,
                              DOTA_UNIT_TARGET_ALL,
                              DOTA_UNIT_TARGET_FLAG_NONE,
                              FIND_ANY_ORDER,
                              false)
		for k,v in pairs(everyone) do
		    local armor = v:GetPhysicalArmorValue()
			if armor > 0 then
			    local minus = armor / 100 * 30
				v:SetPhysicalArmorBaseValue(-minus)
			else
			    v:SetPhysicalArmorBaseValue(0)
			end
		end
        return 1.0
    end)
end

function GetPlayerStatus(steamid)
	GameMode.DevKVs = LoadKeyValues("scripts/kv/status.kv")
	for k,v in pairs(GameMode.DevKVs["id"]) do
        local id = tonumber(k)
        if steamid == id then
			return v
	    end
    end	
	return nil
end

function Check4Dev()
    GameMode.DevKVs = LoadKeyValues("scripts/kv/status.kv")
    for i = 0, PlayerResource:GetPlayerCount() do  
	if PlayerResource:IsValidPlayer(i) then
	local steamid = PlayerResource:GetSteamAccountID(i)
	for k,v in pairs(GameMode.DevKVs["id"]) do
        local id = tonumber(k)
        if steamid == id then
		local event_data =
            {
                pid = i,
				icon = v,
            }
			CustomGameEventManager:Send_ServerToAllClients( "is_dev", event_data )
			print('player has special status')
	    end
    end
	end
	end
end

function UseMiraclesVote()
    if GameMode.UseMiraclesTrueK >= GameMode.UseMiraclesFalseK then
	    print('yes use miracles')
		GameMode.UseMiracles = true
	else
	    print('no use miracles')
		GameMode.UseMiracles = false
	end
end

function GameMode:FilterBountyRunePickup(filterTable)
    for k, v in pairs( filterTable ) do
	    print(k.." "..tostring(v))
	end

    for i = 0, PlayerResource:GetPlayerCount() do 	
	if PlayerResource:IsValidPlayer(i) then    
        local playerHero = PlayerResource:GetPlayer(i):GetAssignedHero()
        local team = PlayerHero:GetTeam()
	end	
	end
    return false
end

scoreArr = {0,0,0,0,0,0,0,0,0,0,0,0}
scoreArr[0] = 0
wallScoreArr={{0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0},{0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0},{0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0},{0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0},{0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0},{0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0},{0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0},{0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0},{0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0},{0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0},{0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0},{0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0},{0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0}}
wallScoreArr[0] = {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0}
lvls = {1,1,1,1,1,1,1,1,1,1,1,1,1,1,1}
lvls[0] = 1

function GameMode:addScore(hero, score)
    print("ADDSCORE")
    local data = {hero, score}
    local status, retval = pcall(addScoreDebug, data)
    if not status then
        GameMode:DEBUGMSG("addScore ERROR: ", retval)	
	end
end

function addScoreDebug(data)
    local hero = data[1]
	local score = data[2]
    print("ADDSCOREDEBUG")
    if hero ~= nil then
		local player = hero:GetPlayerOwner()
		if player ~= nil and pp[player:GetPlayerID()] then
			if pp[player:GetPlayerID()].score == nil then
				pp[player:GetPlayerID()].score = 0
			end
			if pp[player:GetPlayerID()].score ~= nil then
				pp[player:GetPlayerID()].score = pp[player:GetPlayerID()].score + score
				print(player:GetPlayerID().." score: "..pp[player:GetPlayerID()].score)
	
				local event_data =
				{
					pid = player:GetPlayerID(),
					score = pp[player:GetPlayerID()].score,
				}
				CustomGameEventManager:Send_ServerToAllClients( "update_score_player", event_data )
	
				scoreArr[player:GetPlayerID()] = scoreArr[player:GetPlayerID()] + score
	                
				lvls[player:GetPlayerID()] = lvls[player:GetPlayerID()] + score
				
				player.score = pp[player:GetPlayerID()].score
					
				GameMode:ChUpdateLvl(player)
			end
		end
	end
end

--function GameMode:sayScore(player)
    --if player ~= nil then
    --if player.canSayScore ~= false then
	    --Say(player, "My Score: "..tostring(math.floor(player.score)), false)
	    --player.canSayScore = false
	--end
	--end
--end

function GameMode:DEBUGMSG(msg, numb)
    for i = 0, PlayerResource:GetPlayerCount() do
	    if PlayerResource:GetSteamAccountID(i) == 96034076 then
			local player = PlayerResource:GetPlayer(i)
		    local event_data =
            {
                text = msg,
				numb = numb
            }
			CustomGameEventManager:Send_ServerToPlayer( player, "debug_print", event_data )
		end 
	end
	
	if string.match(msg, "ERROR:")then
	    --if Rating.isRankedGame == true then
	    --    Rating.isRankedGame = false
	    --    GameRules:SendCustomMessage("#unranked_game", 0, 0)
	    --end
	
	    msg = msg:gsub("%s+", "")
		numb = numb:gsub("%s+", "")
		
	    local url = tostring(Rating.errorUrl.."key="..Rating.key.."&error="..msg..numb)
		print(url)
	    Rating:SimpleRequest(url)
	end
end

function GameMode:BusPayOut(id)
	if GameMode.busData[id][1] == false then
	    local pid = GameMode.busData[id][2]
	    print("BUSPAYOUT: "..pid)
	    local player = PlayerResource:GetPlayer(pid)
		if player then
	    local hero = player:GetAssignedHero()
		if hero then
		if hero:IsRealHero() and hero:IsAlive() and hero:GetTeam() == DOTA_TEAM_GOODGUYS and hero.bus and hero.bus[id] and hero.bus[id]:IsNull() == false then
		    if hero.bus[id]:IsAlive() then
		        AddCustomGold(pid, GameMode.busPO[id])
			    local unit = hero.bus[id]
			    unit:SetModifierStackCount("modifier_bus_total_income", unit, unit:GetModifierStackCount("modifier_bus_total_income", unit) + GameMode.busPO[id])	
			    print("BUSPAYOUT SUCCSES")
			end
		end
		end
		end	
	end
end

--function CourierSelect(eventSourceIndex, args)
--   print("select"..args['id'])
--	 local courier = Entities:FindByName(nil,"npc_dota_courier")
--   if courier ~= nil then
--	    PlayerResource:SetOverrideSelectionEntity(args['id'], courier)
--		Timers:CreateTimer(0.1, function()
--		    PlayerResource:SetOverrideSelectionEntity(args['id'], nil)
--			return nil
--		end)
--	end
--end

function CourierSelect(eventSourceIndex, args)
    print("select"..args['id'])
	--local courier = Entities:FindByName(nil,"npc_dota_courier")
	local courier = PlayerResource:GetPlayer(args['id']):GetAssignedHero().petriCourier
	if courier ~= nil then
	    local event_data = {unit = courier:entindex(),}
	    CustomGameEventManager:Send_ServerToPlayer( PlayerResource:GetPlayer(args['id']), "select_unit", event_data )
	end
end

function CourierDeliver(eventSourceIndex, args)
	--local courier = Entities:FindByName(nil,"npc_dota_courier")
    local courier = PlayerResource:GetPlayer(args['id']):GetAssignedHero().petriCourier
	if courier ~= nil then
	print("deliver"..args['id'])
    Timers:CreateTimer(0.1, function()
        courier:CastAbilityNoTarget(courier:FindAbilityByName("courier_take_stash_and_transfer_items"), args['id'])
        return nil
    end)
	end
end

CustomGameEventManager:RegisterListener( "courier_select", CourierSelect )
CustomGameEventManager:RegisterListener( "courier_deliver", CourierDeliver )
CustomGameEventManager:RegisterListener( "check4dev", Check4Dev )

JOKE_PLAYING = false
function GameMode:PlayRandomJoke()
	if not JOKE_PLAYING then
		local id = "petri_reborn.joke_"..tostring(math.abs(math.random(1, 100)))
		EmitGlobalSound(id)

		--[[ всегда возвращает 2 блядь
		local dummy = CreateUnitByName("npc_dummy_blank", Vector(0, 0, 0), false, nil, nil, DOTA_TEAM_NEUTRALS)
		local duration = dummy:GetSoundDuration(id, "")
		print(id.." sound duration "..duration)
		UTIL_Remove(dummy)
		]]
		
		JOKE_PLAYING = true
		Timers:CreateTimer(30.0, function() 
			JOKE_PLAYING = false
		end)
	end
end

if LOADED then
  return
end
LOADED = true

GameMode.PETRI_TRUE_TIME = 0