function RemoveSnare( keys )
	local caster = keys.caster
	local target = keys.target
    local ability = keys.ability
	target:RemoveModifierByName("modifier_snare")
	
	if target:GetPlayerOwner() == caster:GetPlayerOwner() and caster:IsRealHero() then
	ability:ApplyDataDrivenModifier(caster, target, "modifier_item_petri_alcohol_active", nil)
	if tonumber(lvls[caster:GetPlayerOwnerID()]) >= 20 then
	    ability:ApplyDataDrivenModifier(caster, target, "modifier_item_petri_alcohol_parcticle_lvl20", nil)
	else
	    ability:ApplyDataDrivenModifier(caster, target, "modifier_item_petri_alcohol_parcticle_default", nil)
	end
	ability:SetCurrentCharges(ability:GetCurrentCharges()-1)
	if ability:GetCurrentCharges() <= 0 then
	    ability:Kill()
    end	
	else
	    ability:EndCooldown() 
	end
end