function ApplyBonusDamage( event )
	local caster = event.caster
	local ability = event.ability

	local units = FindUnitsInRadius(DOTA_TEAM_GOODGUYS, caster:GetAbsOrigin(), nil, ability:GetSpecialValueFor("radius"), DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_ALL, 0, 0, false)

	caster:EmitSound("Hero_LegionCommander.Duel.Cast")

	for k,v in pairs(units) do
		if v:GetPlayerOwnerID() == caster:GetPlayerOwnerID() and v:HasAttackCapability() and
			v:HasAbility("petri_building") then
			ability:ApplyDataDrivenModifier(caster, v, "modifier_item_petri_attack_scroll_active", {duration = ability:GetSpecialValueFor("duration")})
			local fxName = "particles/items_fx/aegis_timer_i.vpcf"
		    if tonumber(lvls[caster:GetPlayerOwnerID()]) >= 75000 then
				ability:ApplyDataDrivenModifier(caster, v, "modifier_item_petri_attack_scroll_lvl40", {duration = ability:GetSpecialValueFor("duration")})
				fxName = "particles/items_fx/aegis_timer_k.vpcf"
			else
			    ability:ApplyDataDrivenModifier(caster, v, "modifier_item_petri_attack_scroll_default", {duration = ability:GetSpecialValueFor("duration")})
			end
		
			local fxIndex = ParticleManager:CreateParticle( fxName, PATTACH_ABSORIGIN, v)
			ParticleManager:SetParticleControl( fxIndex, 0, v:GetAbsOrigin() )
			ParticleManager:ReleaseParticleIndex( fxIndex )
		end
	end
end