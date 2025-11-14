BAG_CONTENTS = {}

BAG_CONTENTS["item_petri_kvn_bag_1"] = {}
BAG_CONTENTS["item_petri_kvn_bag_1"]["0"] = "item_petri_gold_bag"
BAG_CONTENTS["item_petri_kvn_bag_1"]["1"] = "item_petri_evasion_scroll"
BAG_CONTENTS["item_petri_kvn_bag_1"]["2"] = "item_petri_evasion_scroll"
BAG_CONTENTS["item_petri_kvn_bag_1"]["3"] = "item_petri_pocketexit"
BAG_CONTENTS["item_petri_kvn_bag_1"]["4"] = "item_petri_kvn_fan_blink"
BAG_CONTENTS["item_petri_kvn_bag_1"]["5"] = "item_petri_trap"
BAG_CONTENTS["item_petri_kvn_bag_1"]["6"] = "item_petri_trap"
BAG_CONTENTS["item_petri_kvn_bag_1"]["7"] = "item_petri_key"

BAG_CONTENTS["item_petri_kvn_bag_2"] = {}
BAG_CONTENTS["item_petri_kvn_bag_2"]["0"] = "item_petri_gold_bag"
BAG_CONTENTS["item_petri_kvn_bag_2"]["1"] = "item_petri_trap"
BAG_CONTENTS["item_petri_kvn_bag_2"]["2"] = "item_petri_evasion_scroll"
BAG_CONTENTS["item_petri_kvn_bag_2"]["3"] = "item_petri_give_permission_to_build"
BAG_CONTENTS["item_petri_kvn_bag_2"]["4"] = "item_petri_kvn_fan_blink"
BAG_CONTENTS["item_petri_kvn_bag_2"]["5"] = "item_petri_key"

BAG_CONTENTS["item_petri_kvn_bag_3"] = {}
BAG_CONTENTS["item_petri_kvn_bag_3"]["0"] = "item_petri_gold_bag2"
BAG_CONTENTS["item_petri_kvn_bag_3"]["1"] = "item_petri_trap"
BAG_CONTENTS["item_petri_kvn_bag_3"]["2"] = "item_petri_evasion_scroll"
BAG_CONTENTS["item_petri_kvn_bag_3"]["3"] = "item_petri_give_permission_to_build2"
BAG_CONTENTS["item_petri_kvn_bag_3"]["4"] = "item_petri_kvn_fan_blink"
BAG_CONTENTS["item_petri_kvn_bag_3"]["5"] = "item_petri_key"

BAG_CONTENTS["item_petri_kvn_bag_4"] = {}
BAG_CONTENTS["item_petri_kvn_bag_4"]["0"] = "item_petri_gold_bag3"
BAG_CONTENTS["item_petri_kvn_bag_4"]["1"] = "item_petri_trap"
BAG_CONTENTS["item_petri_kvn_bag_4"]["2"] = "item_petri_evasion_scroll"
BAG_CONTENTS["item_petri_kvn_bag_4"]["3"] = "item_petri_give_permission_to_build3"
BAG_CONTENTS["item_petri_kvn_bag_4"]["4"] = "item_petri_kvn_fan_blink"
BAG_CONTENTS["item_petri_kvn_bag_4"]["5"] = "item_petri_key"

function OpenBag(keys)
	local caster = keys.caster
	local ability = keys.ability

	local item_name = ability:GetName()

	for i=0,11 do
		local item = caster:GetItemInSlot(i)
		if item and item ~= ability then
			caster:RemoveItem(item)
		end
	end

	UTIL_Remove(ability)

	if BAG_CONTENTS[item_name] then
		for k,v in pairs(BAG_CONTENTS[item_name]) do
			caster:AddItemByName(v)
		end
	end

	--GameMode:SetupVIPItems(caster, PlayerResource:GetSteamAccountID(caster:GetPlayerOwnerID()))
end