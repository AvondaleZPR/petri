function GameMode:FixHero( event )
  if GameMode.spawnQueueID == nil or (GameMode.spawnQueueID and GameMode.spawnQueueID > 0) then
    local pID = tonumber(event.PlayerID)
    local ply = PlayerResource:GetPlayer(pID)

    if ply then
      local hero = ply:GetAssignedHero()
      if hero and hero:GetUnitName() == "npc_dota_hero_wisp" then
        GameMode:CreateHero(pID, function (  )
          
        end)
      end
    end
  end
end

-- The overall game state has changed
function GameMode:_OnGameRulesStateChange(keys)
  local newState = GameRules:State_Get()
  if newState == DOTA_GAMERULES_STATE_WAIT_FOR_PLAYERS_TO_LOAD then
    self.bSeenWaitForPlayers = true
  elseif newState == DOTA_GAMERULES_STATE_CUSTOM_GAME_SETUP then
    GameMode:OnAllPlayersLoaded()
  elseif newState == DOTA_GAMERULES_STATE_HERO_SELECTION then
    GameMode:PostLoadPrecache()
  elseif newState == DOTA_GAMERULES_STATE_GAME_IN_PROGRESS then
    GameMode:OnGameInProgress()

    GameMode.spawnQueueID = -1

    self.spawnDelay = 2.25

    EasyTimers:CreateTimer(function()
      if not GameMode.heroesSpawned then
        PauseGame(true)
        return 0.1
      else
        PauseGame(false)
		
        return nil
      end
    end, 'auto_pause', 0.03)

    Timers:CreateTimer({
    useGameTime = false,
    endTime = 2,
    callback = function()
      PauseGame(true)

      self.playerQueue = function ()
          GameMode.spawnQueueID = GameMode.spawnQueueID + 1

          -- Update queue info
          CustomGameEventManager:Send_ServerToAllClients("petri_spawning_queue", {queue = GameMode.spawnQueueID})

          -- End pause if every player is checked
          if GameMode.spawnQueueID > 24 then
              GameMode.spawnQueueID = nil
              GameMode.heroesSpawned = true

              Timers:CreateTimer({
              useGameTime = false,
              endTime = 2,
              callback = function()
                  PauseGame(false)
              end})

              return nil
          end

          if PlayerResource:GetConnectionState(GameMode.spawnQueueID) < 1 then
            self.playerQueue()
            return nil
          end

          -- Keep spawning
          Timers:CreateTimer({
          useGameTime = false,
          endTime = 2,
          callback = function()
            -- Skip disconnected players
            if PlayerResource:GetConnectionState(GameMode.spawnQueueID) < 1 then
                self.playerQueue()
                return
            else
                local color = PLAYER_COLORS[GameMode.spawnQueueID]
                if color then
                  PlayerResource:SetCustomPlayerColor(GameMode.spawnQueueID, color[1], color[2], color[3])
                end
                print("HUETA4")
                GameMode:CreateHero(GameMode.spawnQueueID, self.playerQueue)
                return
            end
          end})
      end

      self.playerQueue()
    end})
  end
end

-- An NPC has spawned somewhere in game.  This includes heroes
function GameMode:_OnNPCSpawned(keys)
  local npc = EntIndexToHScript(keys.entindex)

  if npc:IsRealHero() and npc.bFirstSpawned == nil then
    npc.bFirstSpawned = true
    -- GameMode.spawnedArray = GameMode.spawnedArray or {}
    if npc:GetUnitName() == "npc_dota_hero_wisp" then
      npc:AddNewModifier(npc,nil,"modifier_tribune",{})
    end
    -- if not GameMode.spawnedArray[npc:GetPlayerID()] then
    --   GameMode:OnHeroInGame(npc:GetPlayerID(), npc:GetTeamNumber(), npc)
    --   GameMode.spawnedArray[npc:GetPlayerID()] = true
    -- end
  end
end

-- An entity died
function GameMode:_OnEntityKilled( keys )
  -- The Unit that was Killed
  local killedUnit = EntIndexToHScript( keys.entindex_killed )
  -- The Killing entity
  local killerEntity = nil

  if keys.entindex_attacker ~= nil then
    killerEntity = EntIndexToHScript( keys.entindex_attacker )
  end

  if killedUnit:IsRealHero() then
    DebugPrint("KILLED, KILLER: " .. killedUnit:GetName() .. " -- " .. killerEntity:GetName())
    if END_GAME_ON_KILLS and GetTeamHeroKills(killerEntity:GetTeam()) >= KILLS_TO_END_GAME_FOR_TEAM then
      GameRules:SetSafeToLeave( true )
      GameRules:SetGameWinner( killerEntity:GetTeam() )
    end

    --PlayerResource:GetTeamKills
    if SHOW_KILLS_ON_TOPBAR then
      GameRules:GetGameModeEntity():SetTopBarTeamValue ( DOTA_TEAM_BADGUYS, GetTeamHeroKills(DOTA_TEAM_BADGUYS) )
      GameRules:GetGameModeEntity():SetTopBarTeamValue ( DOTA_TEAM_GOODGUYS, GetTeamHeroKills(DOTA_TEAM_GOODGUYS) )
    end
  end
end

-- This function is called once when the player fully connects and becomes "Ready" during Loading
function GameMode:_OnConnectFull(keys)
  GameMode:_CaptureGameMode()

  local entIndex = keys.index+1
  -- The Player entity of the joining user
  local ply = EntIndexToHScript(entIndex)

  local userID = keys.userid

  self.vUserIds = self.vUserIds or {}
  self.vUserIds[userID] = ply
end
