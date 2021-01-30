require('libraries/util/split')
require('libraries/BigNum')

if Rating == nil then
    _G.Rating = class({})
end

function Rating:init()
    Rating.PLAYERS_REQUIERD = 6
	Rating.TOPS = {"rating", "kills", "totalgold", "lvl"}
    
    Rating.playerProfile = {}
	Rating.key = GetDedicatedServerKeyV2("petro")
	Rating.newKey = GetDedicatedServerKeyV2("petro")
	
	Rating.url = "http://185.180.231.205/?"
	Rating.topUrl = "http://185.180.231.205/top.php/?"
	Rating.errorUrl = "http://185.180.231.205/error.php?"
	Rating.gameUrl = "http://185.180.231.205/game.php?"
	Rating.feedbackUrl = "http://185.180.231.205/feedback.php/?"
	
	Rating.isRankedGame = false
	Rating.LastRequestBody = nil
	Rating.Connected = false
	
	Rating.avg_total = 0
	Rating.avg_count = 0
	
	Rating.currExp = {}
	Rating.rangs = {}
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
	local req = CreateHTTPRequest("GET",url)
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
	for i = 1, 4 do
	local url = Rating.topUrl.."stat="..Rating.TOPS[i]
	local req = CreateHTTPRequest("GET",url)
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
	local req = CreateHTTPRequest("GET",url)
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
	
	Rating.avg_total = Rating.avg_total + tonumber(obj[1]["rating"])
	Rating.avg_count = Rating.avg_count + 1
	Rating.avg_rating = Rating.avg_total / Rating.avg_count
	
	lvls[obj.pid] = tonumber(obj[1]["lvl"])
	Rating.currExp[obj.pid] = tonumber(obj[1]["lvl"])
	
	Rating.rangs[obj.pid] = math.floor(tonumber(obj[1]["rating"])/100)
	if Rating.rangs[obj.pid] < 1 then 
		Rating.rangs[obj.pid] = 1
	elseif Rating.rangs[obj.pid] > 24 then
		Rating.rangs[obj.pid] = 24
	end
	
	if Rating.currExp[obj.pid] == nil then
	    Rating.currExp[obj.pid] = 0
	end
	
	Timers:CreateTimer(1, function() 
	    CustomGameEventManager:Send_ServerToAllClients( "new_send_rating", obj )
		
		if GameRules:State_Get() ~= DOTA_GAMERULES_STATE_CUSTOM_GAME_SETUP then
		    return nil
		end
		return 1.0
	end)
end

function Rating:SetPlayerProfiles()
    for i = 0, PlayerResource:GetPlayerCount() do
	if PlayerResource:IsValidPlayer(i) then
	    Rating.playerProfile[i] = class({})
		Rating.playerProfile[i].kills = 0
		Rating.playerProfile[i].gold = 0
		Rating.playerProfile[i].team = PlayerResource:GetTeam(i)
		Rating.playerProfile[i].sid = PlayerResource:GetSteamAccountID(i)
		Rating.playerProfile[i].pid = i
	end
	end
end

function Rating:UpdatePlayerProfile(pid, stat, count)
    print('RATING '..pid.." "..stat.." "..count)
	
	if Rating.playerProfile[pid] then
	
	if stat == "kills" then
	    Rating.playerProfile[pid].kills = Rating.playerProfile[pid].kills + count
	elseif stat == "gold" then
	    Rating.playerProfile[pid].gold = Rating.playerProfile[pid].gold + count
	end
	
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
	
	if lvls[profile.pid] == nil then
	   lvls[profile.pid] = 0 
	end
	if Rating.currExp[profile.pid] == nil then
	   Rating.currExp[profile.pid] = 0 
	end	
	
	local lvl = lvls[profile.pid] - Rating.currExp[profile.pid]
	
	local url = tostring(Rating.url.."sid="..profile.sid.."&key="..Rating.key.."&victory="..victory.."&petri="..petri.."&kills="..profile.kills.."&gold="..profile.gold.."&avg="..Rating.avg_rating.."&exp="..lvl)
    print("RATING url "..url)
	Rating:SimpleRequest(url)
end

function Rating:SendMatch()
	local map = GetMapName()
	local winner = "kvn"
	if GameRules.Winner == DOTA_TEAM_BADGUYS then
		winner = "petri"
	end
	
	local url = Rating.gameUrl.."key="..Rating.newKey.."&winner="..winner.."&map="..map
	
	for i = 0, 20 do
		if Rating.playerProfile[i] then
			local purl = "&p"..i.."="
		
			purl = purl.."sid:"..Rating.playerProfile[i].sid
			purl = purl.."_gold:"..Rating.playerProfile[i].gold
			purl = purl.."_kills:"..Rating.playerProfile[i].kills
			purl = purl.."_team:"..Rating.playerProfile[i].team
		
			if scoreArr[i] then
				purl = purl.."_score:"..scoreArr[i]
			end
		
			url = url..purl
		end
	end
	
	url:gsub("%s+", "")
	--print("sendmatch url "..url)
	
	Timers:CreateTimer(5, function()
		Rating:SimpleRequest(url)
		Timers:CreateTimer(2, function()
			print("sendmatch id "..Rating.LastRequestBody)
			GameRules:SendCustomMessage("<font color='#FF00FF'>"..tostring(Rating.LastRequestBody).."</font>", 0, 0)
		end)
	end)
end

--[[
function Rating:GetAvgRating(rating)
    return tonumber((Rating.avg_total - rating) / (Rating.avg_count - 1))
end
]]

function OnFeedBack(eventSourceIndex, args)
	local str = args["feedback"]
	
	local badSymb = {"&", "#", "'", ""}
	for i = 1, #badSymb	do
		str = str:gsub(badSymb[i], "")
	end
	
	str = str:gsub("%s+", "_")

	local url = Rating.feedbackUrl.."feedback="..str.."&sid="..tostring(PlayerResource:GetSteamAccountID(args["PlayerID"]))
	Rating:SimpleRequest(url)
end
CustomGameEventManager:RegisterListener( "petri_send_feedback", OnFeedBack )