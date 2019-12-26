function OnStartTouch(trigger)
 	local unitName = trigger.activator:GetUnitName()
 	print(unitName)
 	if trigger.activator:GetTeam() == DOTA_TEAM_GOODGUYS then
	    if trigger.activator.isblink ~= true then
	    print("BLOCKING TRIGGER!!!")
 		if trigger.activator.spawnPosition ~= nil then
 			FindClearSpaceForUnit(trigger.activator, trigger.activator.spawnPosition + Vector(-70,-70,0), true)

 			if not trigger.activator:IsStunned() then
 				Notifications:Bottom(trigger.activator:GetPlayerOwnerID(), {text="#you_cant_be_here", duration=2, style={color="red", ["font-size"]="45px"}})
 			end

 			--trigger.activator:GetAbilityByIndex(1):ApplyDataDrivenModifier(trigger.activator, trigger.activator, "modifier_invulnerable", {duration=0.4})

 			trigger.activator:AddNewModifier(trigger.activator, nil, "modifier_stunned", {duration=0.4})

			trigger.activator.insideBlocking = true

	 		Timers:CreateTimer(0.03, function()
	 			MoveCamera(trigger.activator:GetPlayerOwnerID(),trigger.activator)
	 			trigger.activator:Stop()

	 			if trigger.activator:HasAbility("petri_suicide") then
	 				trigger.activator:CastAbilityNoTarget(trigger.activator:FindAbilityByName("petri_suicide"), trigger.activator:GetPlayerOwnerID())
	 			end

	 			trigger.activator.insideBlocking = false
	 		end)
 		end
		end
 	end
end