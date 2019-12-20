require('libraries/util/split')
require('libraries/BigNum')

if Rating == nil then
    _G.Rating = class({})
end

function Rating:init()
    Rating.PLAYERS_REQUIERD = 6
	Rating.TOPS = {"rating", "kills", "totalgold"}
    
    Rating.playerProfile = {}
	Rating.key = GetDedicatedServerKey("v1")
	Rating.url = "http://188.120.231.137/?"
	Rating.topUrl = "http://188.120.231.137/top.php/?"
	Rating.isRankedGame = false
	Rating.LastRequestBody = nil
	Rating.Connected = false
end

function Rating:CheckConnection()
    Rating:SimpleRequest(Rating.url.."sid=1")
	
	Timers:CreateTimer(2, function()
	if Rating.LastRequestBody ~= nil then
	    Rating.Connected = true
		print("Rating connected")
		
	else
	    Rating.Connected = false
		print("Rating connection failed")
	end
	GameMode:DEBUGMSG("rating connected: ", Rating.Connected)
	end)
end

function Rating:SimpleRequest(url)
    local req = CreateHTTPRequestScriptVM("GET",url)
	req:Send(function(res)
        if res.StatusCode == 200 then
            print("rating SimpleRequest 200")		
		    Rating.LastRequestBody = res.Body
		end
    end)
end

function Rating:GetRealPlayerCount()
    local count = 0
	for i = 0, PlayerResource:GetPlayerCount() do
	    if PlayerResource:IsValidPlayer(i) then
		    count = count + 1
		end
	end
	GameMode:DEBUGMSG("Rating player count: ", count)
	return count
end

function Rating:LoadAllPlayers()
    Rating:CheckConnection()
	
	Timers:CreateTimer(5, function()
    if Rating.Connected == true then
		if Rating:GetRealPlayerCount() >= Rating.PLAYERS_REQUIERD and GameRules:IsCheatMode() == false then
		    print('ranked')
	        Rating.isRankedGame = true	    
		end
		for i = 0, PlayerResource:GetPlayerCount() do
		    if PlayerResource:IsValidPlayer(i) then
		        Rating:GetPlayerStat(i)
			end
		end
		Rating:GetTop()
	end
	end)
end

function Rating:GetTop()
	for i = 1, 3 do
	local url = Rating.topUrl.."stat="..Rating.TOPS[i]
	local req = CreateHTTPRequestScriptVM("GET",url)
	req:Send(function(res)
        if res.StatusCode == 200 then
			local obj, pos, err = json.decode(res.Body)
			Rating:SendTop(Rating.TOPS[i], obj)
		end
    end)
	end
end

function Rating:SendTop(stat, obj)
    print("rating top"..stat.." "..obj[1]["sid"])
	local sid = Rating:ConvertSteamId(tonumber(obj[1]["sid"]))
	local data = 
	{
	    sid = sid,
		stat = obj[1][stat]
	}
	CustomGameEventManager:Send_ServerToAllClients( "set_top_"..stat, data )
end

function Rating:ConvertSteamId(sid)
    local a = BigNum.new(sid)
	local b = BigNum.new("76561197960265728")
    local c = BigNum.new(0)
	BigNum.add(a, b, c)
	c = tostring(c)
	return c
end

function Rating:GetPlayerStat(pid)
    print("rating loading player "..pid)
	local url = Rating.url.."sid="..PlayerResource:GetSteamAccountID(pid)
	local req = CreateHTTPRequestScriptVM("GET",url)
	req:Send(function(res)
        if res.StatusCode == 200 then
			local obj, pos, err = json.decode(res.Body)
			obj.pid = pid
			Rating:SendPlayerStat(obj)
		end
    end)
end

function Rating:SendPlayerStat(obj)
    CustomGameEventManager:Send_ServerToAllClients( "new_send_rating", obj )
end

function Rating:SetPlayerProfiles()
    for i = 0, PlayerResource:GetPlayerCount() do
	if PlayerResource:IsValidPlayer(i) then
	    Rating.playerProfile[i] = class({})
		Rating.playerProfile[i].kills = 0
		Rating.playerProfile[i].gold = 0
		Rating.playerProfile[i].team = PlayerResource:GetTeam(i)
		Rating.playerProfile[i].sid = PlayerResource:GetSteamAccountID(i)
	end
	end
end

function Rating:UpdatePlayerProfile(pid, stat, count)
    print('RATING '..pid.." "..stat.." "..count)
	if stat == "kills" then
	    Rating.playerProfile[pid].kills = Rating.playerProfile[pid].kills + count
	elseif stat == "gold" then
	    Rating.playerProfile[pid].gold = Rating.playerProfile[pid].gold + count
	end
end

function Rating:SaveAndSendStats()
    for i = 0, 20 do
	    if Rating.playerProfile[i] ~= nil then
		    GameMode:DEBUGMSG("Rating SASS: ", i)
		    Rating:SaveAndSendPlayer(Rating.playerProfile[i])
		end
	end
end

function Rating:SaveAndSendPlayer(profile)
    local victory = "0"
	if profile.team == GameRules.Winner then
	    victory = "1"
	end
	
	local petri = "0"
	if profile.team == DOTA_TEAM_BADGUYS then
	    petri = "1"
	end
	
	local url = tostring(Rating.url.."sid="..profile.sid.."&key="..Rating.key.."&victory="..victory.."&petri="..petri.."&kills="..profile.kills.."&gold="..profile.gold)
    --print("RATING url "..url)
	Rating:SimpleRequest(url)
end