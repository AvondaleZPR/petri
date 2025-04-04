SU = {}

SU.StatSettings = LoadKeyValues('scripts/kv/StatUploaderSettings.kv')
SU.IsStatServerUp = true

local isStatServerUp = true

-- Request function
function SU:SendRequest( requestParams, successCallback )
  if not SU.IsStatServerUp then
    return
  end
  
  -- Adding auth key
  requestParams.AuthKey = SU.StatSettings.AuthKey
  -- DeepPrintTable(requestParams)

  -- Create the request
  local request = CreateHTTPRequestScriptVM('POST', SU.StatSettings.Host)
  request:SetHTTPRequestGetOrPostParameter('CommandParams', json.encode(requestParams))

  -- Send the request
  request:Send(function(res)
    if res.StatusCode ~= 200 or not res.Body then
        -- Bad request
        SU.IsStatServerUp = false
        
        print("Request error. See info below: ")
        DeepPrintTable(res)
        return
    end

    -- Try to decode the result
    local obj, pos, err = json.decode(res.Body, 1, nil)
    
    -- if not a JSON send full body
    if obj == nil then
      obj = res.Body
    end
    
    -- Feed the result into our callback
    successCallback(obj)
  end)
end

-------------------------------------------------------------------------------
-- Testing functions
-------------------------------------------------------------------------------

-- Testing event
CustomGameEventManager:RegisterListener( "su_test_request", Dynamic_Wrap(SU, 'Test'))

function SU:Test()
  local requestParams = {
    Command = "Testing"
  }
    
  SU:SendRequest( requestParams, function(obj)
      print("Testing result: ", obj)
  end)
end