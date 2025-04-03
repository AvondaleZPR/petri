function Precache(context)
  print("SASAT PRECACHE")

  local function isPlayerSteamIdInGame(iSteamID)
    for iPlayerID = 0, PlayerResource:GetPlayerCount()-1 do
      local iPlayerSteamId = PlayerResource:GetSteamAccountID(iPlayerID)
      if iPlayerSteamId and iPlayerSteamId > 0 and tonumber(iPlayerSteamId) == iSteamID then
        print("SASAT ID IN GAME "..iSteamID)
        return true
      end
    end
    return false
  end

  for k,v in pairs(LoadKeyValues("scripts/kv/custom_skins.kv")) do
    for id,m in pairs(v) do
      if id == "english" or id == "russian" or isPlayerSteamIdInGame(tonumber(id)) then
        for __,g in pairs(m) do
          if string.match(__, "vmdl") then
           print("sasat "..__)
           PrecacheResource("model", __, context)
          end
        end
      end
    end
  end
end