--[[
  A library to help make RTS-style and Tower Defense custom games in Dota 2
  Developer: Myll
  Version: 2.0
  Credits to:
    Ash47 and BMD for timers.lua.
    BMD for helping figure out how to get mouse clicks in Flash.
    Perry for writing FlashUtil, which contains functions for cursor tracking.
]]
-- Rewritten with multiplayer + shift queue in mind

BuildingHelper = {}
BuildingAbilities = {}

if not OutOfWorldVector then
  OutOfWorldVector = Vector(22000,22000,0)
end

MODEL_ALPHA = 100 -- Defines the transparency of the ghost model.

require("libraries/GridNav")

--[[
      Check grid quad
]]--
function BuildingHelper:ValidGridPosition(size, location)

    local halfSide = (size/2)*64
    local boundingRect = {  leftBorderX = location.x-halfSide, 
                            rightBorderX = location.x+halfSide, 
                            topBorderY = location.y+halfSide,
                            bottomBorderY = location.y-halfSide }

    local quads = {};
    local i = 0;
    for x=boundingRect.leftBorderX+32,boundingRect.rightBorderX-32,64 do
        for y=boundingRect.topBorderY-32,boundingRect.bottomBorderY+32,-64 do
            local testLocation = Vector(x, y, location.z)
            quads[i] = GridNav:IsBlocked(testLocation) or not GridNav:IsTraversable(testLocation) 
            i = i + 1
        end
    end
    return quads
end

function BuildingHelper:CheckPosition( args )
  local x = args['X']
  local y = args['Y']
  local z = args['Z']
  local location = Vector(x, y, z)

  local player = PlayerResource:GetPlayer(args["PlayerID"])

  local buildingTable = player.activeBuildingTable
  local fMaxScale = buildingTable:GetVal("MaxScale", "float")
  local size = buildingTable:GetVal("BuildingSize", "number")
  local callbacks = player.activeCallbacks

  if size % 2 ~= 0 then
    location.x = SnapToGrid32(location.x)
    location.y = SnapToGrid32(location.y)
  else
    location.x = SnapToGrid64(location.x)
    location.y = SnapToGrid64(location.y)
  end

  -- Check gridnav
  local validQuad = BuildingHelper:ValidGridPosition(size, location)
  
  CustomGameEventManager:Send_ServerToPlayer(player, "building_helper_grid_validation", validQuad )
end

function BuildingHelper:Init(...)
  GameMode.UnitKVs = LoadKeyValues("scripts/npc/npc_units_custom.txt")
  GameMode.HeroKVs = LoadKeyValues("scripts/npc/npc_heroes_custom.txt")
  GameMode.AbilityKVs = LoadKeyValues("scripts/npc/npc_abilities_custom.txt")
  GameMode.ItemKVs = LoadKeyValues("scripts/npc/npc_items_custom.txt")

  for i=1,2 do
    local t = GameMode.AbilityKVs
    if i == 2 then
      t = GameMode.ItemKVs
    end
    for abil_name,abil_info in pairs(t) do
      if type(abil_info) == "table" then
        local isBuilding = abil_info["Building"]
        local cancelsBuildingGhost = abil_info["CancelsBuildingGhost"]
        if isBuilding ~= nil and tostring(isBuilding) == "1" then
          BuildingAbilities[tostring(abil_name)] = abil_info
        end
      end
    end
  end
end

function BuildingHelper:RegisterLeftClick( args )
  local x = args['X']
  local y = args['Y']
  local z = args['Z']
  local location = Vector(x, y, z)

  --get the player that sent the comman
  local cmdPlayer = PlayerResource:GetPlayer(args['PlayerID'])

  local units = FindUnitsInRadius(DOTA_TEAM_GOODGUYS, location, nil, 130, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, FIND_ANY_ORDER, false)
  
  if #units > 0 then
    if cmdPlayer then
      cmdPlayer.activeBuilder:ClearQueue()
      cmdPlayer.activeBuilding = nil
      cmdPlayer.activeBuilder:Stop()
      cmdPlayer.activeBuilder.ProcessingBuilding = false

      cmdPlayer.waitingForBuildHelper = false

      if cmdPlayer.activeCallbacks.onConstructionCancelled ~= nil then
        cmdPlayer.activeCallbacks.onConstructionCancelled()
      end

      return false
    end
  end

  if cmdPlayer.activeBuilder:HasAbility("has_build_queue") == false then
    cmdPlayer.activeBuilder:AddAbility("has_build_queue")
    local abil = cmdPlayer.activeBuilder:FindAbilityByName("has_build_queue")
    abil:SetLevel(1)
  end

  if cmdPlayer then
    -- NEEDS WORK
    RemoveGatheringAndRepairingModifiers(cmdPlayer.activeBuilder)

    cmdPlayer.activeBuilder:AddToQueue(location)
    cmdPlayer.waitingForBuildHelper = true
  end
end

function BuildingHelper:RegisterRightClick( args )
  --get the player that sent the command
  local cmdPlayer = PlayerResource:GetPlayer(args['PlayerID'])
  if cmdPlayer then
    cmdPlayer.activeBuilder:ClearQueue()
    cmdPlayer.activeBuilding = nil
    cmdPlayer.activeBuilder:Stop()
    cmdPlayer.activeBuilder.ProcessingBuilding = false

    cmdPlayer.waitingForBuildHelper = false

    if cmdPlayer.activeCallbacks.onConstructionCancelled ~= nil then
      cmdPlayer.activeCallbacks.onConstructionCancelled()
    end
  end
end

function BuildingHelper:SetCallbacks(keys)
  local callbacks = {}

  function keys:OnPreConstruction( callback )
    callbacks.onPreConstruction = callback -- Use this to handle player resources, return false to abort the build
  end

  function keys:OnConstructionStarted( callback )
    callbacks.onConstructionStarted = callback
  end

  function keys:OnConstructionCompleted( callback )
    callbacks.onConstructionCompleted = callback
  end

  function keys:OnConstructionFailed( callback ) -- Called if there is a mechanical issue with the building (cant be placed)
    callbacks.onConstructionFailed = callback
  end

  function keys:OnConstructionCancelled( callback ) -- Called when player right clicks to cancel a queue
    callbacks.onConstructionCancelled = callback
  end

  function keys:EnableFireEffect( sFireEffect )
    callbacks.fireEffect = sFireEffect
  end

  function keys:OnBelowHalfHealth( callback )
    callbacks.onBelowHalfHealth = callback
  end

  function keys:OnAboveHalfHealth( callback )
    callbacks.onAboveHalfHealth = callback
  end

  function keys:OnBuildingPosChosen( callback )
    callbacks.onBuildingPosChosen = callback
  end

  return callbacks
end

-- Setup building table, returns a constructed table.
function BuildingHelper:SetupBuildingTable( abilityName )

  local buildingTable = BuildingAbilities[abilityName]

  function buildingTable:GetVal( key, expectedType )
    local val = buildingTable[key]

    --print('val: ' .. tostring(val))
    if val == nil and expectedType == "bool" then
      return false
    end
    if val == nil and expectedType ~= "bool" then
      return nil
    end

    if tostring(val) == "" then
      return nil
    end

    if expectedType == "handle" then
      return val
    end
	
	if key == "BuildTime" and GameMode.isTurboMode then
		return tonumber(val / 2)
	end

    local sVal = tostring(val)
    if sVal == "1" and expectedType == "bool" then
      return true
    elseif sVal == "0" and expectedType == "bool" then
      return false
    elseif sVal == "" then
      return nil
    elseif expectedType == "number" or expectedType == "float" then
      return tonumber(val)
    end
	
    return sVal
  end

  function buildingTable:SetVal( key, value )
    buildingTable[key] = value
  end

  -- Extract data from the KV files, set is called to guarantee these have values later on in execution
  local size = buildingTable:GetVal("BuildingSize", "number")
  if size == nil then
    print('[BuildingHelper] Error: ' .. abilName .. ' does not have a BuildingSize KeyValue')
    return
  end
  if size == 1 then
    print('[BuildingHelper] Warning: ' .. abilName .. ' has a size of 1. Using a gridnav size of 1 is currently not supported, it was increased to 2')
    buildingTable:SetVal("size", 2)
    return
  end

  local unitName = buildingTable:GetVal("UnitName", "string")
  if unitName == nil then
    print('[BuildingHelper] Error: ' .. abilName .. ' does not have a UnitName KeyValue')
    return
  end

  local castRange = buildingTable:GetVal("AbilityCastRange", "number")
  if castRange == nil then
    castRange = 200
  end
  buildingTable:SetVal("AbilityCastRange", castRange)

  return buildingTable
end

--Places a new building on full health and returns the handle. Places grid nav blockers
--Skips the construction phase and doesn't require a builder, this is most important to place the "base" buildings for the players when the game starts.
--Make sure the position is valid before calling this in code.
function BuildingHelper:PlaceBuilding(hero, name, location, snapToGrid, blockGridNav, size)
  
  local pID = hero:GetPlayerOwnerID()
  local playersHero = hero
  
  local gridNavBlockers = nil
  if blockGridNav then
    gridNavBlockers = BuildingHelper:BlockGridNavSquare(size, location)
  end

  if snapToGrid then
    if size % 2 ~= 0 then
      location.x = SnapToGrid32(location.x)
      location.y = SnapToGrid32(location.y)
    else
      location.x = SnapToGrid64(location.x)
      location.y = SnapToGrid64(location.y)
    end
  end

  -- Spawn the building
  local building = CreateUnitByName(name, location, false, playersHero, playersHero, playersHero:GetTeamNumber())
  building:SetControllableByPlayer(pID, true)
  building:SetOwner(playersHero)
  building.blockers = gridNavBlockers
  building.state = "complete"

  function building:RemoveBuilding( bForcedKill )
    if building.blockers ~= nil then
      for k, v in pairs(building.blockers) do
        DoEntFireByInstanceHandle(v, "Disable", "1", 0, nil, nil)
        DoEntFireByInstanceHandle(v, "Kill", "1", 1, nil, nil)
      end

      if bForcedKill then
        building:ForceKill(bForcedKill)
      end
    end
  end

  local mapping = {}
  for y = 1, size do
    mapping[y] = {}
    for x = 1, size do
      mapping[y][x] = 1
    end
  end

  GNV.LayerManager:Write( { ["LayerName"] = 'Buildings', ["X"] = location.x, ["Y"] = location.y, ["Width"] = size, ["Height"] = size, ['Mapping'] = mapping } )

  building.RemoveFromGNV = function ()
    local mapping = {}
    for y = 1, size do
      mapping[y] = {}
      for x = 1, size do
        mapping[y][x] = 0
      end
    end
    GNV.LayerManager:Write( { ["LayerName"] = 'Buildings', ["X"] = location.x, ["Y"] = location.y, ["Width"] = size, ["Height"] = size, ['Mapping'] = mapping } )
  end

  -- Return the created building
  return building

end


function BuildingHelper:AddBuilding(keys)

  -- Callbacks
  callbacks = self:SetCallbacks(keys)


  local ability = keys.ability
  local abilName = ability:GetAbilityName()
  local buildingTable = self:SetupBuildingTable(abilName) 


  buildingTable:SetVal("AbilityHandle", ability)

  local size = buildingTable:GetVal("BuildingSize", "number")
  local unitName = buildingTable:GetVal("UnitName", "string")

  -- Prepare the builder, if it hasn't already been done. Since this would need to be done for every builder in some games, might as well do it here.
  local builder = keys.caster

  if builder.buildingQueue == nil or Timers.timers[builder.workTimer] == nil then    
    InitializeBuilder(builder)
  end

  local fMaxScale = buildingTable:GetVal("MaxScale", "float")
  if fMaxScale == nil then
    -- If no MaxScale is defined, check the "ModelScale" KeyValue. Otherwise just default to 1
    local fModelScale = GameMode.UnitKVs[unitName].ModelScale
    if fModelScale then
      fMaxScale = fModelScale
    else
      fMaxScale = 1
    end
  end
  buildingTable:SetVal("MaxScale", fMaxScale)

  -- Get the local player, this assumes the player is only placing one building at a time
  local player = PlayerResource:GetPlayer(builder:GetMainControllingPlayer())
  
  player.buildingPosChosen = false
  player.activeBuilder = builder
  player.activeBuilding = unitName
  player.activeBuildingTable = buildingTable
  player.activeCallbacks = callbacks

  -- Create model ghost dummy out of the map, then make pretty particles
  player.activeBuildingTable.mgd = CreateUnitByName(unitName, OutOfWorldVector, false, nil, nil, builder:GetTeam())

  local customScale

  customScale = SetCustomBuildingModel(player.activeBuildingTable.mgd, PlayerResource:GetSteamAccountID(player:GetPlayerID()))

  if customScale then fMaxScale = customScale end

  --<BMD> position is 0, model attach is 1, color is CP2, alpha is CP3.x, scale is CP4.x
  player.activeBuildingTable.modelParticle = ParticleManager:CreateParticleForPlayer("particles/buildinghelper/ghost_model.vpcf", PATTACH_ABSORIGIN, player.activeBuildingTable.mgd, player)
  ParticleManager:SetParticleControlEnt(player.activeBuildingTable.modelParticle, 1, player.activeBuildingTable.mgd, 1, "follow_origin", player.activeBuildingTable.mgd:GetAbsOrigin(), true)            
  ParticleManager:SetParticleControl(player.activeBuildingTable.modelParticle, 3, Vector(MODEL_ALPHA,0,0))
  ParticleManager:SetParticleControl(player.activeBuildingTable.modelParticle, 4, Vector(fMaxScale,0,0))

  ParticleManager:SetParticleControl(player.activeBuildingTable.modelParticle, 2, Vector(0,255,0))

  CustomGameEventManager:Send_ServerToPlayer(player, "building_helper_enable", {["state"] = "active", ["size"] = size, ["entindex"] = player.activeBuildingTable.mgd:entindex(), ["fMaxScale"] = fMaxScale} )

  return buildingTable
end

--[[
      ValidPosition
      * Checks GridNav square of certain size at a location
      * Sends onConstructionFailed if invalid
]]--
function BuildingHelper:ValidPosition(size, location, callbacks)

    local halfSide = (size/2)*64
    local boundingRect = {  leftBorderX = location.x-halfSide, 
                            rightBorderX = location.x+halfSide, 
                            topBorderY = location.y+halfSide,
                            bottomBorderY = location.y-halfSide }

    for x=boundingRect.leftBorderX+32,boundingRect.rightBorderX-32,64 do
        for y=boundingRect.topBorderY-32,boundingRect.bottomBorderY+32,-64 do
            local testLocation = Vector(x, y, location.z)
            if GridNav:IsBlocked(testLocation) or GridNav:IsTraversable(testLocation) == false then
                if callbacks.onConstructionFailed then
                    callbacks.onConstructionFailed()
                    return false
                end
            end
        end
    end
	
	print("ti debil")
	local units = FindUnitsInRadius(DOTA_TEAM_GOODGUYS, location, nil, size*64, DOTA_UNIT_TARGET_TEAM_FRIENDLY,
                          DOTA_UNIT_TARGET_ALL,
                          DOTA_UNIT_TARGET_FLAG_NONE,
                          FIND_ANY_ORDER,
                          false)
	for _,unit in pairs(units) do
	    print(unit.blocks)
        if unit.blocks == false then
            if callbacks.onConstructionFailed then
                callbacks.onConstructionFailed()
                return false
            end
		end
    end	
    					
    return true
end


--[[
      InitializeBuildingEntity
      * Creates the building

]]--
function BuildingHelper:InitializeBuildingEntity( keys )
  local builder = keys.caster
  local pID = builder:GetMainControllingPlayer()
  local work = builder.work
  local callbacks = work.callbacks
  local unitName = work.name
  local location = work.location
  local player = PlayerResource:GetPlayer(pID)
  local playersHero = player:GetAssignedHero()
  local buildingTable = work.buildingTable
  local size = buildingTable:GetVal("BuildingSize", "number")
  local instantBuild = work.instantBuild

  -- Worker is done with this building
  builder.ProcessingBuilding = false
  
  -- Check if the building ability is on cooldown, if it is then it cannot be cast
  local ability = buildingTable:GetVal("AbilityHandle", "handle")

  -- Check gridnav and cancel if invalid
  if not BuildingHelper:ValidPosition(size, location, callbacks) then
    -- Remove the model particle and Advance Queue
    if callbacks.onConstructionFailed ~= nil then
      callbacks.onConstructionFailed(work)
    end
    if work.particleIndex then
      ParticleManager:DestroyParticle(work.particleIndex, true)
    else
      callbacks.onConstructionFailed(work)
    end
    return
  end

  local gridNavBlockers = self:BlockGridNavSquare(size, location)
  
  if callbacks.onPreConstruction ~= nil then
    local result = callbacks.onPreConstruction()
    if result ~= nil then
      if result == false then
        if callbacks.onConstructionFailed ~= nil then
          callbacks.onConstructionFailed(work)
        end
        ParticleManager:DestroyParticle(work.particles, true)
        builder.work = nil
        for k, v in pairs(gridNavBlockers) do
          DoEntFireByInstanceHandle(v, "Disable", "1", 0, nil, nil)
          DoEntFireByInstanceHandle(v, "Kill", "1", 1, nil, nil)
        end
        return
      end
    end
  end
    
  -- Spawn the building
  local building = CreateUnitByName(unitName, OutOfWorldVector, false, playersHero, nil, PlayerResource:GetTeam(pID))
  building:SetControllableByPlayer(pID, true)
  building:SetOwner(PlayerResource:GetPlayer(pID))
  building:SetHullRadius(building:GetHullRadius()+5)
  building:AddNoDraw()

  local s = CreateUnitByName("npc_dummy_unit", location, false, nil, nil, DOTA_TEAM_GOODGUYS)

  FindClearSpaceForUnit(building, building:GetAbsOrigin(), true)
  Timers:CreateTimer(0.06, function ()
    if (IsValidEntity(s)) then
      if (Entities:FindByName(nil, "blocking_trigger_b"):IsTouching(s)) then
        building:ForceKill(false)
      end
      s:ForceKill(false)
    end
  end)

  local customScale

  customScale = SetCustomBuildingModel(building, PlayerResource:GetSteamAccountID(pID))

  Timers:CreateTimer(function() building:SetAbsOrigin(location) end)

  building.blockers = gridNavBlockers
  building.buildingTable = buildingTable

  local fMaxHealth = building:GetMaxHealth()

  if callbacks.onConstructionStarted ~= nil then
    callbacks.onConstructionStarted(building)
  end

  -- Remove ghost model
  UTIL_Remove(buildingTable.mgd)

  if instantBuild == false then
    building.state = "building"

    -- Prevent regen messing with the building spawn hp gain
    local regen = building:GetBaseHealthRegen()
    building:SetBaseHealthRegen(0)

    local buildTime = buildingTable:GetVal("BuildTime", "float")
    if buildTime == nil then
      buildTime = .1
    end

    -- the gametime when the building should be completed.
    local fTimeBuildingCompleted=GameRules:GetGameTime()+buildTime

    -- whether we should update the building's health over the build time.
    local bUpdateHealth = buildingTable:GetVal("UpdateHealth", "bool")
    

    --[[
          Code to update unit health and scale over the build time, maths is a bit spooky but here's whats happening
          Logic follows:
            Calculate HP to increase every frame
            Divide into INT and FLOAT components (SetHealth takes an int)
            Create a timer, tick every frame
              Increase the HP by the INT component
              Each tick increment the FLOAT carry by the FLOAT component
              IF the FLOAT carry > 1, reduce by one and increase the HP by one extra

          Can be optimized later if updating every frame proves to be a problem
    ]]--
    local fAddedHealth = 0

    local fserverFrameRate = 1/30 

    local nHealthInterval = fMaxHealth / (buildTime / fserverFrameRate)
    local fSmallHealthInterval = nHealthInterval - math.floor(nHealthInterval) -- just the floating point component
    nHealthInterval = math.floor(nHealthInterval)
    local fHPAdjustment = 0

    -- whether we should scale the building.
    local bScale = buildingTable:GetVal("Scale", "bool")
    -- the amount to scale to.
    local fMaxScale = buildingTable:GetVal("MaxScale", "float")
    if customScale then fMaxScale = customScale end
    if fMaxScale == nil then
      fMaxScale = 1
    end

    -- Update model size, starting with an initial size
    local fInitialModelScale = 0.03

    -- scale to add every frame, distributed by build time
    local fScaleInterval = (fMaxScale-fInitialModelScale) / (buildTime / fserverFrameRate)

    -- start the building at 20% of max scale.
    local fCurrentScale = fInitialModelScale
    local bScaling = false -- Keep tracking if we're currently model scaling.

    local bPlayerCanControl = buildingTable:GetVal("PlayerCanControl", "bool")
    if bPlayerCanControl then
      building:SetControllableByPlayer(playersHero:GetPlayerID(), true)
      building:SetOwner(playersHero)
    end
      
    building.bUpdatingHealth = false --Keep tracking if we're currently updating health.

    if bUpdateHealth then
      building:SetHealth(1)
      building.bUpdatingHealth = true
    end

    if bScale then
      building:SetModelScale(fCurrentScale)
      bScaling=true
    end


    Timers:CreateTimer(0.1, function()
      building:RemoveNoDraw()
      building.sandstormFX = ParticleManager:CreateParticle("particles/units/heroes/hero_sandking/sandking_sandstorm.vpcf", PATTACH_POINT_FOLLOW, building)
      ParticleManager:SetParticleControl(building.sandstormFX, 1, Vector(buildingTable:GetVal("BuildingSize", "number") * 64, buildingTable:GetVal("BuildingSize", "number") * 64, 0))
    end)

    -- Health Timers
    -- If the tick would be faster than 1 frame, adjust the HP gained per frame
    building.updateHealthTimer = DoUniqueString('health') 
    Timers:CreateTimer(building.updateHealthTimer, {
      callback = function()
      if IsValidEntity(building) then
        local timesUp = GameRules:GetGameTime() >= fTimeBuildingCompleted
        if not timesUp then
          if building.bUpdatingHealth then
            fHPAdjustment = fHPAdjustment + fSmallHealthInterval
            if fHPAdjustment > 1 then
              building:SetHealth(building:GetHealth() + nHealthInterval + 1)
              fHPAdjustment = fHPAdjustment - 1
              fAddedHealth = fAddedHealth + nHealthInterval + 1
            else
              building:SetHealth(building:GetHealth() + nHealthInterval)
              fAddedHealth = fAddedHealth + nHealthInterval
            end
          end
        else
          -- completion: timesUp is true
          building:SetHealth(building:GetHealth() + fMaxHealth - fAddedHealth) -- round up the last little bit
          if callbacks.onConstructionCompleted ~= nil and building:IsAlive() then
            callbacks.onConstructionCompleted(building)
          end
          building.constructionCompleted = true

          building.state = "complete"
          building.bUpdatingHealth = false

          ParticleManager:DestroyParticle(building.sandstormFX, false)

          if building:GetPlayerOwner() and building:IsAlive() then
            building:EmitSound("KVN.BuildingComplete")
          end
          
          -- Write buildings layes
          local mapping = {}
          for y = 1, size do
            mapping[y] = {}
            for x = 1, size do
              mapping[y][x] = 1
            end
          end
          
          GNV.LayerManager:Write( { ["LayerName"] = 'Buildings', ["X"] = location.x, ["Y"] = location.y, ["Width"] = size, ["Height"] = size, ['Mapping'] = mapping } )
      
          building.RemoveFromGNV = function ()
            local mapping = {}
            for y = 1, size do
              mapping[y] = {}
              for x = 1, size do
                mapping[y][x] = 0
              end
            end
            GNV.LayerManager:Write( { ["LayerName"] = 'Buildings', ["X"] = location.x, ["Y"] = location.y, ["Width"] = size, ["Height"] = size, ['Mapping'] = mapping } )
          end

          -- clean up the timer if we don't need it.
          return nil
        end
      else
        -- not valid ent
        return nil
      end
        return fserverFrameRate
    end})

    -- scale timer
    building.updateScaleTimer = DoUniqueString('scale')
    Timers:CreateTimer(building.updateScaleTimer, {
      callback = function()
        if IsValidEntity(building) then
        local timesUp = GameRules:GetGameTime() >= fTimeBuildingCompleted
        if not timesUp then
          if bScaling then
            if fCurrentScale < fMaxScale then
              fCurrentScale = fCurrentScale+fScaleInterval
              building:SetModelScale(fCurrentScale)
            else
              building:SetModelScale(fMaxScale)
              bScaling = false
            end
          end
        else
          building:SetModelScale(fMaxScale)
          return nil
        end
      else
        -- not valid ent
        return nil
      end
        return fserverFrameRate
    end})
  
  -- Instant build = true, so just set everything and do callbacks.
  else
    local fMaxScale = buildingTable:GetVal("MaxScale", "float")
    building:SetModelScale(fMaxScale)
    building.state = "complete"
    building:RemoveNoDraw()
    if callbacks.onConstructionCompleted ~= nil then
      callbacks.onConstructionCompleted(building)
    end
  end

  -- Work is done, clear the work table.
  builder.work = nil

  -- OnBelowHalfHealth timer
  building.onBelowHalfHealthProc = false
  building.healthChecker = Timers:CreateTimer(.2, function()
    if IsValidEntity(building) then
      if building:GetHealth() < fMaxHealth/2.0 and not building.onBelowHalfHealthProc and not building.bUpdatingHealth then
        if callbacks.fireEffect ~= nil then
          building:AddNewModifier(building, nil, callbacks.fireEffect, nil)
        end
        callbacks.onBelowHalfHealth(unit)
        building.onBelowHalfHealthProc = true
      elseif building:GetHealth() >= fMaxHealth/2.0 and building.onBelowHalfHealthProc and not building.bUpdatingHealth then
        if callbacks.fireEffect then
          building:RemoveModifierByName(callbacks.fireEffect)
        end
        callbacks.onAboveHalfHealth(unit)
        building.onBelowHalfHealthProc = false
      end
    else
      return nil
    end

    return .2
  end)

  function building:RemoveBuilding( bForcedKill )
    -- Thanks based T__
    for k, v in pairs(building.blockers) do
      DoEntFireByInstanceHandle(v, "Disable", "1", 0, nil, nil)
      DoEntFireByInstanceHandle(v, "Kill", "1", 1, nil, nil)
    end

    if bForcedKill then
      building:ForceKill(bForcedKill)
    end
    Timers:CreateTimer(0.8, function (  )
      UTIL_Remove(building)
    end)
  end

  -- Remove the model particl
  ParticleManager:DestroyParticle(work.particles, true)

end

--[[
      Builder Functions
      * Sets up all the functions required of a builder. Will run once per builder
      * Manages each workers build queue
]]--
function InitializeBuilder( builder )
  builder.ProcessingBuilding = false

  if builder.buildingQueue == nil then
    builder.buildingQueue = {}
  end


  builder.workTimer = Timers:CreateTimer(0.1, function ()
    if #builder.buildingQueue > 0 and builder.ProcessingBuilding == false then    
      builder.ProcessingBuilding = true
      builder:AddToGrid(builder.buildingQueue[1])
      table.remove(builder.buildingQueue, 1)
    end
    return 0.1
  end)

  function builder:AddToQueue( location )
    -- Adds a location to the builders work queue

    local player = PlayerResource:GetPlayer(builder:GetMainControllingPlayer())
    local building = player.activeBuilding
    local buildingTable = player.activeBuildingTable
    local fMaxScale = buildingTable:GetVal("MaxScale", "float")
    local size = buildingTable:GetVal("BuildingSize", "number")
    local callbacks = player.activeCallbacks

    if size % 2 ~= 0 then
      location.x = SnapToGrid32(location.x)
      location.y = SnapToGrid32(location.y)
    else
      location.x = SnapToGrid64(location.x)
      location.y = SnapToGrid64(location.y)
    end

    -- Check gridnav
    if not BuildingHelper:ValidPosition(size, location, callbacks) then
        return
    end

    ParticleManager:SetParticleControl(player.activeBuildingTable.modelParticle, 0, location)

    table.insert(builder.buildingQueue, {["location"] = location, ["name"] = building, ["buildingTable"] = buildingTable, ["particles"] = player.activeBuildingTable.modelParticle, ["callbacks"] = callbacks, ["instantBuild"] = false})
    
  end

  -- Clear the build queue, the player right clicked
  function builder:ClearQueue()
    
    if builder.work ~= nil then
      ParticleManager:DestroyParticle(builder.work.particles, true)
      if builder.work.callbacks.onConstructionCancelled ~= nil then
        builder.work.callbacks.onConstructionCancelled(work)
        builder.work = nil
      end
    end

    while #builder.buildingQueue > 0 do
      local work = builder.buildingQueue[1]
      ParticleManager:DestroyParticle(work.particles, true)
      table.remove(builder.buildingQueue, 1)
      if work.callbacks.onConstructionCancelled ~= nil then
        work.callbacks.onConstructionCancelled(work)
      end
    end
  end

  function builder:AddToGrid( work )
    -- Processes an item of the builders work queue
    local buildingTable = work.buildingTable
    local castRange = buildingTable:GetVal("AbilityCastRange", "number")
    local callbacks = work.callbacks
    local location = work.location
    builder.work = work


    -- Make the caster move towards the point
    local abilName = "move_to_point_" .. tostring(castRange)
    if GameMode.AbilityKVs[abilName] == nil then
      print('[BuildingHelper] Error: ' .. abilName .. ' was not found in npc_abilities_custom.txt. Using the ability move_to_point_100')
      abilName = "move_to_point_100"
    end

    -- If unit has other move_to_point abils, we should clean them up here
    AbilityIterator(builder, function(abil)
      local name = abil:GetAbilityName()
      if name ~= abilName and string.starts(name, "move_to_point_") then
        builder:RemoveAbility(name)
        --print("removed " .. name)
      end
    end)

    if not builder:HasAbility(abilName) then
      builder:AddAbility(abilName)
    end
    local abil = builder:FindAbilityByName(abilName)
    abil:SetLevel(1)

    Timers:CreateTimer(.03, function()
      builder:CastAbilityOnPosition(location, abil, 0)
      if callbacks.onBuildingPosChosen ~= nil then
        callbacks.onBuildingPosChosen(location)
        callbacks.onBuildingPosChosen = nil
      end
    end)
  end
end

function BuildingHelper:BlockGridNavSquare(size, location)

  if size % 2 ~= 0 then
    location.x = SnapToGrid32(location.x)
    location.y = SnapToGrid32(location.y)
  else
    location.x = SnapToGrid64(location.x)
    location.y = SnapToGrid64(location.y)
  end

  local gridNavBlockers = {}
  if size % 2 == 1 then
    for x = location.x - (size-2) * 32, location.x + (size-2) * 32, 64 do
      for y = location.y - (size-2) * 32, location.y + (size-2) * 32, 64 do
        local blockerLocation = Vector(x, y, location.z)
        local ent = SpawnEntityFromTableSynchronous("point_simple_obstruction", {origin = blockerLocation})
        table.insert(gridNavBlockers, ent)
      end
    end
  else
    for x = location.x - (size / 2) * 32 + 16, location.x + (size / 2) * 32 - 16, 96 do
      for y = location.y - (size / 2) * 32 + 16, location.y + (size / 2) * 32 - 16, 96 do
        local blockerLocation = Vector(x, y, location.z)
        local ent = SpawnEntityFromTableSynchronous("point_simple_obstruction", {origin = blockerLocation})
        table.insert(gridNavBlockers, ent)
      end
    end
  end
  return gridNavBlockers
end


BuildingHelper:Init()

--[[
      Utility functions
]]--
function SnapToGrid64(coord)
  return 64*math.floor(0.5+coord/64)
end

function SnapToGrid32(coord)
  return 32+64*math.floor(coord/64)
end

function AbilityIterator(unit, callback)
    for i=0, unit:GetAbilityCount()-1 do
        local abil = unit:GetAbilityByIndex(i)
        if abil ~= nil then
            callback(abil)
        end
    end
end

function string.starts(String,Start)
   return string.sub(String,1,string.len(Start))==Start
end