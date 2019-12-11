if RandomMap == nil then
    _G.RandomMap = class({})
    
	RandomMap.Types = {}
    RandomMap.MAX_TYPES = 2
    RandomMap.MAX_TYPES_SUB = 10
    RandomMap.NAME_TYPES = "rm_type_"

    RandomMap.Places = {}
    RandomMap.MAX_PLACES = 10
    RandomMap.NAME_PLACES = "rm_place_"
	
	RandomMap.NAME_COL = "_col"
end

function RandomMap:Init()
    RandomMap:GetAllPlaces()
	RandomMap:GetAllTypes()
	
	RandomMap:SetRTypesToAllPlaces()
end

function RandomMap:GetAllPlaces()
    for i = 1, RandomMap.MAX_PLACES do
	    print(tostring(RandomMap.NAME_PLACES..i))
	    RandomMap.Places[i] = Entities:FindByName( nil, tostring(RandomMap.NAME_PLACES..i))
		print(RandomMap.Places[i])
	end
end

function RandomMap:GetAllTypes()
    for i = 1, RandomMap.MAX_TYPES do
	    RandomMap.Types[i] = {}
		for j = 1, RandomMap.MAX_TYPES_SUB do
	        print(tostring(RandomMap.NAME_TYPES..i.."_"..j))
	        RandomMap.Types[i][j] = Entities:FindByName( nil, tostring(RandomMap.NAME_TYPES..i.."_"..j))
			print(RandomMap.Types[i][j])
		end
	end
end

function RandomMap:SetRTypesToAllPlaces()
    for i = 1, RandomMap.MAX_PLACES do
	    RandomMap:SetRTypeToPlace(RandomMap.Places[i])
	end
	RandomMap:RemoveRestTypesAndSubs()
end

function RandomMap:SetRTypeToPlace(place)
    if place ~= nil then
    local pos = place:GetAbsOrigin()
	local rtype = math.random(1, RandomMap.MAX_TYPES)
	for i = 1, RandomMap.MAX_TYPES_SUB do
	    local ype = RandomMap.Types[rtype][i]
		if ype.placed ~= true then
		    ype.placed = true
			ype:SetAbsOrigin(pos)
			RandomMap:AddCol(tostring(RandomMap.NAME_TYPES..rtype.."_"..i), pos)
			break
		end
	end
	end
end

function RandomMap:RemoveRestTypesAndSubs()
    for i = 1, RandomMap.MAX_TYPES do
	    for j = 1, RandomMap.MAX_TYPES_SUB do
		    local ype = RandomMap.Types[i][j]
			if ype.placed ~= true then
				print("remove "..i.." "..j)
			    UTIL_Remove(ype)
			end
		end
	end
	UTIL_Remove(Entities:FindByName(nil, tostring("rm_test")))
	print(Entities:FindByName(nil, tostring("rm_test")))
end

function RandomMap:AddCol(name, point)
    print(tostring(name..RandomMap.NAME_COL))
    local col = Entities:FindByName( nil, tostring(name..RandomMap.NAME_COL))
	col:SetAbsOrigin(point)
end