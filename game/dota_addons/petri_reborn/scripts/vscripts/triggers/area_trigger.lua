function OnStartTouch(trigger)
 	Timers:CreateTimer(0.03, function ()
	    print("IN THE AREA")
 		trigger.activator.currentArea = trigger.caller
 	end)
end
 
function OnEndTouch(trigger)
	if IsValidEntity(trigger.activator) then
	    print("OUT OF THE AREA")
		trigger.activator.currentArea = nil
	end
end

function Activate(...)
	print("Area activated")
end