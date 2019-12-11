function apply( event )
	local caster = event.caster
	local ability = event.ability
	
	if tonumber(lvls[caster:GetPlayerOwnerID()]) >= 50 then
	   	ability:ApplyDataDrivenModifier(caster, caster, "modifier_item_petri_cola_lvl50", nil) 
	else
	   	ability:ApplyDataDrivenModifier(caster, caster, "modifier_item_petri_cola_default", nil) 	
	end
end	