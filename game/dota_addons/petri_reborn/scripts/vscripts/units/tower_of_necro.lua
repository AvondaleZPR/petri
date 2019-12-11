function Upgrade ( event   )
	local caster = event.caster
	local ability = event.ability

	local tower_level = ability:GetLevel()

	if tower_level == 1 then
		UpdateModel(caster, "models/items/pugna/ward/draining_wight/draining_wight.vmdl", 0.7)
	elseif tower_level == 2 then 
		caster:SetModelScale(0.75)
	elseif tower_level == 3 then
		caster:SetModelScale(0.8)
	elseif tower_level == 4 then
		caster:SetModelScale(0.85)
	end

	SetCustomBuildingModel(caster, PlayerResource:GetSteamAccountID(caster:GetPlayerOwnerID()), tower_level)

	local attack = ability:GetLevelSpecialValueFor("attack", tower_level)
	local attack_rate = ability:GetLevelSpecialValueFor("attack_rate", tower_level)

	ability:GetCaster():SetBaseDamageMax(attack)
	ability:GetCaster():SetBaseDamageMin(attack)

	ability:ApplyDataDrivenModifier(caster, caster, "modifier_attack_speed", {})
end

function DamageAura( event )
	local caster = event.caster
	local ability = event.ability
	
	local aura_radius = ability:GetSpecialValueFor("aura_radius")
	local damage_percent = ability:GetSpecialValueFor("damage_percent")

	local units = FindUnitsInRadius(caster:GetTeam(), caster:GetAbsOrigin(), nil, aura_radius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO, 0, 0, false)
	for k,v in pairs(units) do
		if IsValidEntity(v) then
			local damageTable = {
		        victim = v,
		        attacker = caster,
		        damage = v:GetMaxHealth()*damage_percent,
		        damage_type = DAMAGE_TYPE_PURE,
			}
		    ApplyDamage(damageTable)
		end
	end
end