require("triggers/area_trigger") -- чтоб триггеры спотов создовать бля

if RandomMap == nil then
    _G.RandomMap = class({})
    
	RandomMap.MaxSpots = 35 -- кол во спотов
	
	RandomMap.MinWidthX = -30
	RandomMap.MinWidthY = -30
	RandomMap.MaxWidthX = 30
	RandomMap.MaxWidthY = 30
	
	RandomMap.PSOwidth = 128
end

function RandomMap:Init()
	RandomMap:Load()
	rmprint(GetWorldMinX().." "..GetWorldMaxX().." "..GetWorldMinY().." "..GetWorldMaxY())
end

function RandomMap:Load()
	for i = 1, RandomMap.MaxSpots do
		RandomMap:CreateNewSpot(i)
	end
end

function RandomMap:CreateNewSpot(id)
	local widthX = RandomMap:WidthToActualWidth(RandomMap:RandomNumber(RandomMap.MinWidthX, RandomMap.MaxWidthX))
	local widthY = RandomMap:WidthToActualWidth(RandomMap:RandomNumber(RandomMap.MinWidthY, RandomMap.MaxWidthY))
	
	local center = RandomMap:GetRandomSpotPoint(widthX, widthY)
	local maxX = Vector(center.x+widthX, center.y+widthX, center.z)
	local maxY = Vector(center.x-widthY, center.y-widthY, center.z)
	
	local areaTrigger = CreateTrigger(center, maxX, maxY)
	areaTrigger:ConnectOutput("OnStartTouch","OnStartTouch")
	--local areaTrigger = SpawnEntityFromTableSynchronous('trigger_dota', {vscripts = "triggers/area_trigger.lua", targetname = "area_trigger", origin = center, model=Entities:FindByName(nil, "petri_idol"):GetModelName(), IsRealHero=1, wait=1})
	areaTrigger:RedirectOutput("OnStartTouch", "OnStartTouch", areaTrigger)
	
	rmprint(areaTrigger:GetBounds().Maxs.x.." "..maxX.x)
	rmprint(areaTrigger:GetBounds().Maxs.y.." "..maxY.y)
	
	ObstructPoint(maxX)
	ObstructPoint(maxY)
	
	CreateTempTree(center, 999999)
	
	rmprint("spot "..id.." created")
end
------------------------
----------pso-----------
------------------------
function ObstructPoint(point)
	rmprint("obstruct point")

	local pso = SpawnEntityFromTableSynchronous("point_simple_obstruction", {origin = point})
	pso:SetEnabled(true, false)
	
	CreateUnitByName("random_map_thing", point, false, nil, nil, DOTA_TEAM_NEUTRALS)
	--SpawnEntityFromTableSynchronous("prop_dynamic", {model = "models/base_platform.vmdl", DefaultAnim=animation, targetname=DoUniqueString("prop_dynamic")})
	
	return pso
end

----------------------------
--------randomcenter--------
----------------------------
function RandomMap:GetRandomSpotPoint(wX, wY)
	local point = nil
	while (not RandomMap:CheckSpot(point, wX, wY)) do
		point = Vector(RandomMap:RandomNumber(GetWorldMinX(), GetWorldMaxX()), RandomMap:RandomNumber(GetWorldMinY(), GetWorldMaxY()), 0)
	end
	return point
end

function RandomMap:CheckSpot(point, wX, wY)
	if point == nil then return false end
	return RandomMap:CheckPoint(point), RandomMap:CheckPoint(Vector(point.x+wX, point.y+wX, point.z)), RandomMap:CheckPoint(Vector(point.x-wY, point.y-wY, point.z))
end

function RandomMap:CheckPoint(point)
	local nearestArea = Entities:FindByNameNearest("area_trigger", point, 10000)
	if IsInsideEntityBounds(Entities:FindByName(nil, "blocking_trigger_b"), point) or GridNav:IsBlocked(point) or IsInsideEntityBounds(nearestArea, point) then
		return false
	end
	
	return true
end

-----------------------------
------------utils------------
-----------------------------
function RandomMap:RandomNumber(min, max)
	return math.abs(math.random(min, max))
end

function RandomMap:WidthToActualWidth(value)
	return value * RandomMap.PSOwidth
end

function rmprint(text)
	if text == nil then text = "nil" end
	print("[RANDOM MAP] "..text)
end

function rmPrintTable(data)
	for k,v in pairs(data) do
		print("[RANDOM MAP | PRINT TABLE] "..k,v)
	end
end

function rmPing(location)
	MinimapEvent(PlayerResource:GetPlayer(0):GetTeam(), nil, location.x, location.y, DOTA_MINIMAP_EVENT_HINT_LOCATION, 30)
end