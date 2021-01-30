if Classes == nil then
    _G.Classes = class({})
end

function Classes:init()
    Classes.kv = LoadKeyValues("scripts/kv/classes.kv")
	CustomGameEventManager:RegisterListener( "petri_player_pick_class", PickClass )
	CustomGameEventManager:RegisterListener( "petri_player_ban_class", BanClass )
	
	Classes.randomClassBanned = false
	
	Classes.random = {}
	Classes.banned = {}
end

function Classes:RandomClassTimer()
    Timers:CreateTimer(240, function()
	    for i = 0, 20 do
            if PlayerResource:IsValidPlayer(i) then
			    local player = PlayerResource:GetPlayer(i)
				if player and player:GetAssignedHero() and player:GetAssignedHero():GetTeam() == DOTA_TEAM_GOODGUYS and player:GetAssignedHero().PetriClass == nil then
				    Classes:RandomClassForPlayer(player)
				end
			end
        end		
	end)
end

function Classes:IsBanned(name)
--[[
	for i = 0, 20 do
		if PlayerResource:IsValidPlayer(i) then
			local player = PlayerResource:GetPlayer(i) 
			if player and player:GetAssignedHero() and player:GetAssignedHero().PetriBan then
				print(player:GetAssignedHero().PetriBan.." "..name)
				if tostring(player:GetAssignedHero().PetriBan) == tostring(name) then
				    return true
				end
			end
		end
	end
	]]
	print("check is banned "..name)
	
	if Classes.banned[name] == true then return true end
	
	return false
end

function Classes:RandomClassForPlayer(player)
	local hero = player:GetAssignedHero()
	local name = tostring(Classes.random[math.random(1, #Classes.random)])
	
	if Classes:IsBanned(name) == true then
	    Classes:RandomClassForPlayer(player)
	else
	    hero.PetriClass = name
	    local ability = hero:AddAbility(name)
	    ability:SetLevel(1)
	    hero:SwapAbilities("petri_empty6", name, false, true)
	
	    print("RANDOM CLASS FOR PLAYER "..player:GetPlayerID()..name)
	end
end

function Classes:LoadAndSend()
    for k, v in pairs(Classes.kv) do
	    local data = 
		{
		    name = k,
		    id = "id",
			icon = "icon",
			ability = "ability",
			banned = 0
		}
	    for k2, v2 in pairs(v) do
	        print("classes "..k.." "..k2.." "..v2)
			if k2 == data.id then
			    data.id = v2
			elseif k2 == data.icon then
                data.icon = v2			
			elseif k2 == data.ability then
			    data.ability = v2
			end
		end
		
		Classes.random[data.id] = data.ability
		
        if Classes:IsBanned(data.ability) == true then
			print("banned")
			data.banned = 1
		    data.classname = data.name
		end
		
		CustomGameEventManager:Send_ServerToAllClients( "petri_send_class", data )
	end
	CustomGameEventManager:Send_ServerToAllClients( "petri_set_classes", nil )
	
	if Classes.randomClassBanned == false then
		Classes.randomClassBanned = true
			
		for i = 1, (3 - PlayerResource:GetPlayerCountForTeam(DOTA_TEAM_BADGUYS)) do
			BanRandomClass()
		end
		
		Classes:LoadAndSend()
	end
end

function BanRandomClass()
	local name = tostring(Classes.random[math.random(1, #Classes.random)])
	
	if Classes:IsBanned(name) == true then
	    BanRandomClass()
	else
		print("CLASS BANNED "..name)
		Classes.banned[name] = true
	end
end

function PickClass(event, args)
    print("classespick"..event.." "..args["ability"])
	local player = PlayerResource:GetPlayer(args["PlayerID"])
	if player and player:GetAssignedHero() then
	    local hero = player:GetAssignedHero()
		
		if hero:GetTeam() == DOTA_TEAM_BADGUYS then
		    errMsgToPlayer(player, "#classes_wrong_team")
		elseif hero.PetriClass ~= nil or Classes:IsBanned(args["ability"]) == true then
		    errMsgToPlayer(player, "#classes_picked")
		elseif GameRules:GetDOTATime(false, false) > 240 or GameRules:GetDOTATime(false, false) < 60 then
		    errMsgToPlayer(player, "#classes_time_over")
		else
		    hero.PetriClass = args["classname"]
			local ability = hero:AddAbility(args["ability"])
			ability:SetLevel(1)
			hero:SwapAbilities("petri_empty6", args["ability"], false, true)
		end
	end
end

function BanClass(event, args)
    print("classesban"..event.." "..args["classname"])
	local player = PlayerResource:GetPlayer(args["PlayerID"])
	if player and player:GetAssignedHero() then
	    local hero = player:GetAssignedHero()
		
		if hero:GetTeam() == DOTA_TEAM_GOODGUYS then
		    errMsgToPlayer(player, "#classes_ban_wrong_team")
		elseif hero.PetriBan ~= nil then
		    errMsgToPlayer(player, "#classes_banned")
		elseif GameRules:GetDOTATime(false, false) > 60 then
		    errMsgToPlayer(player, "#classes_ban_time_over")
		else
		    hero.PetriBan = args["ability"]
			CustomGameEventManager:Send_ServerToAllClients( "petri_block_class", args )
			Classes.banned[args["ability"]] = true
		end
	end
end

function errMsgToPlayer(player, text)
    Notifications:Bottom(player, {text=text, duration=5, style={color="red", ["font-size"]="50px", border="0px solid blue"}})
end

function GetFrontPoint( event )
	local caster = event.caster
	local fv = caster:GetForwardVector()
	local origin = caster:GetAbsOrigin()
	local distance = event.Distance
	
	local front_position = origin + fv * distance
	local result = {}
	table.insert(result, front_position)

	return result
end

function LandMinesPlant( keys )
	local caster = keys.caster
	local target_point = keys.target_points[1]
	local ability = keys.ability
	local ability_level = ability:GetLevel() - 1

	-- Initialize the count and table
	caster.land_mine_count = caster.land_mine_count or 0
	caster.land_mine_table = caster.land_mine_table or {}

	-- Modifiers
	local modifier_land_mine = keys.modifier_land_mine
	local modifier_tracker = keys.modifier_tracker
	local modifier_caster = keys.modifier_caster
	local modifier_land_mine_invisibility = keys.modifier_land_mine_invisibility

	-- Ability variables
	local activation_time = ability:GetLevelSpecialValueFor("activation_time", ability_level) 
	local max_mines = ability:GetLevelSpecialValueFor("max_mines", ability_level) 
	local fade_time = ability:GetLevelSpecialValueFor("fade_time", ability_level)

	-- Create the land mine and apply the land mine modifier
	local land_mine = CreateUnitByName("npc_dota_techies_land_mine", target_point, false, nil, nil, caster:GetTeamNumber())
	ability:ApplyDataDrivenModifier(caster, land_mine, modifier_land_mine, {})

	-- Update the count and table
	caster.land_mine_count = caster.land_mine_count + 1
	table.insert(caster.land_mine_table, land_mine)

	-- If we exceeded the maximum number of mines then kill the oldest one
	if caster.land_mine_count > max_mines then
		caster.land_mine_table[1]:ForceKill(true)
	end

	-- Increase caster stack count of the caster modifier and add it to the caster if it doesnt exist
	if not caster:HasModifier(modifier_caster) then
		ability:ApplyDataDrivenModifier(caster, caster, modifier_caster, {})
	end

	caster:SetModifierStackCount(modifier_caster, ability, caster.land_mine_count)

	-- Apply the tracker after the activation time
	Timers:CreateTimer(activation_time, function()
		ability:ApplyDataDrivenModifier(caster, land_mine, modifier_tracker, {})
	end)

	-- Apply the invisibility after the fade time
	Timers:CreateTimer(fade_time, function()
		ability:ApplyDataDrivenModifier(caster, land_mine, modifier_land_mine_invisibility, {})
	end)
end

--[[Author: Pizzalol
	Date: 24.03.2015.
	Stop tracking the mine and create vision on the mine area]]
function LandMinesDeath( keys )
	local caster = keys.caster
	local unit = keys.unit
	local ability = keys.ability
	local ability_level = ability:GetLevel() - 1

	-- Ability variables
	local modifier_caster = keys.modifier_caster
	local vision_radius = ability:GetLevelSpecialValueFor("vision_radius", ability_level) 
	local vision_duration = ability:GetLevelSpecialValueFor("vision_duration", ability_level)

	-- Find the mine and remove it from the table
	for i = 1, #caster.land_mine_table do
		if caster.land_mine_table[i] == unit then
			table.remove(caster.land_mine_table, i)
			caster.land_mine_count = caster.land_mine_count - 1
			break
		end
	end

	-- Create vision on the mine position
	ability:CreateVisibilityNode(unit:GetAbsOrigin(), vision_radius, vision_duration)

	-- Update the stack count
	caster:SetModifierStackCount(modifier_caster, ability, caster.land_mine_count)
	if caster.land_mine_count < 1 then
		caster:RemoveModifierByNameAndCaster(modifier_caster, caster) 
	end
end

--[[Author: Pizzalol
	Date: 24.03.2015.
	Tracks if any enemy units are within the mine radius]]
function LandMinesTracker( keys )
	local target = keys.target
	local ability = keys.ability
	local ability_level = ability:GetLevel() - 1

	-- Ability variables
	local trigger_radius = ability:GetLevelSpecialValueFor("small_radius", ability_level) 
	local explode_delay = ability:GetLevelSpecialValueFor("explode_delay", ability_level) 

	-- Target variables
	local target_team = DOTA_UNIT_TARGET_TEAM_ENEMY
	local target_types = DOTA_UNIT_TARGET_HERO
	local target_flags = DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES

	-- Find the valid units in the trigger radius
	local units = FindUnitsInRadius(target:GetTeamNumber(), target:GetAbsOrigin(), nil, trigger_radius, target_team, target_types, target_flags, FIND_CLOSEST, false) 

	-- If there is a valid unit in range then explode the mine
	if #units > 0 then
		Timers:CreateTimer(explode_delay, function()
			if target:IsAlive() then
				target:ForceKill(true) 
			end
		end)
	end
end

function KoshEggCreate(keys)
    local kosh = keys.caster
	local ability = keys.ability
	
	kosh.egg = CreateUnitByName("npc_petri_kosh_egg", kosh:GetAbsOrigin(), true, kosh, kosh, kosh:GetTeamNumber())
	kosh.egg.kosh = kosh
	
	kosh.egg:SetOwner(kosh)
	kosh.egg:SetControllableByPlayer(kosh:GetPlayerOwnerID(), true)
	
	ability:ApplyDataDrivenModifier(kosh, kosh, "modifier_kosh", {})
	ability:ApplyDataDrivenModifier(kosh, kosh.egg, "modifier_kosh_egg", {})
	
	KoshSlow(keys)
	
	if IsInsideEntityBounds(Entities:FindByName(nil, "blocking_trigger_b"), kosh.egg:GetAbsOrigin()) 
	or IsInsideEntityBounds(Entities:FindByNameNearest("egg_blocking_trigger", kosh.egg:GetAbsOrigin(), 999999), kosh.egg:GetAbsOrigin()) then
		print('tp to safe')
		kosh.egg:SetAbsOrigin(Entities:FindByClassname(nil, "info_courier_spawn_radiant"):GetAbsOrigin())
	end
end

function KoshSlow(keys)
    local kosh = keys.caster
	local ability = keys.ability
	local egg = kosh.egg
	local baseMs = kosh:GetBaseMoveSpeed()
	
	Timers:CreateTimer(1, function()
		if kosh and egg and kosh:IsAlive() and egg:IsAlive() then
			local dif = kosh:GetAbsOrigin() - egg:GetAbsOrigin()
			dif = dif:Length2D()/25
			--print("kosh dif "..dif)
			
			--ability:ApplyDataDrivenModifier(kosh, kosh, "modifier_kosh_slow", {value = dif})
			kosh:SetBaseMoveSpeed(baseMs-dif)
	    else
		    return nil
		end
		return 1.0
	end)
end

function add_gold(keys)
    local how_much = keys.ability:GetCurrentCharges()
	print("add_gold"..how_much)
	AddCustomGold( keys.caster:GetPlayerID(), tonumber(how_much))
	keys.ability:SetCurrentCharges(0)
	
	UTIL_Remove(keys.ability)
end

function TakeGold(keys)
    local caster = keys.caster
	local amount = tonumber(keys.amount)

    if SpendCustomGold( caster:GetPlayerOwnerID(), amount) == true then
        local hero = PlayerResource:GetPlayer(caster:GetPlayerOwnerID()):GetAssignedHero()
	    if hero:HasItemInInventory("item_gold") then
	        for i=0, 5 do
                local current_item = hero:GetItemInSlot(i)
                if current_item and current_item:GetName() == "item_gold" then
	                current_item:SetCurrentCharges(current_item:GetCurrentCharges() + amount)
				    break;
                end
		    end
	    else
		    local item = CreateItem("item_gold", nil, nil)
	        item:SetCurrentCharges(item:GetCurrentCharges() + amount)
	        hero:AddItem(item)
	    end
	end
end

function SpiderPos(keys)
    keys.caster.spiderpos = keys.caster:GetAbsOrigin()
end

function HomeComing(keys)
	FindClearSpaceForUnit(keys.caster, keys.caster.spiderpos + Vector(-70,-70,0), true)
	
	Timers:CreateTimer(0.03, function()
	 	MoveCamera(keys.caster:GetPlayerOwnerID(),keys.caster)
	 	keys.caster:Stop()
    end)
end

function NoCourier(keys)
	local caster = keys.caster
	local courier = keys.target
	local ability = keys.ability
	local chance = tonumber(ability:GetLevelSpecialValueFor("kill_chance", 1))
	local payout = tonumber(ability:GetLevelSpecialValueFor("gold", 1))
	local owner = courier:GetOwnerEntity()

	if not courier:IsCourier() then
		ability:EndCooldown()
	elseif owner and owner:GetAssignedHero() then
		if owner:GetAssignedHero():GetUnitName() == "npc_dota_hero_storm_spirit" then
			courier:ForceKill(false)
			ability:EndCooldown()
		else
			AddCustomGold( caster:GetPlayerOwnerID(), payout)
			if math.random(0, 100) <= chance then
				courier:ForceKill(false)
				ability:StartCooldown(ability:GetCooldown(1) * 2)
			end
		end
	else
		print("courier owner not found")
		courier:ForceKill(true)
		ability:EndCooldown()
	end
end

--[[Author: Pizzalol
	Date: 26.09.2015.
	Initializes the required data for the arrow stun,damage and vision calculation]]
function LaunchArrow( keys )
	local caster = keys.caster
	local caster_location = caster:GetAbsOrigin()
	local target_point = keys.target_points[1]
	local ability = keys.ability
	local ability_level = ability:GetLevel() - 1

	ability.arrow_vision_radius = ability:GetLevelSpecialValueFor("arrow_vision", ability_level)
	ability.arrow_vision_duration = ability:GetLevelSpecialValueFor("vision_duration", ability_level)
	ability.arrow_speed = ability:GetLevelSpecialValueFor("arrow_speed", ability_level)
	ability.arrow_start = caster_location
	ability.arrow_start_time = GameRules:GetGameTime()
	ability.arrow_direction = (target_point - caster_location):Normalized()
end

--[[Calculates the distance traveled by the arrow, then applies damage and stun according to calculations]]
function ArrowHit( keys )
	local caster = keys.caster
	local target = keys.target
	local target_location = target:GetAbsOrigin()
	local ability = keys.ability
	local ability_level = ability:GetLevel() - 1
	local ability_damage = ability:GetAbilityDamage()

	-- Initializing the damage table
	local damage_table = {}
	damage_table.attacker = caster
	damage_table.victim = target
	damage_table.damage_type = ability:GetAbilityDamageType()
	damage_table.ability = ability	

	-- Arrow
	local arrow_max_stunrange = ability:GetLevelSpecialValueFor("arrow_max_stunrange", ability_level)
	local arrow_max_damagerange = ability:GetLevelSpecialValueFor("arrow_max_damagerange", ability_level)
	local arrow_min_stun = ability:GetLevelSpecialValueFor("arrow_min_stun", ability_level)
	local arrow_max_stun = ability:GetLevelSpecialValueFor("arrow_max_stun", ability_level)
	local arrow_bonus_damage = ability:GetLevelSpecialValueFor("arrow_bonus_damage", ability_level)

	-- Stun and damage per distance
	local stun_per_30 = arrow_max_stun/(arrow_max_stunrange*1/30)
	local damage_per_30 = arrow_bonus_damage/(arrow_max_damagerange*1/30)

	local arrow_stun_duration = 0
	local arrow_damage = 0
	local distance = (target_location - ability.arrow_start):Length2D()

	-- Stun
	if distance < arrow_max_stunrange then
		arrow_stun_duration = distance*1/30*stun_per_30 + arrow_min_stun
	else
		arrow_stun_duration = arrow_max_stun
	end

	-- Damage
	if distance < arrow_max_damagerange then
		arrow_damage = distance*1/30*damage_per_30 + ability_damage
	else
		arrow_damage = ability_damage + arrow_bonus_damage
	end

	target:AddNewModifier(caster, ability, "modifier_stunned", {duration = arrow_stun_duration})
	damage_table.damage = arrow_damage
	ApplyDamage(damage_table)
end

--[[Calculates arrow location using available data and then creates a vision point]]
function ArrowVision( keys )
	local caster = keys.caster
	local ability = keys.ability

	-- Calculate the arrow location using the data we saved at launch
	local vision_location = ability.arrow_start + ability.arrow_direction * ability.arrow_speed * (GameRules:GetGameTime() - ability.arrow_start_time)

	-- Create the vision point
	AddFOWViewer(caster:GetTeamNumber(), vision_location, ability.arrow_vision_radius, ability.arrow_vision_duration, false)
end

function Illusion(keys)
	local caster = keys.caster
	local target = keys.target
	local playerID = caster:GetPlayerOwnerID()
	local unit_name = target:GetUnitName()
	
	local ability = keys.ability
	local duration = ability:GetLevelSpecialValueFor( "duration", ability:GetLevel() - 1 )
	
	local origin = caster:GetAbsOrigin() + RandomVector(math.random(0,200))
	local outgoingDamage = 0
	local incomingDamage = 1000
	
	local illusion = CreateUnitByName(unit_name, origin, true, caster, nil, caster:GetTeamNumber())
	illusion:SetControllableByPlayer(playerID, true)
	
	local model = target:GetModelName()
	illusion:SetModel(model)
	illusion:SetOriginalModel(model)
	illusion:SetModelScale(target:GetModelScale())
	
	if target:IsRealHero() then
		illusion:SetPlayerID(playerID)
	end
	
	if target:HasInventory() then
		for itemSlot=0,8 do
			local item = target:GetItemInSlot(itemSlot)
			if item ~= nil then
				local itemName = item:GetName()
				local newItem = CreateItem(itemName, illusion, illusion)
				illusion:AddItem(newItem)
			end
		end
	end	
	
	ability:ApplyDataDrivenModifier(caster, illusion, "modifier_petri_illusion", {})
	illusion:AddNewModifier(caster, ability, "modifier_illusion", { duration = duration, outgoing_damage = outgoingDamage, incoming_damage = incomingDamage })
	illusion:MakeIllusion()
	
	illusion:SetMoveCapability(DOTA_UNIT_CAP_MOVE_GROUND)
	--illusion:SetBaseMoveSpeed(350)
	
	if target:IsRealHero() then
		GameMode:SetupCustomSkin(illusion, PlayerResource:GetSteamAccountID(target:GetPlayerOwnerID()), target.key)
	elseif target:HasAbility("petri_building") then
		local lvl = target:GetModifierStackCount("modifier_upgrade", target)
		if lvl < 1 then lvl = 1 end
		SetCustomBuildingModel(illusion, PlayerResource:GetSteamAccountID(target:GetPlayerOwnerID()), lvl)
	elseif target:GetTeam() == DOTA_TEAM_GOODGUYS then
		SetCustomBuildingModel(illusion, PlayerResource:GetSteamAccountID(target:GetPlayerOwnerID()))
	end
end

function WallUpgrade(keys)
	local caster = keys.caster
	local ability = keys.ability
	local wall_level = ability:GetLevel()
	
	ability:SetLevel(wall_level)
	
	if wallScoreArr[caster:GetPlayerOwnerID()+1][wall_level] == 0 then
	    GameMode:addScore(caster:GetPlayerOwner():GetAssignedHero(), 9+wall_level)
		wallScoreArr[caster:GetPlayerOwnerID()+1][wall_level] = 1
	end
	
	
	if caster:HasModifier("modifier_class_wall_buff") then 
		--caster:RemoveModifierByName("modifier_class_wall_buff")
		ability:ApplyDataDrivenModifier(caster, caster, "modifier_class_wall_buff", {})
	end
end

function WallAddPSO(keys)
	local caster = keys.caster
	
	--FindClearSpaceForUnit(caster, caster:GetAbsOrigin(), true)
	if caster.blockers == nil then
		caster.blockers = BuildingHelper:BlockGridNavSquare(2, caster:GetAbsOrigin())
		GameMode:SaveBuildingToPSO(caster)
		
		caster:SetAbsOrigin(caster.WALL_PREV_POS)
	end
end
function WallRemovePSO(keys)
	local caster = keys.caster
	
	for k, v in pairs(caster.blockers) do
        DoEntFireByInstanceHandle(v, "Disable", "1", 0, nil, nil)
        DoEntFireByInstanceHandle(v, "Kill", "1", 1, nil, nil)
    end
	
	caster.blockers = nil
end

function WallThink(keys)
	local caster = keys.caster
	local ability = keys.ability
	local casterCurrPos = caster:GetAbsOrigin()
	local isWall = caster:HasModifier("modifier_class_wall_buff")
	local isDelayed = caster:HasModifier("modifier_class_wall_delay")
	
	local canBeWall = true
	local trigg = Entities:FindByNameNearest("area_trigger", caster:GetAbsOrigin(), 10000)
	if trigg:IsTouching(caster) then 
		if trigg.claimers and CheckAreaClaimers(caster, trigg.claimers) == false then
			canBeWall = false
		end
	end
	
	if caster.WALL_PREV_POS ~= nil and canBeWall then
		if caster.WALL_PREV_POS == casterCurrPos and not isWall and not isDelayed then
			local delay = ability:GetSpecialValueFor("delay")
		
			ability:ApplyDataDrivenModifier(caster, caster, "modifier_class_wall_delay", {duration = delay+0.1})
			Timers:CreateTimer(1.0, function()				
				if caster and ability and caster:IsAlive() then 
					local quads = BuildingHelper:ValidGridPosition(2, caster:GetAbsOrigin())
					if caster:GetAbsOrigin() == casterCurrPos and not caster:HasModifier("modifier_class_wall_buff") and not quads[1] and not quads[2] then
						if delay <= 0 then 
							ability:ApplyDataDrivenModifier(caster, caster, "modifier_class_wall_buff", {})
						end
					else
						caster:RemoveModifierByName("modifier_class_wall_delay")
					end
				end
				
				delay = delay - 1.0
				if delay >= 0 then return 1.0 end
			end)
		end
	end
	
	caster.WALL_PREV_POS = casterCurrPos
end