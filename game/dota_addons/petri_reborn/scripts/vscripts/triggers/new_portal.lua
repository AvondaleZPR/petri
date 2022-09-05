require('libraries/util/split')
require('internal/util')

--[[
lvl_space_name
3_space_npc_petri_creep_bad_actor

newportal_heroname_pos
newportal_npc_dota_hero_brewmaster_spawn

pos:
spawn
first1
first2
second

new_arena_first_brew_creeps
new_arena_first_death_creeps
new_arena_second_brew_creeps

1_space_miniactor
10_space_miniactor

1_space_miniactor_spawn
]]

function Activate(keys)
	--print("NewPortal activated "..thisEntity:GetName())
	local lvl, name = DecodeName(thisEntity:GetName())
	
	local unit = CreateUnitByName("npc_dummy_unit", thisEntity:GetAbsOrigin(), false, nil, nil, DOTA_TEAM_BADGUYS)

	local oldPos = unit:GetAbsOrigin()
	oldPos.z = oldPos.z + 250
	unit:SetAbsOrigin(oldPos)
	
	unit:AddAbility("petri_dummy_static_popup")
	InitAbilities(unit)

	Timers:CreateTimer(5, function ()
		PopupStaticParticle(lvl, Vector(255,0,0), unit)
	end)
end

function OnStartTouch(eventTrigger) 
    local activator = eventTrigger.activator
	local trigger = eventTrigger.caller
	local activatorName = activator:GetUnitName()
	local lvl, creepName = DecodeName(trigger:GetName())
	
	if creepName ~= "miniactor" and CheckBasics(activator) == true and CheckNight(activator:GetPlayerOwnerID()) == true and CheckLevel(activator, lvl) == true then
	    SpawnCreeps(activatorName, creepName)
		SetHeroPos(activator, GetPosition(activatorName, "spawn"))
	end
	
	if creepName == "miniactor" and CheckMiniActor(activator) == true and CheckNight(activator:GetPlayerOwnerID()) == true and CheckLevel(activator, lvl) == true then
	    local pos = Entities:FindByName(nil, trigger:GetName().."_spawn"):GetAbsOrigin()
		SetHeroPos(activator, pos)
		
		MiniActorBosses(trigger:GetName(), lvl)
	end
end

function MiniActorBosses(name, lvl)
    if lvl == 15 and GameMode.miniactorsBoss == nil then
		local bosPos = Entities:FindByName(nil, name.."_boss"):GetAbsOrigin()
		GameMode.miniactorsBoss = CreateUnitByName("npc_petri_creep_boss_kvn", bosPos, true, nil, nil, DOTA_TEAM_NEUTRALS) 
	end    
end

function CheckMiniActor(hero)
    if hero and hero:IsRealHero() == true and hero:GetUnitName() == "npc_dota_hero_storm_spirit" then return true end
	
	if hero:GetUnitName() ~= "npc_dota_hero_storm_spirit" then
	    SendPortalMsg(hero:GetPlayerOwnerID(), "#new_arena_not_miniactor")
	end
	return false
end

function DecodeName(name)
    local arr = split(name, "_space_")
	return tonumber(arr[1]), arr[2]
end

function CheckBasics(npc) 
    if npc and npc:IsRealHero() == true and npc:GetTeam() == DOTA_TEAM_BADGUYS and npc:GetUnitName() ~= "npc_dota_hero_storm_spirit" then
	    return true end
	
	return false
end

function CheckNight(pid)
    if GameMode:isdaydumb() == false then
	    SendPortalMsg(pid, "#no_farm_tonight")
	end
	
	return GameMode:isdaydumb()
end

function CheckLevel(hero, lvl)
    if hero:GetLevel() < lvl then
	    SendPortalMsg(hero:GetPlayerOwnerID(), "#new_arena_lvl_need")
		SendPortalMsg(hero:GetPlayerOwnerID(), lvl)
		return false
	end
	
	return true
end

function SpawnCreeps(heroName, creepName)
    local oneCreep = GetPosition(heroName, "first1")
	local allCreeps = GetPosition(heroName, "first2")
	local secondCreeps = GetPosition(heroName, "second")
	
	local creepArr = ManageCreepArr(heroName, "first", nil)
	local creepArrSecond = ManageCreepArr(heroName, "second", nil)
	
	local creepNameSecond = ""
	if creepArr[1] then 
	    creepNameSecond = ClearCreeps(creepArr) 
	end
	if creepArrSecond[1] then ClearCreeps(creepArrSecond) end
	
	creepArr = {}
	creepArrSecond = {}
	
	creepArr[1] = CreateCreepUnit(creepName, oneCreep)
	creepArr[1].newAreaId = 1
	
	for i = 2, GameRules.PETRI_MAX_CREEPS_ON_ARENA do 
	    creepArr[i] = CreateCreepUnit(creepName, allCreeps)
		creepArr[i].newAreaId = i
	end
	
	if creepNameSecond ~= "" and creepName ~= "npc_petri_creep_bad_actor" then
	for i = 1, GameRules.PETRI_MAX_CREEPS_ON_ARENA do 
	    creepArrSecond[i] = CreateCreepUnit(creepNameSecond, secondCreeps)
		creepArrSecond[i].newAreaId = i
	end
	end
	
	ManageCreepArr(heroName, "first", creepArr)
	ManageCreepArr(heroName, "second", creepArrSecond)
end

function GetPosition(hero, pos)
    return Entities:FindByName(nil, "newportal_"..hero.."_"..pos):GetAbsOrigin()
end

function ClearCreeps(arr)
    --PrintTable(arr)

    local rtrnName = ""
    for i = 1, GameRules.PETRI_MAX_CREEPS_ON_ARENA do
	    local unit = arr[i]
		if unit then
		    rtrnName = unit:GetUnitName()
			print("new_portal unit deleted "..i..rtrnName)
		    UTIL_Remove(unit)
		end
		UTIL_Remove(arr[i])
	end
	
	return rtrnName
end

function ManageCreepArr(heroName, numb, save)
	if heroName == "npc_dota_hero_brewmaster" then
	    if save == nil then
			if numb == "first" then
	            if GameRules.new_arena_first_brew_creeps == nil then
		            GameRules.new_arena_first_brew_creeps = {}
		        end
				return GameRules.new_arena_first_brew_creeps
		    else
		        if GameRules.new_arena_second_brew_creeps == nil then
		            GameRules.new_arena_second_brew_creeps = {}
		        end
				return GameRules.new_arena_second_brew_creeps
		    end
		else
		    if numb == "first" then
                GameRules.new_arena_first_brew_creeps = save
		    else
                GameRules.new_arena_second_brew_creeps = save
		    end
		end
	else
	    if save == nil then
			if numb == "first" then
	            if GameRules.new_arena_first_death_creeps == nil then
		            GameRules.new_arena_first_death_creeps = {}
		        end
				return GameRules.new_arena_first_death_creeps
		    else
		        if GameRules.new_arena_second_death_creeps == nil then
		            GameRules.new_arena_second_death_creeps = {}
		        end
				return GameRules.new_arena_second_death_creeps
		    end
		else
		    if numb == "first" then
                GameRules.new_arena_first_death_creeps = save
		    else
                GameRules.new_arena_second_death_creeps = save
		    end
		end
	end
end

function CreateCreepUnit(name, pos)
    return CreateUnitByName(name, pos, true, nil, nil, DOTA_TEAM_NEUTRALS)
end

function SetHeroPos(hero, pos)
    FindClearSpaceForUnit(hero, pos, true)
	
	hero:Stop()
	
	MoveCamera(hero:GetPlayerOwnerID(), hero)

	local particleName = "particles/econ/events/nexon_hero_compendium_2014/teleport_end_ground_flash_nexon_hero_cp_2014.vpcf"
	local particle = ParticleManager:CreateParticle( particleName, PATTACH_CUSTOMORIGIN, caster )
	ParticleManager:SetParticleControl( particle, 0, hero:GetAbsOrigin() )
end

function SendPortalMsg(pid, msg)
    Notifications:Bottom(pid, {text=msg, duration=5, style={color="red", ["font-size"]="45px"}})
end