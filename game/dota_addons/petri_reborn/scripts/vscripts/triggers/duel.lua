require('duels')

function OnEnter(trigger)
	print("OnEnter")
	
	if trigger.activator:IsRealHero() and trigger.activator:GetTeam() == DOTA_TEAM_BADGUYS and Duels.pcount <= 1 then	
	    Duels:NewDuelist(trigger.activator, trigger.activator:GetPlayerOwnerID())
	end
end

function OnExit(trigger)
	print("OnExit")
	--print(Duels.pcount)
	
	--if Duels.pcount <= 1 then
	    --Duels:ClearDuelists()
	--end
end