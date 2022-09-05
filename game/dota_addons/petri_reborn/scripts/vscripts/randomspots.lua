if RandomSpots == nil then
    _G.RandomSpots = class({})
end

function RandomSpots:Init()
	RandomSpots.INFO_TARGET_NAME = "spot_spawn_point"
	RandomSpots.SPOT_TYPE_COUNT = 16

	RandomSpots:LoadSpots()
end

function RandomSpots:LoadSpots()
	for _,info_target in pairs(Entities:FindAllByName(RandomSpots.INFO_TARGET_NAME)) do
		if info_target then
			RandomSpots:SpawnSpot(info_target:GetOrigin())
		end
	end
end

function RandomSpots:SpawnSpot(location)
	DOTA_SpawnMapAtPosition(RandomSpots:RandomMapName(), location, false, nil, nil, nil)
end

function RandomSpots:RandomMapName()
	return "spots/"..tostring(RandomInt(1, RandomSpots.SPOT_TYPE_COUNT))
end