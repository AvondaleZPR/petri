--[[
	Author: Noya
	Date: 12.02.2015.
	Creates an item on the buildings inventory to consume the queue.
]]
Debug_Queue = false
function EnqueueUnit( event, food )
	local caster = event.caster
	local ability = event.ability
	local player = caster:GetPlayerOwner():GetPlayerID()
	local gold_cost = GetAbilityGoldCost( ability )

	if GetCustomGold( caster:GetPlayerOwnerID() ) < gold_cost then
		return
	end

	local hero = GameMode.assignedPlayerHeroes[caster:GetPlayerOwnerID()]

	if hero.numberOfUnits >= GameRules.PETRI_MAX_WORKERS or hero.numberOfMegaWorkers >= GameRules.PETRI_MAX_MEGA_WORKERS then
		Notifications:Top(caster:GetPlayerOwnerID(),{text="#max_number_of_workers", duration=3, style={color="red"}, continue=false})
		if ability:GetAutoCastState() == true then ability:ToggleAutoCast() end
		return false
	end

	-- Initialize queue
	if not ability.queue then
		ability.queue = {}
	end

	-- Queue up to 6 units max
	if #ability.queue < 6 then

		if CheckFood(caster:GetPlayerOwner(), tonumber(event.food),true)== false then 
			return 
		else
			SpendCustomGold( caster:GetPlayerOwnerID(), gold_cost )
			SpendFood(caster:GetPlayerOwner(), tonumber(event.food))
			hero.numberOfUnits = hero.numberOfUnits + 1
			if tonumber(event.food) == 6 then hero.numberOfMegaWorkers = hero.numberOfMegaWorkers + 1 end
		end

		caster.queueFood = caster.queueFood or 0
		caster.queueFood = caster.queueFood + tonumber(event.food)

		local ability_name = ability:GetAbilityName()
		local item_name = "item_"..ability_name
		local item = CreateItem(item_name, caster, caster)
		caster:AddItem(item)

		-- RemakeQueue
		ability.queue = {}
		for itemSlot = 0, 5, 1 do
			local item = caster:GetItemInSlot( itemSlot )
			if item ~= nil then
				table.insert(ability.queue, item:GetEntityIndex())
			end
		end
	else
		Notifications:Bottom(player, {text="#queue_is_full", duration=1, style={color="red", ["font-size"]="45px"}})

		-- Refund with message
		FireGameEvent( 'custom_error_show', { player_ID = player, _error = "Queue is full" } )		
	end
end

function SetOwner( event )
	local caster = event.caster
	local target = event.target

	local hero = GameMode.assignedPlayerHeroes[caster:GetPlayerOwnerID()]

	target.foodSpent = tonumber(event.food)
	target:SetOwner(hero)

	target.hasNumber = true
end

-- Destroys an item on the buildings inventory, refunding full cost of purchasing and reordering the queue
-- If its the first slot, the channeling ability is also set to not channel, refunding the full price.
function DequeueUnit( event )
	local caster = event.caster
	local item = event.ability
	local player = caster:GetPlayerOwner():GetPlayerID()

	local item_ability = EntIndexToHScript(item:GetEntityIndex())
	local item_ability_name = item_ability:GetAbilityName()

	-- Get tied ability
	local train_ability_name = string.gsub(item_ability_name, "item_", "")
	local train_ability = caster:FindAbilityByName(train_ability_name)
	local gold_cost = GetAbilityGoldCost( train_ability )
	
	local hero = GameMode.assignedPlayerHeroes[caster:GetPlayerOwnerID()]

	if Debug_Queue then
		print("Start dequeue")
	end

	for itemSlot = 0, 5, 1 do
       	local item = caster:GetItemInSlot( itemSlot )
        if item ~= nil then
        	local current_item = EntIndexToHScript(item:GetEntityIndex())

        	if current_item == item_ability then
        		if Debug_Queue then
	        		print("Q")
	        		DeepPrintTable(train_ability.queue)
        		end
        		local queue_element = getIndex(train_ability.queue, item:GetEntityIndex())
        		if Debug_Queue then
        			print(item:GetEntityIndex().." in queue at "..queue_element)
        		end
	            table.remove(train_ability.queue, queue_element)

	            caster:RemoveItem(item)
	            
	            -- Refund ability cost
	            AddCustomGold( player, gold_cost )

	            hero.numberOfUnits = hero.numberOfUnits - 1

	            local foodToReturn = train_ability:GetLevelSpecialValueFor("food_cost", 1)
	            local hero = caster:GetPlayerOwner():GetAssignedHero()
	            hero.food = hero.food - foodToReturn

	            if foodToReturn == 6 then hero.numberOfMegaWorkers = hero.numberOfMegaWorkers - 1 end

	            caster.queueFood = caster.queueFood - foodToReturn

	            if Debug_Queue then
					print("Refund ",gold_cost)
				end

				-- Set not channeling if the cancelled item was the first **current** slot
				if itemSlot == 0 then
					train_ability:SetChanneling(false)
					train_ability:EndChannel(true)
					if Debug_Queue then
						print("Cancel current channel")
					end
					ReorderItems(caster,train_ability.queue)
				else
					if Debug_Queue then
						print("Removed unit in queue slot",itemSlot)	
					end				
				end
				break
			end
        end
    end
end

-- Auxiliar function, takes all items and puts them 1 slot back
function ReorderItems( caster, queue )
	queue = {}
	for itemSlot = 0, 5, 1 do
		local item = caster:GetItemInSlot( itemSlot )
       	if item ~= nil then
       		if Debug_Queue then
       			print("========>REMOVING",item:GetEntityIndex())   		
       		end
    		local new_item = CreateItem(item:GetName(), caster, caster)
       		caster:RemoveItem(item)
			table.insert(queue, new_item:GetEntityIndex())
			if Debug_Queue then
				print("========>ADDED",new_item:GetEntityIndex())   	
			end	
       		caster:AddItem(new_item)
       	end
    end
end


-- Moves on to the next element of the queue
function NextQueue( event )
	local caster = event.caster
	local ability = event.ability
	ability:SetChanneling(false)
	--print("Move next!")

	-- Dequeue
	--DeepPrintTable(event)
	local hAbility = EntIndexToHScript(ability:GetEntityIndex())

	for itemSlot = 0, 5, 1 do
       	local item = caster:GetItemInSlot( itemSlot )
        if item ~= nil then
        	local item_name = tostring(item:GetAbilityName())

        	-- Remove the "item_" to compare
        	local train_ability_name = string.gsub(item_name, "item_", "")

        	if train_ability_name == hAbility:GetAbilityName() then

        		local train_ability = caster:FindAbilityByName(train_ability_name)

        		if Debug_Queue then
	        		print("Q")
	        		DeepPrintTable(train_ability.queue)
        		end
        		local queue_element = getIndex(train_ability.queue, item:GetEntityIndex())
        		if IsValidEntity(item) then
        			if Debug_Queue then
	        			print(item:GetEntityIndex().." in queue at "..queue_element)
	        		end
		            table.remove(train_ability.queue, queue_element)
	            	caster:RemoveItem(item)
	            end

            	break
            elseif item then
        		--print(item_name,hAbility:GetAbilityName())
        	end
        end
    end
end

function AdvanceQueue( event )
	local caster = event.caster
	local ability = event.ability

	if not IsChanneling( caster ) then
		-- RemakeQueue
		ability.queue = {}

		-- Check the first item that contains "train" on the queue
		for itemSlot=0,5 do
			local item = caster:GetItemInSlot(itemSlot)
			if item ~= nil then

				table.insert(ability.queue, item:GetEntityIndex())

				local item_name = tostring(item:GetAbilityName())
				if not IsChanneling( caster ) and string.find(item_name, "train") then
					-- Find the name of the tied ability-item: 
					--	ability = human_train_footman
					-- 	item = item_human_train_footman
					local train_ability_name = string.gsub(item_name, "item_", "")

					local ability_to_channel = caster:FindAbilityByName(train_ability_name)

					ability_to_channel:SetChanneling(true)
					if Debug_Queue then
						print(ability_to_channel:GetAbilityName()," started channel")
					end
					-- After the channeling time, check if it was cancelled or spawn it
					-- EndChannel(false) runs whatever is in the OnChannelSucceded of the function
					Timers:CreateTimer(ability_to_channel:GetChannelTime(), 
					function()
						if Debug_Queue then
							print("===Queue Table====")
							DeepPrintTable(ability_to_channel.queue)
						end
						if IsValidEntity(item) and IsValidEntity(caster) then
							ability_to_channel:EndChannel(false)
							ReorderItems(caster, ability_to_channel.queue)

							caster.queueFood = caster.queueFood - ability_to_channel:GetLevelSpecialValueFor("food_cost", 1)

							if Debug_Queue then
								print("Unit finished building")
							end
						else
							if Debug_Queue then
								print("This unit was interrupted")
							end
						end
					end)
				end
			end
		end
	end
end

-- Auxiliar table function
function tableContains(list, element)
    if list == nil then return false end
    for i=1,#list do
        if list[i] == element then
            return true
        end
    end
    return false
end

function getIndex(list, element)
    if list == nil then return false end
    for i=1,#list do
        if list[i] == element then
            return i
        end
    end
    return -1
end

function getUnitIndex(list, unitName)
    --print("Given Table")
    --DeepPrintTable(list)
    if list == nil then return false end
    for k,v in pairs(list) do
        for key,value in pairs(list[k]) do
        	if Debug_Queue then
          	  print(key,value)
          	end
            if value == unitName then 
                return key
            end
        end        
    end
    return -1
end

-- Auxiliar function that goes through every ability and item, checking for any ability being channelled
function IsChanneling ( unit )
	
	for abilitySlot=0,15 do
		local ability = unit:GetAbilityByIndex(abilitySlot)
		if ability ~= nil and ability:IsChanneling() then 
			return true
		end
	end

	for itemSlot=0,5 do
		local item = unit:GetItemInSlot(itemSlot)
		if item ~= nil and item:IsChanneling() then
			return true
		end
	end

	return false
end

function BuildHero( event )
	local caster = event.caster
	local player = caster:GetPlayerOwner()
	local hero = player:GetAssignedHero()
	local playerID = player:GetPlayerID()
	local unit_name = event.Hero
	local origin = event.caster:GetAbsOrigin() + RandomVector(250)

	-- Get a random position to create the illusion in
	local origin = caster:GetAbsOrigin() + RandomVector(150)

	-- handle_UnitOwner needs to be nil, else it will crash the game.
	local illusion = CreateUnitByName(unit_name, origin, true, hero, nil, hero:GetTeamNumber())
	illusion:SetPlayerID(playerID)
	illusion:SetControllableByPlayer(playerID, true)
	
end