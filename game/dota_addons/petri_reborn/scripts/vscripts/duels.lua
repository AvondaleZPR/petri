if Duels == nil then
    _G.Duels = class({})
	
	Duels.DUELTIME = 30
end

function Duels:InitDuels()
    Duels.point = {Entities:FindByName( nil, "duel_tp3"):GetAbsOrigin(), Entities:FindByName( nil, "duel_tp2"):GetAbsOrigin()}
	Duels.center = Entities:FindByName( nil, "duel_center"):GetAbsOrigin()
	
	Duels.pcount = 0
	Duels.pids = {nil, nil}
	
	Duels.ison = false
	
	Duels.time = nil
	
	--Duels.mh = {nil,nil}
end

function Duels:NewDuelist(hero, pid)
	hero.onduel = true

	Duels.pcount = Duels.pcount+1
	Duels.pids[Duels.pcount] = pid
	
	hero:SetAbsOrigin(Duels.point[Duels.pcount])
	PlayerResource:SetCameraTarget(pid, hero)
	Timers:CreateTimer(0.06, function()
	    PlayerResource:SetCameraTarget(pid, nil)
	    return nil
    end)
	
	hero:Stop()
	
	--Duels:Cooldown(hero, 999999)
	
	if Duels.pcount == 2 then
	    Duels:StartDuel()
	end
end

function Duels:ClearDuelists()
    print("CLEARDUELISTS")
    Duels.pcount = 0
	if Duels.pids[1] ~= nil then
	    PlayerResource:GetPlayer(Duels.pids[1]):GetAssignedHero().onduel = false
		--Duels:Cooldown(PlayerResource:GetPlayer(Duels.pids[1]):GetAssignedHero(), 0)
	end
	if Duels.pids[2] ~= nil then
        PlayerResource:GetPlayer(Duels.pids[2]):GetAssignedHero().onduel = false
		--Duels:Cooldown(PlayerResource:GetPlayer(Duels.pids[2]):GetAssignedHero(), 0)
	end
	Duels.pids = {nil, nil}
end

function Duels:StartDuel()
	local hero1 = PlayerResource:GetPlayer(Duels.pids[1]):GetAssignedHero()
	local hero2 = PlayerResource:GetPlayer(Duels.pids[2]):GetAssignedHero()
	
	Duels:ClearModifiers(hero1)
    Duels:ClearModifiers(hero2)
	
	--local item = CreateItem("item_armor_fix",hero1,hero1)
    --item:ApplyDataDrivenModifier(hero1,hero1,"modifier_deniable",{})
	--item = CreateItem("item_armor_fix",hero2,hero2)
    --item:ApplyDataDrivenModifier(hero2,hero2,"modifier_deniable",{})
	
	--hero1:SetTeam(DOTA_TEAM_NOTEAM)
	--hero1:GetPlayerOwner():SetTeam(DOTA_TEAM_NOTEAM)
	--AddFOWViewer( DOTA_TEAM_NOTEAM, Duels.center, 2000, Duels.DUELTIME, false )
	
	hero1:SetTeam(DOTA_TEAM_GOODGUYS)
	
    Timers:CreateTimer(1, function()
	--if Duels.pcount == 2 then
	    Notifications:TopToAll({text="#DUEL_started", duratione=10, style={color="green"}, continue=false})
	    Duels.ison = true
		Duels:Aggr(hero1, hero2)
		Duels:Timer()
		EmitAnnouncerSound('announcer_ann_custom_mode_20')
        return nil
	--end
    end)
end

function Duels:Aggr(hero1, hero2)
    --[[
	hero1:SetAggroTarget(hero2)
    hero2:SetAggroTarget(hero1)
	
	local h1h = hero1:GetHealth()
	local h2h = hero2:GetHealth()
	Duels.mh[1] = hero1:GetMaxHealth()
	Duels.mh[2] = hero2:GetMaxHealth()
	
	hero1:SetMaxHealth(h1h * 5)
	hero1:SetHealth(h1h)
	hero2:SetMaxHealth(h2h * 5)
	hero2:SetHealth(h2h)
	]]
	
	hero1:SetForceAttackTarget(nil)
	hero2:SetForceAttackTarget(nil)
	
	local order = 
	{
		UnitIndex = hero1:entindex(),
		OrderType = DOTA_UNIT_ORDER_ATTACK_TARGET,
		TargetIndex = hero2:entindex()
	}

	ExecuteOrderFromTable(order)
	
	order = 
	{
		UnitIndex = hero2:entindex(),
		OrderType = DOTA_UNIT_ORDER_ATTACK_TARGET,
		TargetIndex = hero1:entindex()
	}

	ExecuteOrderFromTable(order)
	
	hero1:SetForceAttackTarget(hero2)
	hero2:SetForceAttackTarget(hero1)
end

function Duels:Timer()
    Duels.time = 0
    Timers:CreateTimer(1, function()
	    Duels.time = Duels.time + 1
		print("DUELTIME "..Duels.time)
		if Duels.time == Duels.DUELTIME then
		    Duels:EndWithDraw()
			return nil
		end
		if Duels.ison == false then
			return nil		
		end
		return 1.0
    end)
end

function Duels:EndDuel()
    Duels.ison = false
	for i = 1, 2 do
	if Duels.pids[i] and PlayerResource:IsValidPlayer(Duels.pids[i]) then
	    local player = PlayerResource:GetPlayer(Duels.pids[i])
		local hero = player:GetAssignedHero()
		hero.onduel = false
		hero:SetAggroTarget(nil)
		Timers:CreateTimer(0.5, function()
		    hero:SetTeam(DOTA_TEAM_BADGUYS)
			player:SetTeam(DOTA_TEAM_BADGUYS)
		    hero:RespawnHero(false, false)
			hero:SetForceAttackTarget(nil)
			--hero:SetMaxHealth(Duels.mh[i])
			--hero:SetHealth(Duels.mh[i])
		    print("EndDuel")
		    return nil
        end)
	end
	end
	Duels:ClearDuelists()
end

function Duels:EndDuelLose(loserid)
    local msg = ""
	for i = 1, 2 do
	    if Duels.pids[i] and PlayerResource:GetPlayer(Duels.pids[i]) and PlayerResource:GetPlayer(Duels.pids[i]):GetAssignedHero() then
		
	    if Duels.pids[i] ~= loserid then
		    GameMode:addScore(PlayerResource:GetPlayer(Duels.pids[i]):GetAssignedHero(), 5)
			msg = PlayerResource:GetPlayerName(Duels.pids[i])
		else
            GameMode:addScore(PlayerResource:GetPlayer(Duels.pids[i]):GetAssignedHero(), -5)
		end
		
		end
	end
	Notifications:TopToAll({text=msg, duratione=20, style={color="green"}, continue=false})
	Notifications:TopToAll({text="#DUEL_win", duratione=20, style={color="green"}, continue=false})
	Duels:EndDuel()
end

function Duels:EndWithDraw()
    Notifications:TopToAll({text="#DUEL_draw", duratione=20, style={color="green"}, continue=false})
	Duels:EndDuel()
end

--function Duels:Cooldown(hero, cd)
    --for i = 0, 5 do
	    --local item = hero:GetItemInSlot(i)
		--if item then
		    --item:StartCooldown(cd)
			--if cd == 0 then
			    --item:EndCooldown()
			--end
		--end
	--end
--end

function Duels:ClearModifiers(hero)	
	local modifiers = hero:FindAllModifiers()
	if modifiers then
		for k,modifier in pairs(modifiers) do
			--if modifier:IsHiddenModifier() then
		        --hero:RemoveModifierByName(modifier:GetName())
			--end
			if modifier:GetDuration() ~= -1 then
			    modifier:Destroy()
			end
		end
	end
end