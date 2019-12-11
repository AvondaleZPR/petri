require('libraries/util/split')
require('libraries/BigNum')

local url = "http://151.248.118.61:3000/rating"
local urlpaste = "https://pastebin.com/raw/vXKQUa9n"
--local url = "http://localhost:3000/rating"

--local lvls = {1,1,1,1,1,1,1,1,1,1,1,1,1,1,1}
--lvls[0] = 1

local key = GetDedicatedServerKey("v1")

function loadrating()
    print("loadrating")
    local req = CreateHTTPRequestScriptVM("GET",url)
    req:Send(function(res)
        if res.StatusCode ~= 200 then
		    IS_RANKED_GAME = false
            print("load rating: CONNECTION FAILED, loading from pastebin")
			loadratingpastebin()	
        else 
		    lr(res.Body)
		end
    end)
end

function loadratingpastebin()
    local req = CreateHTTPRequestScriptVM("GET", urlpaste)
	req:Send(function(res)
	    if res.StatusCode ~= 200 then
		    print("load rating: CONNECTION FULLY FAILED")
		else
		    lr(res.Body)
		end
	end)
end

function lr(body)
		    print("load rating: CONNECTED")
			local rating = split(body, " ")
			local top = {0, 1}
			local toplvl = {0, 0}
			Timers:CreateTimer(3, function()
			for _, n in pairs(rating) do
			    local arr = split(n, "_")
				if tonumber(arr[2]) ~= nil and top[2] ~= nil then
				if tonumber(arr[2]) > top[2] then
				    top[1] = tonumber(arr[1])
					top[2] = tonumber(arr[2])
				end
				end
				if tonumber(arr[3]) ~= nil and toplvl[2] ~= nil then
				if tonumber(arr[3]) > toplvl[2] then
				    toplvl[1] = tonumber(arr[1])
					toplvl[2] = tonumber(arr[3])
				end
				end
				for i = 0,PlayerResource:GetPlayerCount() do
				if PlayerResource:IsValidPlayer(i) and PlayerResource:GetConnectionState(i) == DOTA_CONNECTION_STATE_CONNECTED then
					if(tostring(PlayerResource:GetSteamAccountID(i)) == tostring(arr[1])) then  
					    print("load rating: GOT PLAYER RATING")
						print("load rating player level: "..arr[3])
						lvls[i] = arr[3]
                        local event_data =
                        {
                            pid = i,
                            rating = arr[2],
							lvl = arr[3],
                        }
                        CustomGameEventManager:Send_ServerToAllClients( "send_rating", event_data )
						GameMode.ratingArr[i] = arr[2]
					end
					--print("ratingArr: "..GameMode.ratingArr[i])					
				end
				end
			end
			afterLoad()
			local a = BigNum.new(top[1])
			local b = BigNum.new("76561197960265728")
			local c = BigNum.new(0)
			BigNum.add(a, b, c)
			c = tostring(c)
			--print(c)
			local event_data =
            {
                steamid = c,
                rating = top[2],
            }
            CustomGameEventManager:Send_ServerToAllClients( "set_top", event_data )
			
			local d = BigNum.new(toplvl[1])
			local e = BigNum.new("76561197960265728")
			local f = BigNum.new(0)
			BigNum.add(d,e,f)
		    f = tostring(f)
			local event_data =
            {
                steamid = f,
                lvl = toplvl[2],
            }
			CustomGameEventManager:Send_ServerToAllClients( "set_top_lvl", event_data )
		    return nil
            end)
end

function afterLoad()
    Timers:CreateTimer(1, function()
	if GameRules:State_Get() == DOTA_GAMERULES_STATE_CUSTOM_GAME_SETUP then
	    for i = 0, PlayerResource:GetPlayerCount() do
		if PlayerResource:IsValidPlayer(i) and PlayerResource:GetConnectionState(i) == DOTA_CONNECTION_STATE_CONNECTED then
		    local event_data =
            {
                pid = i,
                rating = GameMode.ratingArr[i],
				lvl = lvls[i],
            }
            CustomGameEventManager:Send_ServerToAllClients( "send_rating", event_data )
		end
		end
		return 1.0
	else
	    return 0.0
	end
    end)
end

function saverating(steamid, rating, pid)
    if IS_RANKED_GAME == true then
    print("saverating")
	
	local payload = {
        steamid = steamid,
		rating = rating,
		key = key,
		lvl = (lvls[pid]),
    }
	
	print(payload.lvl)
	
	local encoded = json.encode(payload)
	local req = CreateHTTPRequestScriptVM("POST",url)
	req:SetHTTPRequestGetOrPostParameter('payload', encoded)
	
	req:Send(function(res)
        if res.StatusCode ~= 200 then
		    print("save rating: CONNECTION FAILED")
        else
		    print("save rating: CONNECTED")
		end
	end)
	else
	    print("ne segodnya bro")
	end
end